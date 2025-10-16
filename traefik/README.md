# 🚦 Traefik Configuration

## Vue d'Ensemble

Configuration Traefik pour le reverse proxy, équilibrage de charge et gestion SSL du système DGTT Auto-École.

## 📁 Structure

```
traefik/
├── traefik.yml              # Configuration principale
├── dynamic.yml              # Configuration dynamique (middlewares, routers)
├── rules/                   # Règles par environnement
│   ├── local.yml           # Règles de développement
│   └── production.yml      # Règles de production
└── README.md              # Documentation
```

## 🔧 Configuration Principale

### **traefik.yml**
- **API Dashboard**: Activé sur port 8080
- **Providers**: Docker avec réseau dgtt-network
- **Entry Points**: HTTP (80) et HTTPS (443)
- **Certificats**: Let's Encrypt avec TLS Challenge
- **Logging**: Niveau INFO avec format JSON
- **Métriques**: Prometheus activées

## 🌐 Entry Points

### **Web (HTTP)**
- **Port**: 80
- **Redirection**: Automatique vers HTTPS en production

### **WebSecure (HTTPS)**
- **Port**: 443
- **Certificats**: Let's Encrypt automatiques

## 🔒 Middlewares de Sécurité

### **Security Headers**
- **CSP**: Content Security Policy
- **HSTS**: HTTP Strict Transport Security
- **XSS Protection**: Protection contre XSS
- **Frame Options**: Protection contre clickjacking

### **Rate Limiting**
- **Burst**: 100 requêtes
- **Average**: 50 requêtes par minute

### **CORS**
- **Origins**: Domains autorisés
- **Methods**: GET, POST, PUT, DELETE, OPTIONS
- **Headers**: Headers autorisés

## 🛣️ Routers

### **Backend API**
- **Domaine**: `api.dgtt.local` (dev) / `api.dgtt.fr` (prod)
- **Service**: backend-api
- **Middlewares**: Security, CORS, Rate Limit

### **Frontend Gateway**
- **Domaine**: `dgtt.local` (dev) / `dgtt.fr` (prod)
- **Service**: frontend-gateway
- **Middlewares**: Security, Headers

### **Admin Frontend**
- **Domaine**: `admin.dgtt.local` (dev) / `admin.dgtt.fr` (prod)
- **Service**: frontend-admin
- **Middlewares**: Security, Auth (Basic Auth en prod)

### **Student Frontend**
- **Domaine**: `student.dgtt.local` (dev) / `student.dgtt.fr` (prod)
- **Service**: frontend-student
- **Middlewares**: Security, Headers

## 🔍 Health Checks

Tous les services incluent des health checks:

- **Intervalle**: 30 secondes
- **Timeout**: 5 secondes
- **Path**: /health pour chaque service

## 🌍 Environnements

### **Développement (local.yml)**
- **Protocole**: HTTP uniquement
- **CORS**: Permissif pour localhost
- **Headers**: Headers de développement
- **Auth**: Désactivée

### **Production (production.yml)**
- **Protocole**: HTTPS avec redirection HTTP
- **CORS**: Restrictif aux domaines de production
- **Headers**: Headers de sécurité stricts
- **Auth**: Basic Auth pour admin
- **SSL**: Certificats Let's Encrypt

## 🚀 Utilisation

### **Développement Local:**
```bash
# Ajouter à /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1 dgtt.local
127.0.0.1 admin.dgtt.local
127.0.0.1 student.dgtt.local
127.0.0.1 api.dgtt.local

# Démarrer Traefik
docker-compose up traefik -d

# Accéder au dashboard
open http://localhost:8080
```

### **Production:**
```bash
# Configurer les domaines DNS
# dgtt.fr -> IP du serveur
# admin.dgtt.fr -> IP du serveur
# student.dgtt.fr -> IP du serveur
# api.dgtt.fr -> IP du serveur

# Démarrer avec SSL
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 📊 Monitoring

### **Dashboard Traefik**
- **URL**: http://localhost:8080 (dev) / https://traefik.dgtt.fr (prod)
- **Fonctionnalités**: Routers, Services, Middlewares, Métriques

### **Métriques Prometheus**
- **Endpoint**: /metrics
- **Format**: Prometheus metrics
- **Intégration**: Grafana disponible

### **Logs**
- **Format**: JSON
- **Fichiers**: /var/log/traefik.log, /var/log/access.log
- **Niveau**: INFO (configurable)

## 🔧 Personnalisation

### **Ajouter un Service:**
1. Ajouter le router dans `dynamic.yml`
2. Configurer le service avec health check
3. Appliquer les middlewares appropriés

### **Modifier les Middlewares:**
1. Éditer `dynamic.yml`
2. Redémarrer Traefik
3. Vérifier via dashboard

### **Ajouter des Domaines:**
1. Modifier les règles dans `rules/`
2. Configurer DNS
3. Redémarrer les services

## 🔒 Sécurité

### **Headers de Sécurité**
- **CSP**: Protection contre XSS
- **HSTS**: Force HTTPS
- **X-Frame-Options**: Protection clickjacking
- **X-Content-Type-Options**: Protection MIME sniffing

### **Authentification**
- **Basic Auth**: Pour interface admin en production
- **CORS**: Configuration restrictive
- **Rate Limiting**: Protection DDoS

### **SSL/TLS**
- **Certificats**: Let's Encrypt automatiques
- **Renouvellement**: Automatique
- **Redirection**: HTTP vers HTTPS

## 📚 Ressources

- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [Configuration Docker](https://doc.traefik.io/traefik/providers/docker/)
- [Middlewares](https://doc.traefik.io/traefik/middlewares/overview/)
- [Let's Encrypt](https://doc.traefik.io/traefik/https/acme/)
