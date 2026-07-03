import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

class NotificationItem {
  final int id;
  final String title;
  final String? body;
  final String type;
  final bool isRead;
  final String? data;
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
      title: json['data']?['title'] as String? ?? json['title'] as String? ?? 'Notification',
      body: json['data']?['body'] as String? ?? json['body'] as String?,
      type: json['type'] as String? ?? 'info',
      isRead: json['read_at'] != null,
      data: json['data']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class NotificationsRepository {
  final ApiRepository _api;
  NotificationsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/company/notifications
  Future<List<NotificationItem>> getAll() async {
    final response = await _api.get('/company/notifications');
    final data = response.data;
    if (data is List) {
      return data.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// POST /api/v1/company/notifications/{id}/read
  Future<void> markRead(int id) async {
    await _api.post('/company/notifications/$id/read');
  }

  /// POST /api/v1/company/notifications/read-all
  Future<void> markAllRead() async {
    await _api.post('/company/notifications/read-all');
  }

  /// GET /api/v1/company/notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get('/company/notifications/unread-count');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return (data['data'] as num?)?.toInt() ?? 0;
      }
      if (data is num) return data.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}