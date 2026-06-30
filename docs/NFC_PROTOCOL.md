# NFC Protocol Documentation

## Overview

Система использует NFC метки типа NTAG215 для хранения идентификационной информации, которая позволяет получить экстренный доступ к медицинским данным пациента.

## NTAG215 Specifications

- **Memory**: 540 bytes
- **User Memory**: 504 bytes
- **Type**: ISO/IEC 14443 Type A
- **Operating Frequency**: 13.56 MHz
- **Read Distance**: up to 10 cm

## Data Structure

### Что хранится на NFC метке

**ВАЖНО**: На метке НЕ хранятся медицинские данные напрямую!

На метке хранится только:

```json
{
  "tag_id": "UUID формат",
  "public_key_id": "UUID формат",
  "checksum": "HMAC-SHA256 хэш"
}
```

### Формат данных

```
NDEF Record:
- Record Type: Text
- Encoding: UTF-8
- Payload: JSON string
```

Пример:
```json
{
  "tag_id": "550e8400-e29b-41d4-a716-446655440000",
  "public_key_id": "660e8400-e29b-41d4-a716-446655440001",
  "checksum": "8c7e42c8c6e2c2c8c6e2c2c8c6e2c2c8"
}
```

## Security

### Checksum Generation

Контрольная сумма генерируется с использованием HMAC-SHA256:

```python
import hmac
import hashlib

def generate_checksum(tag_uid, public_key_id, secret_key):
    data = f"{tag_uid}{public_key_id}"
    signature = hmac.new(
        secret_key.encode(),
        data.encode(),
        hashlib.sha256
    ).hexdigest()
    return signature
```

### Verification Flow

1. **Сканирование метки**: Мобильное приложение считывает данные с NFC метки
2. **Проверка подписи**: Backend проверяет checksum с помощью HMAC
3. **Валидация статуса**: Проверка, что метка активна (не отозвана)
4. **Проверка прав**: Проверка, что пользователь разрешил экстренный доступ
5. **Возврат данных**: Backend возвращает экстренные медицинские данные

## Registration Flow

### 1. Подготовка метки

Пользователь приобретает чистую NTAG215 метку.

### 2. Регистрация через приложение

```
User -> App: Инициирует регистрацию метки
App -> NFC Tag: Считывает UID метки
App -> Backend: POST /api/nfc/register/ {tag_uid}
Backend: Генерирует public_key_id и checksum
Backend -> App: Возвращает {tag_id, public_key_id, checksum}
App -> NFC Tag: Записывает JSON данные на метку
App -> User: Подтверждение успешной регистрации
```

### 3. Запись данных

```kotlin
// Android example
fun writeNFCTag(tag: Tag, data: String) {
    val ndef = Ndef.get(tag)
    val message = NdefMessage(
        arrayOf(
            NdefRecord.createTextRecord("en", data)
        )
    )
    ndef.connect()
    ndef.writeNdefMessage(message)
    ndef.close()
}
```

```swift
// iOS example
func writeNFCTag(session: NFCNDEFReaderSession, tag: NFCNDEFTag, data: String) {
    let payload = NFCNDEFPayload(
        format: .nfcWellKnown,
        type: "T".data(using: .utf8)!,
        identifier: Data(),
        payload: data.data(using: .utf8)!
    )
    let message = NFCNDEFMessage(records: [payload])

    tag.writeNDEF(message) { error in
        if error == nil {
            session.alertMessage = "Success"
        }
    }
}
```

## Emergency Access Flow

### 1. Сканирование метки

```
Medical Worker -> NFC Tag: Сканирует метку
App: Считывает JSON данные
App: Парсит tag_id, public_key_id, checksum
```

### 2. Запрос данных

```
App -> Backend: POST /api/nfc/scan/
{
  "tag_uid": "04:12:34:56:78:90:AB",
  "public_key_id": "660e8400-e29b-41d4-a716-446655440001",
  "checksum": "8c7e42c8...",
  "latitude": 55.7558,  // optional
  "longitude": 37.6173  // optional
}
```

### 3. Backend обработка

```python
# 1. Найти метку по tag_uid
nfc_tag = NFCTag.objects.get(tag_uid=tag_uid)

# 2. Проверить статус
if nfc_tag.status != 'ACTIVE':
    return Error("Tag revoked")

# 3. Проверить checksum
data = f"{tag_uid}{public_key_id}"
expected_checksum = nfc_tag.generate_checksum(data)
if not hmac.compare_digest(expected_checksum, checksum):
    return Error("Invalid checksum")

# 4. Проверить разрешение доступа
profile = nfc_tag.user.medical_profile
if not profile.is_public:
    return Error("Access denied")

# 5. Вернуть данные
return {
    "profile": EmergencyProfileSerializer(profile).data
}
```

### 4. Логирование

Все попытки доступа логируются:

- Успешные и неудачные
- IP адрес
- Геолокация (если доступна)
- Время
- Устройство

## Tag Lifecycle

### States

```
ACTIVE → Метка активна и может использоваться
REVOKED → Метка отозвана пользователем
LOST → Метка утеряна
REPLACED → Метка заменена на новую
```

### State Transitions

```
[ACTIVE] --revoke--> [REVOKED]
[ACTIVE] --lost--> [LOST]
[ACTIVE] --replace--> [REPLACED]
```

## Best Practices

### For Patients

1. **Носите метку при себе**: На браслете, в кошельке, на ключах
2. **Обновляйте данные**: Регулярно обновляйте медицинский профиль
3. **Проверяйте историю**: Просматривайте логи доступа к вашим данным
4. **Отзывайте потерянные метки**: Немедленно отзывайте метку при потере

### For Medical Workers

1. **Сканируйте только в экстренных ситуациях**: Не злоупотребляйте доступом
2. **Проверяйте данные**: Убедитесь, что данные актуальны
3. **Документируйте доступ**: Оставляйте заметки о причине доступа

### For Developers

1. **Валидируйте все входные данные**
2. **Используйте HTTPS для всех запросов**
3. **Проверяйте checksum перед запросом к backend**
4. **Обрабатывайте все ошибки**
5. **Логируйте все действия**

## Troubleshooting

### Tag не читается

1. Убедитесь, что NFC включен на устройстве
2. Поднесите метку ближе (1-3 см)
3. Убедитесь, что метка не повреждена
4. Проверьте, что метка NTAG215

### Invalid checksum

1. Метка была перезаписана
2. Данные повреждены
3. Метка не была зарегистрирована правильно
4. Решение: Перерегистрировать метку

### Access denied

1. Пользователь отключил экстренный доступ
2. Метка отозвана
3. Метка не зарегистрирована

## Security Considerations

1. **Физическая безопасность**: Метка может быть скопирована физически
2. **Replay attacks**: Checksum защищает от replay атак
3. **Privacy**: Медицинские данные не хранятся на метке
4. **Revocation**: Возможность немедленного отзыва метки
5. **Audit Trail**: Полное логирование всех доступов

## Future Enhancements

1. **Биометрическая верификация**: Для дополнительной безопасности
2. **Time-based OTP**: Динамический checksum с ограниченным временем жизни
3. **Multi-factor**: Комбинация NFC + PIN
4. **Encrypted payload**: Шифрование данных на метке
