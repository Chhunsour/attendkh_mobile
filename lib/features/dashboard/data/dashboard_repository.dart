import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

/// Dashboard KPIs from API
class DashboardKpis {
  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int absentToday;
  final int onLeaveToday;
  final int pendingLeaveRequests;
  final int pendingExpenses;
  final double? monthlyPayroll;

  const DashboardKpis({
    required this.totalEmployees,
    required this.presentToday,
    required this.lateToday,
    required this.absentToday,
    required this.onLeaveToday,
    required this.pendingLeaveRequests,
    required this.pendingExpenses,
    this.monthlyPayroll,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalEmployees: json['total_employees'] as int? ?? 0,
      presentToday: json['present_today'] as int? ?? 0,
      lateToday: json['late_today'] as int? ?? 0,
      absentToday: json['absent_today'] as int? ?? 0,
      onLeaveToday: json['on_leave_today'] as int? ?? 0,
      pendingLeaveRequests: json['pending_leave_requests'] as int? ?? 0,
      pendingExpenses: json['pending_expenses'] as int? ?? 0,
      monthlyPayroll: (json['monthly_payroll'] as num?)?.toDouble(),
    );
  }
}

/// Full dashboard data from GET /company/dashboard
class DashboardData {
  final int userId;
  final String userName;
  final String? userEmail;
  final List<String> roles;
  final String? companyName;
  final DashboardKpis kpis;

  const DashboardData({
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.roles,
    this.companyName,
    required this.kpis,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final company = json['company'] as Map<String, dynamic>?;
    final kpis = json['kpis'] as Map<String, dynamic>?;
    return DashboardData(
      userId: user['id'] as int,
      userName: user['name'] as String,
      userEmail: user['email'] as String?,
      roles: (user['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      companyName: company?['name'] as String?,
      kpis: kpis != null ? DashboardKpis.fromJson(kpis) : DashboardKpis.fromJson({}),
    );
  }
}

class DashboardRepository {
  final ApiRepository _api;

  DashboardRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/company/dashboard
  Future<DashboardData> getDashboard() async {
    final response = await _api.get('/company/dashboard');

    if (response.data == null) {
      throw Exception('Dashboard data not available');
    }

    return DashboardData.fromJson(response.data as Map<String, dynamic>);
  }
}