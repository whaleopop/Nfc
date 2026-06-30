# API Documentation

## Base URL
```
http://localhost:8000/api
```

## Authentication

### Register
```http
POST /api/auth/register/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "password2": "SecurePassword123",
  "first_name": "Иван",
  "last_name": "Иванов",
  "middle_name": "Иванович",
  "phone": "+79001234567"
}

Response:
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "Иван",
    "last_name": "Иванов",
    ...
  },
  "message": "Пользователь успешно зарегистрирован"
}
```

### Login
```http
POST /api/auth/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123"
}

Response (without 2FA):
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": { ... }
}

Response (with 2FA):
{
  "requires_2fa": true,
  "user_id": "uuid",
  "message": "Требуется 2FA верификация"
}
```

### Refresh Token
```http
POST /api/auth/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}

Response:
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### Get Current User
```http
GET /api/auth/me/
Authorization: Bearer <access_token>

Response:
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "Иванов Иван Иванович",
  ...
}
```

### 2FA Enable
```http
GET /api/auth/2fa/enable/
Authorization: Bearer <access_token>

Response:
{
  "qr_code": "data:image/png;base64,...",
  "secret": "JBSWY3DPEHPK3PXP"
}

POST /api/auth/2fa/enable/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "otp_code": "123456"
}

Response:
{
  "message": "2FA успешно активирован"
}
```

## Medical Profile

### Get Profile
```http
GET /api/profile/
Authorization: Bearer <access_token>

Response:
{
  "id": "uuid",
  "user": "uuid",
  "blood_type": "A+",
  "height": 180,
  "weight": 75.5,
  "emergency_notes": "Важная информация",
  "is_public": true,
  "allergies": [...],
  "chronic_diseases": [...],
  "medications": [...],
  "emergency_contacts": [...]
}
```

### Create Profile
```http
POST /api/profile/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "blood_type": "A+",
  "height": 180,
  "weight": 75.5,
  "emergency_notes": "Важная информация",
  "is_public": true
}
```

### Update Profile
```http
PUT /api/profile/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "blood_type": "O+",
  "emergency_notes": "Обновленная информация"
}
```

### Allergies
```http
# List
GET /api/profile/allergies/
Authorization: Bearer <access_token>

# Create
POST /api/profile/allergies/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "allergen": "Пенициллин",
  "severity": "SEVERE",
  "reaction": "Анафилактический шок",
  "notes": "Опасно"
}

# Update
PUT /api/profile/allergies/{id}/
Authorization: Bearer <access_token>

# Delete
DELETE /api/profile/allergies/{id}/
Authorization: Bearer <access_token>
```

## NFC Management

### Register NFC Tag
```http
POST /api/nfc/register/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "tag_uid": "04:12:34:56:78:90:AB",
  "tag_type": "NTAG215"
}

Response:
{
  "tag": {
    "id": "uuid",
    "tag_uid": "04:12:34:56:78:90:AB",
    "status": "ACTIVE",
    ...
  },
  "nfc_data": {
    "tag_id": "uuid",
    "public_key_id": "key-uuid",
    "checksum": "hmac-hash"
  },
  "message": "NFC метка успешно зарегистрирована"
}
```

### Scan NFC Tag (Emergency Access)
```http
POST /api/nfc/scan/
Content-Type: application/json

{
  "tag_uid": "04:12:34:56:78:90:AB",
  "public_key_id": "key-uuid",
  "checksum": "hmac-hash",
  "latitude": 55.7558,
  "longitude": 37.6173
}

Response:
{
  "profile": {
    "user_name": "Иванов Иван Иванович",
    "blood_type": "A+",
    "allergies": [...],
    "chronic_diseases": [...],
    "medications": [...],
    "emergency_contacts": [...]
  },
  "message": "Успешный доступ к экстренным медицинским данным"
}
```

### List User's Tags
```http
GET /api/nfc/tags/
Authorization: Bearer <access_token>

Response:
[
  {
    "id": "uuid",
    "tag_uid": "04:12:34:56:78:90:AB",
    "status": "ACTIVE",
    "scan_count": 15,
    "last_scanned_at": "2024-01-13T10:30:00Z",
    ...
  }
]
```

### Revoke Tag
```http
POST /api/nfc/revoke/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "tag_id": "uuid",
  "reason": "Метка утеряна"
}

Response:
{
  "message": "NFC метка успешно отозвана",
  "tag": { ... }
}
```

## Audit & Logs

### Get Audit Logs (Admin)
```http
GET /api/audit/logs/
Authorization: Bearer <access_token>

Query Parameters:
- user_id
- action
- resource_type
- severity
- success

Response:
[
  {
    "id": "uuid",
    "user_name": "Иванов Иван",
    "action": "CREATE",
    "resource_type": "PROFILE",
    "severity": "MEDIUM",
    "success": true,
    "created_at": "2024-01-13T10:30:00Z",
    ...
  }
]
```

### Get My Audit Logs
```http
GET /api/audit/my-logs/
Authorization: Bearer <access_token>

Response:
[...]
```

## Error Responses

### 400 Bad Request
```json
{
  "error": "Validation error",
  "details": {
    "field_name": ["Error message"]
  }
}
```

### 401 Unauthorized
```json
{
  "error": "Authentication credentials were not provided"
}
```

### 403 Forbidden
```json
{
  "error": "You do not have permission to perform this action"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Rate Limiting

- Anonymous: 60 requests/minute
- Authenticated: 1000 requests/hour

## Pagination

List endpoints support pagination:

```http
GET /api/resource/?page=1&page_size=20
```

Response includes:
```json
{
  "count": 100,
  "next": "http://api.../resource/?page=2",
  "previous": null,
  "results": [...]
}
```
