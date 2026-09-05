import 'package:attendkh/services/network/api_repository.dart';

class AdminSettingsRepository {
  final ApiRepository _api;

  AdminSettingsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _api.get('/admin/settings');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  /// PUT /api/v1/admin/settings
  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> data) async {
    final response = await _api.put('/admin/settings', data: data);
    if (response.data is Map<String, dynamic>) {
      final respData = response.data as Map<String, dynamic>;
      return respData['data'] as Map<String, dynamic>? ?? respData;
    }
    return data;
  }
}