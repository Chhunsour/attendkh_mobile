import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/models/leave_summary_model.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/services/assets_repository.dart';
import 'package:mpg_hr_mobile_app/services/summary_repository.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';

// ── Repository Providers ────────────────────────────────────────────────────
final hrRepositoryProvider = Provider<HrRepository>((ref) => HrRepository());
final adminOpsRepositoryProvider = Provider<AdminOperationsRepository>((ref) => AdminOperationsRepository());
final recruitmentRepositoryProvider = Provider<RecruitmentRepository>((ref) => RecruitmentRepository());
final assetsRepositoryProvider = Provider<AssetsRepository>((ref) => AssetsRepository());
final summaryRepositoryProvider = Provider<SummaryRepository>((ref) => SummaryRepository());

// ── HR Structure Providers ──────────────────────────────────────────────────
final branchesProvider = FutureProvider<List<BranchData>>((ref) {
  return ref.watch(hrRepositoryProvider).getBranches();
});

final departmentsProvider = FutureProvider<List<DepartmentData>>((ref) {
  return ref.watch(hrRepositoryProvider).getDepartments();
});

final positionsProvider = FutureProvider<List<PositionData>>((ref) {
  return ref.watch(hrRepositoryProvider).getPositions();
});

final teamsProvider = FutureProvider<List<TeamData>>((ref) {
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

/// Simple provider that fetches all employees (scoped to active branch if switched).
final allEmployeesProvider = FutureProvider.autoDispose<List<EmployeeData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(hrRepositoryProvider).getEmployees(
    perPage: 1000,
    branchId: activeBranchId,
  );
});

/// Family provider used by AdminEmployeesScreen (supports search + filters).
final adminEmployeesProvider = FutureProvider.autoDispose.family<List<EmployeeData>, EmployeeFilters>((ref, filters) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(hrRepositoryProvider).getEmployees(
    search: filters.search.isEmpty ? null : filters.search,
    departmentId: filters.departmentId,
    // activeBranchId overrides the manual branch filter if we are impersonating a branch
    branchId: activeBranchId ?? filters.branchId,
    employmentStatus: filters.employmentStatus.isEmpty ? null : filters.employmentStatus,
    employmentType: filters.employmentType.isEmpty ? null : filters.employmentType,
  );
});

final rolesProvider = FutureProvider<List<RoleData>>((ref) {
  return ref.watch(hrRepositoryProvider).getRoles();
});

// ── Admin Operations Providers ──────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardKpiData>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getDashboardStats(branchId: activeBranchId);
});

class AttendanceFilters {
  final String? dateFrom;
  final String? dateTo;
  final int? departmentId;
  final int? employeeId;
  final String? status;
  final int? branchId;

  const AttendanceFilters({
    this.dateFrom,
    this.dateTo,
    this.departmentId,
    this.employeeId,
    this.status,
    this.branchId,
  });

  bool get hasActiveFilters =>
      (dateFrom != null && dateFrom!.isNotEmpty) ||
      (dateTo != null && dateTo!.isNotEmpty) ||
      departmentId != null ||
      employeeId != null ||
      (status != null && status!.isNotEmpty && status != 'all') ||
      branchId != null;

  AttendanceFilters copyWith({
    String? Function()? dateFrom,
    String? Function()? dateTo,
    int? Function()? departmentId,
    int? Function()? employeeId,
    String? Function()? status,
    int? Function()? branchId,
  }) {
    return AttendanceFilters(
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      departmentId: departmentId != null ? departmentId() : this.departmentId,
      employeeId: employeeId != null ? employeeId() : this.employeeId,
      status: status != null ? status() : this.status,
      branchId: branchId != null ? branchId() : this.branchId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceFilters &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          departmentId == other.departmentId &&
          employeeId == other.employeeId &&
          status == other.status &&
          branchId == other.branchId;

  @override
  int get hashCode => Object.hash(
        dateFrom,
        dateTo,
        departmentId,
        employeeId,
        status,
        branchId,
      );
}

final allAttendanceLogsProvider = FutureProvider.autoDispose.family<List<AdminAttendanceRecord>, AttendanceFilters>((ref, filters) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getAllAttendanceLogs(
    branchId: activeBranchId ?? filters.branchId,
    dateFrom: filters.dateFrom,
    dateTo: filters.dateTo,
    departmentId: filters.departmentId,
    employeeId: filters.employeeId,
    status: filters.status,
  );
});

final attendanceCorrectionsProvider = FutureProvider.autoDispose<List<AttendanceCorrectionData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getAttendanceCorrections(branchId: activeBranchId);
});

final allLeaveRequestsProvider = FutureProvider.autoDispose<List<AdminLeaveRequestData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getAllLeaveRequests(branchId: activeBranchId);
});

final leaveTypesProvider = FutureProvider<List<LeaveTypeData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getLeaveTypes();
});

final leaveBalancesProvider = FutureProvider.autoDispose<List<LeaveBalanceData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getLeaveBalances(branchId: activeBranchId);
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
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(assetsRepositoryProvider).getAssets(branchId: activeBranchId);
});

final recruitmentJobsProvider = FutureProvider.autoDispose<RecruitmentJobsResponse>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(recruitmentRepositoryProvider).getJobs(branchId: activeBranchId);
});

final jobCandidatesProvider = FutureProvider.family.autoDispose<List<CandidateData>, int>((ref, jobId) {
  return ref.watch(recruitmentRepositoryProvider).getCandidates(jobId);
});

final performanceReviewsProvider = FutureProvider.autoDispose<List<PerformanceReviewData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getReviews(branchId: activeBranchId);
});

final trainingCoursesProvider = FutureProvider.autoDispose<List<TrainingCourseData>>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getTrainings();
});

final payrollRunsProvider = FutureProvider.autoDispose<List<PayrollRunData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getPayrollRuns(branchId: activeBranchId);
});

final payrollSettingsProvider = FutureProvider.autoDispose<PayrollSettingsData>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getPayrollSettings();
});

final companyFormulasProvider = FutureProvider.autoDispose<PayrollSettingsData>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getCompanyFormulas();
});

final branchPayrollSettingsProvider = FutureProvider.autoDispose.family<PayrollSettingsData, int>((ref, branchId) {
  return ref.watch(adminOpsRepositoryProvider).getBranchPayrollSettings(branchId);
});

final branchFormulasProvider = FutureProvider.autoDispose.family<PayrollSettingsData, int>((ref, branchId) {
  return ref.watch(adminOpsRepositoryProvider).getBranchFormulas(branchId);
});

final employeeDetailProvider = FutureProvider.autoDispose.family<EmployeeData, int>((ref, id) {
  return ref.watch(hrRepositoryProvider).getEmployee(id);
});

// ── Org Chart Provider ──────────────────────────────────────────────────────
final orgChartProvider = FutureProvider.autoDispose<List<OrgNode>>((ref) {
  return ref.watch(hrRepositoryProvider).getOrgChart();
});

// ── Shift Assignments Provider ──────────────────────────────────────────────
final shiftAssignmentsProvider = FutureProvider.autoDispose<List<ShiftAssignmentData>>((ref) {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(adminOpsRepositoryProvider).getShiftAssignments(branchId: activeBranchId);
});

// ── Company Leave Summary Provider ──────────────────────────────────────────
class CompanyLeaveSummaryQuery {
  final int year;
  final int? departmentId;
  final int? branchId;
  final int? employeeId;

  const CompanyLeaveSummaryQuery({
    required this.year,
    this.departmentId,
    this.branchId,
    this.employeeId,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'year': year};
    if (departmentId != null) map['department_id'] = departmentId;
    if (branchId != null) map['branch_id'] = branchId;
    if (employeeId != null) map['employee_id'] = employeeId;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyLeaveSummaryQuery &&
          year == other.year &&
          departmentId == other.departmentId &&
          branchId == other.branchId &&
          employeeId == other.employeeId;

  @override
  int get hashCode => Object.hash(year, departmentId, branchId, employeeId);
}

final companyLeaveSummaryProvider = FutureProvider.autoDispose
    .family<List<CompanyLeaveSummaryItem>, CompanyLeaveSummaryQuery>(
        (ref, query) async {
  final repo = ref.watch(summaryRepositoryProvider);
  final rawList = await repo.fetchSummary(
    type: 'leave',
    filters: query.toMap(),
  );
  return rawList.map(CompanyLeaveSummaryItem.fromJson).toList();
});
