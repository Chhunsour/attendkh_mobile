import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AdminAuditLog {
  final int id;
  final String action;
  final String? performedBy;
  final String? description;
  final String? createdAt;

  const AdminAuditLog({
    required this.id,
    required this.action,
    this.performedBy,
    this.description,
    this.createdAt,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] as int? ?? 0,
      action: json['action'] as String? ?? json['event'] as String? ?? '',
      performedBy: json['performed_by'] as String? ??
          json['user_name'] as String? ??
          json['causer_name'] as String?,
      description: json['description'] as String? ??
          json['details'] as String? ??
          json['properties']?.toString(),
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}

class AdminAuditLogsRepository {
  final ApiRepository _api;

  AdminAuditLogsRepository({ApiRepository? api})
      : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/audit-logs
  Future<List<AdminAuditLog>> getAuditLogs() async {
    final response = await _api.get('/admin/audit-logs');
    // API may return { data: [...] } envelope or a direct list
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AdminAuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => AdminAuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}