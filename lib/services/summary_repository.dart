import 'package:attendkh/services/network/api_repository.dart';

class SummaryRepository {
  final ApiRepository _api;
  SummaryRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<Map<String, dynamic>>> fetchSummary({
    required String type,
    Map<String, dynamic>? filters,
  }) async {
    final response = await _api.get(
      '/company/summaries/$type',
      queryParameters: filters,
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchSpecializedSummary({
    required String type,
    Map<String, dynamic>? filters,
  }) async {
    final response = await _api.get(
      '/company/summaries/$type',
      queryParameters: filters,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is List) {
      return {'data': data};
    }
    return {};
  }
}
