import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  late final FlutterSecureStorage _storage;
  final Map<String, String?> _memoryFallback = {};

  String? _cachedToken;
  String? _cachedCompanyId;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _companyIdKey = 'company_id';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userEmailVerifiedAtKey = 'user_email_verified_at';
  static const _rolesKey = 'user_roles';
  static const _companyNameKey = 'company_name';
  static const _companyLogoKey = 'company_logo';
  static const _employeeIdKey = 'employee_id';
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';

  Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _cachedToken = await _readSafe(_tokenKey);
    _cachedCompanyId = await _readSafe(_companyIdKey);
  }

  Future<String?> _readSafe(String key) async {
    try {
      final val = await _storage.read(key: key);
      _memoryFallback[key] = val;
      return val;
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _writeSafe(String key, String? value) async {
    _memoryFallback[key] = value;
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (_) {}
  }

  /// Synchronous fast accessors for Dio network interceptors (0ms latency)
  String? get cachedAccessToken => _cachedToken ?? _memoryFallback[_tokenKey];
  String? get cachedCompanyId => _cachedCompanyId ?? _memoryFallback[_companyIdKey];

  // Auth Tokens
  Future<String?> get accessToken async {
    _cachedToken ??= await _readSafe(_tokenKey);
    return _cachedToken;
  }

  Future<void> setAccessToken(String token) async {
    _cachedToken = token;
    await _writeSafe(_tokenKey, token);
  }

  Future<void> deleteAccessToken() async {
    _cachedToken = null;
    await _writeSafe(_tokenKey, null);
  }

  Future<String?> get refreshToken => _readSafe(_refreshTokenKey);
  Future<void> setRefreshToken(String token) => _writeSafe(_refreshTokenKey, token);
  Future<void> deleteRefreshToken() => _writeSafe(_refreshTokenKey, null);

  // Company
  Future<String?> get companyId async {
    _cachedCompanyId ??= await _readSafe(_companyIdKey);
    return _cachedCompanyId;
  }

  Future<void> setCompanyId(String id) async {
    _cachedCompanyId = id;
    await _writeSafe(_companyIdKey, id);
  }

  Future<String?> get companyName => _readSafe(_companyNameKey);
  Future<void> setCompanyName(String name) => _writeSafe(_companyNameKey, name);

  Future<String?> get companyLogo => _readSafe(_companyLogoKey);
  Future<void> setCompanyLogo(String logo) => _writeSafe(_companyLogoKey, logo);

  // User
  Future<String?> get userId => _readSafe(_userIdKey);
  Future<void> setUserId(String id) => _writeSafe(_userIdKey, id);

  Future<String?> get employeeId => _readSafe(_employeeIdKey);
  Future<void> setEmployeeId(String id) => _writeSafe(_employeeIdKey, id);

  Future<String?> get userName => _readSafe(_userNameKey);
  Future<void> setUserName(String name) => _writeSafe(_userNameKey, name);

  Future<String?> get userEmail => _readSafe(_userEmailKey);
  Future<void> setUserEmail(String email) => _writeSafe(_userEmailKey, email);

  Future<String?> get userEmailVerifiedAt => _readSafe(_userEmailVerifiedAtKey);
  Future<void> setUserEmailVerifiedAt(String date) => _writeSafe(_userEmailVerifiedAtKey, date);

  Future<List<String>> get roles async {
    final raw = await _readSafe(_rolesKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }
  Future<void> setRoles(List<String> roles) =>
      _writeSafe(_rolesKey, roles.join(','));

  // Preferences
  Future<String?> get themeMode => _readSafe(_themeModeKey);
  Future<void> setThemeMode(String mode) => _writeSafe(_themeModeKey, mode);

  Future<String?> get locale => _readSafe(_localeKey);
  Future<void> setLocale(String locale) => _writeSafe(_localeKey, locale);

  // Clear all stored data (on logout)
  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedCompanyId = null;
    _memoryFallback.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<void> clearAuth() async {
    _cachedToken = null;
    _memoryFallback.remove(_tokenKey);
    _memoryFallback.remove(_refreshTokenKey);
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } catch (_) {}
  }
}