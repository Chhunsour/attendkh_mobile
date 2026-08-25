import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart'; // For RoleData

class SuperAdminRolesPayload {
  final List<RoleData> roles;
  final List<String> allPermissions;

  SuperAdminRolesPayload(this.roles, this.allPermissions);
}

class SuperAdminRoleRepository {
  final ApiRepository _api;
  SuperAdminRoleRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<SuperAdminRolesPayload> getRoles() async {
    final response = await _api.get('/admin/roles');
    
    final mapData = response.data as Map<String, dynamic>;
    final data = (mapData['data']?['roles'] ?? mapData['roles']) as List<dynamic>? ?? [];
    final permData = (mapData['data']?['permissions'] ?? mapData['permissions']) as List<dynamic>? ?? [];
    
    final roles = data.map((json) => RoleData.fromJson(json as Map<String, dynamic>)).toList();
    final allPermissions = permData.map((e) => (e['name'] as String?) ?? '').where((s) => s.isNotEmpty).toList();

    return SuperAdminRolesPayload(roles, allPermissions);
  }

  Future<RoleData> createRole(String name, List<String> permissions) async {
    final response = await _api.post('/admin/roles', data: {'name': name, 'permissions': permissions});
    final map = response.data as Map<String, dynamic>;
    final roleJson = (map['data'] is Map<String, dynamic>) ? map['data'] as Map<String, dynamic> : map;
    return RoleData.fromJson(roleJson);
  }

  Future<RoleData> updateRole(int id, String name, List<String> permissions) async {
    final response = await _api.put('/admin/roles/$id', data: {'name': name, 'permissions': permissions});
    final map = response.data as Map<String, dynamic>;
    final roleJson = (map['data'] is Map<String, dynamic>) ? map['data'] as Map<String, dynamic> : map;
    return RoleData.fromJson(roleJson);
  }

  Future<void> deleteRole(int id) async {
    await _api.delete('/admin/roles/$id');
  }
}
