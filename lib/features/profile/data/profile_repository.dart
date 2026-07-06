import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

class ProfileData {
  final int id;
  final String name;
  final String? email;
  final int companyId;
  final List<String> roles;
  final String? companyName;

  const ProfileData({
    required this.id,
    required this.name,
    this.email,
    required this.companyId,
    this.companyName,
    required this.roles,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    if (user == null) {
      return ProfileData(id: 0, name: 'Unknown', companyId: 0, roles: []);
    }
    final company = json['company'] as Map<String, dynamic>?;
    final companyIdRaw = user['company_id'];
    return ProfileData(
      id: user['id'] as int? ?? 0,
      name: user['name'] as String? ?? '',
      email: user['email'] as String?,
      companyId: companyIdRaw is int ? companyIdRaw : 0,
      companyName: company?['name'] as String?,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ProfileRepository {
  final ApiRepository _api;
  ProfileRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<ProfileData> getProfile() async {
    try {
      final response = await _api.get('/company/profile');
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return ProfileData.fromJson(raw);
      }
      AppLogger.w('Profile API returned unexpected format: ${raw.runtimeType}');
      return const ProfileData(id: 0, name: 'Unknown', companyId: 0, roles: []);
    } catch (e) {
      AppLogger.e('Failed to load profile', e);
      rethrow;
    }
  }

  Future<ProfileData> updateProfile({String? name, String? email}) async {
    try {
      final response = await _api.put('/profile', data: {
        'name': ?name,
        'email': ?email,
      });
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return ProfileData.fromJson(raw);
      }
      throw Exception('Invalid update profile response');
    } catch (e) {
      AppLogger.e('Failed to update profile', e);
      rethrow;
    }
  }

  Future<void> updatePassword({required String currentPassword, required String password, required String passwordConfirmation}) async {
    try {
      await _api.put('/profile/password', data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    } catch (e) {
      AppLogger.e('Failed to update password', e);
      rethrow;
    }
  }
}
