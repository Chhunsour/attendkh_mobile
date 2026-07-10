import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class LeaveBalance {
  final int id;
  final int leaveTypeId;
  final String type;
  final String typeName;
  final double allocated;
  final double used;
  final double carriedForward;
  final double pending;
  final String? color;

  const LeaveBalance({
    required this.id,
    required this.leaveTypeId,
    required this.type,
    required this.typeName,
    required this.allocated,
    required this.used,
    required this.carriedForward,
    required this.pending,
    this.color,
  });

  double get remaining => allocated + carriedForward - used - pending;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'] as int? ?? 0,
      leaveTypeId: json['leave_type_id'] as int? ?? json['leave_type']?['id'] as int? ?? 0,
      type: json['leave_type']?['name'] as String? ?? json['type'] as String? ?? '',
      typeName: json['leave_type']?['name'] as String? ?? json['type'] as String? ?? '',
      allocated: (json['allocated_days'] as num?)?.toDouble() ?? 0,
      used: (json['used_days'] as num?)?.toDouble() ?? 0,
      carriedForward: (json['carried_forward'] as num?)?.toDouble() ?? 0,
      pending: (json['pending_days'] as num?)?.toDouble() ?? 0,
      color: json['leave_type']?['color'] as String? ?? json['color'] as String?,
    );
  }
}

class LeaveRequest {
  final int id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final double days;
  final String? reason;
  final String status;
  final String? approvedBy;
  final String createdAt;

  const LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.reason,
    required this.status,
    this.approvedBy,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      leaveType: json['leave_type']?['name'] as String? ?? '',
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      days: (json['days'] as num?)?.toDouble() ?? (json['total_days'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      approvedBy: json['approver']?['name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class LeaveRepository {
  final ApiRepository _api;
  LeaveRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/company/leave/balances/mine
  Future<List<LeaveBalance>> getMyBalances() async {
    final response = await _api.get('/company/leave/balances/mine');
    final data = response.data;
    if (data is List) {
      return data.map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// GET /api/v1/company/leave/requests
  Future<List<LeaveRequest>> getRequests({String? status}) async {
    final response = await _api.get(
      '/company/leave/requests',
      queryParameters: {'status': status},
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// POST /api/v1/company/leave/requests
  Future<LeaveRequest> submitRequest({
    required int employeeId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await _api.post(
      '/company/leave/requests',
      data: {
        'employee_id': employeeId,
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      },
    );
    final raw = response.data as Map<String, dynamic>;
    final payload = raw['data'] as Map<String, dynamic>? ?? raw;
    return LeaveRequest.fromJson(payload);
  }

  /// POST /api/v1/company/leave/requests/{id}/cancel
  Future<void> cancelRequest(int id) async {
    await _api.post('/company/leave/requests/$id/cancel');
  }
}
