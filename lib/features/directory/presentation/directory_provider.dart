import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/directory/data/directory_repository.dart';

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) => DirectoryRepository());
final employeesProvider = FutureProvider.autoDispose<List<EmployeeData>>((ref) async {
  return ref.watch(directoryRepositoryProvider).getEmployees();
});