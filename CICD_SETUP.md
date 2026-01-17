# CI/CD Setup Guide for NFC Medical App

This guide explains how to set up and use the GitHub Actions workflows with GitHub Container Registry (GHCR) for automated deployment.

## Overview

The project uses two main workflows:
- **Backend GHCR Deploy**: Builds and deploys Django backend with Celery workers
- **Web GHCR Deploy**: Builds and deploys React frontend (Vite)

Both workflows use GitHub Container Registry (GHCR) to store Docker images and deploy to your server via SSH.

## Prerequisites

1. **GitHub Repository**: Your code must be in a GitHub repository
2. **Server**: A remote server with Docker and Docker Compose v2 installed
3. **SSH Access**: SSH key pair for server access
4. **GitHub Packages**: Enabled for your repository (free for public repos)

## Important Notes

### Docker Image Naming

All Docker images are published to GitHub Container Registry (GHCR) with the following naming convention:
- Backend: `ghcr.io/<username>/nfc-backend-nfc:<tag>`
- Frontend: `ghcr.io/<username>/nfc-frontend-nfc:<tag>`

Where `<username>` is your GitHub username and `<tag>` can be:
- `latest` - most recent build
- `sha-<short-commit>` - first 7 characters of commit hash (e.g., `sha-024065c`)
- Branch name (e.g., `main`)

**Note:** The workflows use short SHA (7 characters) for tagging, not the full 40-character commit hash.

## Setup Instructions

### 1. Enable GitHub Packages

GitHub Packages (GHCR) is automatically available. Ensure your repository has the correct permissions:

1. Go to repository Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Click "Save"

### 2. Configure GitHub Secrets

Add the following secrets to your repository (Settings → Secrets and variables → Actions):

#### Required Secrets

**Server Access:**
- `SSH_PRIVATE_KEY`: Your SSH private key for server access
- `SERVER_HOST`: Your server IP or domain (e.g., `192.168.1.100` or `example.com`)
- `SERVER_USER`: SSH username (e.g., `root` or `ubuntu`)
- `SERVER_PATH`: Path where the app is deployed on server (e.g., `/root/nfc-medical-app`)

**Backend Configuration:**
- `SECRET_KEY`: Django secret key
- `DEBUG`: Set to `False` for production
- `ALLOWED_HOSTS`: Comma-separated list of allowed hosts (e.g., `example.com,www.example.com`)

**Database (PostgreSQL):**
- `POSTGRES_DB`: Database name (e.g., `nfc_medical`)
- `POSTGRES_USER`: Database username (e.g., `nfc_user`)
- `POSTGRES_PASSWORD`: Database password
- `DB_PASSWORD`: Same as POSTGRES_PASSWORD (for compatibility)

**Redis:**
- `REDIS_PASSWORD`: Redis password

**Celery (Optional):**
- `CELERY_BROKER_URL`: Redis URL for Celery (e.g., `redis://:password@redis:6379/0`)
- `CELERY_RESULT_BACKEND`: Redis URL for results (e.g., `redis://:password@redis:6379/0`)

**Frontend Configuration:**
- `VITE_API_URL`: Backend API URL (e.g., `https://api.example.com/api`)
- `VITE_APP_NAME`: Application name (e.g., `NFC Medical`)

**Health Check URLs:**
- `BACKEND_URL`: Backend base URL for health checks (e.g., `https://api.example.com`)
- `WEB_URL`: Frontend URL for health checks (e.g., `https://example.com`)

### 3. Prepare Your Server

On your deployment server, run:

```bash
# Create deployment directory
mkdir -p /root/nfc-medical-app
cd /root/nfc-medical-app

# Install Docker and Docker Compose v2 (if not already installed)
curl -fsSL https://get.docker.com | sh

# Enable Docker service
systemctl enable docker
systemctl start docker

# Add your user to docker group (optional, if not using root)
usermod -aG docker $USER
```

### 4. Add SSH Key to Server

On your local machine:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github-actions

# Copy public key to server
ssh-copy-id -i ~/.ssh/github-actions.pub user@your-server

# Copy private key content to GitHub Secrets
cat ~/.ssh/github-actions
# Copy the entire output and paste as SSH_PRIVATE_KEY secret
```

## Usage

### Automatic Deployment

Workflows trigger automatically on push to `main` branch when files change:

**Backend deployment triggers when:**
- Files in `backend/**` directory change
- `docker-compose.yml` changes
- Workflow file `.github/workflows/backend-ghcr-deploy.yml` changes

**Frontend deployment triggers when:**
- Files in `web/**` directory change
- Workflow file `.github/workflows/web-ghcr-deploy.yml` changes

### Manual Deployment

You can also trigger workflows manually:

1. Go to Actions tab in GitHub
2. Select the workflow (Backend GHCR Deploy or Web GHCR Deploy)
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Workflow Process

### Backend Workflow

1. **Build Job**:
   - Checks out code
   - Sets up Docker Buildx
   - Logs into GHCR
   - Builds Docker image for backend
   - Pushes image to GHCR with tags: `latest`, `sha-<commit>`, `branch-<name>`

2. **Deploy Job**:
   - Creates `.env` file with secrets
   - Copies `docker-compose.yml` and `.env` to server via SSH
   - Logs into GHCR on server
   - Pulls latest backend image
   - Stops old containers
   - Starts new containers (backend, celery, celery-beat)
   - Runs migrations and collects static files
   - Performs health check

### Frontend Workflow

1. **Build Job**:
   - Checks out code
   - Sets up Docker Buildx
   - Logs into GHCR
   - Builds Docker image with Vite environment variables
   - Pushes image to GHCR

2. **Deploy Job**:
   - Creates `.env` file with secrets
   - Copies files to server via SSH
   - Pulls latest frontend image
   - Restarts web container
   - Performs health check

## Local Development

For local development, the `docker-compose.yml` still supports building images locally:

```bash
# Build and run locally (without GHCR)
docker compose up -d --build

# Or specify environment variables
GITHUB_REPOSITORY_OWNER=local IMAGE_TAG=dev docker compose up -d --build
```

The compose file uses environment variable defaults that allow local builds when GHCR variables are not set.

## Environment Variables

The `docker-compose.yml` supports both local and production environments:

**For Local Development:**
```bash
# Uses local builds (default)
docker compose up -d --build
```

**For Production (with GHCR):**
```bash
# Set these in your .env file on the server
GITHUB_REPOSITORY_OWNER=whaleopop  # Your GitHub username
IMAGE_TAG=latest  # or sha-<commit> or branch name

# Examples of valid IMAGE_TAG values:
# IMAGE_TAG=latest                                       # Latest build
# IMAGE_TAG=sha-024065c                                  # Specific commit (short SHA - 7 chars)
# IMAGE_TAG=main                                         # Main branch

# Pull and run from GHCR
docker compose pull
docker compose up -d
```

## Troubleshooting

### Build Fails

**Issue**: Docker build fails during workflow

**Solutions**:
- Check Dockerfile syntax
- Ensure all required files are committed
- Check build logs in Actions tab

### Deployment Fails

**Issue**: Deployment step fails

**Solutions**:
- Verify SSH credentials are correct
- Check server has enough disk space: `df -h`
- Ensure Docker is running on server: `systemctl status docker`
- Check server logs: `ssh user@server 'cd /path && docker compose logs'`

### Health Check Fails

**Issue**: Health check times out

**Solutions**:
- Verify backend/frontend URLs are accessible
- Check if containers are running: `docker compose ps`
- Check container logs: `docker compose logs backend` or `docker compose logs web`
- Ensure firewall allows traffic on required ports

### Permission Issues

**Issue**: SSH permission denied

**Solutions**:
- Verify SSH key is correct: `ssh -i ~/.ssh/github-actions user@server`
- Check key permissions: `chmod 600 ~/.ssh/github-actions`
- Ensure public key is in server's `~/.ssh/authorized_keys`

### GHCR Authentication Fails

**Issue**: Cannot push/pull images from GHCR

**Solutions**:
- Ensure workflow has `packages: write` permission
- Check if repository settings allow package creation
- For manual pulls, create Personal Access Token with `read:packages` scope

## Image Management

### View Published Images

1. Go to your repository on GitHub
2. Click "Packages" in the sidebar (or repository Packages tab)
3. You'll see `nfc-backend-nfc` and `nfc-frontend-nfc`

### Pull Images Manually

```bash
# Login to GHCR
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull specific image
docker pull ghcr.io/whaleopop/nfc-backend-nfc:latest
docker pull ghcr.io/whaleopop/nfc-frontend-nfc:latest

# Pull specific commit (short SHA - first 7 characters)
docker pull ghcr.io/whaleopop/nfc-backend-nfc:sha-024065c
docker pull ghcr.io/whaleopop/nfc-frontend-nfc:sha-024065c
```

### Clean Up Old Images

GitHub automatically retains images, but you can delete old ones:

1. Go to repository Packages
2. Select the package (backend or frontend)
3. Click on specific version
4. Click "Delete"

Or use GitHub CLI:

```bash
gh api -X DELETE /user/packages/container/nfc-backend-nfc/versions/VERSION_ID
```

## Security Best Practices

1. **Never commit secrets**: Always use GitHub Secrets
2. **Rotate SSH keys**: Periodically generate new SSH keys
3. **Use strong passwords**: For database and Redis
4. **Limit server access**: Use firewall rules
5. **Regular updates**: Keep Docker and system packages updated
6. **Review workflow logs**: Check for any exposed secrets

## Advanced Configuration

### Custom Image Names

Edit workflow files to change image names:

```yaml
env:
  IMAGE_NAME: your-custom-name  # Change this
```

### Multiple Environments

Create separate workflows for staging/production:

```yaml
on:
  push:
    branches: [ staging ]  # or production
```

Use different secrets for each environment:
- `STAGING_SERVER_HOST`
- `PRODUCTION_SERVER_HOST`
- etc.

### Build Caching

Workflows use GitHub Actions cache for faster builds:

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

This speeds up subsequent builds significantly.

## Monitoring Deployments

### GitHub Actions

- View workflow runs in Actions tab
- Each run shows build and deploy logs
- Failed runs show error details

### Server Side

```bash
# Check running containers
docker compose ps

# View logs
docker compose logs -f backend
docker compose logs -f web

# Check resource usage
docker stats

# View recent deployments
ls -lt /root/nfc-medical-app/
```

## Next Steps

1. ✅ Configure all GitHub Secrets
2. ✅ Prepare your server
3. ✅ Push code to `main` branch
4. ✅ Monitor workflow execution
5. ✅ Verify deployment on server
6. ✅ Test your application

For more help, check the GitHub Actions documentation: https://docs.github.com/en/actions
