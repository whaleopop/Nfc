# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NFC Medical Emergency Access Platform - a digital platform for emergency access to medical information via NFC tags (NTAG215). The system allows patients to register NFC tags with their medical profiles, enabling emergency medical workers to access critical health information by scanning the tag or using a QR code.

**Architecture**: Tri-platform system with Django REST API backend, React web frontend, and Flutter mobile app.

## Development Commands

### Backend (Django)

```bash
cd backend

# Setup
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Database
python manage.py migrate
python manage.py createsuperuser

# Run development server
python manage.py runserver  # http://localhost:8000

# Run tests
pytest
pytest apps/nfc/tests/  # Test specific app

# Code formatting
black .
isort .
flake8

# Create migrations
python manage.py makemigrations

# Django shell
python manage.py shell
```

### Web Frontend (React + Vite)

```bash
cd web

# Setup
npm install

# Development
npm run dev  # http://localhost:3000

# Build
npm run build

# Lint & Format
npm run lint
npm run format
```

### Mobile App (Flutter)

```bash
cd mobile

# Setup
flutter pub get

# Run
flutter run

# Build
flutter build apk  # Android
flutter build ios  # iOS

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

## Core Architecture

### Backend Structure

```
backend/
├── config/              # Django settings and root URLs
├── apps/
│   ├── authentication/  # Custom User model, JWT auth, 2FA
│   ├── profiles/        # Medical profiles, allergies, diseases, medications
│   ├── nfc/            # NFC tags, scanning, emergency access
│   └── audit/          # Audit logging middleware
```

**Key Apps:**

1. **authentication**: Custom User model with roles (PATIENT, MEDICAL_WORKER, ADMIN, SUPER_ADMIN). JWT authentication with refresh token rotation. 2FA support via django-otp.

2. **profiles**: Medical profile with:
   - Basic info: blood_type, height, weight
   - Allergies with severity levels (MILD, MODERATE, SEVERE, LIFE_THREATENING)
   - Chronic diseases with ICD codes
   - Medications with dosage and frequency
   - Emergency contacts with priority
   - Doctor notes (some visible during emergency access)

3. **nfc**: NFC tag management:
   - NFCTag model: tag_uid, status (ACTIVE/REVOKED/LOST/REPLACED), scan_count
   - NFCAccessLog: Complete audit trail of tag access
   - NFCEmergencyAccess: Emergency access records with location data

4. **audit**: AuditLogMiddleware automatically logs all API requests.

### Frontend Structure

```
web/src/
├── pages/              # Route components (Login, Dashboard, Profile, NFCManagement)
├── components/         # Reusable UI components
├── context/           # React Context (AuthContext for global auth state)
├── services/          # API client (axios with interceptors)
└── utils/             # Utilities
```

**Authentication Flow:**
- JWT tokens stored in localStorage
- Axios interceptor automatically adds Bearer token to requests
- Automatic token refresh on 401 responses
- AuthContext provides user state throughout app

### API Endpoints

**Base URL**: `/api/`

**Authentication** (`/api/auth/`):
- `POST /login/` - Login with email/password
- `POST /register/` - User registration
- `POST /refresh/` - Refresh access token
- `POST /logout/` - Logout (blacklist refresh token)
- `POST /2fa/verify/` - 2FA verification

**Profiles** (`/api/profiles/`):
- `GET /` - Get current user's profile
- `POST /` - Create profile
- `PUT /` - Update profile
- `GET /allergies/` - List allergies
- `POST /allergies/` - Add allergy
- `PUT /allergies/{id}/` - Update allergy
- `DELETE /allergies/{id}/` - Delete allergy
- Similar endpoints for chronic-diseases, medications, emergency-contacts

**NFC** (`/api/nfc/`):
- `GET /tags/` - List user's NFC tags
- `POST /register/` - Register new NFC tag (requires tag_uid, tag_type)
- `POST /scan/` - Scan NFC tag (authenticated)
- `POST /revoke/` - Revoke tag (requires tag_id, optional reason)
- `GET /access-logs/` - Get access logs
- `GET /emergency/{tag_uid}/` - **Public endpoint** for emergency access via QR code

## Critical Field Naming Conventions

**IMPORTANT**: Backend and frontend must use consistent field names:

### Allergies
- ✅ `allergen` (backend field name)
- ❌ NOT `name`
- Other fields: `severity`, `reaction`, `notes`, `diagnosed_date`

### Chronic Diseases
- ✅ `disease_name` (backend field name)
- ❌ NOT `name`
- Other fields: `icd_code`, `diagnosis_date`, `notes`, `is_active`

### Medications
- ✅ `medication_name` (backend field name)
- ❌ NOT `name`
- Other fields: `dosage`, `frequency`, `start_date`, `end_date`, `prescribing_doctor`, `is_active`

### NFC Tags
- ✅ `tag_uid` (unique identifier)
- ✅ `status` (ACTIVE/REVOKED/LOST/REPLACED)
- ✅ `scan_count` (number of scans)
- ❌ NOT `name`, `is_active`, `access_count`

### Blood Types (Russian Format)
- ✅ Use Russian blood type notation: `I+`, `I-`, `II+`, `II-`, `III+`, `III-`, `IV+`, `IV-`
- Display format: `I (0) Rh+`, `II (A) Rh+`, `III (B) Rh+`, `IV (AB) Rh+`
- ❌ NOT American format: `O+`, `A+`, `B+`, `AB+`

## Authentication & Security

### User Roles & Permissions

- **PATIENT**: Can manage own profile, NFC tags, view access logs
- **MEDICAL_WORKER**: Can access emergency data from NFC scans
- **ADMIN**: User management, view all logs
- **SUPER_ADMIN**: Full system access

### JWT Configuration

- Access token lifetime: 15 minutes (configurable via `JWT_ACCESS_TOKEN_LIFETIME`)
- Refresh token lifetime: 24 hours (configurable via `JWT_REFRESH_TOKEN_LIFETIME`)
- Tokens rotate on refresh
- Blacklisting enabled for revoked tokens

### Security Features

- AES-256 encryption for NFC data
- HMAC checksums for tag verification
- Rate limiting (60/min for anonymous, 1000/hour for authenticated)
- CORS configuration for allowed origins
- Audit logging for all operations
- 2FA support (TOTP)

## Database Models

### Custom User Model

```python
AUTH_USER_MODEL = 'authentication.User'
```

Uses email as USERNAME_FIELD (not username). All users have: email, first_name, last_name, middle_name (optional), role, phone (optional).

### Key Model Relationships

- User 1:1 MedicalProfile
- MedicalProfile 1:N Allergy, ChronicDisease, Medication, EmergencyContact, DoctorNote
- User 1:N NFCTag
- NFCTag 1:N NFCAccessLog, NFCEmergencyAccess

## Environment Configuration

Backend uses `python-decouple` for configuration. Key environment variables:

```env
# Django
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=nfc_medical
DB_USER=nfc_user
DB_PASSWORD=changeme
DB_HOST=localhost
DB_PORT=5432

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=changeme

# JWT
JWT_ACCESS_TOKEN_LIFETIME=15
JWT_REFRESH_TOKEN_LIFETIME=1440

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# NFC
NFC_TAG_TYPE=NTAG215
NFC_ENCRYPTION_KEY=changeme-32-bytes-hex-key-here
```

Frontend uses environment variables via Vite:

```env
VITE_API_URL=http://localhost:8000
VITE_BASE_URL=/
```

## Common Integration Issues

### Frontend-Backend Field Mismatches

When working with medical data forms:
1. Always use `allergen` (not `name`) for allergies
2. Always use `disease_name` for chronic diseases
3. Always use `medication_name` for medications
4. Severity values: MILD, MODERATE, SEVERE, LIFE_THREATENING (uppercase)

### NFC Tag Management

When displaying or managing NFC tags:
1. Use `tag_uid` for the unique identifier
2. Use `status` (not `is_active`) for tag state
3. Use `scan_count` (not `access_count`) for usage statistics
4. QR code URLs should point to `/emergency/{tag_uid}/` (public endpoint)

### API Authentication

- All endpoints require authentication except:
  - `/api/auth/login/`
  - `/api/auth/register/`
  - `/api/nfc/emergency/{tag_uid}/`
- Include `Authorization: Bearer <token>` header
- Handle 401 responses by refreshing token or redirecting to login

## Testing

### Backend Tests

Located in `apps/*/tests/`. Use pytest with Django plugin:

```bash
pytest  # Run all tests
pytest apps/nfc/tests/test_models.py  # Specific file
pytest -v  # Verbose
pytest --cov  # Coverage report
```

### Frontend Tests

Currently uses ESLint for code quality. Testing framework can be added.

## Mobile App Architecture

Flutter app uses:
- **State Management**: Provider
- **HTTP Client**: Dio with retrofit
- **NFC**: nfc_manager package
- **Secure Storage**: flutter_secure_storage for tokens
- **Local DB**: Hive for offline caching
- **Encryption**: encrypt package for AES-256

## API Documentation

When backend is running, access auto-generated API documentation:
- Swagger UI: http://localhost:8000/api/docs/
- ReDoc: http://localhost:8000/api/redoc/
- OpenAPI Schema: http://localhost:8000/api/schema/

Generated via drf-spectacular.

## Git Workflow

Current branch: `main`
Recent work focused on fixing frontend-backend integration issues with API endpoints and field naming consistency.
