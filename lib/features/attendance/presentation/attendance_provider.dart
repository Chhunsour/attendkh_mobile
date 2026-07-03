import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/features/attendance/data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final todayAttendanceProvider = FutureProvider.autoDispose<TodayAttendance?>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final today = await repo.getToday();
  AppLogger.i('Today attendance: ${today?.status ?? "no record"}');
  return today;
});

final attendanceSummaryProvider = FutureProvider.autoDispose.family<AttendanceSummary, String?>((ref, month) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getSummary(month: month);
});

final attendanceHistoryProvider = FutureProvider.autoDispose.family<List<TodayAttendance>, String?>((ref, month) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getHistory(month: month);
});
