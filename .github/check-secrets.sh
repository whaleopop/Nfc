#!/bin/bash

# Script to check if all required GitHub Secrets are configured

echo "🔐 GitHub Secrets Configuration Checker"
echo "========================================="
echo ""

REPO="${1:-whaleOpop/Nfc}"

echo "Checking secrets for repository: $REPO"
echo ""

REQUIRED_SECRETS=(
  # Server connection
  "SSH_PRIVATE_KEY"
  "SERVER_HOST"
  "SERVER_USER"
  "SERVER_PATH"

  # Backend
  "SECRET_KEY"
  "DEBUG"
  "ALLOWED_HOSTS"
  "BACKEND_URL"

  # Database
  "POSTGRES_DB"
  "POSTGRES_USER"
  "POSTGRES_PASSWORD"
  "DB_PASSWORD"

  # Redis
  "REDIS_PASSWORD"

  # Celery
  "CELERY_BROKER_URL"
  "CELERY_RESULT_BACKEND"

  # Frontend
  "VITE_API_URL"
  "VITE_APP_NAME"
  "WEB_URL"
)

echo "Required secrets:"
echo ""

for secret in "${REQUIRED_SECRETS[@]}"; do
  echo "  - $secret"
done

echo ""
echo "To set these secrets, go to:"
echo "https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "Or use GitHub CLI:"
echo ""
echo "  gh secret set SECRET_KEY --body 'your-secret-key'"
echo "  gh secret set SERVER_HOST --body 'your-server-ip'"
echo "  # ... etc"
echo ""

# Check if gh CLI is available
if command -v gh &> /dev/null; then
  echo "📋 Checking existing secrets using gh CLI..."
  echo ""

  existing_secrets=$(gh secret list --repo "$REPO" 2>/dev/null | awk '{print $1}')

  if [ -z "$existing_secrets" ]; then
    echo "⚠️ Could not fetch secrets. Make sure you're authenticated with 'gh auth login'"
  else
    missing_count=0
    found_count=0

    for secret in "${REQUIRED_SECRETS[@]}"; do
      if echo "$existing_secrets" | grep -q "^${secret}$"; then
        echo "  ✅ $secret"
        found_count=$((found_count + 1))
      else
        echo "  ❌ $secret (missing)"
        missing_count=$((missing_count + 1))
      fi
    done

    echo ""
    echo "Summary: $found_count/${#REQUIRED_SECRETS[@]} secrets configured"

    if [ $missing_count -gt 0 ]; then
      echo "⚠️ $missing_count secrets are missing"
      exit 1
    else
      echo "✅ All required secrets are configured!"
    fi
  fi
else
  echo "💡 Install GitHub CLI to automatically check secrets: https://cli.github.com/"
fi
