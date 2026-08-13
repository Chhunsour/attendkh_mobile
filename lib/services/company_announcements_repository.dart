import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class CompanyAnnouncementData {
  final int id;
  final String title;
  final String content;
  final bool isPublished;
  final String? publishedAt;
  final String priority;
  final String audience;
  final String? expiresAt;
  final String? createdAt;
  final String? authorName;

  const CompanyAnnouncementData({
    required this.id,
    required this.title,
    required this.content,
    required this.isPublished,
    this.publishedAt,
    this.priority = 'normal',
    this.audience = 'all',
    this.expiresAt,
    this.createdAt,
    this.authorName,
  });

  factory CompanyAnnouncementData.fromJson(Map<String, dynamic> json) {
    return CompanyAnnouncementData(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      audience: json['audience'] as String? ?? 'all',
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String?,
      authorName: json['author']?['name'] as String?,
    );
  }
}

class CompanyAnnouncementsResponse {
  final List<CompanyAnnouncementData> announcements;
  final int currentPage;
  final int lastPage;
  final int total;
  final int from;
  final int to;

  const CompanyAnnouncementsResponse({
    required this.announcements,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.from = 0,
    this.to = 0,
  });
}

class CompanyAnnouncementsRepository {
  final ApiRepository _api;
  CompanyAnnouncementsRepository({ApiRepository? api})
      : _api = api ?? ApiRepository();

  Future<CompanyAnnouncementsResponse> getAnnouncements({
    String? search,
    String priority = 'all',
    int page = 1,
  }) async {
    final Map<String, dynamic> query = {'page': page};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (priority != 'all') query['priority'] = priority;

    final response = await _api.get('/company/announcements', queryParameters: query);
    final data = response.data;

    List<CompanyAnnouncementData> announcements = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;
    int from = 0;
    int to = 0;

    if (data is Map) {
      if (data['data'] != null && data['data'] is List) {
        final list = data['data'] as List;
        announcements = list
            .map((e) => CompanyAnnouncementData.fromJson(e as Map<String, dynamic>))
            .toList();
        currentPage = (data['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (data['last_page'] as num?)?.toInt() ?? 1;
        total = (data['total'] as num?)?.toInt() ?? 0;
        from = (data['from'] as num?)?.toInt() ?? 0;
        to = (data['to'] as num?)?.toInt() ?? 0;
      } else if (data['data'] is Map && data['data']?['data'] != null) {
        final nested = data['data'] as Map;
        announcements = (nested['data'] as List)
            .map((e) => CompanyAnnouncementData.fromJson(e as Map<String, dynamic>))
            .toList();
        currentPage = (nested['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (nested['last_page'] as num?)?.toInt() ?? 1;
        total = (nested['total'] as num?)?.toInt() ?? 0;
        from = (nested['from'] as num?)?.toInt() ?? 0;
        to = (nested['to'] as num?)?.toInt() ?? 0;
      } else if (data['announcements'] != null) {
        final annMap = data['announcements'] as Map;
        if (annMap['data'] != null) {
          announcements = (annMap['data'] as List)
              .map((e) => CompanyAnnouncementData.fromJson(e as Map<String, dynamic>))
              .toList();
          currentPage = (annMap['current_page'] as num?)?.toInt() ?? 1;
          lastPage = (annMap['last_page'] as num?)?.toInt() ?? 1;
          total = (annMap['total'] as num?)?.toInt() ?? 0;
          from = (annMap['from'] as num?)?.toInt() ?? 0;
          to = (annMap['to'] as num?)?.toInt() ?? 0;
        }
      }
    } else if (data is List) {
      announcements = data
          .map((e) => CompanyAnnouncementData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CompanyAnnouncementsResponse(
      announcements: announcements,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      from: from,
      to: to,
    );
  }

  Future<CompanyAnnouncementData> createAnnouncement(Map<String, dynamic> data) async {
    final response = await _api.post('/company/announcements', data: data);
    final raw = response.data;
    if (raw is Map && raw['data'] is Map) {
      return CompanyAnnouncementData.fromJson(raw['data'] as Map<String, dynamic>);
    }
    return CompanyAnnouncementData.fromJson(raw as Map<String, dynamic>);
  }

  Future<void> updateAnnouncement(int id, Map<String, dynamic> data) async {
    await _api.put('/company/announcements/$id', data: data);
  }

  Future<void> deleteAnnouncement(int id) async {
    await _api.delete('/company/announcements/$id');
  }

  Future<void> publishAnnouncement(int id) async {
    await _api.post('/company/announcements/$id/publish');
  }

  Future<void> unpublishAnnouncement(int id) async {
    await _api.post('/company/announcements/$id/unpublish');
  }
}
