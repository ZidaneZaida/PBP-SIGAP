/// Konfigurasi URL dan Endpoint API Backend SIGAP.
class ApiConfig {
  /// Base URL backend.
  /// Dapat dioverride saat compile/run dengan flag:
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:8000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Auth endpoints
  static const String register = '/api/auth/register/';
  static const String login = '/api/auth/login/';
  static const String refresh = '/api/auth/token/refresh/';
  static const String logout = '/api/auth/logout/';
  static const String me = '/api/me/';
  static const String preferences = '/api/me/preferences/';

  // Public & Content endpoints
  static const String health = '/api/health/';
  static const String alertsLatest = '/api/alerts/latest/';
  static const String alerts = '/api/alerts/';
  static const String assistancePoints = '/api/assistance-points/';
  static const String guides = '/api/guides/';
  static const String emergencyContacts = '/api/emergency-contacts/';
  static const String news = '/api/news/';
  static const String dashboard = '/api/dashboard/';

  // Family endpoints
  static const String familyGroups = '/api/family/groups/';
  static const String familyJoin = '/api/family/join/';
}

