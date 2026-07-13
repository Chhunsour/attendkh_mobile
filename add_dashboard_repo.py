with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

dashboard_code = """
// ── Dashboard ─────────────────────────────────────────────────────────────
class DashboardKpiData {
  final int totalEmployees;
  final int todayAttendance;
  final int pendingLeaves;
  final int pendingExpenses;
  final int openJobs;
  final int totalAssets;
  final int assignedAssets;
  final double monthlyPayroll;

  const DashboardKpiData({
    required this.totalEmployees,
    required this.todayAttendance,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.openJobs,
    required this.totalAssets,
    required this.assignedAssets,
    required this.monthlyPayroll,
  });

  factory DashboardKpiData.fromJson(Map<String, dynamic> json) {
    return DashboardKpiData(
      totalEmployees: json['total_employees'] as int? ?? 0,
      todayAttendance: json['today_attendance'] as int? ?? 0,
      pendingLeaves: json['pending_leaves'] as int? ?? 0,
      pendingExpenses: json['pending_expenses'] as int? ?? 0,
      openJobs: json['open_jobs'] as int? ?? 0,
      totalAssets: json['total_assets'] as int? ?? 0,
      assignedAssets: json['assigned_assets'] as int? ?? 0,
      monthlyPayroll: double.tryParse(json['monthly_payroll']?.toString() ?? '0') ?? 0.0,
    );
  }
}

"""

if 'class DashboardKpiData' not in content:
    content = content.replace(
        "class AdminOperationsRepository {",
        dashboard_code + "class AdminOperationsRepository {"
    )

    get_method = """
  // ── Dashboard ────────────────────────────────────────────────────────────
  Future<DashboardKpiData> getDashboardStats() async {
    final response = await _api.get('/company/dashboard');
    final data = response.data['data']?['kpis'] ?? response.data['kpis'] ?? response.data;
    return DashboardKpiData.fromJson(data as Map<String, dynamic>);
  }
"""
    content = content.replace(
        "  // ── Attendance ──────────────────────────────────────────────────────────",
        get_method + "  // ── Attendance ──────────────────────────────────────────────────────────"
    )

    with open('lib/services/admin_operations_repository.dart', 'w') as f:
        f.write(content)
