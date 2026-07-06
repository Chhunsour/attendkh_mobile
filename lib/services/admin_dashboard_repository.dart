import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

/// KPI stats from GET /api/v1/admin/dashboard
class AdminDashboardStats {
  final int totalCompanies;
  final int totalUsers;
  final int activeCompanies;
  final int openTickets;
  final int publishedAnnouncements;

  const AdminDashboardStats({
    required this.totalCompanies,
    required this.totalUsers,
    required this.activeCompanies,
    required this.openTickets,
    required this.publishedAnnouncements,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return AdminDashboardStats(
      totalCompanies: stats['total_companies'] as int? ?? 0,
      totalUsers: stats['total_users'] as int? ?? 0,
      activeCompanies: stats['active_companies'] as int? ?? 0,
      openTickets: stats['open_tickets'] as int? ?? 0,
      publishedAnnouncements: stats['published_announcements'] as int? ?? 0,
    );
  }
}

/// Recent activity item (signup or ticket)
class AdminActivityItem {
  final int id;
  final String name;
  final String action;
  final String date;

  const AdminActivityItem({
    required this.id,
    required this.name,
    required this.action,
    required this.date,
  });

  factory AdminActivityItem.fromJson(Map<String, dynamic> json) {
    return AdminActivityItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      action: json['action'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}

/// Full admin dashboard data
class AdminDashboardData {
  final AdminDashboardStats stats;
  final List<AdminActivityItem> recentSignups;
  final List<AdminActivityItem> recentTickets;

  const AdminDashboardData({
    required this.stats,
    required this.recentSignups,
    required this.recentTickets,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final signupsList = json['recentSignups'] as List<dynamic>? ?? [];
    final ticketsList = json['recentTickets'] as List<dynamic>? ?? [];
    return AdminDashboardData(
      stats: AdminDashboardStats.fromJson(json),
      recentSignups: signupsList
          .map((e) => AdminActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentTickets: ticketsList
          .map((e) => AdminActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Repository — calls GET /api/v1/admin/dashboard
class AdminDashboardRepository {
  final ApiRepository _api;

  AdminDashboardRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<AdminDashboardData> getDashboard() async {
    final response = await _api.get<Map<String, dynamic>>('/admin/dashboard');
    final raw = response.data;
    if (raw == null) throw Exception('No dashboard data returned');
    return AdminDashboardData.fromJson(raw);
  }
}
