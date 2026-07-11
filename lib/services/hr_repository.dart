import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';

// ── Branch ──────────────────────────────────────────────────────────────────
class BranchData {
  final int id;
  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final String? email;
  final String? managerName;
  final int? managerId;
  final bool? isActive;
  final int? employeesCount;
  final double? latitude;
  final double? longitude;
  final int? allowedRadiusMeters;

  const BranchData({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.email,
    this.managerName,
    this.managerId,
    this.isActive,
    this.employeesCount,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      managerName: json['manager']?['name'] as String?,
      managerId: json['manager_id'] as int?,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] == 1 || json['is_active'] == '1'),
      employeesCount: json['employees_count'] as int?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      allowedRadiusMeters: json['allowed_radius_meters'] as int?,
    );
  }
}

// ── Department ──────────────────────────────────────────────────────────────
class DepartmentData {
  final int id;
  final String name;
  final String? code;
  final int? branchId;
  final String? branchName;
  final int? parentId;
  final String? parentName;
  final int? managerId;
  final String? managerName;
  final bool? isActive;
  final int? employeesCount;

  const DepartmentData({
    required this.id,
    required this.name,
    this.code,
    this.branchId,
    this.branchName,
    this.parentId,
    this.parentName,
    this.managerId,
    this.managerName,
    this.isActive,
    this.employeesCount,
  });

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch']?['name'] as String?,
      parentId: json['parent_id'] as int?,
      parentName: json['parent']?['name'] as String?,
      managerId: json['manager_id'] as int?,
      managerName: json['manager']?['name'] as String?,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] == 1 || json['is_active'] == '1'),
      employeesCount: json['employees_count'] as int?,
    );
  }
}

// ── Position ────────────────────────────────────────────────────────────────
class PositionData {
  final int id;
  final String name;
  final String? code;
  final String? level;
  final int? departmentId;
  final String? departmentName;
  final bool? isActive;
  final int? employeesCount;

  const PositionData({
    required this.id,
    required this.name,
    this.code,
    this.level,
    this.departmentId,
    this.departmentName,
    this.isActive,
    this.employeesCount,
  });

  factory PositionData.fromJson(Map<String, dynamic> json) {
    return PositionData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      level: json['level'] as String?,
      departmentId: json['department_id'] as int?,
      departmentName: json['department']?['name'] as String?,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] == 1 || json['is_active'] == '1'),
      employeesCount: json['employees_count'] as int?,
    );
  }
}

// ── Team ────────────────────────────────────────────────────────────────────
class TeamData {
  final int id;
  final String name;
  final String? description;
  final int? departmentId;
  final String? departmentName;
  final int? leaderId;
  final String? leaderName;
  final bool? isActive;
  final int? employeesCount;

  const TeamData({
    required this.id,
    required this.name,
    this.description,
    this.departmentId,
    this.departmentName,
    this.leaderId,
    this.leaderName,
    this.isActive,
    this.employeesCount,
  });

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      departmentId: json['department_id'] as int?,
      departmentName: json['department']?['name'] as String?,
      leaderId: json['leader_id'] as int?,
      leaderName: (json['leader'] != null)
          ? '${json['leader']['first_name'] ?? ''} ${json['leader']['last_name'] ?? ''}'.trim()
          : null,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] == 1 || json['is_active'] == '1'),
      employeesCount: json['employees_count'] as int? ?? json['members_count'] as int?,
    );
  }
}

// ── Employee ────────────────────────────────────────────────────────────────
class EmployeeData {
  final int id;
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String name;
  final String? email;
  final String? employeeId;
  final String? department;
  final String? position;
  final String? branch;
  final String? phone;
  final String? status;
  final String? employmentType;
  final String? employmentStatus;
  final String? joinDate;
  final String? avatar;
  final double? salary;
  final int? departmentId;
  final int? positionId;
  final int? branchId;
  final String? gender;
  final String? dateOfBirth;
  final String? maritalStatus;
  final String? nationalId;
  final String? address;
  final String? bankName;
  final String? bankAccount;
  final String? notes;
  final Map<String, dynamic>? emergencyContact;
  final List<LeaveBalanceData>? leaveBalances;
  final List<AdminLeaveRequestData>? recentLeaveRequests;
  final List<AdminAttendanceRecord>? recentAttendances;

  const EmployeeData({
    required this.id,
    this.userId,
    required this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.employeeId,
    this.department,
    this.position,
    this.branch,
    this.phone,
    this.status,
    this.employmentType,
    this.employmentStatus,
    this.joinDate,
    this.avatar,
    this.salary,
    this.departmentId,
    this.positionId,
    this.branchId,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.nationalId,
    this.address,
    this.bankName,
    this.bankAccount,
    this.notes,
    this.emergencyContact,
    this.leaveBalances,
    this.recentLeaveRequests,
    this.recentAttendances,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      name: json['name'] as String? ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      email: json['email'] as String?,
      employeeId: json['employee_id'] as String?,
      department: json['department']?['name'] as String? ?? json['department'] as String?,
      position: json['position']?['name'] as String? ?? json['position'] as String?,
      branch: json['branch']?['name'] as String? ?? json['branch'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      employmentType: json['employment_type'] as String?,
      employmentStatus: json['employment_status'] as String?,
      joinDate: json['hire_date'] as String? ?? json['join_date'] as String?,
      avatar: json['avatar'] as String? ?? json['photo'] as String?,
      salary: (json['salary'] as num?)?.toDouble(),
      departmentId: json['department_id'] as int?,
      positionId: json['position_id'] as int?,
      branchId: json['branch_id'] as int?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      maritalStatus: json['marital_status'] as String?,
      nationalId: json['national_id'] as String?,
      address: json['address'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccount: json['bank_account'] as String?,
      notes: json['notes'] as String?,
      emergencyContact: json['emergency_contact'] is Map
          ? Map<String, dynamic>.from(json['emergency_contact'] as Map)
          : null,
      leaveBalances: json['leave_balances'] == null
          ? null
          : (json['leave_balances'] as List)
              .map((e) => LeaveBalanceData.fromJson(e as Map<String, dynamic>))
              .toList(),
      recentLeaveRequests: json['recent_leave_requests'] == null
          ? null
          : (json['recent_leave_requests'] as List)
              .map((e) => AdminLeaveRequestData.fromJson(e as Map<String, dynamic>))
              .toList(),
      recentAttendances: json['recent_attendances'] == null
          ? null
          : (json['recent_attendances'] as List)
              .map((e) => AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

// ── Role ────────────────────────────────────────────────────────────────────
class RoleData {
  final int id;
  final String name;
  final String? guardName;
  final int? permissionsCount;
  final List<String>? permissions;

  const RoleData({required this.id, required this.name, this.guardName, this.permissionsCount, this.permissions});

  factory RoleData.fromJson(Map<String, dynamic> json) {
    return RoleData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      guardName: json['guard_name'] as String?,
      permissionsCount: json['permissions_count'] as int?,
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

// ── Org Node (Org Chart) ────────────────────────────────────────────────────
class OrgNode {
  final int id;
  final String firstName;
  final String lastName;
  final String? photo;
  final String employmentStatus;
  final String? email;
  final String? phone;
  final String? positionName;
  final String? departmentName;
  final List<OrgNode>? subordinates;

  const OrgNode({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photo,
    this.employmentStatus = 'active',
    this.email,
    this.phone,
    this.positionName,
    this.departmentName,
    this.subordinates,
  });

  String get name => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  int get subordinatesCount => subordinates?.length ?? 0;
  bool get hasSubordinates => subordinates != null && subordinates!.isNotEmpty;

  factory OrgNode.fromJson(Map<String, dynamic> json) {
    return OrgNode(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      photo: json['photo'] as String?,
      employmentStatus: json['employment_status'] as String? ?? 'active',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      positionName: json['position']?['name'] as String?,
      departmentName: json['department']?['name'] as String?,
      subordinates: json['subordinates'] != null
          ? (json['subordinates'] as List)
              .map((e) => OrgNode.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

// ── HR Repository ───────────────────────────────────────────────────────────
class HrRepository {
  final ApiRepository _api;
  HrRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  // ── Branches ────────────────────────────────────────────────────────────
  Future<List<BranchData>> getBranches() async {
    final response = await _api.get('/company/branches');
    return _parseList(response.data, BranchData.fromJson);
  }

  Future<BranchData> createBranch({
    required String name,
    String? code,
    String? address,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    int? allowedRadiusMeters,
    int? managerId,
    bool? isActive,
  }) async {
    final response = await _api.post('/company/branches', data: {
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'allowed_radius_meters': allowedRadiusMeters,
      'manager_id': managerId,
      'is_active': isActive ?? true,
    });
    return BranchData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateBranch(int id, {
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    int? allowedRadiusMeters,
    int? managerId,
    bool? isActive,
  }) async {
    await _api.put('/company/branches/$id', data: {
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'allowed_radius_meters': allowedRadiusMeters,
      'manager_id': managerId,
      'is_active': isActive,
    });
  }

  Future<void> deleteBranch(int id) async => _api.delete('/company/branches/$id');

  // ── Departments ─────────────────────────────────────────────────────────
  Future<List<DepartmentData>> getDepartments() async {
    final response = await _api.get('/company/departments');
    return _parseList(response.data, DepartmentData.fromJson);
  }

  Future<DepartmentData> createDepartment({
    required String name,
    String? code,
    int? branchId,
    int? parentId,
    int? managerId,
    bool? isActive,
  }) async {
    final response = await _api.post('/company/departments', data: {
      'name': name,
      'code': code,
      'branch_id': branchId,
      'parent_id': parentId,
      'manager_id': managerId,
      'is_active': isActive ?? true,
    });
    return DepartmentData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateDepartment(int id, {
    required String name,
    String? code,
    int? branchId,
    int? parentId,
    int? managerId,
    bool? isActive,
  }) async {
    await _api.put('/company/departments/$id', data: {
      'name': name,
      'code': code,
      'branch_id': branchId,
      'parent_id': parentId,
      'manager_id': managerId,
      'is_active': isActive,
    });
  }

  Future<void> deleteDepartment(int id) async => _api.delete('/company/departments/$id');

  // ── Positions ───────────────────────────────────────────────────────────
  Future<List<PositionData>> getPositions() async {
    final response = await _api.get('/company/positions');
    return _parseList(response.data, PositionData.fromJson);
  }

  Future<PositionData> createPosition({
    required String name,
    String? code,
    int? departmentId,
    String? level,
    bool? isActive,
  }) async {
    final response = await _api.post('/company/positions', data: {
      'name': name,
      'code': code,
      'department_id': departmentId,
      'level': level,
      'is_active': isActive ?? true,
    });
    return PositionData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updatePosition(int id, {
    required String name,
    String? code,
    int? departmentId,
    String? level,
    bool? isActive,
  }) async {
    await _api.put('/company/positions/$id', data: {
      'name': name,
      'code': code,
      'department_id': departmentId,
      'level': level,
      'is_active': isActive,
    });
  }

  Future<void> deletePosition(int id) async => _api.delete('/company/positions/$id');

  // ── Teams ───────────────────────────────────────────────────────────────
  Future<List<TeamData>> getTeams() async {
    final response = await _api.get('/company/teams');
    return _parseList(response.data, TeamData.fromJson);
  }

  Future<TeamData> createTeam({
    required String name,
    String? description,
    int? departmentId,
    int? leaderId,
    bool? isActive,
  }) async {
    final response = await _api.post('/company/teams', data: {
      'name': name,
      'description': description,
      'department_id': departmentId,
      'leader_id': leaderId,
      'is_active': isActive ?? true,
    });
    return TeamData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateTeam(int id, {
    required String name,
    String? description,
    int? departmentId,
    int? leaderId,
    bool? isActive,
  }) async {
    await _api.put('/company/teams/$id', data: {
      'name': name,
      'description': description,
      'department_id': departmentId,
      'leader_id': leaderId,
      'is_active': isActive,
    });
  }

  Future<void> deleteTeam(int id) async => _api.delete('/company/teams/$id');

  // ── Employees ───────────────────────────────────────────────────────────
  Future<List<EmployeeData>> getEmployees({
    String? search,
    int? departmentId,
    int? branchId,
    String? employmentStatus,
    String? employmentType,
  }) async {
    final response = await _api.get('/company/employees', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'department_id': ?departmentId,
      'branch_id': ?branchId,
      if (employmentStatus != null && employmentStatus.isNotEmpty) 'employment_status': employmentStatus,
      if (employmentType != null && employmentType.isNotEmpty) 'employment_type': employmentType,
    });
    return _parseList(response.data, EmployeeData.fromJson);
  }


  Future<EmployeeData> getEmployee(int id) async {
    final response = await _api.get('/company/employees/$id');
    final dataMap = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>;
    return EmployeeData.fromJson(dataMap);
  }

  Future<EmployeeData> createEmployee({
    required String firstName,
    required String lastName,
    required String employmentType,
    required String employmentStatus,
    required String hireDate,
    String? email,
    String? phone,
    double? salary,
    int? departmentId,
    int? positionId,
    int? branchId,
    int? teamId,
    int? managerId,
    String? gender,
    String? dateOfBirth,
    String? maritalStatus,
    String? nationalId,
    String? address,
    String? bankName,
    String? bankAccount,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? notes,
    String? probationEndDate,
    File? photo,
  }) async {
    final Map<String, dynamic> dataMap = {
      'first_name': firstName,
      'last_name': lastName,
      'employment_type': employmentType,
      'employment_status': employmentStatus,
      'hire_date': hireDate,
      'email': ?email,
      'phone': ?phone,
      'salary': ?salary,
      'department_id': ?departmentId,
      'position_id': ?positionId,
      'branch_id': ?branchId,
      'team_id': ?teamId,
      'manager_id': ?managerId,
      'gender': ?gender,
      'date_of_birth': ?dateOfBirth,
      'marital_status': ?maritalStatus,
      'national_id': ?nationalId,
      'address': ?address,
      'bank_name': ?bankName,
      'bank_account': ?bankAccount,
      'emergency_contact_name': ?emergencyContactName,
      'emergency_contact_relationship': ?emergencyContactRelationship,
      'emergency_contact_phone': ?emergencyContactPhone,
      'notes': ?notes,
      'probation_end_date': ?probationEndDate,
    };

    if (photo != null) {
      dataMap['photo'] = await MultipartFile.fromFile(photo.path);
    }

    final formData = FormData.fromMap(dataMap);

    final response = await _api.post('/company/employees', data: formData);
    final raw = response.data as Map<String, dynamic>;
    final payload = raw['data'] as Map<String, dynamic>? ?? raw;
    return EmployeeData.fromJson(payload);
  }

  Future<EmployeeData> updateEmployee(int id, {
    String? firstName,
    String? lastName,
    String? employmentType,
    String? employmentStatus,
    String? hireDate,
    String? email,
    String? phone,
    double? salary,
    int? departmentId,
    int? positionId,
    int? branchId,
    int? teamId,
    int? managerId,
    String? gender,
    String? dateOfBirth,
    String? maritalStatus,
    String? nationalId,
    String? address,
    String? bankName,
    String? bankAccount,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? notes,
    String? probationEndDate,
    File? photo,
  }) async {
    final Map<String, dynamic> dataMap = {
      '_method': 'PUT', // Spoofing PUT for Laravel when sending FormData
      'first_name': ?firstName,
      'last_name': ?lastName,
      'employment_type': ?employmentType,
      'employment_status': ?employmentStatus,
      'hire_date': ?hireDate,
      'email': ?email,
      'phone': ?phone,
      'salary': ?salary,
      'department_id': ?departmentId,
      'position_id': ?positionId,
      'branch_id': ?branchId,
      'team_id': ?teamId,
      'manager_id': ?managerId,
      'gender': ?gender,
      'date_of_birth': ?dateOfBirth,
      'marital_status': ?maritalStatus,
      'national_id': ?nationalId,
      'address': ?address,
      'bank_name': ?bankName,
      'bank_account': ?bankAccount,
      'emergency_contact_name': ?emergencyContactName,
      'emergency_contact_relationship': ?emergencyContactRelationship,
      'emergency_contact_phone': ?emergencyContactPhone,
      'notes': ?notes,
      'probation_end_date': ?probationEndDate,
    };

    if (photo != null) {
      dataMap['photo'] = await MultipartFile.fromFile(photo.path);
    }

    final formData = FormData.fromMap(dataMap);

    await _api.post('/company/employees/$id', data: formData);
    // The update endpoint returns null data — re-fetch the updated employee.
    return getEmployee(id);
  }

  Future<void> deleteEmployee(int id) async => _api.delete('/company/employees/$id');

  // ── Roles ───────────────────────────────────────────────────────────────
  Future<List<RoleData>> getRoles() async {
    final response = await _api.get('/company/roles');
    return _parseList(response.data, RoleData.fromJson);
  }

  Future<RoleData> createRole({required String name, List<String>? permissions}) async {
    final response = await _api.post('/company/roles', data: {
      'name': name,
      'permissions': ?permissions,
    });
    return RoleData.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Org Chart ───────────────────────────────────────────────────────────
  Future<List<OrgNode>> getOrgChart() async {
    final response = await _api.get('/company/org-chart');
    final data = response.data;
    if (data is List) {
      return data.map((e) => OrgNode.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List)
          .map((e) => OrgNode.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}