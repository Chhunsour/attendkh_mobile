import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/hr_repository.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';

// ── Repository Providers ────────────────────────────────────────────────────
final hrRepositoryProvider = Provider<HrRepository>((ref) => HrRepository());
final adminOpsRepositoryProvider = Provider<AdminOperationsRepository>((ref) => AdminOperationsRepository());

// ── HR Structure Providers ──────────────────────────────────────────────────
final branchesProvider = FutureProvider.autoDispose<List<BranchData>>((ref) {
  return ref.watch(hrRepositoryProvider).getBranches();
});

final departmentsProvider = FutureProvider.autoDispose<List<DepartmentData>>((ref) {
  return ref.watch(hrRepositoryProvider).getDepartments();
});

final positionsProvider = FutureProvider.autoDispose<List<PositionData>>((ref) {
  return ref.watch(hrRepositoryProvider).getPositions();
});

final teamsProvider = FutureProvider.autoDispose<List<TeamData>>((ref) {
  return ref.watch(hrRepositoryProvider).getTeams();
});

final employeesProvider = FutureProvider.autoDispose<List<EmployeeData>>((ref) {
  return ref.watch(hrRepositoryProvider).getEmployees();
});

final rolesProvider = FutureProvider.autoDispose<List<RoleData>>((ref) {
  return ref.watch(hrRepositoryProvider).getRoles();
});

// ── Admin Operations Providers ──────────────────────────────────────────────
final attendanceCorrectionsProvider = FutureProvider.autoDispose<List<AttendanceCorrectionData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getAttendanceCorrections();
});

final allLeaveRequestsProvider = FutureProvider.autoDispose<List<AdminLeaveRequestData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getAllLeaveRequests();
});

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveTypeData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getLeaveTypes();
});

final shiftsAdminProvider = FutureProvider.autoDispose<List<ShiftData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getShifts();
});

final holidaysAdminProvider = FutureProvider.autoDispose<List<HolidayData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getHolidays();
});

final assetsProvider = FutureProvider.autoDispose<List<AssetData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getAssets();
});

final jobPostingsProvider = FutureProvider.autoDispose<List<JobPostingData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getJobPostings();
});

final performanceReviewsProvider = FutureProvider.autoDispose<List<PerformanceReviewData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getReviews();
});

final trainingCoursesProvider = FutureProvider.autoDispose<List<TrainingCourseData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getTrainings();
});

final payrollRunsProvider = FutureProvider.autoDispose<List<PayrollRunData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getPayrollRuns();
});