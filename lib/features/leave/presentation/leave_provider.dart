import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/features/leave/data/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository();
});

final leaveBalancesProvider = FutureProvider.autoDispose<List<LeaveBalance>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  final balances = await repo.getMyBalances();
  AppLogger.i('Leave balances loaded: ${balances.length} types');
  return balances;
});

final leaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequest>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getRequests();
});