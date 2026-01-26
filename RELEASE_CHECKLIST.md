# 🚀 Release v1.0.0 - Quick Checklist

## ☑️ Pre-Release (Сделай ЭТО СНАЧАЛА!)

- [ ] **Обновить GitHub Secrets** → https://github.com/whaleOpop/Nfc/settings/secrets/actions
  - [ ] `VITE_API_URL` = `https://testapi.soldium.ru/api`
  - [ ] `VITE_APP_NAME` = `NFC Medical Platform`
  - [ ] `WEB_URL` = `https://test.soldium.ru`
  - [ ] `SERVER_PATH` = `/root/nfc-app`

## ☑️ Release (Запуск сборки)

```bash
# 1. Добавить все файлы
git add .

# 2. Коммит (включает исправление workflows)
git commit -m "🎉 Release v1.0.0 - Complete Frontend Implementation

- Add complete web frontend with all pages
- Fix workflows: smart container check + start only needed services
- Backend workflow intelligently manages db/redis/backend
- Remove health checks from workflows for faster deployment
- Add VERSION, CHANGELOG, and release documentation
"

# 3. Пуш (запустит все workflows!)
git push origin main
```

## ☑️ Monitoring (Следить за процессом)

- [ ] Открыть https://github.com/whaleOpop/Nfc/actions
- [ ] Дождаться завершения workflows:
  - [ ] Backend Build & Deploy (~5-10 мин)
  - [ ] Web Frontend Build & Deploy (~5-10 мин)
  - [ ] iOS Build (~15-20 мин)
  - [ ] Android Build (~10-15 мин)

## ☑️ Post-Deploy (После успешного деплоя)

На сервере:
```bash
ssh root@46.173.18.72
cd /root/nfc-app

# Проверить/обновить ALLOWED_HOSTS
nano .env
# Добавь: ALLOWED_HOSTS=localhost,127.0.0.1,46.173.18.72,testapi.soldium.ru,test.soldium.ru,soldium.ru

# Перезапустить бэкенд
docker-compose restart backend celery celery-beat

# Проверить статус
docker-compose ps
docker-compose logs -f web
```

## ☑️ Testing (Проверка работоспособности)

- [ ] **Web Frontend**
  - [ ] Открыть https://test.soldium.ru/register
  - [ ] Зарегистрировать тестового юзера
  - [ ] Проверить Dashboard
  - [ ] Создать NFC метку
  - [ ] Проверить профиль
  - [ ] Проверить Emergency Access

- [ ] **DevTools Check**
  - [ ] F12 → Network
  - [ ] Запросы идут на `https://testapi.soldium.ru/api/*` ✅
  - [ ] НЕТ ошибок CORS ✅
  - [ ] НЕТ 405/404 ошибок ✅

- [ ] **Mobile Apps**
  - [ ] Скачать iOS IPA из Releases
  - [ ] Скачать Android APK из Releases
  - [ ] Протестировать на устройствах

## ☑️ Release Notes (Опубликовать релиз)

- [ ] Создать Release на GitHub: https://github.com/whaleOpop/Nfc/releases/new
  - Tag: `v1.0.0`
  - Title: `Release v1.0.0 - Complete Frontend Implementation`
  - Description: Скопировать из `CHANGELOG.md`
  - Прикрепить IPA и APK

---

## 🔥 Если что-то сломалось

**Откат фронтенда:**
```bash
cd /root/nfc-app
nano .env  # IMAGE_TAG=sha-f056626
docker-compose pull web && docker-compose up -d web --force-recreate
```

**Откат бэкенда:**
```bash
nano .env  # IMAGE_TAG=sha-ea9e145
docker-compose pull backend && docker-compose up -d backend --force-recreate
docker-compose restart celery celery-beat
```

**Логи:**
```bash
docker-compose logs -f backend
docker-compose logs -f web
docker logs soldium-nginx
```

---

**Статус:** ⏳ Готово к запуску
