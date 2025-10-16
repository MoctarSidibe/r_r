# 🏛️ Consul Configuration

## Vue d'Ensemble

Configuration Consul pour la découverte de services et la gestion de configuration du système DGTT Auto-École.

## 📁 Structure

```
consul/
├── config.json              # Configuration principale Consul
├── services/                # Définitions des services
│   ├── backend-api.json     # Service API Laravel
│   ├── frontend-admin.json  # Interface Admin
│   ├── frontend-student.json # Interface Étudiant
│   ├── frontend-gateway.json # Gateway Frontend
│   ├── postgres.json        # Base de données
│   └── redis.json           # Cache Redis
└── README.md               # Documentation
```

## 🔧 Configuration Principale

### **config.json**
- **Datacenter**: dc1
- **Mode**: Server (single-node pour développement)
- **UI**: Activée sur port 8500
- **Connect**: Activé pour service mesh
- **ACL**: Désactivé pour développement

## 📊 Services Enregistrés

### **Backend API**
- **Nom**: backend-api
- **Port**: 80
- **Tags**: api, laravel, backend
- **Health Check**: HTTP /health

### **Frontend Admin**
- **Nom**: frontend-admin
- **Port**: 80
- **Tags**: frontend, admin, react
- **Health Check**: HTTP /health

### **Frontend Student**
- **Nom**: frontend-student
- **Port**: 80
- **Tags**: frontend, student, react
- **Health Check**: HTTP /health

### **Frontend Gateway**
- **Nom**: frontend-gateway
- **Port**: 80
- **Tags**: frontend, gateway, nginx
- **Health Check**: HTTP /health

### **PostgreSQL**
- **Nom**: postgres
- **Port**: 5432
- **Tags**: database, postgresql
- **Health Check**: pg_isready

### **Redis**
- **Nom**: redis
- **Port**: 6379
- **Tags**: cache, redis
- **Health Check**: redis-cli ping

## 🚀 Utilisation

### **Démarrer Consul:**
```bash
# Via Docker Compose
docker-compose up consul -d

# Vérifier le statut
docker-compose ps consul
```

### **Accéder à l'UI:**
- **URL**: http://localhost:8500
- **Services**: Liste de tous les services enregistrés
- **Health**: État de santé des services
- **KV Store**: Stockage clé-valeur pour configuration

### **Vérifier les Services:**
```bash
# Lister les services
consul catalog services

# Détails d'un service
consul catalog service backend-api

# Santé des services
consul catalog nodes -service=backend-api
```

## 🔍 Health Checks

Tous les services incluent des health checks automatiques:

- **Intervalle**: 10 secondes
- **Timeout**: 3-5 secondes
- **Deregister**: 30 secondes après échec critique

## 📈 Monitoring

- **UI Consul**: Interface web pour surveillance
- **API REST**: Endpoints pour intégration
- **Prometheus**: Métriques disponibles
- **Logs**: Surveillance via Docker logs

## 🔧 Personnalisation

### **Ajouter un Service:**
1. Créer un fichier JSON dans `services/`
2. Définir le service avec health check
3. Redémarrer Consul pour charger la configuration

### **Modifier la Configuration:**
1. Éditer `config.json`
2. Redémarrer le container Consul
3. Vérifier la configuration via UI

## 🔒 Sécurité

- **ACL**: Désactivé en développement, activable en production
- **TLS**: Configurable pour communication chiffrée
- **Connect**: Service mesh pour communication sécurisée

## 📚 Ressources

- [Documentation Consul](https://www.consul.io/docs)
- [Service Discovery](https://www.consul.io/docs/connect)
- [Health Checks](https://www.consul.io/docs/agent/checks)
- [Configuration](https://www.consul.io/docs/agent/options)
