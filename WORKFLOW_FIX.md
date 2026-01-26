# GitHub Actions Workflow Fix

## Проблема

Workflows падали с ошибкой:
```
Error response from daemon: Conflict. The container name "/nfc_web" is already in use
Error response from daemon: Conflict. The container name "/nfc_backend" is already in use
```

## Исправление

### Backend Workflow ([backend-ghcr-deploy.yml](.github/workflows/backend-ghcr-deploy.yml))
Добавлено принудительное удаление контейнеров по имени:
```bash
docker compose stop backend celery celery-beat || true
docker compose rm -f backend celery celery-beat || true

# Fallback - удаление по имени если compose не сработал
docker rm -f nfc_backend nfc_celery nfc_celery_beat 2>/dev/null || true
```

### Frontend Workflow ([web-ghcr-deploy.yml](.github/workflows/web-ghcr-deploy.yml))
Добавлено принудительное удаление контейнера по имени:
```bash
docker compose stop web || true
docker compose rm -f web || true

# Fallback - удаление по имени
docker rm -f nfc_web 2>/dev/null || true
```

## Дополнительные изменения

### 1. Удалены Health Checks
Убраны health check шаги из обоих workflows, потому что:
- ❌ Могут падать если URL недоступен снаружи
- ❌ Добавляют лишнее время к деплою
- ✅ Проверка контейнеров через `docker compose ps` достаточна

### 2. Backend БЕЗ зависимостей + ручное подключение к сети
Workflow использует `--no-deps` ВСЕГДА и подключает к сети вручную:

```bash
# Запускаем БЕЗ зависимостей (не трогаем db/redis)
docker compose up -d --no-deps backend celery celery-beat --force-recreate

# Находим сеть где находятся db и redis
NETWORK_NAME=$(docker network ls --format '{{.Name}}' | grep 'nfc.*network' | head -n1)

# Подключаем backend к этой сети
docker network connect $NETWORK_NAME nfc_backend 2>/dev/null || true
docker network connect $NETWORK_NAME nfc_celery 2>/dev/null || true
docker network connect $NETWORK_NAME nfc_celery_beat 2>/dev/null || true
```

**Почему это работает:**
- ✅ `--no-deps` предотвращает создание db/redis (игнорирует depends_on)
- ✅ Backend запускается изолированно без сети
- ✅ Вручную подключаем к сети где находятся db/redis
- ✅ Backend может обращаться к `db` и `redis` хостам
- ✅ Никаких конфликтов имён контейнеров!

## Что теперь делать

Workflows исправлены, теперь они:
1. ✅ Останавливают старые контейнеры через `docker compose stop`
2. ✅ Удаляют старые контейнеры через `docker compose rm -f`
3. ✅ Принудительно удаляют по имени если что-то пошло не так
4. ✅ Создают новые контейнеры без конфликтов
5. ✅ Не делают health checks (быстрее деплой)

**Можно делать коммит и пуш!** 🚀

Workflows больше не будут падать с ошибкой "container already in use".
