import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AdminAnnouncement {
  final int id;
  final String title;
  final String body;
  final String priority;
  final String audience;
  final String? expiresAt;
  final bool isPublished;
  final String? createdAt;
  final String? updatedAt;

  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.priority = 'normal',
    this.audience = 'all',
    this.expiresAt,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminAnnouncement.fromJson(Map<String, dynamic> json) {
    return AdminAnnouncement(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['content'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      audience: json['audience'] as String? ?? 'all',
      expiresAt: json['expires_at'] as String?,
      isPublished: (json['is_published'] is bool)
          ? json['is_published'] as bool
          : (json['is_published'] == 1 || json['is_published'] == '1'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': body,
        'priority': priority,
        'audience': audience,
        if (expiresAt != null) 'expires_at': expiresAt,
        'is_published': isPublished,
      };
}

class AdminAnnouncementsRepository {
  final ApiRepository _api;

  AdminAnnouncementsRepository({ApiRepository? api})
      : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/announcements
  Future<List<AdminAnnouncement>> getAnnouncements() async {
    final response = await _api.get('/admin/announcements');
    // API may return { data: [...] } envelope or paginated { data: { data: [...] } }
    List<dynamic> list;
    if (response.data is List) {
      list = response.data as List<dynamic>;
    } else if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>? ?? [];
    } else {
      list = [];
    }
    return list
        .map((e) => AdminAnnouncement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/admin/announcements
  Future<AdminAnnouncement> createAnnouncement(Map<String, dynamic> data) async {
    final response = await _api.post('/admin/announcements', data: data);
    return AdminAnnouncement.fromJson(_unwrapSingle(response.data));
  }

  /// PUT /api/v1/admin/announcements/{id}
  Future<AdminAnnouncement> updateAnnouncement(
      int id, Map<String, dynamic> data) async {
    final response = await _api.put('/admin/announcements/$id', data: data);
    return AdminAnnouncement.fromJson(_unwrapSingle(response.data));
  }

  /// Unwrap single-entity response that may be { data: { ... } }
  Map<String, dynamic> _unwrapSingle(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }

  /// DELETE /api/v1/admin/announcements/{id}
  Future<void> deleteAnnouncement(int id) async {
    await _api.delete('/admin/announcements/$id');
  }
}