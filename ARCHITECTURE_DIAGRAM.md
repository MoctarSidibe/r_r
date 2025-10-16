# 🏗️ Architecture Technique DGTT Auto-École

## Vue d'Ensemble de l'Architecture

```mermaid
graph TB
    %% External Users
    Admin[👨‍💼 Administrateurs<br/>Gestion Auto-École]
    Candidate[🎓 Candidats<br/>Apprentissage Conduite]
    Instructor[👨‍🏫 Instructeurs<br/>Enseignement]
    
    %% Internet Layer
    Internet[🌐 Internet<br/>Point d'Entrée]
    
    %% Load Balancer & Reverse Proxy
    subgraph "🚦 Traefik - Reverse Proxy & Load Balancer"
        Traefik[🚦 Traefik v3.0<br/>• SSL Termination<br/>• Load Balancing<br/>• Route Management<br/>• Security Headers]
    end
    
    %% Frontend Gateway & Micro Frontends
    subgraph "🎨 Frontend Microservices Architecture"
        Gateway[🌐 Frontend Gateway<br/>Micro Frontend Orchestrator<br/>• Route Management<br/>• Header Injection<br/>• Health Checks]
        
        subgraph "📊 Admin Micro Frontend"
            AdminFE[📊 Interface Admin<br/>React + TypeScript + Material-UI<br/>• Gestion Auto-École<br/>• Gestion Instructeurs<br/>• Validation Examens<br/>• Rapports & Analytics]
        end
        
        subgraph "🎓 Candidate Micro Frontend"
            CandidateFE[🎓 Interface Candidat<br/>React + TypeScript + Axios<br/>• Planning Personnel<br/>• Suivi Progression<br/>• Messagerie<br/>• Notifications]
        end
    end
    
    %% Service Discovery
    subgraph "🔍 Consul - Service Discovery"
        Consul[🏛️ Consul Cluster<br/>• Service Registry<br/>• Health Checks<br/>• Configuration Management<br/>• Load Balancing]
    end
    
    %% Backend Services
    subgraph "⚙️ Backend Services Layer"
        Backend[🔧 Laravel API<br/>PHP 8.2 + Laravel 12<br/>• Authentication & Authorization<br/>• Business Logic<br/>• API Endpoints<br/>• Data Validation]
        
        subgraph "🔄 Background Workers"
            Worker1[📧 Notification Worker<br/>• Email Processing<br/>• SMS Sending<br/>• Push Notifications]
            Worker2[📊 Report Worker<br/>• Data Processing<br/>• Report Generation<br/>• Export Functions]
        end
    end
    
    %% Data Layer
    subgraph "💾 Data & Storage Layer"
        subgraph "🗄️ PostgreSQL Database"
            PGPrimary[(🐘 PostgreSQL Primary<br/>• Master Database<br/>• Write Operations<br/>• ACID Compliance<br/>• Data Integrity)]
            PGReplica[(🐘 PostgreSQL Replica<br/>• Read Operations<br/>• Query Optimization<br/>• Backup & Recovery)]
        end
        
        subgraph "⚡ Redis Cache Layer"
            RedisPrimary[🔴 Redis Primary<br/>• Session Storage<br/>• Application Cache<br/>• Rate Limiting<br/>• Temporary Data]
            RedisReplica[🔴 Redis Replica<br/>• Cache Backup<br/>• Read Scaling<br/>• Failover Support]
        end
        
        subgraph "📨 RabbitMQ Message Queue"
            RabbitMQ[🐰 RabbitMQ Cluster<br/>• Async Processing<br/>• Message Routing<br/>• Queue Management<br/>• Dead Letter Handling]
        end
    end
    
    %% Monitoring & Observability
    subgraph "📊 Monitoring & Observability"
        Prometheus[📈 Prometheus<br/>• Metrics Collection<br/>• Alerting Rules<br/>• Service Discovery<br/>• Time Series Data]
        Grafana[📊 Grafana<br/>• Dashboards<br/>• Data Visualization<br/>• Alert Management<br/>• Performance Monitoring]
        Elasticsearch[🔍 Elasticsearch<br/>• Log Storage<br/>• Full-Text Search<br/>• Data Analytics<br/>• Index Management]
        Logstash[📝 Logstash<br/>• Log Processing<br/>• Data Pipeline<br/>• Filter & Transform<br/>• Output Routing]
        Filebeat[📁 Filebeat<br/>• Log Collection<br/>• File Monitoring<br/>• Ship to Logstash<br/>• Container Logs]
    end
    
    %% Security & Backup
    subgraph "🔒 Security & Backup Layer"
        Backup[💾 Automated Backup<br/>• Encrypted Backups<br/>• Point-in-Time Recovery<br/>• Cross-Region Replication<br/>• Retention Policies]
        Security[🛡️ Security Scanner<br/>• Vulnerability Detection<br/>• Compliance Checking<br/>• Container Security<br/>• Dependency Scanning]
    end
    
    %% User Flow Connections
    Admin --> Internet
    Candidate --> Internet
    Instructor --> Internet
    Internet --> Traefik
    
    %% Traefik to Gateway
    Traefik --> Gateway
    
    %% Gateway to Micro Frontends
    Gateway --> AdminFE
    Gateway --> CandidateFE
    
    %% Service Discovery Connections
    Backend --> Consul
    AdminFE --> Consul
    CandidateFE --> Consul
    
    %% Frontend to Backend API
    AdminFE --> Backend
    CandidateFE --> Backend
    
    %% Backend to Database Layer
    Backend --> PGPrimary
    Backend --> PGReplica
    Backend --> RedisPrimary
    Backend --> RabbitMQ
    
    %% Database Replication
    PGPrimary -.->|Replication| PGReplica
    RedisPrimary -.->|Replication| RedisReplica
    
    %% Workers to Message Queue
    Worker1 --> RabbitMQ
    Worker2 --> RabbitMQ
    
    %% Monitoring Connections
    Prometheus --> Backend
    Prometheus --> Traefik
    Prometheus --> Consul
    Prometheus --> PGPrimary
    Prometheus --> RedisPrimary
    Prometheus --> RabbitMQ
    
    Grafana --> Prometheus
    Filebeat --> Logstash
    Logstash --> Elasticsearch
    Grafana --> Elasticsearch
    
    %% Security & Backup
    Backup --> PGPrimary
    Security --> Backend
    
    %% Styling
    classDef userClass fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef frontendClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef backendClass fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef dataClass fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef monitorClass fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef securityClass fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    classDef proxyClass fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    
    class Admin,Candidate,Instructor userClass
    class Gateway,AdminFE,CandidateFE frontendClass
    class Backend,Worker1,Worker2 backendClass
    class PGPrimary,PGReplica,RedisPrimary,RedisReplica,RabbitMQ dataClass
    class Prometheus,Grafana,Elasticsearch,Logstash,Filebeat monitorClass
    class Backup,Security securityClass
    class Traefik,Consul proxyClass
```

## 🔄 Flux de Données Principaux

### **1. Authentification Utilisateur**
```
Utilisateur → Internet → Traefik → Frontend Gateway → Micro Frontend → API Laravel → PostgreSQL
```

### **2. Planification de Cours**
```
Admin → Interface Admin → API Laravel → PostgreSQL → RabbitMQ → Worker → Notification → Candidat
```

### **3. Validation d'Examen (Manuelle)**
```
Instructeur → Interface Admin → API Laravel → PostgreSQL → Notification → Candidat
```

### **4. Traitement Asynchrone**
```
Événement → RabbitMQ → Worker → Email/SMS/Export → Utilisateur Final
```

## 🎯 Composants Clés

### **Frontend Microservices**
- **Architecture Modulaire**: Déploiement indépendant de chaque micro frontend
- **Gateway Pattern**: Routage intelligent vers les micro frontends appropriés
- **Technology Stack**: React + TypeScript + Material-UI + Axios

### **Backend API**
- **Framework**: Laravel 12 avec PHP 8.2
- **Authentication**: Sanctum pour l'authentification API
- **Validation**: Validation manuelle des examens par admins/instructeurs
- **Queues**: Traitement asynchrone avec RabbitMQ

### **Infrastructure**
- **Service Discovery**: Consul pour la découverte automatique des services
- **Load Balancing**: Traefik pour l'équilibrage de charge et SSL
- **Message Queue**: RabbitMQ pour le traitement asynchrone
- **Caching**: Redis pour les sessions et le cache applicatif

### **Base de Données**
- **Primary**: PostgreSQL avec réplication pour la haute disponibilité
- **Cache**: Redis avec réplication pour la scalabilité
- **Schema**: Optimisé pour les besoins DGTT avec validation manuelle

### **Monitoring & Observabilité**
- **Métriques**: Prometheus pour la collecte de métriques
- **Visualisation**: Grafana pour les tableaux de bord
- **Logs**: ELK Stack pour l'agrégation et l'analyse des logs
- **Alertes**: Alertes automatiques en cas de problème

## 🔒 Sécurité & Conformité

### **Authentification & Autorisation**
- **Multi-Rôles**: Admin, Instructeur, Candidat avec permissions granulaires
- **API Security**: Tokens sécurisés avec Laravel Sanctum
- **Session Management**: Sessions chiffrées avec Redis

### **Protection des Données**
- **Chiffrement**: Données sensibles chiffrées au repos et en transit
- **Validation**: Validation côté serveur et client
- **Audit Trail**: Traçabilité complète des actions utilisateur

### **Infrastructure Sécurisée**
- **Container Security**: Images Docker sécurisées et mises à jour
- **Network Isolation**: Isolation réseau avec Docker
- **SSL/TLS**: Certificats automatiques avec Let's Encrypt

## 📈 Scalabilité & Performance

### **Horizontal Scaling**
- **Micro Frontends**: Scaling indépendant de chaque frontend
- **API Load Balancing**: Répartition de charge avec Traefik
- **Database Replication**: Réplicas de lecture pour PostgreSQL et Redis

### **Optimisation des Performances**
- **Caching Strategy**: Cache Redis multi-niveaux
- **CDN Ready**: Configuration prête pour CDN
- **Database Optimization**: Index optimisés et requêtes performantes

### **Haute Disponibilité**
- **Health Checks**: Vérification automatique de la santé des services
- **Failover**: Basculement automatique en cas de panne
- **Backup Strategy**: Sauvegardes automatisées et chiffrées

Cette architecture fournit une base solide, scalable et sécurisée pour la gestion d'auto-écoles DGTT avec validation manuelle des examens et traitement asynchrone des notifications.
