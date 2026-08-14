import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/top_employee_repository.dart';

final topEmployeesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, month) async {
  final repository = ref.watch(topEmployeeRepositoryProvider);
  return repository.getTopEmployees(month);
});
