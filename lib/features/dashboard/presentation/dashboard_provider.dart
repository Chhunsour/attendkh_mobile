import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/features/dashboard/data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final data = await repo.getDashboard();
  AppLogger.i('Dashboard loaded — ${data.kpis.presentToday} present today');
  return data;
});