import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

class TodayAttendance {
  final int? id;
  final String? clockIn;
  final String? clockOut;
  final String? clockInPhoto;
  final String? clockOutPhoto;
  final String? status;
  final double? workHours;
  final String? date;

  const TodayAttendance({
    this.id,
    this.clockIn,
    this.clockOut,
    this.clockInPhoto,
    this.clockOutPhoto,
    this.status,
    this.workHours,
    this.date,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      id: json['id'] as int?,
      clockIn: json['clock_in'] as String?,
      clockOut: json['clock_out'] as String?,
      clockInPhoto: json['clock_in_photo'] as String?,
      clockOutPhoto: json['clock_out_photo'] as String?,
      status: json['status'] as String?,
      workHours: (json['work_hours'] as num?)?.toDouble(),
      date: json['date'] as String?,
    );
  }
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int totalDays;
  final double totalHours;

  const AttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.totalDays,
    required this.totalHours,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      totalDays: json['total_days'] as int? ?? 0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AttendanceRepository {
  final ApiRepository _api;
  AttendanceRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// GET /api/v1/company/attendance/today
  Future<TodayAttendance?> getToday() async {
    final response = await _api.get('/company/attendance/today');
    final data = response.data;
    if (data is Map<String, dynamic> && data.isNotEmpty) {
      return TodayAttendance.fromJson(data);
    }
    return null;
  }

  /// POST /api/v1/company/attendance/clock-in
  Future<TodayAttendance> clockIn({
    double? lat,
    double? lng,
    String? deviceId,
  }) async {
    final response = await _api.post(
      '/company/attendance/clock-in',
      data: {
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
        'method': 'mobile',
      },
    );
    return TodayAttendance.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/company/attendance/clock-out
  Future<TodayAttendance> clockOut({
    double? lat,
    double? lng,
    String? deviceId,
  }) async {
    final response = await _api.post(
      '/company/attendance/clock-out',
      data: {
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
        'method': 'mobile',
      },
    );
    return TodayAttendance.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/company/attendance/summary
  Future<AttendanceSummary> getSummary({String? month}) async {
    final response = await _api.get(
      '/company/attendance/summary',
      queryParameters: {'month': month},
    );
    return AttendanceSummary.fromJson(response.data as Map<String, dynamic>);
  }
}