import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

class EmployeeData {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? department;
  final String? position;
  final String employeeId;
  final String status;

  const EmployeeData({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.department,
    this.position,
    required this.employeeId,
    required this.status,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      department: json['department']?['name'] as String?,
      position: json['position']?['name'] as String?,
      employeeId: json['employee_id'] as String? ?? '',
      status: json['employment_status'] as String? ?? 'active',
    );
  }
}

class DirectoryRepository {
  final ApiRepository _api;
  DirectoryRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<EmployeeData>> getEmployees({int page = 1}) async {
    final response = await _api.get('/company/employees', queryParameters: {'page': page});
    final data = response.data;
    if (data is List) return data.map((e) => EmployeeData.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => EmployeeData.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}