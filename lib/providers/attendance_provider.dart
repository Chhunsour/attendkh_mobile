import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/models/monthly_attendance_model.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final todayAttendanceProvider = FutureProvider<TodayAttendance?>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final today = await repo.getToday();
  AppLogger.i('Today attendance: ${today?.status ?? "no record"}');
  return today;
});

final attendanceSummaryProvider =
    FutureProvider.autoDispose.family<AttendanceSummary, String?>((ref, month) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getSummary(month: month);
});

final attendanceHistoryProvider =
    FutureProvider.autoDispose.family<List<TodayAttendance>, String?>((ref, month) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getHistory(month: month);
});

class CompanyMonthlyAttendanceQuery {
  final String? month;
  final int? departmentId;
  final int? branchId;

  const CompanyMonthlyAttendanceQuery({
    this.month,
    this.departmentId,
    this.branchId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyMonthlyAttendanceQuery &&
          month == other.month &&
          departmentId == other.departmentId &&
          branchId == other.branchId;

  @override
  int get hashCode => Object.hash(month, departmentId, branchId);
}

final companyMonthlyAttendanceProvider = FutureProvider.autoDispose
    .family<CompanyMonthlyAttendanceData, CompanyMonthlyAttendanceQuery>(
        (ref, query) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getCompanyMonthlyAttendance(
    month: query.month,
    departmentId: query.departmentId,
    branchId: query.branchId,
  );
});
