import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  late final FlutterSecureStorage _storage;

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
  static const _biometricEnabledKey = 'biometric_enabled';

  Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    try {
      _cachedToken = await _storage.read(key: _tokenKey);
      _cachedCompanyId = await _storage.read(key: _companyIdKey);
    } catch (e) {
      _cachedToken = null;
      _cachedCompanyId = null;
    }
  }

  /// Synchronous fast accessors for Dio network interceptors (0ms latency)
  String? get cachedAccessToken => _cachedToken;
  String? get cachedCompanyId => _cachedCompanyId;

  // Auth Tokens
  Future<String?> get accessToken async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<void> setAccessToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteAccessToken() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  Future<void> setRefreshToken(String token) => _storage.write(key: _refreshTokenKey, value: token);
  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshTokenKey);

  // Company
  Future<String?> get companyId async {
    _cachedCompanyId ??= await _storage.read(key: _companyIdKey);
    return _cachedCompanyId;
  }

  Future<void> setCompanyId(String id) async {
    _cachedCompanyId = id;
    await _storage.write(key: _companyIdKey, value: id);
  }

  Future<String?> get companyName => _storage.read(key: _companyNameKey);
  Future<void> setCompanyName(String name) => _storage.write(key: _companyNameKey, value: name);

  Future<String?> get companyLogo => _storage.read(key: _companyLogoKey);
  Future<void> setCompanyLogo(String logo) => _storage.write(key: _companyLogoKey, value: logo);

  // User
  Future<String?> get userId => _storage.read(key: _userIdKey);
  Future<void> setUserId(String id) => _storage.write(key: _userIdKey, value: id);

  Future<String?> get employeeId => _storage.read(key: _employeeIdKey);
  Future<void> setEmployeeId(String id) => _storage.write(key: _employeeIdKey, value: id);

  Future<String?> get userName => _storage.read(key: _userNameKey);
  Future<void> setUserName(String name) => _storage.write(key: _userNameKey, value: name);

  Future<String?> get userEmail => _storage.read(key: _userEmailKey);
  Future<void> setUserEmail(String email) => _storage.write(key: _userEmailKey, value: email);

  Future<String?> get userEmailVerifiedAt => _storage.read(key: _userEmailVerifiedAtKey);
  Future<void> setUserEmailVerifiedAt(String date) => _storage.write(key: _userEmailVerifiedAtKey, value: date);

  Future<List<String>> get roles async {
    final raw = await _storage.read(key: _rolesKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }
  Future<void> setRoles(List<String> roles) =>
      _storage.write(key: _rolesKey, value: roles.join(','));

  // Preferences
  Future<String?> get themeMode => _storage.read(key: _themeModeKey);
  Future<void> setThemeMode(String mode) => _storage.write(key: _themeModeKey, value: mode);

  Future<String?> get locale => _storage.read(key: _localeKey);
  Future<void> setLocale(String locale) => _storage.write(key: _localeKey, value: locale);

  Future<bool> get isBiometricEnabled async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  // Clear all stored data (on logout)
  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedCompanyId = null;
    await _storage.deleteAll();
  }

  Future<void> clearAuth() async {
    _cachedToken = null;
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}