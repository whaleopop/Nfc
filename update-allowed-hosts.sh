#!/bin/bash

# Скрипт для обновления ALLOWED_HOSTS на сервере

echo "🔧 Обновление ALLOWED_HOSTS в .env файле..."

# Проверка наличия .env
if [ ! -f .env ]; then
    echo "❌ Файл .env не найден!"
    exit 1
fi

# Текущее значение ALLOWED_HOSTS
CURRENT_HOSTS=$(grep "^ALLOWED_HOSTS=" .env | cut -d'=' -f2)
echo "📋 Текущие ALLOWED_HOSTS: $CURRENT_HOSTS"

# Новое значение с добавлением soldium.ru
NEW_HOSTS="localhost,127.0.0.1,46.173.18.72,testapi.soldium.ru,test.soldium.ru,soldium.ru"

# Обновление .env файла
if grep -q "^ALLOWED_HOSTS=" .env; then
    # Замена существующей строки
    sed -i "s|^ALLOWED_HOSTS=.*|ALLOWED_HOSTS=$NEW_HOSTS|" .env
    echo "✅ ALLOWED_HOSTS обновлен"
else
    # Добавление новой строки
    echo "ALLOWED_HOSTS=$NEW_HOSTS" >> .env
    echo "✅ ALLOWED_HOSTS добавлен"
fi

echo "📋 Новые ALLOWED_HOSTS: $NEW_HOSTS"

# Перезапуск бэкенд контейнеров
echo ""
echo "🔄 Перезапуск бэкенд контейнеров..."
docker-compose restart backend celery celery-beat

echo ""
echo "✅ Готово! Проверьте логи:"
echo "   docker-compose logs -f backend"
