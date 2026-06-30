.PHONY: help build up down restart logs shell migrate makemigrations createsuperuser test clean

help:
	@echo "NFC Medical Platform - Makefile Commands"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make build          - Build all Docker images"
	@echo "  make up             - Start all services"
	@echo "  make down           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo "  make logs           - View logs (all services)"
	@echo "  make logs-backend   - View backend logs"
	@echo "  make logs-web       - View web logs"
	@echo ""
	@echo "Django Commands:"
	@echo "  make shell          - Open Django shell"
	@echo "  make bash           - Open bash in backend container"
	@echo "  make migrate        - Run database migrations"
	@echo "  make makemigrations - Create new migrations"
	@echo "  make createsuperuser - Create Django superuser"
	@echo "  make collectstatic  - Collect static files"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run all backend tests"
	@echo "  make test-coverage  - Run tests with coverage"
	@echo ""
	@echo "Database:"
	@echo "  make dbshell        - Open PostgreSQL shell"
	@echo "  make dbreset        - Reset database (WARNING: deletes all data)"
	@echo "  make backup         - Backup database"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Remove all containers, volumes, and images"
	@echo "  make prune          - Docker system prune"

# Docker commands
build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

logs-backend:
	docker-compose logs -f backend

logs-web:
	docker-compose logs -f web

logs-celery:
	docker-compose logs -f celery

# Django commands
shell:
	docker-compose exec backend python manage.py shell

bash:
	docker-compose exec backend bash

migrate:
	docker-compose exec backend python manage.py migrate

makemigrations:
	docker-compose exec backend python manage.py makemigrations

createsuperuser:
	docker-compose exec backend python manage.py createsuperuser

collectstatic:
	docker-compose exec backend python manage.py collectstatic --noinput

# Testing
test:
	docker-compose exec backend pytest

test-coverage:
	docker-compose exec backend pytest --cov --cov-report=html

lint-backend:
	docker-compose exec backend flake8 .
	docker-compose exec backend black --check .

format-backend:
	docker-compose exec backend black .
	docker-compose exec backend isort .

# Database commands
dbshell:
	docker-compose exec db psql -U nfc_user -d nfc_medical

dbreset:
	@echo "WARNING: This will delete all data. Press Ctrl+C to cancel."
	@sleep 5
	docker-compose down -v
	docker-compose up -d db
	@sleep 3
	docker-compose exec backend python manage.py migrate
	docker-compose exec backend python manage.py createsuperuser

backup:
	docker-compose exec db pg_dump -U nfc_user nfc_medical > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created: backup_$(shell date +%Y%m%d_%H%M%S).sql"

restore:
	@echo "Usage: make restore FILE=backup_YYYYMMDD_HHMMSS.sql"
	docker-compose exec -T db psql -U nfc_user nfc_medical < $(FILE)

# Web commands
web-install:
	cd web && npm install

web-dev:
	cd web && npm run dev

web-build:
	cd web && npm run build

# Mobile commands
mobile-get:
	cd mobile && flutter pub get

mobile-run:
	cd mobile && flutter run

mobile-build-apk:
	cd mobile && flutter build apk --release

mobile-build-ios:
	cd mobile && flutter build ios --release

# Cleanup
clean:
	docker-compose down -v --rmi all --remove-orphans

prune:
	docker system prune -af --volumes

# Setup (first time)
setup:
	@echo "Setting up NFC Medical Platform..."
	cp backend/.env.example backend/.env
	@echo ".env file created. Please edit backend/.env with your settings."
	@echo "Then run: make up && make migrate && make createsuperuser"

# Development
dev: up logs

# Production
prod-build:
	docker-compose -f docker-compose.prod.yml build

prod-up:
	docker-compose -f docker-compose.prod.yml up -d

prod-down:
	docker-compose -f docker-compose.prod.yml down
