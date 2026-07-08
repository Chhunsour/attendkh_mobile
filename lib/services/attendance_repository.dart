import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

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
    try {
      final response = await _api.get('/company/attendance/today');
      final data = response.data;
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          return TodayAttendance.fromJson(data['data'] as Map<String, dynamic>);
        }
        return TodayAttendance.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.w('Attendance today fetch failed — returning null', e);
      return null;
    }
  }

  /// POST /api/v1/company/attendance/clock-in
  Future<TodayAttendance> clockIn({
    double? lat,
    double? lng,
    String? deviceId,
    String? photoPath,
  }) async {
    dynamic payload;

    if (photoPath != null) {
      payload = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
        'photo': await MultipartFile.fromFile(photoPath, filename: 'clock_in.jpg'),
        'method': 'mobile',
      });
    } else {
      payload = {
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
        'method': 'mobile',
      };
    }

    final response = await _api.post(
      '/company/attendance/clock-in',
      data: payload,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return TodayAttendance.fromJson(data['data'] as Map<String, dynamic>);
    }
    return TodayAttendance.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/v1/company/attendance/clock-out
  Future<TodayAttendance> clockOut({
    double? lat,
    double? lng,
    String? deviceId,
    String? photoPath,
  }) async {
    dynamic payload;

    if (photoPath != null) {
      payload = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
        'photo': await MultipartFile.fromFile(photoPath, filename: 'clock_out.jpg'),
        'method': 'mobile',
      });
    } else {
      payload = {
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
        'method': 'mobile',
      };
    }

    final response = await _api.post(
      '/company/attendance/clock-out',
      data: payload,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return TodayAttendance.fromJson(data['data'] as Map<String, dynamic>);
    }
    return TodayAttendance.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/v1/company/attendance/summary
  Future<AttendanceSummary> getSummary({String? month}) async {
    final response = await _api.get(
      '/company/attendance/summary',
      queryParameters: {'month': month},
    );
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        return AttendanceSummary.fromJson(raw['data'] as Map<String, dynamic>);
      }
      return AttendanceSummary.fromJson(raw);
    }
    return const AttendanceSummary(present: 0, absent: 0, late: 0, halfDay: 0, totalDays: 0, totalHours: 0);
  }

  /// GET /api/v1/company/attendance — history of records
  Future<List<TodayAttendance>> getHistory({String? month}) async {
    final response = await _api.get(
      '/company/attendance',
      queryParameters: {'month': month},
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => TodayAttendance.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => TodayAttendance.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// POST /api/v1/company/attendance/corrections
  Future<void> requestCorrection({required String date, required String type, required String reason}) async {
    await _api.post('/company/attendance/corrections', data: {
      'date': date,
      'type': type,
      'reason': reason,
    });
  }
}
