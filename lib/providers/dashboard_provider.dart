import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/utils/logger/app_logger.dart';
import 'package:attendkh/services/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final data = await repo.getDashboard();
  AppLogger.i('Dashboard loaded — ${data.kpis.totalEmployees} employees');
  return data;
});

final employeeDashboardSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final data = await repo.getEmployeeDashboardSummary();
  return data;
});