import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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
  final double? accruedToDate;
  final double? availableDays;

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
    this.accruedToDate,
    this.availableDays,
  });

  double get remaining {
    final total = allocated + carriedForward;
    final rem = total - used - pending;
    return rem < 0 ? 0.0 : rem;
  }

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    double? parseNullableDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return LeaveBalance(
      id: json['id'] as int? ?? 0,
      leaveTypeId: json['leave_type_id'] as int? ?? json['leave_type']?['id'] as int? ?? 0,
      type: json['leave_type']?['name'] as String? ?? json['type'] as String? ?? '',
      typeName: json['leave_type']?['name'] as String? ?? json['type'] as String? ?? '',
      allocated: parseDouble(json['allocated_days']),
      used: parseDouble(json['used_days']),
      carriedForward: parseDouble(json['carried_forward']),
      pending: parseDouble(json['pending_days']),
      color: json['leave_type']?['color'] as String? ?? json['color'] as String?,
      accruedToDate: parseNullableDouble(json['accrued_to_date']),
      availableDays: parseNullableDouble(json['available_days']),
    );
  }
}

class LeaveRequest {
  final int id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final double days;
  final bool isHalfDay;
  final String? documentUrl;
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
    this.isHalfDay = false,
    this.documentUrl,
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
      days: json['days'] != null ? double.tryParse(json['days'].toString()) ?? 0 : (json['total_days'] != null ? double.tryParse(json['total_days'].toString()) ?? 0 : 0),
      isHalfDay: json['half_day'] == true || json['half_day'] == 1,
      documentUrl: json['document'] as String?,
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

  /// GET /api/v1/company/leave/types
  Future<List<LeaveType>> getLeaveTypes() async {
    final response = await _api.get('/company/leave/types');
    final data = response.data;
    if (data is List) {
      return data.map((e) => LeaveType.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => LeaveType.fromJson(e as Map<String, dynamic>)).toList();
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
    bool isHalfDay = false,
    String? halfDayPeriod,
    PlatformFile? attachment,
  }) async {
    Map<String, dynamic> data = {
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'half_day': isHalfDay ? 1 : 0,
    };

    if (isHalfDay && halfDayPeriod != null) {
      data['half_day_period'] = halfDayPeriod;
    }

    if (attachment != null && attachment.path != null) {
      data['document'] = await MultipartFile.fromFile(
        attachment.path!,
        filename: attachment.name,
      );
    }

    final response = await _api.post(
      '/company/leave/requests',
      data: FormData.fromMap(data),
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

class LeaveType {
  final int id;
  final String name;
  final int daysPerYear;
  final bool isPaid;
  final String accrualMode;
  final double? maxDaysPerMonth;
  final String exceedAccrualAction;

  const LeaveType({
    required this.id,
    required this.name,
    required this.daysPerYear,
    this.isPaid = true,
    this.accrualMode = 'upfront',
    this.maxDaysPerMonth,
    this.exceedAccrualAction = 'convert_to_unpaid',
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    double? parseNullableDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return LeaveType(
      id: json['id'] as int,
      name: json['name'] as String,
      daysPerYear: json['days_per_year'] as int? ?? 0,
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      accrualMode: json['accrual_mode'] as String? ?? 'upfront',
      maxDaysPerMonth: parseNullableDouble(json['max_days_per_month']),
      exceedAccrualAction: json['exceed_accrual_action'] as String? ?? 'convert_to_unpaid',
    );
  }
}
