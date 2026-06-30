#!/bin/bash

# Quick setup script for GitHub Secrets using gh CLI
# Usage: ./setup-secrets.sh

set -e

if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) is not installed"
  echo "Install it from: https://cli.github.com/"
  exit 1
fi

echo "🔐 GitHub Secrets Setup for NFC Medical"
echo "========================================"
echo ""

# Check if authenticated
if ! gh auth status &> /dev/null; then
  echo "⚠️ Not authenticated with GitHub"
  echo "Run: gh auth login"
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "📦 Repository: $REPO"
echo ""

read -p "Continue with secret setup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 0
fi

echo ""
echo "Setting up secrets..."
echo ""

# Function to set secret
set_secret() {
  local name=$1
  local prompt=$2
  local default=$3

  if [ -n "$default" ]; then
    read -p "$prompt [$default]: " value
    value=${value:-$default}
  else
    read -p "$prompt: " value
  fi

  if [ -n "$value" ]; then
    echo "$value" | gh secret set "$name"
    echo "  ✅ $name set"
  else
    echo "  ⏭️  $name skipped"
  fi
}

# Server connection
echo "📡 Server Connection"
set_secret "SERVER_HOST" "Server IP or domain" ""
set_secret "SERVER_USER" "SSH user" "root"
set_secret "SERVER_PATH" "Deployment path" "/root/nfc-app"

echo ""
echo "🔑 SSH Private Key"
echo "Paste your SSH private key (finish with Ctrl+D on empty line):"
ssh_key=$(cat)
if [ -n "$ssh_key" ]; then
  echo "$ssh_key" | gh secret set SSH_PRIVATE_KEY
  echo "  ✅ SSH_PRIVATE_KEY set"
else
  echo "  ⏭️  SSH_PRIVATE_KEY skipped"
fi

echo ""
echo "🐍 Django Backend"
# Generate SECRET_KEY if not provided
default_secret_key=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())' 2>/dev/null || echo "")
set_secret "SECRET_KEY" "Django secret key" "$default_secret_key"
set_secret "DEBUG" "Debug mode" "False"
set_secret "ALLOWED_HOSTS" "Allowed hosts (comma-separated)" "*"
set_secret "BACKEND_URL" "Backend URL" "http://localhost:8000"

echo ""
echo "🗄️  PostgreSQL Database"
set_secret "POSTGRES_DB" "Database name" "nfc_medical"
set_secret "POSTGRES_USER" "Database user" "nfc_user"
set_secret "POSTGRES_PASSWORD" "Database password" ""
set_secret "DB_PASSWORD" "Database password (same as above)" ""

echo ""
echo "📦 Redis"
set_secret "REDIS_PASSWORD" "Redis password" "changeme"

echo ""
echo "⚙️  Celery"
read -p "Redis password for Celery (press enter to use same as REDIS_PASSWORD): " celery_redis_pass
celery_redis_pass=${celery_redis_pass:-changeme}

celery_broker="redis://:${celery_redis_pass}@redis:6379/0"
echo "$celery_broker" | gh secret set CELERY_BROKER_URL
echo "  ✅ CELERY_BROKER_URL set"

echo "$celery_broker" | gh secret set CELERY_RESULT_BACKEND
echo "  ✅ CELERY_RESULT_BACKEND set"

echo ""
echo "🌐 Frontend"
set_secret "VITE_API_URL" "API URL for frontend" "http://localhost:8000/api"
set_secret "VITE_APP_NAME" "Application name" "NFC Medical"
set_secret "WEB_URL" "Frontend URL" "http://localhost:3000"

echo ""
echo "✅ Secret setup completed!"
echo ""
echo "To verify secrets, run: gh secret list"
echo "Or use: ./.github/check-secrets.sh"
