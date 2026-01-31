/// API Configuration for NFC Medical Backend
class ApiConfig {
  // Base URL - change this to your backend URL
  static const String baseUrl = 'https://testapi.soldium.ru';

  // API endpoints
  static const String apiPrefix = '/api';

  // Auth endpoints
  static const String login = '$apiPrefix/auth/login/';
  static const String register = '$apiPrefix/auth/register/';
  static const String refresh = '$apiPrefix/auth/refresh/';
  static const String logout = '$apiPrefix/auth/logout/';

  // Profile endpoints
  static const String profile = '$apiPrefix/profiles/';
  static const String allergies = '$apiPrefix/profiles/allergies/';
  static const String chronicDiseases = '$apiPrefix/profiles/chronic-diseases/';
  static const String medications = '$apiPrefix/profiles/medications/';
  static const String emergencyContacts = '$apiPrefix/profiles/emergency-contacts/';

  // NFC endpoints
  static const String nfcTags = '$apiPrefix/nfc/tags/';
  static const String nfcRegister = '$apiPrefix/nfc/register/';
  static const String nfcScan = '$apiPrefix/nfc/scan/';
  static const String nfcRevoke = '$apiPrefix/nfc/revoke/';
  static const String nfcAccessLogs = '$apiPrefix/nfc/access-logs/';

  // Emergency access (public)
  static String nfcEmergency(String tagUid) => '$apiPrefix/nfc/emergency/$tagUid/';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
