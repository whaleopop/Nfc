#!/bin/bash
# Run this script on the server to generate Django migrations

set -e

echo "🔧 Generating Django migrations on server..."
echo ""

cd /root/nfc-app

# Create temporary directory for migrations
mkdir -p /tmp/nfc-migrations

# Run makemigrations and copy results
echo "📝 Running makemigrations..."
docker compose run --rm \
  -v /tmp/nfc-migrations:/migrations-temp \
  backend sh -c "
    python manage.py makemigrations --noinput &&
    echo '' &&
    echo 'Copying migration files...' &&
    find /app/apps -name '*.py' -path '*/migrations/*' -not -name '__init__.py' -exec cp --parents {} /migrations-temp/ \; &&
    echo 'Done!'
  "

# Copy migrations from temp to backend directory
if [ -d "/tmp/nfc-migrations/app/apps" ]; then
  echo ""
  echo "📦 Copying migrations to backend/apps..."
  cp -r /tmp/nfc-migrations/app/apps/*/migrations/*.py backend/apps/*/migrations/ 2>/dev/null || true
  rm -rf /tmp/nfc-migrations
fi

# Show created files
echo ""
echo "✅ Migration files created:"
find backend/apps -name "*.py" -path "*/migrations/*" -not -name "__init__.py" -ls

echo ""
echo "📌 Next steps:"
echo "1. Add and commit migrations:"
echo "   git add backend/apps/*/migrations/"
echo "   git commit -m 'Add Django migrations'"
echo "   git push origin main"
echo ""
echo "2. Rebuild and redeploy:"
echo "   docker compose down"
echo "   docker compose pull backend"
echo "   docker compose up -d backend"
