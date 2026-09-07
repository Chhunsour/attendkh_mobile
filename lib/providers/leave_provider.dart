import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/utils/logger/app_logger.dart';
import 'package:attendkh/services/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository();
});

final leaveBalancesProvider = FutureProvider.autoDispose<List<LeaveBalance>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  final balances = await repo.getMyBalances();
  AppLogger.i('Leave balances loaded: ${balances.length} types');
  return balances;
});

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveType>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getLeaveTypes();
});

final leaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequest>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getRequests();
});