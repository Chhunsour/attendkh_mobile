import 'package:attendkh/services/network/api_repository.dart';

class NotificationItem {
  final int id;
  final String title;
  final String? body;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    this.body,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      title:
          json['data']?['title'] as String? ??
          json['title'] as String? ??
          'Notification',
      body:
          json['data']?['body'] as String? ??
          json['body'] as String? ??
          json['message'] as String?,
      type: json['type'] as String? ?? 'info',
      isRead: json['read_at'] != null,
      data: json['data'] is Map ? json['data'] as Map<String, dynamic> : null,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class NotificationsRepository {
  final ApiRepository _api;
  NotificationsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/company/notifications
  Future<List<NotificationItem>> getAll({
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final response = await _api.get(
      '/company/notifications',
      queryParameters: queryParams,
    );
    return _parseNotifications(response.data);
  }

  /// POST /api/v1/company/notifications/{id}/read
  Future<void> markRead(int id) async {
    await _api.post('/company/notifications/$id/read');
  }

  /// GET /api/v1/company/notifications/{id}/download-file
  Future<void> downloadAttachment(int id, String savePath) async {
    await _api.download(
      '/company/notifications/$id/download-file',
      savePath,
      method: 'GET',
    );
  }

  /// POST /api/v1/company/notifications/read-all
  Future<void> markAllRead() async {
    await _api.post('/company/notifications/read-all');
  }

  // ── Admin endpoints ──────────────────────────────────────────────────────

  /// Parse notifications from various API response formats
  List<NotificationItem> _parseNotifications(dynamic data) {
    if (data is List) {
      return data
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map) {
      final innerData = data['data'];
      if (innerData is Map) {
        if (innerData['notifications'] is Map &&
            innerData['notifications']['data'] is List) {
          return (innerData['notifications']['data'] as List)
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (innerData['notifications'] is List) {
          return (innerData['notifications'] as List)
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (innerData['data'] is List) {
          return (innerData['data'] as List)
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (innerData is List) {
        return innerData
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data['notifications'] is Map &&
          data['notifications']['data'] is List) {
        return (data['notifications']['data'] as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data['notifications'] is List) {
        return (data['notifications'] as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// GET /api/v1/admin/notifications
  Future<List<NotificationItem>> getAdminAll({
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final response = await _api.get(
      '/admin/notifications',
      queryParameters: queryParams,
    );
    final data = response.data;
    return _parseNotifications(data);
  }

  /// POST /api/v1/admin/notifications/{id}/read
  Future<void> adminMarkRead(int id) async {
    await _api.post('/admin/notifications/$id/read');
  }

  /// POST /api/v1/admin/notifications/read-all
  Future<void> adminMarkAllRead() async {
    await _api.post('/admin/notifications/read-all');
  }

  /// GET /api/v1/admin/notifications/unread-count
  Future<int> getAdminUnreadCount() async {
    try {
      final response = await _api.get('/admin/notifications/unread-count');
      final data = response.data;
      if (data is Map) {
        if (data['data'] is Map && data['data']['count'] != null) {
          return (data['data']['count'] as num).toInt();
        }
        if (data['data'] is num) {
          return (data['data'] as num).toInt();
        }
        if (data['count'] is num) {
          return (data['count'] as num).toInt();
        }
      }
      if (data is num) return data.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// GET /api/v1/company/notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get('/company/notifications/unread-count');
      final data = response.data;
      if (data is Map) {
        if (data['data'] is Map && data['data']['count'] != null) {
          return (data['data']['count'] as num).toInt();
        }
        if (data['data'] is num) {
          return (data['data'] as num).toInt();
        }
        if (data['count'] is num) {
          return (data['count'] as num).toInt();
        }
        if (data['unread_count'] is num) {
          return (data['unread_count'] as num).toInt();
        }
      }
      if (data is num) return data.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
