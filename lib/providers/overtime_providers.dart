import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/overtime_request.dart';
import '../services/overtime_repository.dart';

final overtimeRequestsProvider = FutureProvider.autoDispose<List<OvertimeRequest>>((ref) async {
  final repository = ref.watch(overtimeRepositoryProvider);
  return repository.getOvertimeRequests();
});

final managerOvertimeRequestsProvider = FutureProvider.autoDispose<List<OvertimeRequest>>((ref) async {
  final repository = ref.watch(overtimeRepositoryProvider);
  return repository.getManagerOvertimeRequests();
});
