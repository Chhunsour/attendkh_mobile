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
    final user = json['user'] as Map<String, dynamic>;
    final company = json['company'] as Map<String, dynamic>?;
    return ProfileData(
      id: user['id'] as int,
      name: user['name'] as String,
      email: user['email'] as String?,
      companyId: user['company_id'] as int,
      companyName: company?['name'] as String?,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ProfileRepository {
  final ApiRepository _api;
  ProfileRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<ProfileData> getProfile() async {
    final response = await _api.get('/company/profile');
    return ProfileData.fromJson(response.data as Map<String, dynamic>);
  }
}