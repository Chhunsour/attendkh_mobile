import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AdminAuditLog {
  final int id;
  final String action;
  final String? performedBy;
  final String? description;
  final String? subjectType;
  final String? event;
  final String? createdAt;
  final Map<String, dynamic>? changes;

  const AdminAuditLog({
    required this.id,
    required this.action,
    this.performedBy,
    this.description,
    this.subjectType,
    this.event,
    this.createdAt,
    this.changes,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    final causer = json['causer'] as Map<String, dynamic>?;
    return AdminAuditLog(
      id: json['id'] as int? ?? 0,
      action:
          json['description'] as String? ??
          json['event'] as String? ??
          'unknown',
      performedBy:
          causer?['name'] as String? ??
          json['performed_by'] as String? ??
          json['user_name'] as String?,
      description: _buildDescription(json),
      subjectType: (json['subject_type'] as String? ?? '').split('\\').last,
      event: json['event'] as String?,
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
    final String subjectType = (json['subject_type'] as String? ?? '')
        .split('\\')
        .last;
    final subjectId = json['subject_id']?.toString() ?? '?';
    if (subjectType.isNotEmpty) {
      return '$subjectType #$subjectId';
    }
    return json['description'] as String? ?? 'Unknown activity';
  }
}

class AdminAuditLogsPayload {
  final List<AdminAuditLog> logs;
  final List<String> events;

  AdminAuditLogsPayload(this.logs, this.events);
}

class AdminAuditLogsRepository {
  final ApiRepository _api;

  AdminAuditLogsRepository({ApiRepository? api})
    : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/audit-logs
  Future<AdminAuditLogsPayload> getAuditLogs({
    String? search,
    String? event,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (event != null && event.isNotEmpty) queryParams['event'] = event;

    final response = await _api.get(
      '/admin/audit-logs',
      queryParameters: queryParams,
    );

    List<dynamic> logList = [];
    List<String> events = [];

    // response.data is already unwrapped by ApiResponse.fromJson
    // It's either { logs: { data: [...] }, events: [...] } (new format)
    // or a direct list / { data: [...] } (old format)
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;

      // New format: { logs: {...}, events: [...] }
      if (data.containsKey('logs')) {
        final logsField = data['logs'];
        if (logsField is Map<String, dynamic>) {
          // Paginated: { logs: { data: [...] } }
          logList = logsField['data'] as List<dynamic>? ?? [];
        } else if (logsField is List) {
          logList = logsField;
        }
        events =
            (data['events'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      } else if (data['data'] is List) {
        // Old format: { data: [...] }
        logList = data['data'] as List<dynamic>;
      } else if (data['data'] is Map<String, dynamic>) {
        // Paginated old format: { data: { data: [...] } }
        final paginated = data['data'] as Map<String, dynamic>;
        logList = paginated['data'] as List<dynamic>? ?? [];
      }
    } else if (response.data is List) {
      logList = response.data as List<dynamic>;
    }

    final logs = logList
        .map((e) => AdminAuditLog.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminAuditLogsPayload(logs, events);
  }
}
