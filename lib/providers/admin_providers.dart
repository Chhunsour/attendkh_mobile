import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';

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

// ── Employee Filter Model ────────────────────────────────────────────────────
class EmployeeFilters {
  final String search;
  final int? departmentId;
  final int? branchId;
  final String employmentStatus;
  final String employmentType;

  const EmployeeFilters({
    this.search = '',
    this.departmentId,
    this.branchId,
    this.employmentStatus = '',
    this.employmentType = '',
  });

  EmployeeFilters copyWith({
    String? search,
    Object? departmentId = _sentinel,
    Object? branchId = _sentinel,
    String? employmentStatus,
    String? employmentType,
  }) {
    return EmployeeFilters(
      search: search ?? this.search,
      departmentId: departmentId == _sentinel ? this.departmentId : departmentId as int?,
      branchId: branchId == _sentinel ? this.branchId : branchId as int?,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      employmentType: employmentType ?? this.employmentType,
    );
  }

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      departmentId != null ||
      branchId != null ||
      employmentStatus.isNotEmpty ||
      employmentType.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeFilters &&
          search == other.search &&
          departmentId == other.departmentId &&
          branchId == other.branchId &&
          employmentStatus == other.employmentStatus &&
          employmentType == other.employmentType;

  @override
  int get hashCode => Object.hash(search, departmentId, branchId, employmentStatus, employmentType);
}

const _sentinel = Object();

/// Simple provider that fetches all employees without filters (used by dropdowns, e.g. manager picker).
final allEmployeesProvider = FutureProvider.autoDispose<List<EmployeeData>>((ref) {
  return ref.watch(hrRepositoryProvider).getEmployees();
});

/// Family provider used by AdminEmployeesScreen (supports search + filters).
final adminEmployeesProvider = FutureProvider.autoDispose.family<List<EmployeeData>, EmployeeFilters>((ref, filters) {
  return ref.watch(hrRepositoryProvider).getEmployees(
    search: filters.search.isEmpty ? null : filters.search,
    departmentId: filters.departmentId,
    branchId: filters.branchId,
    employmentStatus: filters.employmentStatus.isEmpty ? null : filters.employmentStatus,
    employmentType: filters.employmentType.isEmpty ? null : filters.employmentType,
  );
});

final rolesProvider = FutureProvider.autoDispose<List<RoleData>>((ref) {
  return ref.watch(hrRepositoryProvider).getRoles();
});

// ── Admin Operations Providers ──────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardKpiData>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getDashboardStats();
});


final allAttendanceLogsProvider = FutureProvider.autoDispose<List<AdminAttendanceRecord>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getAllAttendanceLogs();
});

final attendanceCorrectionsProvider = FutureProvider.autoDispose<List<AttendanceCorrectionData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getAttendanceCorrections();
});

final allLeaveRequestsProvider = FutureProvider.autoDispose<List<AdminLeaveRequestData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getAllLeaveRequests();
});

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveTypeData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getLeaveTypes();
});

final leaveBalancesProvider = FutureProvider.autoDispose<List<LeaveBalanceData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getLeaveBalances();
});

final shiftsProvider = FutureProvider.autoDispose<List<ShiftData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getShifts();
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

final jobCandidatesProvider = FutureProvider.family.autoDispose<List<CandidateData>, int>((ref, jobId) {
  return ref.watch(adminOpsRepositoryProvider).getCandidates(jobId);
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

final payrollSettingsProvider = FutureProvider.autoDispose<PayrollSettingsData>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getPayrollSettings();
});

final employeeDetailProvider = FutureProvider.autoDispose.family<EmployeeData, int>((ref, id) {
  return ref.watch(hrRepositoryProvider).getEmployee(id);
});

// ── Org Chart Provider ──────────────────────────────────────────────────────
final orgChartProvider = FutureProvider.autoDispose<List<OrgNode>>((ref) {
  return ref.watch(hrRepositoryProvider).getOrgChart();
});
