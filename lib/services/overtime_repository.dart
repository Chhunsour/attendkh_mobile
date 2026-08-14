import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/overtime_request.dart';
import 'network/api_repository.dart';

final overtimeRepositoryProvider = Provider<OvertimeRepository>((ref) {
  return OvertimeRepository();
});

class OvertimeRepository extends ApiRepository {
  Future<List<OvertimeRequest>> getOvertimeRequests() async {
    final response = await get('/company/overtime-requests');
    if (response.isSuccess) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => OvertimeRequest.fromJson(json)).toList();
    }
    throw Exception(response.message ?? 'Failed to load overtime requests');
  }

  Future<OvertimeRequest> submitOvertimeRequest({
    required String date,
    required String startTime,
    required String endTime,
    double? amount,
    String? reason,
  }) async {
    final data = {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'amount': amount,
      'reason': reason,
    };

    final response = await post('/company/overtime-requests', data: data);
    
    if (response.isSuccess) {
      return OvertimeRequest.fromJson(response.data);
    }
    throw Exception(response.message ?? 'Failed to submit overtime request');
  }

  Future<Map<String, dynamic>> getShiftForDate(String date) async {
    final response = await get('/company/overtime-requests/shift', queryParameters: {'date': date});
    if (response.isSuccess) {
      return response.data as Map<String, dynamic>;
    }
    return {
      'is_working': false,
      'start_time': null,
      'end_time': null,
    };
  }

  Future<List<OvertimeRequest>> getManagerOvertimeRequests() async {
    final response = await get('/company/manage-overtime');
    if (response.isSuccess) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => OvertimeRequest.fromJson(json)).toList();
    }
    throw Exception(response.message ?? 'Failed to load manager overtime requests');
  }

  Future<OvertimeRequest> updateOvertimeStatus(int id, String status) async {
    final response = await post('/company/manage-overtime/$id/status', data: {'status': status});
    if (response.isSuccess) {
      return OvertimeRequest.fromJson(response.data);
    }
    throw Exception(response.message ?? 'Failed to update overtime status');
  }
}
