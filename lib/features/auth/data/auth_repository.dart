import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

/// Raw API response for login
class LoginResult {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String userName;
  final String? userEmail;
  final int companyId;
  final String? companyName;
  final List<String> roles;

  const LoginResult({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.companyId,
    this.companyName,
    required this.roles,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final company = user['company'] as Map<String, dynamic>?;
    final companyIdRaw = user['company_id'];
    return LoginResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      userId: user['id'] as int,
      userName: user['name'] as String,
      userEmail: user['email'] as String?,
      companyId: companyIdRaw is int ? companyIdRaw : 0,
      companyName: company?['name'] as String?,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Raw API response for current user
class CurrentUser {
  final int id;
  final String name;
  final String? email;
  final int companyId;
  final List<String> roles;
  final String? companyName;

  const CurrentUser({
    required this.id,
    required this.name,
    this.email,
    required this.companyId,
    this.companyName,
    required this.roles,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>?;
    final companyIdRaw = json['company_id'];
    return CurrentUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      companyId: companyIdRaw is int ? companyIdRaw : 0,
      companyName: company?['name'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class AuthRepository {
  final ApiRepository _api;

  AuthRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// POST /api/v1/login
  Future<LoginResult> login({
    required String login,
    required String password,
    String? deviceName,
  }) async {
    final response = await _api.post(
      '/login',
      data: {
        'login': login,
        'password': password,
        'device_name': deviceName ?? 'mobile_app',
      },
    );

    if (response.data == null) {
      throw Exception('Login failed: no data returned');
    }

    return LoginResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/logout
  Future<void> logout() async {
    await _api.post('/logout');
  }

  /// GET /api/v1/user
  Future<CurrentUser> getCurrentUser() async {
    final response = await _api.get('/user');

    if (response.data == null) {
      throw Exception('Failed to load user data');
    }

    return CurrentUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/register
  Future<RegisterResult> registerCompany({
    required String userName,
    required String userPhone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String companyName,
    String? companySize,
    String? companyPhone,
  }) async {
    final response = await _api.post(
      '/register',
      data: {
        'user_name': userName,
        'user_phone': userPhone,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'company_name': companyName,
        'company_size': companySize,
        'company_phone': companyPhone,
      },
    );

    if (response.data == null) {
      throw Exception('Registration failed: no data returned');
    }

    return RegisterResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/forgot-password
  Future<void> forgotPassword(String email) async {
    await _api.post('/forgot-password', data: {'email': email});
  }

  /// POST /api/v1/reset-password
  Future<void> resetPassword({required String token, required String email, required String password, required String passwordConfirmation}) async {
    await _api.post('/reset-password', data: {
      'token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }
}

/// Raw API response for company registration
class RegisterResult {
  final int userId;
  final String userName;
  final String userEmail;
  final int companyId;
  final String companyName;
  final List<String> roles;
  final List<String> permissions;
  final String accessToken;

  const RegisterResult({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.companyId,
    required this.companyName,
    required this.roles,
    required this.permissions,
    required this.accessToken,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final company = json['company'] as Map<String, dynamic>;
    return RegisterResult(
      userId: user['id'] as int,
      userName: user['name'] as String,
      userEmail: user['email'] as String? ?? '',
      companyId: company['id'] as int,
      companyName: company['name'] as String,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      permissions:
          (user['permissions'] as List<dynamic>?)?.cast<String>() ?? [],
      accessToken: json['access_token'] as String,
    );
  }
}
