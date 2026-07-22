import 'package:flutter_riverpod/flutter_riverpod.dart';
// For RoleData
import 'package:mpg_hr_mobile_app/services/super_admin_role_repository.dart';

final superAdminRoleRepositoryProvider = Provider((ref) => SuperAdminRoleRepository());

final superAdminRolesProvider = FutureProvider.autoDispose<SuperAdminRolesPayload>((ref) async {
  final repo = ref.read(superAdminRoleRepositoryProvider);
  return repo.getRoles();
});
