# DGTT Auto-École - Makefile pour faciliter le développement

.PHONY: help install build start stop restart logs clean backup restore test

# Couleurs pour les messages
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m # No Color

help: ## Afficher l'aide
	@echo "$(BLUE)DGTT Auto-École - Commandes disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Installer les dépendances et configurer l'environnement
	@echo "$(BLUE)🔧 Installation des dépendances...$(NC)"
	@cp env.example .env
	@echo "$(YELLOW)⚠️  Veuillez configurer le fichier .env$(NC)"
	@docker-compose pull
	@docker-compose build

build: ## Construire les images Docker
	@echo "$(BLUE)🐳 Construction des images Docker...$(NC)"
	@docker-compose build --no-cache

start: ## Démarrer tous les services
	@echo "$(BLUE)🚀 Démarrage des services...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)✅ Services démarrés$(NC)"
	@echo "$(BLUE)📊 Vérification du statut:$(NC)"
	@docker-compose ps

stop: ## Arrêter tous les services
	@echo "$(BLUE)🛑 Arrêt des services...$(NC)"
	@docker-compose down

restart: stop start ## Redémarrer tous les services

logs: ## Afficher les logs de tous les services
	@docker-compose logs -f

logs-backend: ## Afficher les logs du backend
	@docker-compose logs -f backend-auto-ecole

logs-frontend-admin: ## Afficher les logs du frontend admin
	@docker-compose logs -f frontend-auto-ecole

logs-frontend-student: ## Afficher les logs du frontend étudiant
	@docker-compose logs -f frontend-candidat

logs-db: ## Afficher les logs de la base de données
	@docker-compose logs -f postgres

clean: ## Nettoyer les conteneurs, images et volumes
	@echo "$(BLUE)🧹 Nettoyage...$(NC)"
	@docker-compose down -v --remove-orphans
	@docker system prune -f
	@docker volume prune -f

clean-all: ## Nettoyage complet (images incluses)
	@echo "$(RED)⚠️  Nettoyage complet - toutes les images seront supprimées$(NC)"
	@docker-compose down -v --remove-orphans
	@docker system prune -a -f
	@docker volume prune -f

backup: ## Créer une sauvegarde de la base de données
	@echo "$(BLUE)💾 Création de la sauvegarde...$(NC)"
	@mkdir -p backups
	@docker-compose exec -T postgres pg_dump -U dgtt_user dgtt_autoecole > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Sauvegarde créée dans backups/$(NC)"

restore: ## Restaurer la base de données (utiliser: make restore FILE=backup.sql)
	@echo "$(BLUE)🔄 Restauration de la base de données...$(NC)"
	@if [ -z "$(FILE)" ]; then echo "$(RED)❌ Spécifiez le fichier: make restore FILE=backup.sql$(NC)"; exit 1; fi
	@docker-compose exec -T postgres psql -U dgtt_user dgtt_autoecole < $(FILE)
	@echo "$(GREEN)✅ Base de données restaurée$(NC)"

test: ## Exécuter les tests
	@echo "$(BLUE)🧪 Exécution des tests...$(NC)"
	@docker-compose exec backend-auto-ecole php artisan test

test-frontend: ## Exécuter les tests frontend
	@echo "$(BLUE)🧪 Tests frontend admin...$(NC)"
	@cd dgtt-fronted-auto-ecole-main && npm test
	@echo "$(BLUE)🧪 Tests frontend étudiant...$(NC)"
	@cd dgtt-frontend-candidat-main && npm test

migrate: ## Exécuter les migrations
	@echo "$(BLUE)🗃️  Exécution des migrations...$(NC)"
	@docker-compose exec backend-auto-ecole php artisan migrate

migrate-fresh: ## Réinitialiser et exécuter les migrations avec seed
	@echo "$(BLUE)🗃️  Réinitialisation de la base de données...$(NC)"
	@docker-compose exec backend-auto-ecole php artisan migrate:fresh --seed

seed: ## Exécuter les seeders
	@echo "$(BLUE)🌱 Exécution des seeders...$(NC)"
	@docker-compose exec backend-auto-ecole php artisan db:seed

shell-backend: ## Ouvrir un shell dans le conteneur backend
	@docker-compose exec backend-auto-ecole bash

shell-db: ## Ouvrir un shell PostgreSQL
	@docker-compose exec postgres psql -U dgtt_user dgtt_autoecole

status: ## Afficher le statut des services
	@echo "$(BLUE)📊 Statut des services:$(NC)"
	@docker-compose ps
	@echo ""
	@echo "$(BLUE)🌐 URLs d'accès:$(NC)"
	@echo "  - API Backend: http://api.dgtt.local"
	@echo "  - Interface Admin: http://admin.dgtt.local"
	@echo "  - Interface Étudiant: http://student.dgtt.local"
	@echo "  - Dashboard Traefik: http://localhost:8080"
	@echo "  - Interface Consul: http://localhost:8500"

setup-dev: ## Configuration pour le développement
	@echo "$(BLUE)🔧 Configuration pour le développement...$(NC)"
	@cp docker-compose.override.yml.example docker-compose.override.yml 2>/dev/null || echo "Fichier override déjà présent"
	@echo "$(GREEN)✅ Configuration développement prête$(NC)"

deploy-prod: ## Déployer en production (Hetzner)
	@echo "$(BLUE)🚀 Déploiement en production...$(NC)"
	@chmod +x deploy-hetzner.sh
	@echo "$(YELLOW)⚠️  Assurez-vous d'être connecté au serveur de production$(NC)"
	@./deploy-hetzner.sh

monitor: ## Afficher les ressources système
	@echo "$(BLUE)📊 Monitoring des ressources:$(NC)"
	@echo "$(BLUE)=== Docker Stats ===$(NC)"
	@docker stats --no-stream
	@echo ""
	@echo "$(BLUE)=== Disk Usage ===$(NC)"
	@df -h
	@echo ""
	@echo "$(BLUE)=== Memory Usage ===$(NC)"
	@free -h

update: ## Mettre à jour les images et redémarrer
	@echo "$(BLUE)🔄 Mise à jour des services...$(NC)"
	@docker-compose pull
	@docker-compose up -d
	@echo "$(GREEN)✅ Services mis à jour$(NC)"

health-check: ## Vérifier la santé des services
	@echo "$(BLUE)🏥 Vérification de la santé des services...$(NC)"
	@curl -f http://localhost:8080/api/http/services || echo "$(RED)❌ Traefik non accessible$(NC)"
	@curl -f http://localhost:8500/v1/status/leader || echo "$(RED)❌ Consul non accessible$(NC)"
	@docker-compose exec postgres pg_isready -U dgtt_user || echo "$(RED)❌ PostgreSQL non accessible$(NC)"
	@echo "$(GREEN)✅ Vérifications terminées$(NC)"
