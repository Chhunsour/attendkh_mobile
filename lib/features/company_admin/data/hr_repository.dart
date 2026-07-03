import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

// ── Branch ──────────────────────────────────────────────────────────────────
class BranchData {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final int? employeesCount;

  const BranchData({required this.id, required this.name, this.address, this.phone, this.email, this.employeesCount});

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      employeesCount: json['employees_count'] as int?,
    );
  }
}

// ── Department ──────────────────────────────────────────────────────────────
class DepartmentData {
  final int id;
  final String name;
  final String? description;
  final String? headName;
  final int? employeesCount;

  const DepartmentData({required this.id, required this.name, this.description, this.headName, this.employeesCount});

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      headName: json['head']?['name'] as String? ?? json['department_head']?['name'] as String?,
      employeesCount: json['employees_count'] as int?,
    );
  }
}

// ── Position ────────────────────────────────────────────────────────────────
class PositionData {
  final int id;
  final String name;
  final String? description;
  final int? employeesCount;

  const PositionData({required this.id, required this.name, this.description, this.employeesCount});

  factory PositionData.fromJson(Map<String, dynamic> json) {
    return PositionData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      employeesCount: json['employees_count'] as int?,
    );
  }
}

// ── Team ────────────────────────────────────────────────────────────────────
class TeamData {
  final int id;
  final String name;
  final String? description;
  final String? leaderName;
  final int? membersCount;

  const TeamData({required this.id, required this.name, this.description, this.leaderName, this.membersCount});

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      leaderName: json['leader']?['name'] as String?,
      membersCount: json['members_count'] as int?,
    );
  }
}

// ── Employee ────────────────────────────────────────────────────────────────
class EmployeeData {
  final int id;
  final String name;
  final String? email;
  final String? employeeId;
  final String? department;
  final String? position;
  final String? branch;
  final String? phone;
  final String? status;
  final String? joinDate;
  final String? avatar;

  const EmployeeData({
    required this.id,
    required this.name,
    this.email,
    this.employeeId,
    this.department,
    this.position,
    this.branch,
    this.phone,
    this.status,
    this.joinDate,
    this.avatar,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      employeeId: json['employee_id'] as String?,
      department: json['department']?['name'] as String? ?? json['department'] as String?,
      position: json['position']?['name'] as String? ?? json['position'] as String?,
      branch: json['branch']?['name'] as String? ?? json['branch'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      joinDate: json['join_date'] as String? ?? json['hired_date'] as String?,
      avatar: json['avatar'] as String?,
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

// ── HR Repository ───────────────────────────────────────────────────────────
class HrRepository {
  final ApiRepository _api;
  HrRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  // ── Branches ────────────────────────────────────────────────────────────
  Future<List<BranchData>> getBranches() async {
    final response = await _api.get('/company/branches');
    return _parseList(response.data, BranchData.fromJson);
  }

  Future<BranchData> createBranch({required String name, String? address, String? phone, String? email}) async {
    final response = await _api.post('/company/branches', data: {'name': name, 'address': ?address, 'phone': ?phone, 'email': ?email});
    return BranchData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BranchData> updateBranch(int id, {required String name, String? address, String? phone, String? email}) async {
    final response = await _api.put('/company/branches/$id', data: {'name': name, 'address': ?address, 'phone': ?phone, 'email': ?email});
    return BranchData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBranch(int id) async => _api.delete('/company/branches/$id');

  // ── Departments ─────────────────────────────────────────────────────────
  Future<List<DepartmentData>> getDepartments() async {
    final response = await _api.get('/company/departments');
    return _parseList(response.data, DepartmentData.fromJson);
  }

  Future<DepartmentData> createDepartment({required String name, String? description, int? headId}) async {
    final response = await _api.post('/company/departments', data: {'name': name, 'description': ?description, 'department_head_id': ?headId});
    return DepartmentData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DepartmentData> updateDepartment(int id, {required String name, String? description, int? headId}) async {
    final response = await _api.put('/company/departments/$id', data: {'name': name, 'description': ?description, 'department_head_id': ?headId});
    return DepartmentData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDepartment(int id) async => _api.delete('/company/departments/$id');

  // ── Positions ───────────────────────────────────────────────────────────
  Future<List<PositionData>> getPositions() async {
    final response = await _api.get('/company/positions');
    return _parseList(response.data, PositionData.fromJson);
  }

  Future<PositionData> createPosition({required String name, String? description}) async {
    final response = await _api.post('/company/positions', data: {'name': name, 'description': ?description});
    return PositionData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PositionData> updatePosition(int id, {required String name, String? description}) async {
    final response = await _api.put('/company/positions/$id', data: {'name': name, 'description': ?description});
    return PositionData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePosition(int id) async => _api.delete('/company/positions/$id');

  // ── Teams ───────────────────────────────────────────────────────────────
  Future<List<TeamData>> getTeams() async {
    final response = await _api.get('/company/teams');
    return _parseList(response.data, TeamData.fromJson);
  }

  Future<TeamData> createTeam({required String name, String? description, int? leaderId}) async {
    final response = await _api.post('/company/teams', data: {'name': name, 'description': ?description, 'team_leader_id': ?leaderId});
    return TeamData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeamData> updateTeam(int id, {required String name, String? description, int? leaderId}) async {
    final response = await _api.put('/company/teams/$id', data: {'name': name, 'description': ?description, 'team_leader_id': ?leaderId});
    return TeamData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTeam(int id) async => _api.delete('/company/teams/$id');

  // ── Employees ───────────────────────────────────────────────────────────
  Future<List<EmployeeData>> getEmployees({String? search, int? departmentId, int? branchId}) async {
    final response = await _api.get('/company/employees', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'department_id': ?departmentId,
      'branch_id': ?branchId,
    });
    return _parseList(response.data, EmployeeData.fromJson);
  }

  Future<EmployeeData> getEmployee(int id) async {
    final response = await _api.get('/company/employees/$id');
    return EmployeeData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmployeeData> createEmployee({required String name, required String email, int? departmentId, int? positionId, int? branchId, int? teamId, String? phone, String? joinDate}) async {
    final response = await _api.post('/company/employees', data: {
      'name': name, 'email': email,
      'department_id': ?departmentId,
      'position_id': ?positionId,
      'branch_id': ?branchId,
      'team_id': ?teamId,
      'phone': ?phone,
      'join_date': ?joinDate,
    });
    return EmployeeData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmployeeData> updateEmployee(int id, {String? name, String? email, int? departmentId, int? positionId, int? branchId, int? teamId, String? phone}) async {
    final response = await _api.put('/company/employees/$id', data: {
      'name': ?name, 'email': ?email,
      'department_id': ?departmentId,
      'position_id': ?positionId,
      'branch_id': ?branchId,
      'team_id': ?teamId,
      'phone': ?phone,
    });
    return EmployeeData.fromJson(response.data as Map<String, dynamic>);
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

  // ── Helpers ─────────────────────────────────────────────────────────────
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}