import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

# Add Data Classes at the end of the classes section (before AdminOperationsRepository class)
new_classes = """

class BranchData {
  final int id;
  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final String? email;
  final int? managerId;
  final String? managerName;
  final bool isActive;

  const BranchData({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.email,
    this.managerId,
    this.managerName,
    this.isActive = true,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      managerId: int.tryParse(json['manager_id']?.toString() ?? ''),
      managerName: json['manager']?['name'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class DepartmentData {
  final int id;
  final String name;
  final String? code;
  final int? branchId;
  final String? branchName;
  final int? managerId;
  final String? managerName;
  final bool isActive;

  const DepartmentData({
    required this.id,
    required this.name,
    this.code,
    this.branchId,
    this.branchName,
    this.managerId,
    this.managerName,
    this.isActive = true,
  });

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      branchId: int.tryParse(json['branch_id']?.toString() ?? ''),
      branchName: json['branch']?['name'] as String?,
      managerId: int.tryParse(json['manager_id']?.toString() ?? ''),
      managerName: json['manager']?['name'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class PositionData {
  final int id;
  final String name;
  final String? code;
  final int? departmentId;
  final String? departmentName;
  final String? level;
  final bool isActive;

  const PositionData({
    required this.id,
    required this.name,
    this.code,
    this.departmentId,
    this.departmentName,
    this.level,
    this.isActive = true,
  });

  factory PositionData.fromJson(Map<String, dynamic> json) {
    return PositionData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      departmentId: int.tryParse(json['department_id']?.toString() ?? ''),
      departmentName: json['department']?['name'] as String?,
      level: json['level'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class TeamData {
  final int id;
  final String name;
  final String? description;
  final int? departmentId;
  final String? departmentName;
  final int? leaderId;
  final String? leaderName;
  final bool isActive;

  const TeamData({
    required this.id,
    required this.name,
    this.description,
    this.departmentId,
    this.departmentName,
    this.leaderId,
    this.leaderName,
    this.isActive = true,
  });

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      departmentId: int.tryParse(json['department_id']?.toString() ?? ''),
      departmentName: json['department']?['name'] as String?,
      leaderId: int.tryParse(json['leader_id']?.toString() ?? ''),
      leaderName: json['leader']?['name'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class AdminOperationsRepository {"""

content = content.replace("class AdminOperationsRepository {", new_classes)

# Add endpoints inside the repository
new_endpoints = """
  // ── Core Organization Structure ───────────────────────────────────────────
  Future<List<BranchData>> getAllBranches() async {
    final response = await _api.get('/company/branches');
    return _parseList(response.data, BranchData.fromJson);
  }
  Future<void> createBranch(Map<String, dynamic> data) async => _api.post('/company/branches', data: data);
  Future<void> updateBranch(int id, Map<String, dynamic> data) async => _api.put('/company/branches/$id', data: data);
  Future<void> deleteBranch(int id) async => _api.delete('/company/branches/$id');

  Future<List<DepartmentData>> getAllDepartments() async {
    final response = await _api.get('/company/departments');
    return _parseList(response.data, DepartmentData.fromJson);
  }
  Future<void> createDepartment(Map<String, dynamic> data) async => _api.post('/company/departments', data: data);
  Future<void> updateDepartment(int id, Map<String, dynamic> data) async => _api.put('/company/departments/$id', data: data);
  Future<void> deleteDepartment(int id) async => _api.delete('/company/departments/$id');

  Future<List<PositionData>> getAllPositions() async {
    final response = await _api.get('/company/positions');
    return _parseList(response.data, PositionData.fromJson);
  }
  Future<void> createPosition(Map<String, dynamic> data) async => _api.post('/company/positions', data: data);
  Future<void> updatePosition(int id, Map<String, dynamic> data) async => _api.put('/company/positions/$id', data: data);
  Future<void> deletePosition(int id) async => _api.delete('/company/positions/$id');

  Future<List<TeamData>> getAllTeams() async {
    final response = await _api.get('/company/teams');
    return _parseList(response.data, TeamData.fromJson);
  }
  Future<void> createTeam(Map<String, dynamic> data) async => _api.post('/company/teams', data: data);
  Future<void> updateTeam(int id, Map<String, dynamic> data) async => _api.put('/company/teams/$id', data: data);
  Future<void> deleteTeam(int id) async => _api.delete('/company/teams/$id');

  // ── Employees (Admin)"""

content = content.replace("  // ── Employees (Admin)", new_endpoints)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(content)

