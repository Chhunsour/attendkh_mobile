import 'package:attendkh/utils/logger/app_logger.dart';
import 'package:attendkh/services/network/api_repository.dart';

/// Dashboard KPIs from API (matches ReportService::dashboardKpis response)
class DashboardKpis {
  final int totalEmployees;
  final int todayAttendance;
  final int pendingLeaves;
  final int pendingExpenses;
  final int openJobs;
  final int totalAssets;
  final int assignedAssets;
  final double? monthlyPayroll;

  const DashboardKpis({
    required this.totalEmployees,
    required this.todayAttendance,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.openJobs,
    required this.totalAssets,
    required this.assignedAssets,
    this.monthlyPayroll,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalEmployees: json['total_employees'] as int? ?? 0,
      todayAttendance: json['today_attendance'] as int? ?? 0,
      pendingLeaves: json['pending_leaves'] as int? ?? 0,
      pendingExpenses: json['pending_expenses'] as int? ?? 0,
      openJobs: json['open_jobs'] as int? ?? 0,
      totalAssets: json['total_assets'] as int? ?? 0,
      assignedAssets: json['assigned_assets'] as int? ?? 0,
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
    try {
      final response = await _api.get('/company/dashboard');
      final raw = response.data;
      if (raw == null) {
        throw Exception('Dashboard data not available');
      }
      if (raw is Map<String, dynamic>) {
        if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
          return DashboardData.fromJson(raw['data'] as Map<String, dynamic>);
        }
        return DashboardData.fromJson(raw);
      }
      throw Exception('Invalid dashboard response format: ${raw.runtimeType}');
    } catch (e) {
      AppLogger.e('Dashboard fetch failed', e);
      rethrow;
    }
  }

  /// GET /api/v1/company/employee-dashboard-summary
  Future<Map<String, dynamic>> getEmployeeDashboardSummary() async {
    try {
      final response = await _api.get('/company/employee-dashboard-summary');
      final raw = response.data;
      if (raw == null) {
        throw Exception('Employee Dashboard summary not available');
      }
      if (raw is Map<String, dynamic>) {
        if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
          return raw['data'] as Map<String, dynamic>;
        }
        return raw;
      }
      return {};
    } catch (e) {
      AppLogger.e('Employee Dashboard summary fetch failed', e);
      rethrow;
    }
  }
}