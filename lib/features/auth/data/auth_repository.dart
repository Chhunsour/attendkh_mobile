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
    return LoginResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      userId: user['id'] as int,
      userName: user['name'] as String,
      userEmail: user['email'] as String?,
      companyId: user['company_id'] as int,
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
    return CurrentUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      companyId: json['company_id'] as int,
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
}