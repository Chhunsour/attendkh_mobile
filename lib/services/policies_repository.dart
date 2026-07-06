import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class Policy {
  final int id;
  final String title;
  final String content;
  final String category;
  final String version;
  final String status;
  final String? effectiveDate;
  final String? reviewDate;
  final String createdAt;

  const Policy({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.version,
    required this.status,
    this.effectiveDate,
    this.reviewDate,
    required this.createdAt,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      version: json['version'] as String? ?? '1.0',
      status: json['status'] as String? ?? 'draft',
      effectiveDate: json['effective_date'] as String?,
      reviewDate: json['review_date'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class PoliciesRepository {
  final ApiRepository _api;
  PoliciesRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/company/policies
  Future<List<Policy>> getAll({String? status, String? category}) async {
    final response = await _api.get(
      '/company/policies',
      queryParameters: {
        if (status != null && status != 'all') 'status': status,
        if (category != null && category != 'all') 'category': category,
      },
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => Policy.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => Policy.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}