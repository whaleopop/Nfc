# NFC Medical Mobile App

Flutter мобильное приложение для экстренного доступа к медицинской информации через NFC.

## Требования

- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode
- Устройство с NFC (физическое для тестирования)

## Платформы

- **Android**: 8.0+ (API level 26+)
- **iOS**: 13.0+

## Основные функции

### Для пациентов
- Регистрация и авторизация
- Управление медицинским профилем
- Регистрация NFC меток
- Управление аллергиями, заболеваниями, лекарствами
- Управление экстренными контактами
- Просмотр истории доступа к данным
- 2FA аутентификация

### Для медработников
- Сканирование NFC меток
- Просмотр экстренных медицинских данных
- Добавление заметок к профилям пациентов

## Структура проекта

```
lib/
├── main.dart                  # Точка входа
├── models/                    # Модели данных
│   ├── user.dart
│   ├── medical_profile.dart
│   ├── nfc_tag.dart
│   └── ...
├── services/                  # Сервисы
│   ├── api_service.dart       # API клиент
│   ├── auth_service.dart      # Аутентификация
│   ├── nfc_service.dart       # NFC логика
│   ├── storage_service.dart   # Локальное хранилище
│   └── ...
├── screens/                   # Экраны
│   ├── auth/
│   ├── profile/
│   ├── nfc/
│   └── ...
├── widgets/                   # Переиспользуемые виджеты
│   ├── buttons/
│   ├── cards/
│   ├── forms/
│   └── ...
└── utils/                     # Утилиты
    ├── constants.dart
    ├── validators.dart
    └── ...
```

## Установка

1. Клонируйте репозиторий
2. Установите зависимости:
```bash
cd mobile
flutter pub get
```

3. Запустите приложение:
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

## Конфигурация

Создайте файл `lib/utils/config.dart`:

```dart
class Config {
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const String apiTimeout = '30000'; // ms
}
```

## NFC

### Android

Добавьте в `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="true" />
```

### iOS

Добавьте в `ios/Runner/Info.plist`:

```xml
<key>NFCReaderUsageDescription</key>
<string>Необходим для чтения медицинских данных с NFC метки</string>
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
    <string>TAG</string>
</array>
```

## Безопасность

- Все токены хранятся в Secure Storage (Keychain/Keystore)
- Медицинские данные шифруются локально (AES-256)
- SSL Pinning для API запросов
- Биометрическая аутентификация (опционально)

## Тестирование

```bash
flutter test
```

## Сборка

### Android (APK)
```bash
flutter build apk --release
```

### Android (App Bundle)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Известные проблемы

- NFC доступен только на физических устройствах
- iOS требует специальные entitlements для NFC

## Лицензия

Proprietary
