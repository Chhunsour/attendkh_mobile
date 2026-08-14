import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class ProfileData {
  final int id;
  final String name;
  final String? fullName;
  final String? khmerName;
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

  // New Fields
  final String? employeeId;
  final String? nationalId;
  final String? maritalStatus;
  final String? employmentType;
  final String? employmentStatus;
  final String? hireDate;
  final String? probationEndDate;
  final String? team;
  final String? manager;
  final num? salary;
  final String? bankName;
  final String? bankAccount;
  final Map<String, dynamic>? emergencyContact;

  const ProfileData({
    required this.id,
    required this.name,
    this.fullName,
    this.khmerName,
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
    this.employeeId,
    this.nationalId,
    this.maritalStatus,
    this.employmentType,
    this.employmentStatus,
    this.hireDate,
    this.probationEndDate,
    this.team,
    this.manager,
    this.salary,
    this.bankName,
    this.bankAccount,
    this.emergencyContact,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final user =
        json['user'] as Map<String, dynamic>? ?? json; // handle nested or flat
    if (!user.containsKey('id')) {
      return ProfileData(id: 0, name: 'Unknown', companyId: 0, roles: []);
    }
    final company = json['company'] as Map<String, dynamic>?;
    final companyIdRaw = user['company_id'];
    return ProfileData(
      id: user['id'] as int? ?? 0,
      name: user['name'] as String? ?? '',
      fullName: user['full_name'] as String? ?? user['name'] as String?,
      khmerName: user['khmer_name'] as String?,
      email: user['email'] as String?,
      companyId: companyIdRaw is int ? companyIdRaw : 0,
      companyName: company?['name'] as String?,
      branchId: user['branch_id'] as int?,
      branchName: user['branch_name'] as String?,
      branchLat: user['branch_lat'] != null
          ? double.tryParse(user['branch_lat'].toString())
          : null,
      branchLng: user['branch_lng'] != null
          ? double.tryParse(user['branch_lng'].toString())
          : null,
      branchRadius: user['branch_radius'] as int?,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      phone: user['phone'] as String?,
      gender: user['gender'] as String?,
      dateOfBirth: user['date_of_birth'] as String?,
      address: user['address'] as String?,
      photoUrl: user['photo_url'] as String?,
      department: user['department'] as String?,
      jobTitle: user['job_title'] as String?,
      employeeId: user['employee_id'] as String?,
      nationalId: user['national_id'] as String?,
      maritalStatus: user['marital_status'] as String?,
      employmentType: user['employment_type'] as String?,
      employmentStatus: user['employment_status'] as String?,
      hireDate: user['hire_date'] as String?,
      probationEndDate: user['probation_end_date'] as String?,
      team: user['team'] as String?,
      manager: user['manager'] as String?,
      salary: user['salary'] != null
          ? num.tryParse(user['salary'].toString())
          : null,
      bankName: user['bank_name'] as String?,
      bankAccount: user['bank_account'] as String?,
      emergencyContact: user['emergency_contact'] is Map
          ? Map<String, dynamic>.from(user['emergency_contact'])
          : (user['emergency_contact'] is String
                ? (const {})
                : null),
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
    String? fullName,
    String? khmerName,
    String? email,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? maritalStatus,
    String? bankName,
    String? bankAccount,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    File? photo,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'full_name': fullName,
        'khmer_name': khmerName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'address': address,
        'marital_status': ?maritalStatus,
        'bank_name': ?bankName,
        'bank_account': ?bankAccount,
        'emergency_contact_name': ?emergencyContactName,
        'emergency_contact_relationship': ?emergencyContactRelationship,
        'emergency_contact_phone': ?emergencyContactPhone,
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

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _api.put(
        '/profile/password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } catch (e) {
      AppLogger.e('Failed to update password', e);
      rethrow;
    }
  }
}
