# 🚀 Déploiement DGTT Auto-École sur Hetzner

## 📋 Informations du Serveur
- **IP du Serveur**: 168.119.123.247
- **OS**: Ubuntu Linux
- **Objectif**: Déploiement complet du système DGTT Auto-École

## ⚠️ ATTENTION - Sauvegarde
Avant de commencer, assurez-vous d'avoir sauvegardé toutes les données importantes sur le serveur !

---

## 🔥 ÉTAPE 1: Nettoyage Complet du Serveur

### **1.1 Connexion au Serveur**
```bash
ssh root@168.119.123.247
```

### **1.2 Arrêter tous les Services Docker (si présents)**
```bash
# Vérifier les conteneurs en cours
docker ps -a

# Arrêter tous les conteneurs
docker stop $(docker ps -aq)

# Supprimer tous les conteneurs
docker rm $(docker ps -aq)

# Supprimer tous les volumes
docker volume rm $(docker volume ls -q)

# Supprimer toutes les images
docker rmi $(docker images -q)
```

### **1.3 Nettoyer le Système**
```bash
# Supprimer tous les dossiers de projets existants
rm -rf /opt/*
rm -rf /home/*/projects
rm -rf /var/www/*
rm -rf /srv/*

# Nettoyer les packages
apt autoremove -y
apt autoclean
apt clean

# Nettoyer les logs
journalctl --vacuum-time=1d
```

### **1.4 Redémarrer le Serveur**
```bash
reboot
```

---

## 🛠️ ÉTAPE 2: Préparation du Serveur

### **2.1 Mise à Jour du Système**
```bash
# Mettre à jour la liste des packages
apt update

# Mettre à jour le système
apt upgrade -y

# Redémarrer si nécessaire
reboot
```

### **2.2 Installation des Prérequis**
```bash
# Installation des outils essentiels
apt install -y curl wget git vim nano htop unzip software-properties-common

# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Ajouter l'utilisateur au groupe docker
usermod -aG docker root

# Installation de Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Vérifier les installations
docker --version
docker-compose --version
```

### **2.3 Configuration du Firewall**
```bash
# Installation d'UFW (Uncomplicated Firewall)
apt install -y ufw

# Configuration des règles de base
ufw default deny incoming
ufw default allow outgoing

# Autoriser SSH
ufw allow ssh

# Autoriser HTTP et HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Autoriser les ports pour le développement (optionnel)
ufw allow 8080/tcp  # Traefik Dashboard
ufw allow 8500/tcp  # Consul UI
ufw allow 15672/tcp # RabbitMQ Management

# Activer le firewall
ufw --force enable

# Vérifier le statut
ufw status
```

---

## 📁 ÉTAPE 3: Création de la Structure du Projet

### **3.1 Création du Dossier Principal**
```bash
# Créer le dossier du projet
mkdir -p /opt/dgtt-auto-ecole
cd /opt/dgtt-auto-ecole

# Créer la structure des dossiers
mkdir -p {backend,frontend-admin,frontend-candidate,frontend-gateway}
mkdir -p {consul,traefik,rabbitmq,database/init}
mkdir -p {security,monitoring,scripts}
```

### **3.2 Vérification de la Structure**
```bash
# Vérifier la structure créée
tree /opt/dgtt-auto-ecole
```

---

## 🐳 ÉTAPE 4: Configuration Docker

### **4.1 Créer le fichier docker-compose.yml**
```bash
cat > /opt/dgtt-auto-ecole/docker-compose.yml << 'EOF'
services:
  # =============================================
  # SERVICE DISCOVERY & CONFIGURATION
  # =============================================
  consul:
    image: consul:1.15
    container_name: dgtt-consul
    command: agent -server -bootstrap-expect=1 -ui -node=server-1 -bind=0.0.0.0 -client=0.0.0.0 -datacenter=dc1
    ports:
      - "8500:8500"
      - "8600:8600/udp"
    volumes:
      - consul_data:/consul/data
      - consul_config:/consul/config
    networks:
      - dgtt-network
    restart: unless-stopped
    environment:
      - CONSUL_BIND_INTERFACE=eth0
    healthcheck:
      test: ["CMD", "consul", "members"]
      interval: 10s
      timeout: 3s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  # =============================================
  # DATABASE
  # =============================================
  postgres:
    image: postgres:15-alpine
    container_name: dgtt-postgres
    environment:
      POSTGRES_DB: dgtt_auto_ecole
      POSTGRES_USER: dgtt_user
      POSTGRES_PASSWORD: dgtt_password_secure_2024
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - dgtt-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dgtt_user -d dgtt_auto_ecole"]
      interval: 10s
      timeout: 5s
      retries: 5

  # =============================================
  # REDIS CACHE
  # =============================================
  redis:
    image: redis:7-alpine
    container_name: dgtt-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - dgtt-network
    restart: unless-stopped
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  # =============================================
  # MESSAGE QUEUE (RabbitMQ)
  # =============================================
  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    container_name: dgtt-rabbitmq
    environment:
      - RABBITMQ_DEFAULT_USER=dgtt_user
      - RABBITMQ_DEFAULT_PASS=dgtt_password_secure_2024
      - RABBITMQ_DEFAULT_VHOST=dgtt_vhost
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - dgtt-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  # =============================================
  # REVERSE PROXY & LOAD BALANCER
  # =============================================
  traefik:
    image: traefik:v3.0
    container_name: dgtt-traefik
    command:
      - --api.dashboard=true
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
      - --certificatesresolvers.letsencrypt.acme.email=admin@dgtt.fr
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_acme:/letsencrypt
    networks:
      - dgtt-network
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`168.119.123.247`) && PathPrefix(`/traefik`)"
      - "traefik.http.routers.traefik.entrypoints=web"

volumes:
  # Database volumes
  postgres_data:
  redis_data:
  rabbitmq_data:
  
  # Service discovery volumes
  consul_data:
  consul_config:
  
  # Traefik volumes
  traefik_acme:

networks:
  dgtt-network:
    driver: bridge
EOF
```

---

## 🗄️ ÉTAPE 5: Configuration de la Base de Données

### **5.1 Créer le script d'initialisation de la base**
```bash
cat > /opt/dgtt-auto-ecole/database/init/01_init_database.sql << 'EOF'
-- DGTT Auto-École Database Initialization
-- Création du schéma de base de données

-- =============================================
-- EXTENSIONS
-- =============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- CORE TABLES
-- =============================================

-- Users table (admins, instructors, candidates)
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    user_type ENUM('admin', 'instructor', 'candidate') NOT NULL,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    email_verified_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Auto-écoles
CREATE TABLE IF NOT EXISTS auto_ecoles (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    license_number VARCHAR(100) UNIQUE NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Instructors
CREATE TABLE IF NOT EXISTS instructors (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    auto_ecole_id BIGINT REFERENCES auto_ecoles(id) ON DELETE CASCADE,
    license_number VARCHAR(100) UNIQUE NOT NULL,
    specialization ENUM('car', 'motorcycle', 'truck') NOT NULL,
    experience_years INTEGER DEFAULT 0,
    hourly_rate DECIMAL(8,2) DEFAULT 0.00,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students/Candidates
CREATE TABLE IF NOT EXISTS students (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    auto_ecole_id BIGINT REFERENCES auto_ecoles(id) ON DELETE CASCADE,
    student_number VARCHAR(100) UNIQUE NOT NULL,
    license_type ENUM('A', 'B', 'C', 'D') NOT NULL,
    registration_date DATE NOT NULL,
    status ENUM('registered', 'in_training', 'completed', 'suspended') DEFAULT 'registered',
    total_hours DECIMAL(5,2) DEFAULT 0.00,
    practical_hours DECIMAL(5,2) DEFAULT 0.00,
    theoretical_hours DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    auto_ecole_id BIGINT REFERENCES auto_ecoles(id) ON DELETE CASCADE,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type ENUM('car', 'motorcycle', 'truck') NOT NULL,
    transmission ENUM('manual', 'automatic') NOT NULL,
    fuel_type ENUM('petrol', 'diesel', 'electric', 'hybrid') NOT NULL,
    status ENUM('available', 'in_use', 'maintenance', 'retired') DEFAULT 'available',
    insurance_expiry DATE,
    technical_inspection_expiry DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Training Sessions
CREATE TABLE IF NOT EXISTS training_sessions (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    student_id BIGINT REFERENCES students(id) ON DELETE CASCADE,
    instructor_id BIGINT REFERENCES instructors(id) ON DELETE CASCADE,
    vehicle_id BIGINT REFERENCES vehicles(id) ON DELETE SET NULL,
    auto_ecole_id BIGINT REFERENCES auto_ecoles(id) ON DELETE CASCADE,
    session_type ENUM('theory', 'practice') NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_hours DECIMAL(3,2) NOT NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lessons
CREATE TABLE IF NOT EXISTS lessons (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    auto_ecole_id BIGINT REFERENCES auto_ecoles(id) ON DELETE CASCADE,
    instructor_id BIGINT REFERENCES instructors(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    lesson_type ENUM('theory', 'practice') NOT NULL,
    duration_hours DECIMAL(3,2) NOT NULL,
    max_students INTEGER DEFAULT 1,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lesson Enrollments
CREATE TABLE IF NOT EXISTS lesson_enrollments (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    lesson_id BIGINT REFERENCES lessons(id) ON DELETE CASCADE,
    student_id BIGINT REFERENCES students(id) ON DELETE CASCADE,
    enrollment_date DATE NOT NULL,
    status ENUM('enrolled', 'attended', 'missed', 'cancelled') DEFAULT 'enrolled',
    attendance_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- EXAM VALIDATION (Manual Process)
-- =============================================
CREATE TABLE IF NOT EXISTS exam_validations (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    student_id BIGINT REFERENCES students(id) ON DELETE CASCADE,
    validator_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    auto_ecole_id BIGINT REFERENCES auto_ecoles(id) ON DELETE CASCADE,
    exam_type ENUM('theory', 'practical', 'final') NOT NULL,
    validation_date DATE NOT NULL,
    status ENUM('pending', 'passed', 'failed', 'cancelled') DEFAULT 'pending',
    score INTEGER,
    max_score INTEGER DEFAULT 100,
    notes TEXT,
    validated_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- NOTIFICATION & MESSAGING TABLES
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'warning', 'error', 'success') DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4(),
    sender_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    receiver_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_instructors_auto_ecole ON instructors(auto_ecole_id);
CREATE INDEX IF NOT EXISTS idx_students_auto_ecole ON students(auto_ecole_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_auto_ecole ON vehicles(auto_ecole_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_training_sessions_student ON training_sessions(student_id);
CREATE INDEX IF NOT EXISTS idx_training_sessions_date ON training_sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_exam_validations_student ON exam_validations(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_validations_validator ON exam_validations(validator_id);
CREATE INDEX IF NOT EXISTS idx_exam_validations_date ON exam_validations(validation_date);

-- =============================================
-- TRIGGERS FOR UPDATED_AT
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN (
            'users', 'auto_ecoles', 'instructors', 'students', 'vehicles',
            'training_sessions', 'lessons', 'lesson_enrollments', 'exam_validations',
            'notifications', 'messages'
        )
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%I_updated_at ON %I;
            CREATE TRIGGER update_%I_updated_at
                BEFORE UPDATE ON %I
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at_column();
        ', table_name, table_name, table_name, table_name);
    END LOOP;
END;
$$;
EOF
```

### **5.2 Créer le script de données de test**
```bash
cat > /opt/dgtt-auto-ecole/database/init/02_seed_data.sql << 'EOF'
-- DGTT Auto-École Seed Data
-- Données de test pour le développement

-- Insert sample auto-écoles
INSERT INTO auto_ecoles (name, address, phone, email, license_number) VALUES
('Auto-École Excellence', '123 Avenue de la République, 75011 Paris', '+33 1 23 45 67 89', 'contact@excellence-auto.fr', 'AE-2024-001'),
('Auto-École Pro Drive', '456 Boulevard Saint-Germain, 75006 Paris', '+33 1 98 76 54 32', 'info@prodrive.fr', 'AE-2024-002'),
('Auto-École Sécurité Plus', '789 Rue de Rivoli, 75001 Paris', '+33 1 11 22 33 44', 'contact@securiteplus.fr', 'AE-2024-003');

-- Insert sample users (admin, instructors, candidates)
INSERT INTO users (name, email, password, phone, user_type, status) VALUES
-- Admin users
('Admin DGTT', 'admin@dgtt.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 1 00 00 00 01', 'admin', 'active'),

-- Instructors
('Marie Dubois', 'marie.dubois@excellence-auto.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 1 23 45 67 01', 'instructor', 'active'),
('Pierre Martin', 'pierre.martin@excellence-auto.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 1 23 45 67 02', 'instructor', 'active'),
('Sophie Laurent', 'sophie.laurent@prodrive.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 1 98 76 54 01', 'instructor', 'active'),
('Jean Moreau', 'jean.moreau@securiteplus.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 1 11 22 33 01', 'instructor', 'active'),

-- Candidates
('Emma Rousseau', 'emma.rousseau@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 6 12 34 56 78', 'candidate', 'active'),
('Lucas Petit', 'lucas.petit@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 6 23 45 67 89', 'candidate', 'active'),
('Chloé Bernard', 'chloe.bernard@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 6 34 56 78 90', 'candidate', 'active'),
('Thomas Garcia', 'thomas.garcia@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 6 45 67 89 01', 'candidate', 'active'),
('Léa Rodriguez', 'lea.rodriguez@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+33 6 56 78 90 12', 'candidate', 'active');

-- Insert instructors
INSERT INTO instructors (user_id, auto_ecole_id, license_number, specialization, experience_years, hourly_rate) VALUES
(2, 1, 'INS-2024-001', 'car', 5, 45.00),
(3, 1, 'INS-2024-002', 'car', 8, 50.00),
(4, 2, 'INS-2024-003', 'motorcycle', 3, 40.00),
(5, 3, 'INS-2024-004', 'car', 10, 55.00);

-- Insert students/candidates
INSERT INTO students (user_id, auto_ecole_id, student_number, license_type, registration_date, status, total_hours, practical_hours, theoretical_hours) VALUES
(6, 1, 'STU-2024-001', 'B', '2024-01-15', 'in_training', 20, 15, 5),
(7, 1, 'STU-2024-002', 'B', '2024-02-01', 'in_training', 12, 8, 4),
(8, 2, 'STU-2024-003', 'A', '2024-01-20', 'in_training', 18, 12, 6),
(9, 2, 'STU-2024-004', 'B', '2024-02-10', 'registered', 5, 3, 2),
(10, 3, 'STU-2024-005', 'B', '2024-01-25', 'completed', 35, 25, 10);

-- Insert vehicles
INSERT INTO vehicles (auto_ecole_id, make, model, year, license_plate, vehicle_type, transmission, fuel_type, status, insurance_expiry, technical_inspection_expiry) VALUES
(1, 'Peugeot', '208', 2022, 'AA-123-BB', 'car', 'manual', 'petrol', 'available', '2024-12-31', '2024-11-30'),
(1, 'Renault', 'Clio', 2021, 'CC-456-DD', 'car', 'manual', 'diesel', 'available', '2024-10-31', '2024-09-30'),
(1, 'BMW', 'F 750 GS', 2023, 'EE-789-FF', 'motorcycle', 'manual', 'petrol', 'available', '2024-08-31', '2024-07-31'),
(2, 'Volkswagen', 'Golf', 2020, 'GG-012-HH', 'car', 'automatic', 'petrol', 'in_use', '2024-11-30', '2024-10-31'),
(2, 'Yamaha', 'MT-07', 2022, 'II-345-JJ', 'motorcycle', 'manual', 'petrol', 'available', '2024-09-30', '2024-08-31'),
(3, 'Peugeot', '308', 2023, 'KK-678-LL', 'car', 'manual', 'hybrid', 'available', '2024-12-31', '2024-11-30');

-- Insert lessons
INSERT INTO lessons (auto_ecole_id, instructor_id, title, description, lesson_type, duration_hours, max_students) VALUES
(1, 1, 'Code de la Route - Bases', 'Introduction aux règles de circulation et panneaux', 'theory', 2.0, 25),
(1, 2, 'Conduite en Ville', 'Pratique de la conduite en environnement urbain', 'practice', 1.5, 1),
(2, 3, 'Sécurité Motocycliste', 'Techniques de sécurité spécifiques à la moto', 'theory', 1.5, 20),
(3, 4, 'Conduite Économique', 'Techniques pour réduire la consommation', 'practice', 2.0, 1);

-- Insert lesson enrollments
INSERT INTO lesson_enrollments (lesson_id, student_id, enrollment_date, status, attendance_date) VALUES
(1, 1, '2024-01-20', 'attended', '2024-01-25'),
(1, 2, '2024-02-05', 'attended', '2024-02-10'),
(2, 1, '2024-02-01', 'attended', '2024-02-03'),
(3, 3, '2024-02-15', 'enrolled', NULL),
(4, 5, '2024-02-20', 'attended', '2024-02-22');

-- Insert training sessions
INSERT INTO training_sessions (student_id, instructor_id, vehicle_id, auto_ecole_id, session_type, session_date, start_time, end_time, duration_hours, status, notes) VALUES
(1, 1, 1, 1, 'practical', '2024-03-01', '09:00:00', '10:30:00', 1.5, 'scheduled', 'Première leçon de conduite'),
(1, 2, 2, 1, 'practical', '2024-03-03', '14:00:00', '15:30:00', 1.5, 'scheduled', 'Conduite en ville'),
(2, 1, 1, 1, 'practical', '2024-03-02', '10:00:00', '11:30:00', 1.5, 'scheduled', 'Leçon de base'),
(3, 3, 3, 2, 'practical', '2024-03-04', '16:00:00', '17:30:00', 1.5, 'scheduled', 'Séance moto'),
(5, 4, 6, 3, 'practical', '2024-03-05', '08:00:00', '10:00:00', 2.0, 'scheduled', 'Leçon finale');

-- Insert notifications
INSERT INTO notifications (user_id, title, message, type) VALUES
(6, 'Nouvelle leçon programmée', 'Votre prochaine leçon de conduite est prévue le 1er mars à 9h00', 'info'),
(7, 'Rappel de leçon', 'N''oubliez pas votre leçon de conduite demain à 10h00', 'warning'),
(8, 'Bienvenue', 'Bienvenue dans notre auto-école! Votre formation peut commencer.', 'info'),
(9, 'Leçon confirmée', 'Votre leçon de conduite est confirmée pour le 5 mars à 8h00', 'success'),
(10, 'Formation terminée', 'Félicitations! Votre formation est terminée. Vous pouvez maintenant passer l''examen.', 'success');

-- Insert messages
INSERT INTO messages (sender_id, receiver_id, subject, message, is_read) VALUES
(2, 6, 'Prochaine leçon', 'Bonjour Emma, j''ai programmé votre prochaine leçon pour le 1er mars. N''oubliez pas votre permis de conduire.', FALSE),
(1, 2, 'Planning de la semaine', 'Marie, pouvez-vous confirmer votre disponibilité pour les leçons de la semaine prochaine?', FALSE),
(4, 8, 'Sécurité moto', 'Chloé, pensez à apporter votre équipement de protection pour la prochaine séance.', FALSE);

-- Insert exam validations (Manual validation by admin/instructor)
INSERT INTO exam_validations (student_id, validator_id, auto_ecole_id, exam_type, validation_date, status, score, max_score, notes, validated_at) VALUES
(10, 5, 3, 'theory', '2024-02-28', 'passed', 38, 40, 'Excellent résultat théorique. Toutes les questions importantes maîtrisées.', '2024-02-28 14:30:00'),
(10, 5, 3, 'practical', '2024-03-01', 'passed', 29, 31, 'Très bonne conduite pratique. Respect des règles de circulation et bonne maîtrise du véhicule.', '2024-03-01 16:45:00'),
(8, 4, 2, 'theory', '2024-03-05', 'pending', NULL, 40, 'Examen théorique moto programmé', NULL),
(1, 2, 1, 'theory', '2024-03-10', 'pending', NULL, 40, 'Examen théorique voiture programmé', NULL);
EOF
```

---

## 🚀 ÉTAPE 6: Démarrage des Services

### **6.1 Démarrer les Services de Base**
```bash
cd /opt/dgtt-auto-ecole

# Démarrer les services de base
docker-compose up -d consul postgres redis rabbitmq traefik

# Attendre que les services soient prêts
sleep 30

# Vérifier le statut
docker-compose ps
```

### **6.2 Vérifier les Services**
```bash
# Vérifier Consul
curl http://localhost:8500/v1/status/leader

# Vérifier PostgreSQL
docker-compose exec postgres psql -U dgtt_user -d dgtt_auto_ecole -c "SELECT version();"

# Vérifier Redis
docker-compose exec redis redis-cli ping

# Vérifier RabbitMQ
curl http://localhost:15672
```

---

## 🌐 ÉTAPE 7: Configuration du DNS et Accès

### **7.1 Configuration des Hosts Locaux (pour test)**
```bash
# Ajouter les entrées dans /etc/hosts pour les tests
echo "168.119.123.247 dgtt.fr" >> /etc/hosts
echo "168.119.123.247 api.dgtt.fr" >> /etc/hosts
echo "168.119.123.247 admin.dgtt.fr" >> /etc/hosts
echo "168.119.123.247 candidate.dgtt.fr" >> /etc/hosts
```

### **7.2 Test d'Accès aux Services**
```bash
# Test Consul UI
curl -I http://168.119.123.247:8500

# Test Traefik Dashboard
curl -I http://168.119.123.247:8080

# Test RabbitMQ Management
curl -I http://168.119.123.247:15672
```

---

## 📊 ÉTAPE 8: Monitoring et Vérification

### **8.1 Vérification des Logs**
```bash
# Voir les logs de tous les services
docker-compose logs

# Logs d'un service spécifique
docker-compose logs consul
docker-compose logs postgres
docker-compose logs traefik
```

### **8.2 Vérification des Volumes**
```bash
# Lister les volumes Docker
docker volume ls

# Vérifier l'espace disque
df -h
```

### **8.3 Vérification des Ressources**
```bash
# Utilisation CPU et mémoire
htop

# Utilisation des ports
netstat -tulpn | grep -E ':(80|443|5432|6379|5672|15672|8500|8080)'
```

---

## 🔧 ÉTAPE 9: Configuration Avancée (Optionnel)

### **9.1 Configuration SSL avec Let's Encrypt**
```bash
# Le SSL sera configuré automatiquement par Traefik
# Vérifier les certificats
docker-compose exec traefik ls -la /letsencrypt/
```

### **9.2 Configuration des Backups**
```bash
# Créer un script de backup
cat > /opt/dgtt-auto-ecole/scripts/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups"
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker-compose exec -T postgres pg_dump -U dgtt_user dgtt_auto_ecole > $BACKUP_DIR/postgres_backup_$DATE.sql

# Backup des volumes Docker
docker run --rm -v dgtt-auto-ecole_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres_data_$DATE.tar.gz -C /data .

# Nettoyer les anciens backups (garder 7 jours)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/dgtt-auto-ecole/scripts/backup.sh
```

### **9.3 Configuration du Cron pour les Backups**
```bash
# Ajouter une tâche cron pour les backups quotidiens
echo "0 2 * * * /opt/dgtt-auto-ecole/scripts/backup.sh" | crontab -
```

---

## ✅ ÉTAPE 10: Vérification Finale

### **10.1 Checklist de Déploiement**
```bash
# Vérifier tous les services
docker-compose ps

# Vérifier les ports ouverts
ss -tulpn | grep -E ':(80|443|5432|6379|5672|15672|8500|8080)'

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h

# Vérifier les logs d'erreur
docker-compose logs | grep -i error
```

### **10.2 URLs d'Accès**
- **Consul UI**: http://168.119.123.247:8500
- **Traefik Dashboard**: http://168.119.123.247:8080
- **RabbitMQ Management**: http://168.119.123.247:15672
- **PostgreSQL**: 168.119.123.247:5432

### **10.3 Informations de Connexion**
- **PostgreSQL**: 
  - Host: 168.119.123.247
  - Port: 5432
  - Database: dgtt_auto_ecole
  - User: dgtt_user
  - Password: dgtt_password_secure_2024

- **RabbitMQ**:
  - Host: 168.119.123.247
  - Port: 5672 (AMQP) / 15672 (Management)
  - User: dgtt_user
  - Password: dgtt_password_secure_2024
  - VHost: dgtt_vhost

---

## 🎯 Prochaines Étapes

1. **Déploiement des Frontends**: Ajouter les services frontend-admin et frontend-candidate
2. **Déploiement du Backend**: Ajouter l'API Laravel
3. **Configuration SSL**: Configurer les domaines avec certificats Let's Encrypt
4. **Monitoring**: Ajouter Prometheus, Grafana et ELK Stack
5. **Tests**: Effectuer des tests de charge et de sécurité

---

## 📞 Support

En cas de problème :
1. Vérifier les logs : `docker-compose logs [service]`
2. Vérifier le statut : `docker-compose ps`
3. Redémarrer les services : `docker-compose restart [service]`
4. Vérifier les ressources : `htop`, `df -h`

**🎉 Félicitations ! La base de votre infrastructure DGTT Auto-École est maintenant déployée sur Hetzner !**
