#!/bin/bash
# Run this on the server to create missing Django migrations

cd /root/nfc-app

echo "Creating Django migrations..."

# Run makemigrations in backend container
docker compose run --rm --no-deps backend python manage.py makemigrations

echo ""
echo "Migrations created! Now copy them back to your local machine:"
echo ""
echo "From your local machine run:"
echo "scp -r root@YOUR_SERVER:/root/nfc-app/backend/apps/*/migrations ./backend/apps/"
