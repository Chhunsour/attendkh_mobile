import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AnnouncementData {
  final int id;
  final String title;
  final String content;
  final bool isImportant;
  final bool isPublished;
  final String? publishedAt;
  final String createdAt;

  const AnnouncementData({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
  });

  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    return AnnouncementData(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      isImportant: json['is_important'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      publishedAt: json['published_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class AnnouncementsRepository {
  final ApiRepository _api;
  AnnouncementsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<AnnouncementData>> getAnnouncements() async {
    final response = await _api.get('/company/announcements');
    final data = response.data;
    if (data is List) return data.map((e) => AnnouncementData.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => AnnouncementData.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}