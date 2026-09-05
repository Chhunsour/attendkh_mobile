import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/providers/branch_switch_provider.dart';
import '../services/top_employee_repository.dart';

final topEmployeesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, month) async {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  final repository = ref.watch(topEmployeeRepositoryProvider);
  return repository.getTopEmployees(month, branchId: activeBranchId);
});
