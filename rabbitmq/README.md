# 🐰 RabbitMQ Configuration

## Vue d'Ensemble

Configuration RabbitMQ pour la gestion des files de messages asynchrones du système DGTT Auto-École.

## 📁 Structure

```
rabbitmq/
├── rabbitmq.conf        # Configuration principale RabbitMQ
├── definitions.json     # Définitions des utilisateurs, vhosts, exchanges, queues
└── README.md           # Documentation
```

## 🔧 Configuration Principale

### **rabbitmq.conf**
- **Port AMQP**: 5672 (communication des applications)
- **Port Management**: 15672 (interface web)
- **Utilisateur par défaut**: dgtt_user
- **VHost par défaut**: dgtt_vhost
- **Limite mémoire**: 60% de la RAM disponible
- **Limite disque**: 2GB libre minimum

## 👥 Utilisateurs

### **dgtt_user** (Administrateur)
- **Rôle**: Administrateur complet
- **Permissions**: Lecture, écriture, configuration sur dgtt_vhost
- **Usage**: Application backend principale

### **dgtt_worker** (Worker)
- **Rôle**: Gestionnaire (management)
- **Permissions**: Lecture, écriture, configuration sur dgtt_vhost
- **Usage**: Workers de traitement asynchrone

## 🏢 VHost

### **dgtt_vhost**
- **Nom**: dgtt_vhost
- **Isolation**: Environnement isolé pour l'application DGTT
- **Sécurité**: Permissions granulaires par utilisateur

## 📨 Exchanges

### **dgtt.notifications** (Topic)
- **Type**: Topic exchange
- **Usage**: Routage des notifications par type
- **Routing Keys**: email.*, sms.*, push.*

### **dgtt.reports** (Topic)
- **Type**: Topic exchange
- **Usage**: Génération de rapports
- **Routing Keys**: generate.*, export.*

### **dgtt.emails** (Direct)
- **Type**: Direct exchange
- **Usage**: Envoi direct d'emails
- **Routing Key**: send

## 📋 Queues

### **notifications.email**
- **Purpose**: Traitement des emails de notification
- **TTL**: 1 heure (3600000ms)
- **Binding**: dgtt.notifications → email.*

### **notifications.sms**
- **Purpose**: Traitement des SMS de notification
- **TTL**: 1 heure (3600000ms)
- **Binding**: dgtt.notifications → sms.*

### **reports.generation**
- **Purpose**: Génération de rapports
- **TTL**: 2 heures (7200000ms)
- **Binding**: dgtt.reports → generate.*

### **emails.send**
- **Purpose**: Envoi direct d'emails
- **TTL**: 1 heure (3600000ms)
- **Binding**: dgtt.emails → send

## 🔗 Bindings

| Exchange | Queue | Routing Key | Purpose |
|----------|-------|-------------|---------|
| dgtt.notifications | notifications.email | email.* | Emails de notification |
| dgtt.notifications | notifications.sms | sms.* | SMS de notification |
| dgtt.reports | reports.generation | generate.* | Génération de rapports |
| dgtt.emails | emails.send | send | Envoi direct d'emails |

## 🚀 Utilisation

### **Accès à l'Interface Web:**
- **URL**: http://localhost:15672
- **Utilisateur**: dgtt_user
- **Mot de passe**: dgtt_password

### **Connexion AMQP:**
```php
// Configuration Laravel
'rabbitmq' => [
    'host' => env('RABBITMQ_HOST', 'rabbitmq'),
    'port' => env('RABBITMQ_PORT', 5672),
    'user' => env('RABBITMQ_USER', 'dgtt_user'),
    'password' => env('RABBITMQ_PASSWORD', 'dgtt_password'),
    'vhost' => env('RABBITMQ_VHOST', 'dgtt_vhost'),
],
```

### **Publier des Messages:**
```php
// Notification par email
$message = [
    'type' => 'lesson_reminder',
    'student_id' => 123,
    'instructor_id' => 456,
    'lesson_date' => '2024-03-01 14:00:00'
];

// Publier avec routing key
$this->publish('dgtt.notifications', 'email.lesson_reminder', $message);
```

### **Consommer des Messages:**
```php
// Worker de notification email
$this->consume('notifications.email', function($message) {
    // Traiter l'email de notification
    $this->sendEmailNotification($message);
});
```

## 📊 Monitoring

### **Interface Web RabbitMQ:**
- **Overview**: Vue d'ensemble des connections, channels, exchanges, queues
- **Connections**: Connexions actives
- **Channels**: Canaux de communication
- **Exchanges**: Exchanges et leurs bindings
- **Queues**: Queues et leurs messages
- **Admin**: Gestion des utilisateurs et vhosts

### **Métriques Clés:**
- **Messages publiés/consommés**: Volume de trafic
- **Taille des queues**: Accumulation de messages
- **Taux de consommation**: Performance des workers
- **Connections actives**: Charge système

## 🔧 Configuration Avancée

### **Clustering (Futur):**
```conf
# Pour un cluster multi-nodes
cluster_formation.peer_discovery_backend = classic_config
cluster_formation.classic_config.nodes.1 = rabbit@node1
cluster_formation.classic_config.nodes.2 = rabbit@node2
```

### **Haute Disponibilité:**
```json
// Queues HA
{
  "name": "notifications.email.ha",
  "arguments": {
    "x-ha-policy": "all"
  }
}
```

### **Limites de Performance:**
- **Connection Max**: 1000 connexions simultanées
- **Channel Max**: 2047 canaux par connexion
- **Frame Max**: 131KB par message
- **Heartbeat**: 60 secondes

## 🔒 Sécurité

### **Authentification:**
- **Mécanismes**: PLAIN, AMQPLAIN
- **Utilisateurs**: Gestion via interface web ou API
- **Permissions**: Granulaires par vhost

### **Isolation:**
- **VHosts**: Isolation complète des applications
- **Permissions**: Contrôle d'accès par ressource
- **Networks**: Accès réseau restreint

## 📚 Ressources

- [Documentation RabbitMQ](https://www.rabbitmq.com/documentation.html)
- [Configuration](https://www.rabbitmq.com/configure.html)
- [Management Plugin](https://www.rabbitmq.com/management.html)
- [Clustering](https://www.rabbitmq.com/clustering.html)
- [High Availability](https://www.rabbitmq.com/ha.html)
