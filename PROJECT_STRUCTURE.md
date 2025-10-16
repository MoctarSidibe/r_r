# 📁 Structure du Projet DGTT Auto-École

## Vue d'Ensemble

```
r-dgtt/
├── 📱 FRONTEND MICROSERVICES
│   ├── frontend-gateway/           # 🌐 Gateway Micro Frontends
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── README.md
│   ├── frontend-admin/             # 📊 Interface Administrateur
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── src/                   # Code React + TypeScript
│   └── frontend-student/           # 🎓 Interface Étudiant
│       ├── Dockerfile
│       ├── nginx.conf
│       └── src/                   # Code React + TypeScript
│
├── ⚙️ BACKEND SERVICES
│   └── backend/                    # 🔧 API Laravel
│       ├── Dockerfile
│       ├── app/                   # Code PHP Laravel
│       ├── database/              # Migrations et Seeders
│       └── tests/                 # Tests unitaires
│
├── 🏛️ INFRASTRUCTURE CONFIGURATION
│   ├── consul/                     # 🔍 Service Discovery
│   │   ├── config.json            # Configuration Consul
│   │   ├── services/              # Définitions des services
│   │   └── README.md              # Documentation
│   ├── traefik/                    # 🚦 Reverse Proxy
│   │   ├── traefik.yml            # Configuration principale
│   │   ├── dynamic.yml            # Configuration dynamique
│   │   ├── rules/                 # Règles par environnement
│   │   └── README.md              # Documentation
│   └── rabbitmq/                   # 🐰 Message Queue
│       ├── rabbitmq.conf          # Configuration RabbitMQ
│       ├── definitions.json       # Queues et exchanges
│       └── README.md              # Documentation
│
├── 🗄️ DATABASE
│   └── database/
│       └── init/
│           ├── 01_init_database.sql    # Schéma de base
│           └── 02_seed_data.sql        # Données de test
│
├── 🐳 DOCKER & ORCHESTRATION
│   ├── docker-compose.yml         # Orchestration principale
│   └── Makefile                   # Commandes utiles
│
├── 📚 DOCUMENTATION
│   ├── README.md                  # Documentation principale
│   ├── ARCHITECTURE.md            # Architecture technique
│   ├── PROJECT_STRUCTURE.md       # Ce fichier
│   └── .gitignore                 # Fichiers ignorés par Git
│
└── 🔒 SECURITY
    └── security/
        └── security-policy.yml    # Politiques de sécurité
```

## 🎯 Répartition des Responsabilités

### **Frontend Microservices**
- **Gateway** : Routage et orchestration des micro frontends
- **Admin** : Interface de gestion pour les administrateurs
- **Student** : Interface étudiante pour les cours et suivi

### **Backend Services**
- **API Laravel** : Logique métier, authentification, API REST

### **Infrastructure**
- **Consul** : Découverte de services et configuration centralisée
- **Traefik** : Reverse proxy, load balancing, SSL termination
- **RabbitMQ** : File de messages pour traitement asynchrone

### **Base de Données**
- **PostgreSQL** : Données persistantes
- **Redis** : Cache et sessions
- **Scripts SQL** : Initialisation et données de test

## 🔧 Technologies par Module

| Module | Technologies | Rôle |
|--------|-------------|------|
| **Frontend Gateway** | Nginx, Docker | Orchestration micro frontends |
| **Frontend Admin** | React, TypeScript, Material-UI | Interface administrateur |
| **Frontend Student** | React, TypeScript, Axios | Interface étudiante |
| **Backend API** | Laravel 12, PHP 8.2 | API et logique métier |
| **Consul** | Consul 1.17 | Service discovery |
| **Traefik** | Traefik v3 | Reverse proxy |
| **RabbitMQ** | RabbitMQ 3.12 | Message queue |
| **PostgreSQL** | PostgreSQL 15 | Base de données |
| **Redis** | Redis 7 | Cache et sessions |

## 🚀 Points d'Entrée

### **Développement**
```bash
# Démarrage complet
make start

# Services individuels
docker-compose up consul -d
docker-compose up traefik -d
docker-compose up postgres -d
docker-compose up rabbitmq -d
docker-compose up backend -d
docker-compose up frontend-gateway -d
docker-compose up frontend-admin -d
docker-compose up frontend-student -d
```

### **URLs de Développement**
- **Interface Principale** : http://dgtt.local
- **Interface Admin** : http://admin.dgtt.local
- **Interface Étudiant** : http://student.dgtt.local
- **API Backend** : http://api.dgtt.local
- **Consul UI** : http://localhost:8500
- **RabbitMQ Management** : http://localhost:15672
- **Traefik Dashboard** : http://localhost:8080

## 📊 Flux de Communication

```
Internet → Traefik → Frontend Gateway → Micro Frontends
                    ↓
                 Backend API → PostgreSQL
                    ↓
                 RabbitMQ → Workers → Notifications
```

## 🔍 Monitoring

### **Health Checks**
- Tous les services incluent des health checks
- Surveillance via Consul
- Alertes automatiques en cas de problème

### **Logs**
- Logs centralisés via Docker
- Rotation automatique des logs
- Niveaux de log configurables

### **Métriques**
- Traefik : Métriques de routage
- RabbitMQ : Métriques de messages
- PostgreSQL : Métriques de base de données

Cette structure modulaire permet un développement, déploiement et maintenance facilités de chaque composant indépendamment.
