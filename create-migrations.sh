#!/bin/bash

# Script to create Django migrations using Docker

echo "Creating Django migrations..."

cd "$(dirname "$0")"

# Build backend image if needed
docker compose build backend

# Create migrations
docker compose run --rm backend python manage.py makemigrations

echo "Done! Migrations created."
echo "Please commit the new migration files:"
echo "git add backend/apps/*/migrations/"
echo "git commit -m 'Add initial Django migrations'"
