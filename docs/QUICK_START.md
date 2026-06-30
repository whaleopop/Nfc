# Quick Start Guide

Быстрый старт для локальной разработки проекта NFC Medical Platform.

## Минимальные требования

- Docker Desktop
- Git
- Текстовый редактор (VS Code рекомендуется)

## Шаг 1: Клонирование проекта

```bash
git clone <repository-url>
cd nfc-medical-platform
```

## Шаг 2: Настройка Backend

### 2.1 Создайте .env файл

```bash
cd backend
cp .env.example .env
```

### 2.2 Отредактируйте .env (опционально для dev)

Для локальной разработки можно оставить значения по умолчанию.

## Шаг 3: Запуск через Docker

```bash
# Вернитесь в корневую директорию
cd ..

# Запустите все сервисы
docker-compose up -d
```

Это запустит:
- PostgreSQL
- Redis
- Django Backend
- Celery Worker
- Nginx
- React Web

## Шаг 4: Инициализация базы данных

```bash
# Применить миграции
docker-compose exec backend python manage.py migrate

# Создать суперпользователя
docker-compose exec backend python manage.py createsuperuser

# Следуйте инструкциям и введите:
# Email: admin@example.com
# Password: (ваш пароль)
```

## Шаг 5: Проверка

Откройте браузер и перейдите:

- **API Docs**: http://localhost:8000/api/docs/
- **Admin Panel**: http://localhost:8000/admin/
- **Web App**: http://localhost:3000/

## Шаг 6: Первый запрос к API

### Регистрация пользователя

```bash
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@example.com",
    "password": "SecurePass123",
    "password2": "SecurePass123",
    "first_name": "Иван",
    "last_name": "Петров",
    "phone": "+79001234567"
  }'
```

### Вход

```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@example.com",
    "password": "SecurePass123"
  }'
```

Сохраните полученные `access` и `refresh` токены.

### Создание медицинского профиля

```bash
curl -X POST http://localhost:8000/api/profile/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "blood_type": "A+",
    "height": 180,
    "weight": 75,
    "emergency_notes": "Аллергия на пенициллин",
    "is_public": true
  }'
```

## Разработка Mobile (Flutter)

### Установка зависимостей

```bash
cd mobile
flutter pub get
```

### Запуск

```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### Изменение API URL

Отредактируйте `mobile/lib/utils/constants.dart`:

```dart
static const String apiBaseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
// или
static const String apiBaseUrl = 'http://localhost:8000/api'; // iOS simulator
```

## Разработка Web (React)

### Установка зависимостей

```bash
cd web
npm install
```

### Запуск dev server

```bash
npm run dev
```

Web приложение будет доступно по адресу: http://localhost:3000

## Полезные команды

### Docker

```bash
# Остановить все сервисы
docker-compose down

# Пересобрать образы
docker-compose build

# Посмотреть логи
docker-compose logs -f backend

# Зайти в контейнер
docker-compose exec backend bash
```

### Django

```bash
# Создать миграции
docker-compose exec backend python manage.py makemigrations

# Применить миграции
docker-compose exec backend python manage.py migrate

# Django shell
docker-compose exec backend python manage.py shell

# Создать суперпользователя
docker-compose exec backend python manage.py createsuperuser

# Собрать статику
docker-compose exec backend python manage.py collectstatic
```

### Database

```bash
# Подключиться к PostgreSQL
docker-compose exec db psql -U nfc_user -d nfc_medical

# Бэкап
docker-compose exec db pg_dump -U nfc_user nfc_medical > backup.sql

# Восстановление
docker-compose exec -T db psql -U nfc_user nfc_medical < backup.sql
```

## Тестирование API через Swagger

1. Откройте http://localhost:8000/api/docs/
2. Нажмите "Authorize"
3. Введите токен: `Bearer YOUR_ACCESS_TOKEN`
4. Тестируйте эндпоинты через UI

## Типичные проблемы

### Порт уже занят

```bash
# Проверьте занятые порты
docker ps

# Измените порты в docker-compose.yml
```

### База данных не инициализирована

```bash
# Удалите volumes и пересоздайте
docker-compose down -v
docker-compose up -d
docker-compose exec backend python manage.py migrate
```

### Backend не запускается

```bash
# Проверьте логи
docker-compose logs backend

# Часто помогает пересборка
docker-compose build backend
docker-compose up -d backend
```

## Следующие шаги

1. Прочитайте [API Documentation](./API.md)
2. Изучите [NFC Protocol](./NFC_PROTOCOL.md)
3. Настройте вашу IDE для разработки
4. Создайте тестовые данные через Admin Panel

## Полезные ссылки

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Flutter Documentation](https://flutter.dev/docs)
- [React Documentation](https://react.dev/)
- [Material-UI](https://mui.com/)

## Получение помощи

- Проверьте логи: `docker-compose logs`
- Прочитайте документацию в папке `docs/`
- Создайте issue в GitHub
