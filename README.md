# NFC Medical Emergency Access Platform

**Version 1.0.0** - Full Release with Complete Frontend

Цифровая платформа экстренного доступа к медицинской информации через NFC-метки (NTAG215).

## Архитектура

```
nfc-medical-platform/
├── backend/          # Django REST API
├── mobile/           # Flutter приложение (iOS/Android)
├── web/              # Web-платформа (личные кабинеты, админка)
├── docs/             # Документация
└── docker/           # Docker конфигурация
```

## Технологический стек

### Backend
- Python 3.11
- Django 4.x
- Django REST Framework
- PostgreSQL
- Redis
- Celery
- JWT Authentication

### Mobile
- Flutter 3.x
- NFC support (NTAG215)
- AES-256 encryption
- Secure Storage

### Web
- React / Vue.js
- Material UI
- Responsive design

### Infrastructure
- Docker / Docker Compose
- Nginx
- TLS 1.2+

## Компоненты системы

### 1. NFC-метка (NTAG215)
Хранит только:
```json
{
  "tag_id": "UUID",
  "public_key_id": "KEY_ID",
  "checksum": "HMAC"
}
```

### 2. Роли пользователей
- **Пациент**: Управление профилем, NFC
- **Медработник**: Просмотр экстренных данных
- **Администратор**: Управление пользователями, логи
- **Супер-админ**: Полный доступ

### 3. Медицинский профиль
- Группа крови + резус
- Аллергии
- Хронические заболевания
- Текущая терапия
- Экстренные контакты
- Примечания врача

## Безопасность
- AES-256 локальное шифрование
- TLS 1.2+
- JWT + refresh tokens
- 2FA (SMS / TOTP)
- Ролевая модель доступа
- Полный аудит операций
- Rate limiting
- IP blacklist

## Быстрый старт

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

### Web
```bash
cd web
npm install
npm run dev
```

### Docker
```bash
docker-compose up -d
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Вход
- `POST /api/auth/refresh` - Обновление токена
- `POST /api/auth/2fa` - 2FA верификация

### Profile
- `GET /api/profile/{id}` - Получить профиль
- `POST /api/profile` - Создать профиль
- `PUT /api/profile` - Обновить профиль

### NFC
- `POST /api/nfc/register` - Регистрация метки
- `POST /api/nfc/scan` - Скан метки
- `POST /api/nfc/revoke` - Отзыв метки

### Admin
- `GET /api/admin/users` - Список пользователей
- `GET /api/admin/logs` - Журнал аудита
- `GET /api/admin/stats` - Статистика

## 🚀 Deployment

Проект поддерживает автоматический CI/CD через GitHub Actions:

### Frontend Deployment
- **GitHub Pages** (рекомендуется) - бесплатный хостинг с HTTPS и CDN
- **Self-hosted** - на собственном сервере с Nginx

### Backend Deployment
- Docker-based deployment на VPS/Dedicated сервер
- Автоматические миграции и health checks

### Mobile Apps
- Автоматическая сборка APK/AAB (Android)
- Автоматическая сборка IPA (iOS)
- GitHub Releases для каждой версии

**Документация по deployment**: См. [DEPLOYMENT.md](./DEPLOYMENT.md)

**Быстрый старт с GitHub Pages**:
1. Settings → Pages → Source: GitHub Actions
2. Добавить `VITE_API_URL` в Secrets
3. Push в main → автодеплой

**Детальная документация**:
- [GitHub Pages Setup](.github/GITHUB_PAGES_SETUP.md)
- [Secrets Configuration](.github/SECRETS_SETUP.md)
- [Workflows Documentation](.github/workflows/README.md)
- [Server Setup Script](.github/SERVER_SETUP.sh)

---

## Разработка

### Этапы
1. **Проектирование** (2-3 недели)
2. **Backend MVP** (4-6 недель)
3. **Flutter MVP** (4-6 недель)
4. **Web-платформа** (3-4 недели)
5. **Безопасность и тесты** (2-3 недели)

## Документация
- [Backend API](./docs/backend.md)
- [Mobile App](./docs/mobile.md)
- [Web Platform](./docs/web.md)
- [NFC Protocol](./docs/nfc.md)
- [Security](./docs/security.md)

## Лицензия
Proprietary

## Контакты
TBD
