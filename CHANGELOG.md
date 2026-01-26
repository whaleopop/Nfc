# Changelog

All notable changes to the NFC Medical Platform will be documented in this file.

## [1.0.0] - 2026-01-26

### 🎉 Full Release - Complete Frontend Implementation

#### Added - Web Frontend
- **Login Page** (`/login`) - User authentication with email/password validation
- **Registration Page** (`/register`) - Complete user registration with role selection (Patient/Medical Worker/Admin)
- **Dashboard** (`/dashboard`) - Main user panel with statistics and quick actions
- **Medical Profile** (`/profile`) - Comprehensive medical data management:
  - Basic info: blood type, height, weight, emergency notes
  - Allergies with severity levels
  - Chronic diseases with diagnosis dates
  - Current medications with dosage
  - Emergency contacts
- **NFC Management** (`/nfc`) - NFC tag creation and management:
  - Create and activate/deactivate NFC tags
  - Generate and download QR codes
  - View access history and statistics
- **Admin Panel** (`/admin`) - Administrative dashboard for medical workers and admins:
  - System statistics
  - Access logs monitoring
  - User management (planned)
- **Emergency Access** (`/emergency/:tagId`) - Public emergency data access page:
  - Patient information display
  - Critical medical data (blood type, allergies, diseases)
  - Emergency contacts
  - Works without authentication

#### Added - Infrastructure
- **API Service** (`web/src/services/api.js`) - Centralized Axios client with:
  - Automatic JWT token injection
  - Automatic token refresh on 401 errors
  - Organized API endpoints (auth, profile, NFC)
- **AuthContext** (`web/src/contexts/AuthContext.jsx`) - Global authentication state management
- **ProtectedRoute** - HOC for protecting private routes
- **Frontend Documentation** - Complete README with setup instructions

#### Changed
- Updated frontend API URL configuration to use `https://testapi.soldium.ru/api`
- Improved frontend build process with proper environment variables
- Updated GitHub Actions workflows to use correct VITE variables from secrets
- Removed health checks from workflows to speed up deployment

#### Fixed
- Fixed frontend API URL double-domain issue
- Fixed ALLOWED_HOSTS configuration for multiple domains
- Fixed Docker Compose build args for frontend environment variables
- Fixed CORS configuration for cross-origin requests
- Fixed GitHub Actions workflows to properly remove old containers before deployment
- Fixed backend workflow to use --no-deps and manual network connection (prevents db/redis conflicts)

#### Backend
- Existing Django REST API with JWT authentication
- Medical profile management endpoints
- NFC tag management endpoints
- Emergency access public endpoints

#### Mobile
- Flutter iOS/Android application
- NFC tag reading support (NTAG215)
- AES-256 encryption for secure data

#### DevOps
- GitHub Actions CI/CD for all components
- Docker containerization
- Nginx reverse proxy configuration
- Automated deployment to production server

### Configuration
- Added GitHub Secrets for frontend environment variables
- Updated deployment scripts for proper build configuration
- Created deployment documentation and quick fix guides

### Documentation
- Complete web frontend documentation in `web/README.md`
- Deployment fix instructions in `DEPLOY_FRONTEND_FIX.md`
- Quick fix guide in `QUICK_FIX.md`
- API endpoints documentation
- Testing instructions

---

## Future Releases

### Planned Features
- [ ] User profile editing (non-medical)
- [ ] Patient search and management for medical workers
- [ ] User avatar upload
- [ ] Analytics and charts in admin panel
- [ ] Export medical data to PDF
- [ ] Multi-language support (currently Russian only)
- [ ] Dark mode
- [ ] Push notifications on NFC access
- [ ] Medical profile change history
- [ ] Temporary access grants for specific medical workers

---

## Version Format

We follow [Semantic Versioning](https://semver.org/):
- MAJOR.MINOR.PATCH
- MAJOR: Incompatible API changes
- MINOR: New functionality (backwards compatible)
- PATCH: Bug fixes (backwards compatible)

[1.0.0]: https://github.com/whaleOpop/Nfc/releases/tag/v1.0.0
