#!/bin/bash

# ========================================
# NFC Medical Platform - Server Setup Script
# ========================================
#
# Быстрая настройка сервера для деплоя
# Backend (Django + Docker) и Frontend (React + Nginx)
#
# Использование:
#   chmod +x SERVER_SETUP.sh
#   sudo ./SERVER_SETUP.sh
#
# ========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}NFC Medical Platform - Server Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Проверка что скрипт запущен с sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Пожалуйста, запустите скрипт с sudo${NC}"
  exit 1
fi

# Получение информации от пользователя
read -p "Введите путь для backend (например: /var/www/nfc-medical): " BACKEND_PATH
read -p "Введите путь для frontend (например: /var/www/html/nfc-medical): " FRONTEND_PATH
read -p "Введите URL репозитория GitHub: " REPO_URL
read -p "Введите доменное имя (например: example.com): " DOMAIN_NAME

echo ""
echo -e "${YELLOW}📋 Настройки:${NC}"
echo "Backend: $BACKEND_PATH"
echo "Frontend: $FRONTEND_PATH"
echo "Repository: $REPO_URL"
echo "Domain: $DOMAIN_NAME"
echo ""
read -p "Продолжить? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 1. Обновление системы
echo -e "${GREEN}📦 Обновление системы...${NC}"
apt update && apt upgrade -y

# 2. Установка Docker
echo -e "${GREEN}🐳 Установка Docker...${NC}"
if ! command -v docker &> /dev/null; then
    apt install -y docker.io
    systemctl start docker
    systemctl enable docker
    echo -e "${GREEN}✅ Docker установлен${NC}"
else
    echo -e "${YELLOW}⏭️ Docker уже установлен${NC}"
fi

# 3. Установка Docker Compose
echo -e "${GREEN}🐳 Установка Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    apt install -y docker-compose
    echo -e "${GREEN}✅ Docker Compose установлен${NC}"
else
    echo -e "${YELLOW}⏭️ Docker Compose уже установлен${NC}"
fi

# 4. Установка Git
echo -e "${GREEN}📥 Установка Git...${NC}"
if ! command -v git &> /dev/null; then
    apt install -y git
    echo -e "${GREEN}✅ Git установлен${NC}"
else
    echo -e "${YELLOW}⏭️ Git уже установлен${NC}"
fi

# 5. Установка Nginx
echo -e "${GREEN}🌐 Установка Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo -e "${GREEN}✅ Nginx установлен${NC}"
else
    echo -e "${YELLOW}⏭️ Nginx уже установлен${NC}"
fi

# 6. Установка Certbot (для SSL)
echo -e "${GREEN}🔒 Установка Certbot...${NC}"
apt install -y certbot python3-certbot-nginx

# 7. Создание директорий
echo -e "${GREEN}📁 Создание директорий...${NC}"
mkdir -p "$BACKEND_PATH"
mkdir -p "$FRONTEND_PATH"

# 8. Клонирование репозитория
echo -e "${GREEN}📥 Клонирование репозитория...${NC}"
if [ -d "$BACKEND_PATH/.git" ]; then
    echo -e "${YELLOW}⏭️ Репозиторий уже клонирован${NC}"
    cd "$BACKEND_PATH"
    git pull
else
    git clone "$REPO_URL" "$BACKEND_PATH"
    cd "$BACKEND_PATH"
fi

# 9. Создание .env файла для backend
echo -e "${GREEN}⚙️ Создание .env файла...${NC}"
if [ ! -f "$BACKEND_PATH/backend/.env" ]; then
    cp "$BACKEND_PATH/backend/.env.example" "$BACKEND_PATH/backend/.env" || true
    echo -e "${YELLOW}⚠️ Не забудьте настроить $BACKEND_PATH/backend/.env${NC}"
fi

# 10. Настройка Nginx для frontend
echo -e "${GREEN}🌐 Настройка Nginx...${NC}"
cat > /etc/nginx/sites-available/nfc-medical <<EOL
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    # Frontend
    root $FRONTEND_PATH;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API proxy
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Django admin
    location /admin {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Static files for Django
    location /static {
        alias $BACKEND_PATH/backend/staticfiles;
    }

    # Media files
    location /media {
        alias $BACKEND_PATH/backend/media;
    }
}
EOL

# Активация сайта
ln -sf /etc/nginx/sites-available/nfc-medical /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации Nginx
nginx -t

# Перезагрузка Nginx
systemctl reload nginx

echo -e "${GREEN}✅ Nginx настроен${NC}"

# 11. Настройка прав доступа
echo -e "${GREEN}🔐 Настройка прав доступа...${NC}"
chown -R www-data:www-data "$FRONTEND_PATH"
chmod -R 755 "$FRONTEND_PATH"

# Получение текущего пользователя (не root)
ACTUAL_USER="${SUDO_USER:-$USER}"
chown -R $ACTUAL_USER:$ACTUAL_USER "$BACKEND_PATH"

# Добавление пользователя в группу docker
usermod -aG docker $ACTUAL_USER

# 12. Настройка Firewall
echo -e "${GREEN}🔥 Настройка Firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp   # SSH
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS
    ufw --force enable
    echo -e "${GREEN}✅ Firewall настроен${NC}"
else
    echo -e "${YELLOW}⚠️ UFW не установлен, пропускаем настройку firewall${NC}"
fi

# 13. Первоначальный запуск backend
echo -e "${GREEN}🚀 Запуск backend...${NC}"
cd "$BACKEND_PATH"
docker-compose up -d --build

echo -e "${GREEN}⏳ Ожидание запуска сервисов...${NC}"
sleep 15

echo -e "${GREEN}🔄 Применение миграций...${NC}"
docker-compose exec -T backend python manage.py migrate --noinput || true

echo -e "${GREEN}📦 Сбор статических файлов...${NC}"
docker-compose exec -T backend python manage.py collectstatic --noinput || true

# 14. Создание суперпользователя
echo ""
echo -e "${YELLOW}👤 Создание суперпользователя Django...${NC}"
echo -e "${YELLOW}(Вы можете пропустить, нажав Ctrl+C)${NC}"
docker-compose exec backend python manage.py createsuperuser || true

# 15. SSL сертификат
echo ""
echo -e "${GREEN}🔒 Настройка SSL...${NC}"
read -p "Установить SSL сертификат (Let's Encrypt)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME
    echo -e "${GREEN}✅ SSL сертификат установлен${NC}"
fi

# 16. Итоговая информация
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Настройка сервера завершена!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📋 Следующие шаги:${NC}"
echo ""
echo "1. Настройте .env файл:"
echo "   nano $BACKEND_PATH/backend/.env"
echo ""
echo "2. Перезапустите backend после настройки .env:"
echo "   cd $BACKEND_PATH"
echo "   docker-compose restart"
echo ""
echo "3. Настройте GitHub Secrets в репозитории:"
echo "   - SSH_PRIVATE_KEY"
echo "   - SERVER_HOST"
echo "   - SERVER_USER"
echo "   - SERVER_PATH=$BACKEND_PATH"
echo "   - WEB_PATH=$FRONTEND_PATH"
echo "   - BACKEND_URL=http://$DOMAIN_NAME"
echo "   - WEB_URL=http://$DOMAIN_NAME"
echo ""
echo "4. Проверьте доступность:"
echo "   Backend:  http://$DOMAIN_NAME/api/"
echo "   Admin:    http://$DOMAIN_NAME/admin/"
echo "   Frontend: http://$DOMAIN_NAME/"
echo ""
echo -e "${GREEN}🎉 Готово! Теперь вы можете делать push в main для автодеплоя${NC}"
echo ""
