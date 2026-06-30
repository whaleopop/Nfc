# Deployment Guide

## Prerequisites

- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+
- Node.js 18+ (для локальной разработки web)
- Flutter 3.0+ (для мобильной разработки)
- SSL сертификаты (для продакшена)

## Quick Start (Development)

### 1. Clone Repository

```bash
git clone <repository-url>
cd nfc-medical-platform
```

### 2. Environment Setup

Создайте `.env` файлы:

```bash
# Backend
cp backend/.env.example backend/.env

# Отредактируйте backend/.env с вашими настройками
```

### 3. Start Services

```bash
docker-compose up -d
```

Это запустит:
- PostgreSQL (port 5432)
- Redis (port 6379)
- Django Backend (port 8000)
- Celery Worker
- Celery Beat
- Nginx (port 80, 443)
- React Web (port 3000)

### 4. Initialize Database

```bash
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py createsuperuser
```

### 5. Access

- **Backend API**: http://localhost:8000/api
- **Admin Panel**: http://localhost:8000/admin
- **API Docs**: http://localhost:8000/api/docs
- **Web App**: http://localhost:3000

## Production Deployment

### Option 1: Docker Compose (Single Server)

#### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin
```

#### 2. Clone & Configure

```bash
git clone <repository-url>
cd nfc-medical-platform

# Configure environment
cp backend/.env.example backend/.env
nano backend/.env
```

**Important settings for production**:
```env
DEBUG=False
SECRET_KEY=<generate-strong-secret>
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

DB_PASSWORD=<strong-password>
REDIS_PASSWORD=<strong-password>

SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

#### 3. SSL Setup

```bash
# Using Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot certonly --nginx -d yourdomain.com -d www.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem docker/nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem docker/nginx/ssl/key.pem
```

#### 4. Update Nginx Config

Раскомментируйте HTTPS секцию в `docker/nginx/conf.d/default.conf`

#### 5. Build & Deploy

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Initialize database
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py createsuperuser
docker-compose exec backend python manage.py collectstatic --noinput
```

#### 6. Setup Auto-renewal (SSL)

```bash
# Add cron job
sudo crontab -e

# Add this line
0 0 * * * certbot renew --quiet && docker-compose restart nginx
```

### Option 2: Kubernetes

#### 1. Prepare Kubernetes Cluster

```bash
# Example using DigitalOcean Kubernetes
doctl kubernetes cluster create nfc-medical \
  --region nyc1 \
  --node-pool "name=worker;size=s-2vcpu-4gb;count=3"
```

#### 2. Create Namespaces

```bash
kubectl create namespace nfc-medical
```

#### 3. Deploy PostgreSQL

```yaml
# postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: nfc-medical
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: nfc_medical
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

#### 4. Deploy Backend

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: nfc-medical
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: your-registry/nfc-medical-backend:latest
        ports:
        - containerPort: 8000
        env:
        - name: DB_HOST
          value: postgres
        envFrom:
        - secretRef:
            name: backend-secret
```

#### 5. Apply

```bash
kubectl apply -f postgres-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f web-deployment.yaml
kubectl apply -f ingress.yaml
```

### Option 3: Cloud Platform (AWS Example)

#### Architecture

```
                    ┌─────────────┐
                    │ CloudFront  │
                    │   (CDN)     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Route 53  │
                    │    (DNS)    │
                    └──────┬──────┘
                           │
          ┌────────────────┴────────────────┐
          │                                  │
   ┌──────▼──────┐                  ┌───────▼───────┐
   │     ALB     │                  │      S3       │
   │ (Load Bal.) │                  │ (Web Static)  │
   └──────┬──────┘                  └───────────────┘
          │
   ┌──────▼──────┐
   │     ECS     │
   │  (Backend)  │
   └──────┬──────┘
          │
   ┌──────▼──────┬──────────┐
   │     RDS     │  ElastiCache│
   │ (Postgres)  │  (Redis)    │
   └─────────────┴─────────────┘
```

#### 1. Setup RDS

```bash
aws rds create-db-instance \
  --db-instance-identifier nfc-medical-db \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --master-username admin \
  --master-user-password <strong-password> \
  --allocated-storage 20
```

#### 2. Setup ElastiCache

```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id nfc-medical-redis \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-cache-nodes 1
```

#### 3. Deploy Backend to ECS

```bash
# Build and push Docker image
docker build -t nfc-medical-backend backend/
docker tag nfc-medical-backend:latest <ecr-url>/nfc-medical-backend:latest
docker push <ecr-url>/nfc-medical-backend:latest

# Create ECS task definition and service
aws ecs create-service ...
```

## Monitoring & Logging

### Sentry (Error Tracking)

```python
# settings.py
import sentry_sdk

sentry_sdk.init(
    dsn="your-sentry-dsn",
    environment="production",
)
```

### Prometheus + Grafana

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'backend'
    static_configs:
      - targets: ['backend:8000']
```

### Logging

```bash
# View logs
docker-compose logs -f backend
docker-compose logs -f celery

# In production
kubectl logs -f deployment/backend -n nfc-medical
```

## Backup Strategy

### Database Backup

```bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec -T postgres pg_dump -U nfc_user nfc_medical > backup_$DATE.sql
```

### Automated Backups

```bash
# Add to crontab
0 2 * * * /path/to/backup-script.sh
```

## Scaling

### Horizontal Scaling

```bash
# Scale backend workers
docker-compose up -d --scale backend=3

# Kubernetes
kubectl scale deployment backend --replicas=5 -n nfc-medical
```

### Database Scaling

- Read replicas for PostgreSQL
- Redis cluster for caching
- CDN for static files

## Security Checklist

- [ ] Change all default passwords
- [ ] Enable SSL/TLS
- [ ] Configure firewall rules
- [ ] Enable rate limiting
- [ ] Setup fail2ban
- [ ] Regular security updates
- [ ] Enable audit logging
- [ ] Backup encryption
- [ ] Two-factor authentication
- [ ] Regular security audits

## Health Checks

```bash
# Backend health
curl http://localhost:8000/api/

# Database
docker-compose exec postgres pg_isready

# Redis
docker-compose exec redis redis-cli ping
```

## Rollback Procedure

```bash
# Docker Compose
docker-compose down
git checkout previous-version
docker-compose up -d

# Kubernetes
kubectl rollout undo deployment/backend -n nfc-medical
```

## Performance Optimization

1. **Database Indexing**: Ensure proper indexes on frequently queried fields
2. **Caching**: Use Redis for session and query caching
3. **CDN**: Use CDN for static assets
4. **Compression**: Enable gzip/brotli compression
5. **Connection Pooling**: Configure database connection pooling

## Troubleshooting

### Backend not starting

```bash
docker-compose logs backend
# Check database connectivity
docker-compose exec backend python manage.py check
```

### Database connection issues

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Test connection
docker-compose exec backend python manage.py dbshell
```

### High memory usage

```bash
# Check resource usage
docker stats

# Adjust memory limits in docker-compose.yml
```

## Support

For deployment issues, contact: support@nfc-medical.ru
