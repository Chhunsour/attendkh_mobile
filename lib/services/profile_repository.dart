import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class ProfileData {
  final int id;
  final String name;
  final String? email;
  final int companyId;
  final List<String> roles;
  final String? companyName;
  final int? branchId;
  final String? branchName;
  final double? branchLat;
  final double? branchLng;
  final int? branchRadius;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? photoUrl;
  final String? department;
  final String? jobTitle;

  const ProfileData({
    required this.id,
    required this.name,
    this.email,
    required this.companyId,
    this.companyName,
    this.branchId,
    this.branchName,
    this.branchLat,
    this.branchLng,
    this.branchRadius,
    required this.roles,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.photoUrl,
    this.department,
    this.jobTitle,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json; // handle nested or flat
    if (!user.containsKey('id')) {
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
      branchId: user['branch_id'] as int?,
      branchName: user['branch_name'] as String?,
      branchLat: user['branch_lat'] != null ? double.tryParse(user['branch_lat'].toString()) : null,
      branchLng: user['branch_lng'] != null ? double.tryParse(user['branch_lng'].toString()) : null,
      branchRadius: user['branch_radius'] as int?,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      phone: user['phone'] as String?,
      gender: user['gender'] as String?,
      dateOfBirth: user['date_of_birth'] as String?,
      address: user['address'] as String?,
      photoUrl: user['photo_url'] as String?,
      department: user['department'] as String?,
      jobTitle: user['job_title'] as String?,
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
        final data = raw['data'] ?? raw;
        return ProfileData.fromJson(data);
      }
      AppLogger.w('Profile API returned unexpected format: ${raw.runtimeType}');
      return const ProfileData(id: 0, name: 'Unknown', companyId: 0, roles: []);
    } catch (e) {
      AppLogger.e('Failed to load profile', e);
      rethrow;
    }
  }

  Future<ProfileData> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? address,
    File? photo,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'address': address,
      };

      if (photo != null) {
        data['photo'] = await MultipartFile.fromFile(photo.path);
      }

      final formData = FormData.fromMap(data);

      final response = await _api.post('/company/profile', data: formData);
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final resData = raw['data'] ?? raw;
        return ProfileData.fromJson(resData);
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
