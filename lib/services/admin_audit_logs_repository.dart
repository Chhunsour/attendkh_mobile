import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AdminAuditLog {
  final int id;
  final String action;
  final String? performedBy;
  final String? description;
  final String? createdAt;
  final Map<String, dynamic>? changes;

  const AdminAuditLog({
    required this.id,
    required this.action,
    this.performedBy,
    this.description,
    this.createdAt,
    this.changes,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    final causer = json['causer'] as Map<String, dynamic>?;
    return AdminAuditLog(
      id: json['id'] as int? ?? 0,
      action: json['event'] as String? ?? json['description'] as String? ?? 'unknown',
      performedBy: causer?['name'] as String? ??
          json['performed_by'] as String? ??
          json['user_name'] as String?,
      description: _buildDescription(json),
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
      changes: _extractChanges(json),
    );
  }

  static Map<String, dynamic>? _extractChanges(Map<String, dynamic> json) {
    if (json['attribute_changes'] is Map<String, dynamic> &&
        (json['attribute_changes'] as Map).isNotEmpty) {
      return json['attribute_changes'] as Map<String, dynamic>;
    }
    if (json['properties'] is Map<String, dynamic> &&
        (json['properties'] as Map).isNotEmpty) {
      return json['properties'] as Map<String, dynamic>;
    }
    return null;
  }

  static String _buildDescription(Map<String, dynamic> json) {
    final String subjectType = (json['subject_type'] as String? ?? '').split('\\').last;
    final subjectId = json['subject_id']?.toString() ?? '?';
    if (subjectType.isNotEmpty) {
      return '$subjectType #$subjectId';
    }
    return json['description'] as String? ?? 'Unknown activity';
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