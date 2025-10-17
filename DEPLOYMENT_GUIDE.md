# 🚀 Guide de Déploiement DGTT Auto-École

## 📋 État Actuel
- ✅ **Services d'Infrastructure**: Consul, PostgreSQL, Redis, RabbitMQ, Traefik (DÉJÀ DÉPLOYÉS)
- ❌ **Services d'Application**: Backend Laravel, Frontend Admin, Frontend Candidate, Frontend Gateway (À DÉPLOYER)

## 🎯 Objectif
Déployer tous les services d'application sur le serveur Hetzner (168.119.123.247)

---

## 🔧 ÉTAPE 1: Préparation du Serveur

### **1.1 Connexion au Serveur**
```bash
ssh root@168.119.123.247
cd /opt/dgtt-auto-ecole
```

### **1.2 Vérification de l'État Actuel**
```bash
# Vérifier les services en cours
docker-compose ps

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h
```

---

## 🚀 ÉTAPE 2: Déploiement du Backend Laravel

### **2.1 Construction et Démarrage du Backend**
```bash
# Construire et démarrer le backend
docker-compose up -d --build backend

# Attendre que le service soit prêt
sleep 60

# Vérifier les logs
docker-compose logs backend
```

### **2.2 Vérification du Backend**
```bash
# Vérifier le statut
docker-compose ps backend

# Tester l'endpoint de santé
curl http://localhost/api/health

# Tester l'API
curl http://localhost/api/
```

---

## 🎨 ÉTAPE 3: Déploiement des Frontends

### **3.1 Déploiement du Frontend Gateway**
```bash
# Construire et démarrer le gateway
docker-compose up -d --build frontend-gateway

# Vérifier les logs
docker-compose logs frontend-gateway

# Tester le gateway
curl http://localhost/health
```

### **3.2 Déploiement du Frontend Admin**
```bash
# Construire et démarrer l'admin
docker-compose up -d --build frontend-admin

# Vérifier les logs
docker-compose logs frontend-admin

# Tester l'admin
curl http://localhost/admin/health
```

### **3.3 Déploiement du Frontend Candidate**
```bash
# Construire et démarrer le candidat
docker-compose up -d --build frontend-candidate

# Vérifier les logs
docker-compose logs frontend-candidate

# Tester le candidat
curl http://localhost/candidate/health
```

---

## 🔍 ÉTAPE 4: Vérification Complète

### **4.1 Vérification de Tous les Services**
```bash
# Vérifier le statut de tous les services
docker-compose ps

# Vérifier les logs de tous les services
docker-compose logs --tail=50
```

### **4.2 Tests des Endpoints**
```bash
# Test du Gateway
curl -I http://168.119.123.247/

# Test de l'Admin
curl -I http://168.119.123.247/admin/

# Test du Candidat
curl -I http://168.119.123.247/candidate/

# Test de l'API
curl -I http://168.119.123.247/api/

# Test de Traefik
curl -I http://168.119.123.247:8080/

# Test de Consul
curl -I http://168.119.123.247:8500/

# Test de RabbitMQ
curl -I http://168.119.123.247:15672/
```

### **4.3 Vérification de la Base de Données**
```bash
# Se connecter à la base de données
docker-compose exec postgres psql -U dgtt_user -d dgtt_auto_ecole

# Vérifier les tables
\dt

# Vérifier les données
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM auto_ecoles;
SELECT COUNT(*) FROM students;

# Quitter
\q
```

---

## 🌐 ÉTAPE 5: Configuration des Accès

### **5.1 URLs d'Accès Finales**
- **Interface Principale**: http://168.119.123.247
- **Interface Admin**: http://168.119.123.247/admin
- **Interface Candidat**: http://168.119.123.247/candidate
- **API Backend**: http://168.119.123.247/api
- **Traefik Dashboard**: http://168.119.123.247:8080
- **Consul UI**: http://168.119.123.247:8500
- **RabbitMQ Management**: http://168.119.123.247:15672

### **5.2 Informations de Connexion**
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

## 🛠️ ÉTAPE 6: Commandes de Maintenance

### **6.1 Gestion des Services**
```bash
# Redémarrer un service
docker-compose restart [service-name]

# Redémarrer tous les services
docker-compose restart

# Arrêter tous les services
docker-compose down

# Démarrer tous les services
docker-compose up -d

# Voir les logs d'un service
docker-compose logs [service-name]

# Voir les logs en temps réel
docker-compose logs -f [service-name]
```

### **6.2 Gestion des Images**
```bash
# Reconstruire une image
docker-compose build [service-name]

# Reconstruire toutes les images
docker-compose build

# Nettoyer les images inutilisées
docker system prune -a
```

### **6.3 Gestion de la Base de Données**
```bash
# Sauvegarder la base de données
docker-compose exec postgres pg_dump -U dgtt_user dgtt_auto_ecole > backup.sql

# Restaurer la base de données
docker-compose exec -T postgres psql -U dgtt_user -d dgtt_auto_ecole < backup.sql

# Voir l'utilisation de l'espace
docker-compose exec postgres psql -U dgtt_user -d dgtt_auto_ecole -c "SELECT pg_size_pretty(pg_database_size('dgtt_auto_ecole'));"
```

---

## 🚨 Dépannage

### **Problèmes Courants**

#### **Service ne démarre pas**
```bash
# Vérifier les logs
docker-compose logs [service-name]

# Vérifier les ressources
docker stats

# Vérifier l'espace disque
df -h
```

#### **Erreur de connexion à la base de données**
```bash
# Vérifier que PostgreSQL est en cours
docker-compose ps postgres

# Vérifier les logs PostgreSQL
docker-compose logs postgres

# Tester la connexion
docker-compose exec postgres psql -U dgtt_user -d dgtt_auto_ecole -c "SELECT version();"
```

#### **Erreur de build**
```bash
# Nettoyer le cache Docker
docker system prune -a

# Reconstruire sans cache
docker-compose build --no-cache [service-name]
```

#### **Problème de mémoire**
```bash
# Vérifier l'utilisation mémoire
free -h
docker stats

# Arrêter les services non essentiels
docker-compose stop [service-name]
```

---

## 📊 Monitoring

### **Vérification de la Santé des Services**
```bash
# Script de vérification automatique
#!/bin/bash
echo "=== Vérification des Services DGTT ==="

# Consul
if curl -f http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
    echo "✅ Consul: OK"
else
    echo "❌ Consul: ERREUR"
fi

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U dgtt_user -d dgtt_auto_ecole > /dev/null 2>&1; then
    echo "✅ PostgreSQL: OK"
else
    echo "❌ PostgreSQL: ERREUR"
fi

# Redis
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis: OK"
else
    echo "❌ Redis: ERREUR"
fi

# RabbitMQ
if curl -f http://localhost:15672 > /dev/null 2>&1; then
    echo "✅ RabbitMQ: OK"
else
    echo "❌ RabbitMQ: ERREUR"
fi

# Traefik
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Traefik: OK"
else
    echo "❌ Traefik: ERREUR"
fi

# Backend
if curl -f http://localhost/api/health > /dev/null 2>&1; then
    echo "✅ Backend: OK"
else
    echo "❌ Backend: ERREUR"
fi

# Gateway
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Gateway: OK"
else
    echo "❌ Gateway: ERREUR"
fi

echo "=== Vérification terminée ==="
```

---

## 🎉 Félicitations !

Une fois toutes les étapes terminées, votre système DGTT Auto-École sera entièrement déployé et opérationnel sur le serveur Hetzner.

### **Prochaines Étapes Recommandées**
1. **Configuration SSL** avec Let's Encrypt
2. **Monitoring** avec Prometheus et Grafana
3. **Sauvegardes automatiques**
4. **Tests de charge**
5. **Audit de sécurité**

---

## 📞 Support

En cas de problème :
1. Vérifier les logs : `docker-compose logs [service]`
2. Vérifier le statut : `docker-compose ps`
3. Redémarrer les services : `docker-compose restart [service]`
4. Vérifier les ressources : `htop`, `df -h`
