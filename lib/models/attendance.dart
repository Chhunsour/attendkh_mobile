import 'package:equatable/equatable.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  halfDay,
  onLeave,
  holiday,
  restDay;

  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.late: return 'Late';
      case AttendanceStatus.halfDay: return 'Half Day';
      case AttendanceStatus.onLeave: return 'On Leave';
      case AttendanceStatus.holiday: return 'Holiday';
      case AttendanceStatus.restDay: return 'Rest Day';
    }
  }
}

enum ClockMethod { mobile, web, qr, manual }

class AttendanceRecord extends Equatable {
  final int id;
  final int userId;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final ClockMethod? clockInMethod;
  final ClockMethod? clockOutMethod;
  final double? workHours;
  final AttendanceStatus status;
  final String? notes;
  final String? branchName;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.clockInMethod,
    this.clockOutMethod,
    this.workHours,
    required this.status,
    this.notes,
    this.branchName,
  });

  @override
  List<Object?> get props => [id, userId, date, status];
}

class AttendanceSummary extends Equatable {
  final int totalEmployees;
  final int present;
  final int late;
  final int absent;
  final int onLeave;

  const AttendanceSummary({
    required this.totalEmployees,
    required this.present,
    required this.late,
    required this.absent,
    required this.onLeave,
  });

  factory AttendanceSummary.empty() => const AttendanceSummary(
        totalEmployees: 0,
        present: 0,
        late: 0,
        absent: 0,
        onLeave: 0,
      );

  @override
  List<Object?> get props => [totalEmployees, present, late, absent, onLeave];
}