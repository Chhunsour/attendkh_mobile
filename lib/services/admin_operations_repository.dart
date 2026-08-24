import 'dart:convert';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:path_provider/path_provider.dart';

// ── Common Models ────────────────────────────────────────────────────────────
// ── Attendance Correction ───────────────────────────────────────────────────
class AttendanceCorrectionData {
  final int id;
  final String employeeName;
  final String? employeeCode;
  final String date;
  final String? reason;
  final String status;
  final String? clockIn;
  final String? clockOut;
  final String? reviewerNotes;

  const AttendanceCorrectionData({
    required this.id,
    required this.employeeName,
    this.employeeCode,
    required this.date,
    this.reason,
    required this.status,
    this.clockIn,
    this.clockOut,
    this.reviewerNotes,
  });

  factory AttendanceCorrectionData.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    String name = '';
    if (emp is Map<String, dynamic>) {
      name = (emp['full_name'] as String?) ??
          (emp['name'] as String?) ??
          (emp['first_name'] != null
              ? '${emp['first_name']} ${emp['last_name'] ?? ''}'.trim()
              : '');
    }
    if (name.isEmpty) {
      name = (json['user']?['name'] as String?) ?? '';
    }

    final empCode = emp is Map<String, dynamic>
        ? (emp['employee_id'] as String?)
        : null;

    return AttendanceCorrectionData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeName: name.isNotEmpty ? name : 'Employee #${json['employee_id'] ?? ''}',
      employeeCode: empCode,
      date: json['date'] as String? ?? '',
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      clockIn:
          json['clock_in'] as String? ?? json['requested_clock_in'] as String?,
      clockOut:
          json['clock_out'] as String? ??
          json['requested_clock_out'] as String?,
      reviewerNotes: json['reviewer_notes'] as String?,
    );
  }
}

// ── Admin Attendance Record ─────────────────────────────────────────────────
class AdminAttendanceRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String status;
  final double? workHours;
  final int? lateMinutes;
  final int? earlyClockInMinutes;
  final int? approvedPreShiftOtMinutes;
  final bool canApprovePreShiftOt;
  final String? notes;
  final String? clockInPhoto;
  final String? clockOutPhoto;
  final String? clockInMethod;
  final String? clockOutMethod;
  final bool? isGeoValid;

  const AdminAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
    this.workHours,
    this.lateMinutes,
    this.earlyClockInMinutes,
    this.approvedPreShiftOtMinutes,
    this.canApprovePreShiftOt = false,
    this.notes,
    this.clockInPhoto,
    this.clockOutPhoto,
    this.clockInMethod,
    this.clockOutMethod,
    this.isGeoValid,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    String name = 'Unknown';
    if (emp != null) {
      if (emp['full_name'] != null && emp['full_name'].toString().isNotEmpty) {
        name = emp['full_name'].toString();
      } else if (emp['khmer_name'] != null &&
          emp['khmer_name'].toString().isNotEmpty) {
        name = emp['khmer_name'].toString();
      } else if (emp['user'] != null && emp['user']['name'] != null) {
        name = emp['user']['name'].toString();
      } else if (emp['first_name'] != null) {
        name = '${emp['first_name']} ${emp['last_name'] ?? ''}'.trim();
      }
    }
    return AdminAttendanceRecord(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeId: int.tryParse(json['employee_id']?.toString() ?? '') ?? 0,
      employeeName: name,
      date: json['date'] as String? ?? '',
      clockIn: json['clock_in'] as String?,
      clockOut: json['clock_out'] as String?,
      status: json['status'] as String? ?? 'absent',
      workHours: json['work_hours'] != null
          ? double.tryParse(json['work_hours'].toString())
          : null,
      lateMinutes: json['late_minutes'] != null
          ? int.tryParse(json['late_minutes'].toString())
          : null,
      earlyClockInMinutes: int.tryParse(
        json['early_clock_in_minutes']?.toString() ?? '',
      ),
      approvedPreShiftOtMinutes: int.tryParse(
        json['approved_pre_shift_ot_minutes']?.toString() ?? '',
      ),
      canApprovePreShiftOt: json['can_approve_pre_shift_ot'] == true,
      notes: json['notes'] as String?,
      clockInPhoto: json['clock_in_photo'] as String?,
      clockOutPhoto: json['clock_out_photo'] as String?,
      clockInMethod: json['clock_in_method'] as String?,
      clockOutMethod: json['clock_out_method'] as String?,
      isGeoValid: json['is_geo_valid'] as bool?,
    );
  }
}

// ── Admin Leave Request ─────────────────────────────────────────────────────
class AdminLeaveRequestData {
  final int id;
  final String employeeName;
  final String? employeeCode;
  final String? employeePosition;
  final String? employeePhoto;
  final String leaveType;
  final String leaveTypeName;
  final String? leaveTypeColor;
  final bool halfDay;
  final String startDate;
  final String endDate;
  final double days;
  final String? reason;
  final String status;
  final String createdAt;

  const AdminLeaveRequestData({
    required this.id,
    required this.employeeName,
    this.employeeCode,
    this.employeePosition,
    this.employeePhoto,
    required this.leaveType,
    this.leaveTypeName = '',
    this.leaveTypeColor,
    this.halfDay = false,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory AdminLeaveRequestData.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    String empName = '';
    String? empCode;
    String? empPos;
    String? empPhoto;

    if (emp != null) {
      if (emp['full_name'] != null && emp['full_name'].toString().isNotEmpty) {
        empName = emp['full_name'].toString();
      } else if (emp['khmer_name'] != null &&
          emp['khmer_name'].toString().isNotEmpty) {
        empName = emp['khmer_name'].toString();
      } else if (emp['user'] != null && emp['user']['name'] != null) {
        empName = emp['user']['name'].toString();
      } else if (emp['first_name'] != null) {
        empName = '${emp['first_name']} ${emp['last_name'] ?? ''}'.trim();
      }
      empCode = emp['employee_id']?.toString() ?? emp['code']?.toString();

      if (emp['position'] != null && emp['position'] is Map) {
        empPos = emp['position']['name']?.toString();
      } else if (emp['designation'] != null && emp['designation'] is Map) {
        empPos = emp['designation']['name']?.toString();
      } else if (emp['position'] != null && emp['position'] is String) {
        empPos = emp['position'].toString();
      } else if (emp['job_title'] != null) {
        empPos = emp['job_title'].toString();
      }

      empPhoto =
          emp['profile_photo_url']?.toString() ?? emp['photo']?.toString();
    }

    return AdminLeaveRequestData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeName: empName.isNotEmpty
          ? empName
          : json['user']?['name'] as String? ?? 'Employee',
      employeeCode: empCode,
      employeePosition: empPos,
      employeePhoto: empPhoto,
      leaveType: json['leave_type']?['name'] as String? ?? '',
      leaveTypeName: json['leave_type']?['name'] as String? ?? '',
      leaveTypeColor: json['leave_type']?['color'] as String?,
      halfDay: json['half_day'] as bool? ?? false,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      days: double.tryParse(json['total_days']?.toString() ?? '') ?? 1.0,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

// ── Leave Type ──────────────────────────────────────────────────────────────
class LeaveTypeData {
  final int id;
  final String name;
  final String? code;
  final double defaultDays;
  final String? color;
  final bool isActive;
  final bool isPaid;
  final bool carryForward;
  final bool requiresDocument;
  final bool isProrated;
  final int? minimumTenureDays;
  final bool allowHalfDay;
  final int noticePeriodDays;
  final int? maxConsecutiveDays;
  final int sortOrder;
  final int? maxCarryForward;
  final String genderSpecific;

  const LeaveTypeData({
    required this.id,
    required this.name,
    this.code,
    required this.defaultDays,
    this.color,
    this.isActive = true,
    this.isPaid = true,
    this.carryForward = false,
    this.requiresDocument = false,
    this.isProrated = false,
    this.minimumTenureDays,
    this.allowHalfDay = false,
    this.noticePeriodDays = 0,
    this.maxConsecutiveDays,
    this.sortOrder = 0,
    this.maxCarryForward,
    this.genderSpecific = 'all',
  });

  factory LeaveTypeData.fromJson(Map<String, dynamic> json) {
    return LeaveTypeData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      defaultDays:
          double.tryParse(json['default_days']?.toString() ?? '') ??
          double.tryParse(json['days_per_year']?.toString() ?? '') ??
          0,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isPaid: json['is_paid'] as bool? ?? true,
      carryForward: json['carry_forward'] as bool? ?? false,
      requiresDocument: json['requires_document'] as bool? ?? false,
      isProrated: json['is_prorated'] as bool? ?? false,
      minimumTenureDays: int.tryParse(
        json['minimum_tenure_days']?.toString() ?? '',
      ),
      allowHalfDay: json['allow_half_day'] as bool? ?? false,
      noticePeriodDays:
          int.tryParse(json['notice_period_days']?.toString() ?? '') ?? 0,
      maxConsecutiveDays: int.tryParse(
        json['max_consecutive_days']?.toString() ?? '',
      ),
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      maxCarryForward: int.tryParse(
        json['max_carry_forward']?.toString() ?? '',
      ),
      genderSpecific: json['gender_specific'] as String? ?? 'all',
    );
  }
}

// ── Leave Balance ───────────────────────────────────────────────────────────
class LeaveBalanceData {
  final int id;
  final String employeeName;
  final String? employeeCode;
  final String? employeePosition;
  final String? employeeAvatar;
  final String leaveTypeName;
  final int year;
  final double allocatedDays;
  final double carriedForward;
  final double usedDays;

  const LeaveBalanceData({
    required this.id,
    required this.employeeName,
    this.employeeCode,
    this.employeePosition,
    this.employeeAvatar,
    required this.leaveTypeName,
    required this.year,
    required this.allocatedDays,
    required this.carriedForward,
    required this.usedDays,
  });

  factory LeaveBalanceData.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    String empName = '';
    String? empCode;
    String? empPos;
    String? empPhoto;

    if (emp != null) {
      if (emp['full_name'] != null && emp['full_name'].toString().isNotEmpty) {
        empName = emp['full_name'].toString();
      } else if (emp['khmer_name'] != null &&
          emp['khmer_name'].toString().isNotEmpty) {
        empName = emp['khmer_name'].toString();
      } else if (emp['user'] != null && emp['user']['name'] != null) {
        empName = emp['user']['name'].toString();
      } else if (emp['first_name'] != null) {
        empName = '${emp['first_name']} ${emp['last_name'] ?? ''}'.trim();
      }
      empCode = emp['employee_id']?.toString() ?? emp['code']?.toString();

      if (emp['position'] != null && emp['position'] is Map) {
        empPos = emp['position']['name']?.toString();
      } else if (emp['designation'] != null && emp['designation'] is Map) {
        empPos = emp['designation']['name']?.toString();
      } else if (emp['position'] != null && emp['position'] is String) {
        empPos = emp['position'].toString();
      } else if (emp['job_title'] != null) {
        empPos = emp['job_title'].toString();
      }

      empPhoto =
          emp['profile_photo_url']?.toString() ??
          emp['photo']?.toString() ??
          emp['avatar']?.toString();
    }

    return LeaveBalanceData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeName: empName.isNotEmpty
          ? empName
          : json['user']?['name'] as String? ?? 'Employee',
      employeeCode: empCode,
      employeePosition: empPos,
      employeeAvatar: empPhoto,
      leaveTypeName: json['leave_type']?['name'] as String? ?? '',
      year: int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      allocatedDays:
          double.tryParse(json['allocated_days']?.toString() ?? '') ?? 0,
      carriedForward:
          double.tryParse(json['carried_forward']?.toString() ?? '') ?? 0,
      usedDays: double.tryParse(json['used_days']?.toString() ?? '') ?? 0,
    );
  }
}

// ── Daily Schedule ───────────────────────────────────────────────────────────
class DailySchedule {
  final bool isWorking;
  final String start;
  final String end;
  final String? breakStart;
  final String? breakEnd;

  const DailySchedule({
    required this.isWorking,
    required this.start,
    required this.end,
    this.breakStart,
    this.breakEnd,
  });

  factory DailySchedule.fromJson(Map<String, dynamic> json) {
    return DailySchedule(
      isWorking: json['is_working'] as bool? ?? true,
      start: json['start'] as String? ?? '09:00',
      end: json['end'] as String? ?? '17:00',
      breakStart: json['break_start'] as String?,
      breakEnd: json['break_end'] as String?,
    );
  }
}

// ── Shift ───────────────────────────────────────────────────────────────────
class ShiftData {
  final int id;
  final String name;
  final String? code;
  final Map<String, DailySchedule>? schedule;
  final int gracePeriod;
  final int overtimeThreshold;
  final bool isOvernight;
  final bool isActive;
  final int? employeesCount;

  const ShiftData({
    required this.id,
    required this.name,
    this.code,
    this.schedule,
    this.gracePeriod = 15,
    this.overtimeThreshold = 30,
    this.isOvernight = false,
    this.isActive = true,
    this.employeesCount,
  });

  factory ShiftData.fromJson(Map<String, dynamic> json) {
    Map<String, DailySchedule>? schedule;
    if (json['schedule'] != null && json['schedule'] is Map) {
      schedule = (json['schedule'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, DailySchedule.fromJson(v as Map<String, dynamic>)),
      );
    }
    return ShiftData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      schedule: schedule,
      gracePeriod: int.tryParse(json['grace_period']?.toString() ?? '') ?? 15,
      overtimeThreshold:
          int.tryParse(json['overtime_threshold']?.toString() ?? '') ?? 30,
      isOvernight: json['is_overnight'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      employeesCount:
          int.tryParse(json['employees_count']?.toString() ?? '') ??
          int.tryParse(json['assignments_count']?.toString() ?? ''),
    );
  }

  /// Convenience: list of working day names (e.g. ['monday', 'tuesday', ...])
  List<String> get workDays =>
      schedule?.entries
          .where((e) => e.value.isWorking)
          .map((e) => e.key)
          .toList() ??
      [];

  /// Number of working days
  int get workingDaysCount => workDays.length;

  /// First working day's start time (convenience for single-shift-day UIs)
  String get startTime {
    final s = schedule;
    if (s == null) return '09:00';
    final entry = s.entries.cast<MapEntry<String, DailySchedule>>().firstWhere(
      (e) => e.value.isWorking,
      orElse: () => const MapEntry(
        'monday',
        DailySchedule(isWorking: true, start: '09:00', end: '17:00'),
      ),
    );
    return entry.value.start;
  }

  /// First working day's end time
  String get endTime {
    final s = schedule;
    if (s == null) return '17:00';
    final entry = s.entries.cast<MapEntry<String, DailySchedule>>().firstWhere(
      (e) => e.value.isWorking,
      orElse: () => const MapEntry(
        'monday',
        DailySchedule(isWorking: true, start: '09:00', end: '17:00'),
      ),
    );
    return entry.value.end;
  }

  /// Break duration in minutes derived from first working day
  int? get breakDuration {
    final s = schedule;
    if (s == null) return null;
    final entry = s.entries.cast<MapEntry<String, DailySchedule>>().firstWhere(
      (e) =>
          e.value.isWorking &&
          e.value.breakStart != null &&
          e.value.breakEnd != null,
      orElse: () => const MapEntry(
        '',
        DailySchedule(isWorking: true, start: '', end: ''),
      ),
    );
    if (entry.key.isEmpty ||
        entry.value.breakStart == null ||
        entry.value.breakEnd == null) {
      return null;
    }
    final startParts = entry.value.breakStart!
        .split(':')
        .map(int.parse)
        .toList();
    final endParts = entry.value.breakEnd!.split(':').map(int.parse).toList();
    return (endParts[0] * 60 + endParts[1]) -
        (startParts[0] * 60 + startParts[1]);
  }
}

class ShiftAssignmentData {
  final int id;
  final int employeeId;
  final int shiftId;
  final String? effectiveDate;
  final String? endDate;
  final String? shiftName;
  final String? employeeName;
  final String? employeeCode;
  final String? employeePosition;
  final String? employeePhoto;
  final Map<String, dynamic>? shiftSchedule;

  const ShiftAssignmentData({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    this.effectiveDate,
    this.endDate,
    this.shiftName,
    this.employeeName,
    this.employeeCode,
    this.employeePosition,
    this.employeePhoto,
    this.shiftSchedule,
  });

  factory ShiftAssignmentData.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    String? empName;
    String? empCode;
    String? empPos;
    String? empPhoto;

    if (emp != null) {
      if (emp['full_name'] != null && emp['full_name'].toString().isNotEmpty) {
        empName = emp['full_name'].toString();
      } else if (emp['khmer_name'] != null &&
          emp['khmer_name'].toString().isNotEmpty) {
        empName = emp['khmer_name'].toString();
      } else if (emp['user'] != null && emp['user']['name'] != null) {
        empName = emp['user']['name'].toString();
      } else if (emp['first_name'] != null) {
        empName = '${emp['first_name']} ${emp['last_name'] ?? ''}'.trim();
      }
      empCode = emp['employee_id']?.toString() ?? emp['code']?.toString();

      if (emp['position'] != null && emp['position'] is Map) {
        empPos = emp['position']['name']?.toString();
      } else if (emp['designation'] != null && emp['designation'] is Map) {
        empPos = emp['designation']['name']?.toString();
      } else if (emp['position'] != null && emp['position'] is String) {
        empPos = emp['position'].toString();
      } else if (emp['job_title'] != null) {
        empPos = emp['job_title'].toString();
      }

      empPhoto = emp['profile_photo_url']?.toString() ??
          emp['photo']?.toString() ??
          emp['avatar']?.toString();
    }

    final shiftObj = json['shift'];
    Map<String, dynamic>? sched;
    if (shiftObj != null && shiftObj['schedule'] != null) {
      if (shiftObj['schedule'] is Map) {
        sched = Map<String, dynamic>.from(shiftObj['schedule']);
      } else if (shiftObj['schedule'] is String) {
        try {
          final decoded = jsonDecode(shiftObj['schedule']);
          if (decoded is Map) {
            sched = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return ShiftAssignmentData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeId: int.tryParse(json['employee_id']?.toString() ?? '') ?? 0,
      shiftId: int.tryParse(json['shift_id']?.toString() ?? '') ?? 0,
      effectiveDate: json['effective_date']?.toString(),
      endDate: json['end_date']?.toString(),
      shiftName: shiftObj?['name']?.toString(),
      employeeName: empName,
      employeeCode: empCode,
      employeePosition: empPos,
      employeePhoto: empPhoto,
      shiftSchedule: sched,
    );
  }
}

// ── Holiday ─────────────────────────────────────────────────────────────────
class HolidayData {
  final int id;
  final String name;
  final String date;
  final String type;
  final String? description;
  final bool isRecurring;

  const HolidayData({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.description,
    this.isRecurring = false,
  });

  factory HolidayData.fromJson(Map<String, dynamic> json) {
    return HolidayData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'company',
      description: json['description'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
    );
  }
}

// ── Performance Review ─────────────────────────────────────────────────────
class PerformanceReviewData {
  final int id;
  final String employeeName;
  final String? period;
  final double? score;
  final String status;
  final String? reviewDate;

  const PerformanceReviewData({
    required this.id,
    required this.employeeName,
    this.period,
    this.score,
    required this.status,
    this.reviewDate,
  });

  factory PerformanceReviewData.fromJson(Map<String, dynamic> json) {
    return PerformanceReviewData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeName:
          json['employee']?['name'] as String? ??
          (json['employee'] != null && json['employee']['first_name'] != null
              ? '${json['employee']['first_name']} ${json['employee']['last_name'] ?? ''}'
                    .trim()
              : null) ??
          '',
      period: json['period'] as String?,
      score: double.tryParse(json['score']?.toString() ?? ''),
      status: json['status'] as String? ?? 'draft',
      reviewDate: json['review_date'] as String?,
    );
  }
}

// ── Training Course ────────────────────────────────────────────────────────
class TrainingCourseData {
  final int id;
  final String title;
  final String? description;
  final int? enrolledCount;
  final String status;

  const TrainingCourseData({
    required this.id,
    required this.title,
    this.description,
    this.enrolledCount,
    required this.status,
  });

  factory TrainingCourseData.fromJson(Map<String, dynamic> json) {
    return TrainingCourseData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      enrolledCount: int.tryParse(json['enrolled_count']?.toString() ?? ''),
      status: json['status'] as String? ?? 'active',
    );
  }
}

// ── Payroll Run ─────────────────────────────────────────────────────────────
class PayrollRunData {
  final int id;
  final String period;
  final String periodStart;
  final String periodEnd;
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
  final double totalAmount;
  final int employeesCount;
  final String status;

  const PayrollRunData({
    required this.id,
    required this.period,
    this.periodStart = '',
    this.periodEnd = '',
    this.totalGross = 0.0,
    this.totalDeductions = 0.0,
    this.totalNet = 0.0,
    required this.totalAmount,
    required this.employeesCount,
    required this.status,
  });

  factory PayrollRunData.fromJson(Map<String, dynamic> json) {
    final net =
        double.tryParse(json['total_net']?.toString() ?? '') ??
        double.tryParse(json['total_amount']?.toString() ?? '') ??
        double.tryParse(json['net_salary']?.toString() ?? '') ??
        0.0;
    return PayrollRunData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      period:
          json['period'] as String? ?? json['payroll_period'] as String? ?? '',
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      totalGross: double.tryParse(json['total_gross']?.toString() ?? '') ?? 0.0,
      totalDeductions:
          double.tryParse(json['total_deductions']?.toString() ?? '') ?? 0.0,
      totalNet: net,
      totalAmount: net,
      employeesCount:
          int.tryParse(
            json['total_employees']?.toString() ??
                json['employees_count']?.toString() ??
                '',
          ) ??
          0,
      status: json['status'] as String? ?? 'draft',
    );
  }
}

// ── Payroll Run Detail ──────────────────────────────────────────────────────
class PayrollRunDetailData {
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
  final String status;
  final int totalEmployees;

  const PayrollRunDetailData({
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
    required this.status,
    required this.totalEmployees,
  });

  factory PayrollRunDetailData.fromJson(Map<String, dynamic> json) {
    return PayrollRunDetailData(
      totalGross: double.tryParse(json['total_gross']?.toString() ?? '') ?? 0,
      totalDeductions:
          double.tryParse(json['total_deductions']?.toString() ?? '') ?? 0,
      totalNet: double.tryParse(json['total_net']?.toString() ?? '') ?? 0,
      status: json['status'] as String? ?? 'draft',
      totalEmployees:
          int.tryParse(json['total_employees']?.toString() ?? '') ?? 0,
    );
  }
}

// ── Admin Payslip Detail ────────────────────────────────────────────────────
class AdminPayslipDetailData {
  final String employeeName;
  final String department;
  final double netSalary;
  final double basicSalary;
  final double overtimePay;
  final double allowances;
  final double otherEarnings;
  final double grossSalary;
  final double taxDeduction;
  final double insuranceDeduction;
  final double lateDeduction;
  final double earlyLeaveDeduction;
  final double otherDeductions;
  final double totalDeductions;
  final int workingDays;
  final int presentDays;
  final int lateDays;
  final int overtimeHours;

  const AdminPayslipDetailData({
    required this.employeeName,
    required this.department,
    required this.netSalary,
    required this.basicSalary,
    required this.overtimePay,
    required this.allowances,
    required this.otherEarnings,
    required this.grossSalary,
    required this.taxDeduction,
    required this.insuranceDeduction,
    required this.lateDeduction,
    this.earlyLeaveDeduction = 0,
    required this.otherDeductions,
    required this.totalDeductions,
    required this.workingDays,
    required this.presentDays,
    required this.lateDays,
    required this.overtimeHours,
  });

  factory AdminPayslipDetailData.fromJson(Map<String, dynamic> json) {
    return AdminPayslipDetailData(
      employeeName:
          json['employee_name'] as String? ??
          json['employee']?['name'] as String? ??
          (json['employee'] != null && json['employee']['first_name'] != null
              ? '${json['employee']['first_name']} ${json['employee']['last_name'] ?? ''}'
                    .trim()
              : null) ??
          '',
      department:
          json['department'] as String? ??
          json['employee']?['department']?['name'] as String? ??
          '',
      netSalary: double.tryParse(json['net_salary']?.toString() ?? '') ?? 0,
      basicSalary: double.tryParse(json['basic_salary']?.toString() ?? '') ?? 0,
      overtimePay: double.tryParse(json['overtime_pay']?.toString() ?? '') ?? 0,
      allowances: double.tryParse(json['allowances']?.toString() ?? '') ?? 0,
      otherEarnings:
          double.tryParse(json['other_earnings']?.toString() ?? '') ?? 0,
      grossSalary: double.tryParse(json['gross_salary']?.toString() ?? '') ?? 0,
      taxDeduction:
          double.tryParse(json['tax_deduction']?.toString() ?? '') ?? 0,
      insuranceDeduction:
          double.tryParse(json['insurance_deduction']?.toString() ?? '') ?? 0,
      lateDeduction:
          double.tryParse(json['late_deduction']?.toString() ?? '') ?? 0,
      earlyLeaveDeduction:
          double.tryParse(json['early_leave_deduction']?.toString() ?? '') ?? 0,
      otherDeductions:
          double.tryParse(json['other_deductions']?.toString() ?? '') ?? 0,
      totalDeductions:
          double.tryParse(json['total_deductions']?.toString() ?? '') ?? 0,
      workingDays: int.tryParse(json['working_days']?.toString() ?? '') ?? 0,
      presentDays: int.tryParse(json['present_days']?.toString() ?? '') ?? 0,
      lateDays: int.tryParse(json['late_days']?.toString() ?? '') ?? 0,
      overtimeHours:
          int.tryParse(json['overtime_hours']?.toString() ?? '') ?? 0,
    );
  }
}

// ── Payroll Settings ────────────────────────────────────────────────────────
class PayrollSettingsData {
  final bool isCustom;
  final bool overtimeEnabled;
  final double overtimeThreshold;
  final bool lateDeductionEnabled;
  final double halfDayHours;
  final double halfDayDeductionPercentage;
  final String payrollPeriod;
  final int payrollStartDay;
  final String currency;
  final String currencySymbol;

  final int lateGracePeriodMinutes;
  final String lateDeductionType;
  final double lateDeductionRate;

  final String earlyLeaveDeductionType;
  final double earlyLeaveDeductionRate;
  final int earlyLeaveGracePeriodMinutes;

  final double regularOtMultiplier;
  final double restDayOtMultiplier;
  final double publicHolidayOtMultiplier;
  final double companyHolidayOtMultiplier;

  final String earlyClockInPolicy;
  final double preShiftOtMultiplier;
  final int maxPreShiftOtMinutes;

  final bool taxEnabled;
  final double taxRatePercentage;
  final bool insuranceEnabled;
  final double insuranceRatePercentage;

  final String workingDaysType;
  final int fixedWorkingDays;

  const PayrollSettingsData({
    this.isCustom = false,
    required this.overtimeEnabled,
    required this.overtimeThreshold,
    required this.lateDeductionEnabled,
    this.taxEnabled = false,
    this.taxRatePercentage = 0.0,
    this.insuranceEnabled = false,
    this.insuranceRatePercentage = 0.0,
    required this.halfDayHours,
    required this.halfDayDeductionPercentage,
    required this.payrollPeriod,
    required this.payrollStartDay,
    required this.currency,
    required this.currencySymbol,
    required this.lateGracePeriodMinutes,
    required this.lateDeductionType,
    required this.lateDeductionRate,
    required this.earlyLeaveDeductionType,
    required this.earlyLeaveDeductionRate,
    required this.earlyLeaveGracePeriodMinutes,
    required this.regularOtMultiplier,
    required this.restDayOtMultiplier,
    required this.publicHolidayOtMultiplier,
    required this.companyHolidayOtMultiplier,
    required this.earlyClockInPolicy,
    required this.preShiftOtMultiplier,
    required this.maxPreShiftOtMinutes,
    required this.workingDaysType,
    required this.fixedWorkingDays,
  });

  factory PayrollSettingsData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    return PayrollSettingsData(
      isCustom: json['is_custom'] as bool? ?? false,
      overtimeEnabled:
          json['overtime_enabled'] == 1 || json['overtime_enabled'] == true,
      overtimeThreshold: parseDouble(json['overtime_threshold'], 1.0),
      lateDeductionEnabled:
          json['late_deduction_enabled'] == 1 ||
          json['late_deduction_enabled'] == true,
      taxEnabled: json['tax_enabled'] == 1 || json['tax_enabled'] == true,
      taxRatePercentage: parseDouble(json['tax_rate_percentage'], 0.0),
      insuranceEnabled:
          json['insurance_enabled'] == 1 || json['insurance_enabled'] == true,
      insuranceRatePercentage: parseDouble(
        json['insurance_rate_percentage'],
        0.0,
      ),
      halfDayHours: parseDouble(json['half_day_hours'], 4.0),
      halfDayDeductionPercentage: parseDouble(
        json['half_day_deduction_percentage'],
        50.0,
      ),
      payrollPeriod: json['payroll_period'] as String? ?? 'monthly',
      payrollStartDay: parseInt(json['payroll_start_day'], 1),
      currency: json['currency'] as String? ?? 'USD',
      currencySymbol: json['currency_symbol'] as String? ?? '\$',
      lateGracePeriodMinutes: parseInt(json['late_grace_period_minutes'], 15),
      lateDeductionType: json['late_deduction_type'] as String? ?? 'per_minute',
      lateDeductionRate: parseDouble(json['late_deduction_rate'], 1.0),
      earlyLeaveDeductionType:
          json['early_leave_deduction_type'] as String? ?? 'per_minute',
      earlyLeaveDeductionRate: parseDouble(
        json['early_leave_deduction_rate'],
        1.0,
      ),
      earlyLeaveGracePeriodMinutes: parseInt(
        json['early_leave_grace_period_minutes'],
        0,
      ),
      regularOtMultiplier: parseDouble(json['regular_ot_multiplier'], 1.5),
      restDayOtMultiplier: parseDouble(json['rest_day_ot_multiplier'], 2.0),
      publicHolidayOtMultiplier: parseDouble(
        json['public_holiday_ot_multiplier'],
        2.0,
      ),
      companyHolidayOtMultiplier: parseDouble(
        json['company_holiday_ot_multiplier'],
        1.5,
      ),
      earlyClockInPolicy: json['early_clock_in_policy'] as String? ?? 'ignore',
      preShiftOtMultiplier: parseDouble(json['pre_shift_ot_multiplier'], 1.25),
      maxPreShiftOtMinutes: parseInt(json['max_pre_shift_ot_minutes'], 120),
      workingDaysType: json['working_days_type'] as String? ?? 'calendar_days',
      fixedWorkingDays: parseInt(json['fixed_working_days'], 22),
    );
  }
}

// ── Admin Operations Repository ─────────────────────────────────────────────

// ── Dashboard ─────────────────────────────────────────────────────────────
class DashboardKpiData {
  final int totalEmployees;
  final int todayAttendance;
  final int pendingLeaves;
  final int pendingExpenses;
  final int openJobs;
  final int totalAssets;
  final int assignedAssets;
  final double monthlyPayroll;
  final List<RecentActivity> recentActivity;

  const DashboardKpiData({
    required this.totalEmployees,
    required this.todayAttendance,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.openJobs,
    required this.totalAssets,
    required this.assignedAssets,
    required this.monthlyPayroll,
    this.recentActivity = const [],
  });

  factory DashboardKpiData.fromJson(Map<String, dynamic> json) {
    final activityList = json['recent_activity'] as List? ?? [];
    return DashboardKpiData(
      totalEmployees:
          int.tryParse(json['total_employees']?.toString() ?? '') ?? 0,
      todayAttendance:
          int.tryParse(json['today_attendance']?.toString() ?? '') ?? 0,
      pendingLeaves:
          int.tryParse(json['pending_leaves']?.toString() ?? '') ?? 0,
      pendingExpenses:
          int.tryParse(json['pending_expenses']?.toString() ?? '') ?? 0,
      openJobs: int.tryParse(json['open_jobs']?.toString() ?? '') ?? 0,
      totalAssets: int.tryParse(json['total_assets']?.toString() ?? '') ?? 0,
      assignedAssets:
          int.tryParse(json['assigned_assets']?.toString() ?? '') ?? 0,
      monthlyPayroll:
          double.tryParse(json['monthly_payroll']?.toString() ?? '0') ?? 0.0,
      recentActivity: activityList
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentActivity {
  final String type;
  final String message;
  final String time;
  final String? name;
  final String? photo;

  const RecentActivity({
    required this.type,
    required this.message,
    required this.time,
    this.name,
    this.photo,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      time: json['time'] as String? ?? '',
      name: (json['name'] as String?)?.trim(),
      photo: json['photo'] as String?,
    );
  }

  /// The message repeats the name as its prefix; drop it when we render the
  /// name separately. Falls back to the full message if the prefix moves.
  String get action {
    final n = name;
    if (n == null || n.isEmpty || !message.startsWith(n)) return message;
    return message.substring(n.length).trim();
  }
}

class AdminOperationsRepository {
  final ApiRepository _api;
  AdminOperationsRepository({ApiRepository? api})
    : _api = api ?? ApiRepository();

  // ── Dashboard ────────────────────────────────────────────────────────────
  /// Fetch dashboard KPI stats. When [branchId] is provided (Owner impersonation),
  /// the backend scopes all counts to employees in that branch only.
  Future<DashboardKpiData> getDashboardStats({int? branchId}) async {
    final queryParams = <String, dynamic>{};
    if (branchId != null) queryParams['branch_id'] = branchId;
    final response = await _api.get(
      '/company/dashboard',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data =
        response.data['data']?['kpis'] ??
        response.data['kpis'] ??
        response.data;
    return DashboardKpiData.fromJson(data as Map<String, dynamic>);
  }

  // ── Attendance Corrections ──────────────────────────────────────────────
  /// Fetch all attendance logs. When [branchId] is provided, scoped to that branch.
  Future<List<AdminAttendanceRecord>> getAllAttendanceLogs({
    int? branchId,
    String? dateFrom,
    String? dateTo,
    int? departmentId,
    int? employeeId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (branchId != null) queryParams['branch_id'] = branchId;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
    if (departmentId != null) queryParams['department_id'] = departmentId;
    if (employeeId != null) queryParams['employee_id'] = employeeId;
    if (status != null && status.isNotEmpty && status != 'all') queryParams['status'] = status;

    final response = await _api.get(
      '/company/attendance',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    // The API returns { status: 'success', data: { attendances: [...] } }
    // ApiResponse automatically extracts the 'data' field, so response.data is the inner object.
    final dynamic data = response.data['attendances'] ?? [];
    return _parseList(data, AdminAttendanceRecord.fromJson);
  }

  Future<List<AttendanceCorrectionData>> getAttendanceCorrections() async {
    final response = await _api.get('/company/attendance/corrections');
    return _parseList(response.data, AttendanceCorrectionData.fromJson);
  }

  Future<void> approveCorrection(int id) async =>
      _api.post('/company/attendance/corrections/$id/approve');
  Future<void> rejectCorrection(int id) async =>
      _api.post('/company/attendance/corrections/$id/reject');
  Future<void> deleteAttendance(int id) async =>
      _api.delete('/company/attendance/$id');
  Future<void> approveOvertime(int id) async =>
      _api.post('/company/attendance/$id/approve-overtime');
  Future<void> addManualAttendance(Map<String, dynamic> data) async =>
      _api.post('/company/attendance/manual', data: data);
  Future<void> updateAttendance(int id, Map<String, dynamic> data) async =>
      _api.put('/company/attendance/$id', data: data);

  // ── Leave Requests (Admin) ──────────────────────────────────────────────
  /// Fetch all leave requests. When [branchId] is provided, scoped to that branch.
  Future<List<AdminLeaveRequestData>> getAllLeaveRequests({
    String? status,
    int? branchId,
  }) async {
    final queryParams = <String, dynamic>{'status': status};
    if (branchId != null) queryParams['branch_id'] = branchId;
    final response = await _api.get(
      '/company/leave/requests',
      queryParameters: queryParams,
    );
    return _parseList(response.data, AdminLeaveRequestData.fromJson);
  }

  Future<void> approveLeaveRequest(int id, {String? notes}) async =>
      _api.post(
        '/company/leave/requests/$id/approve',
        data: {
          if (notes != null && notes.trim().isNotEmpty)
            'approver_notes': notes.trim(),
        },
      );
  Future<void> rejectLeaveRequest(int id, {String? reason}) async => _api.post(
    '/company/leave/requests/$id/reject',
    data: {
      if (reason != null && reason.trim().isNotEmpty)
        'rejection_reason': reason.trim(),
    },
  );
  Future<void> updateLeaveRequest(int id, Map<String, dynamic> data) async =>
      _api.put('/company/leave/requests/$id', data: data);

  Future<void> createLeaveRequest({
    required int employeeId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    required bool halfDay,
    String? halfDayPeriod,
  }) async => _api.post(
    '/company/leave/requests',
    data: {
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'half_day': halfDay,
      if (halfDay && halfDayPeriod != null) 'half_day_period': halfDayPeriod,
    },
  );

  // ── Leave Types ─────────────────────────────────────────────────────────
  Future<List<LeaveTypeData>> getLeaveTypes() async {
    final response = await _api.get('/company/leave/types');
    return _parseList(response.data, LeaveTypeData.fromJson);
  }

  Future<LeaveTypeData> createLeaveType({
    required String name,
    required double defaultDays,
    String? color,
    String? code,
    bool isPaid = true,
    bool carryForward = false,
    bool requiresDocument = false,
    bool isProrated = false,
    int? minimumTenureDays,
    bool allowHalfDay = false,
    int noticePeriodDays = 0,
    int? maxConsecutiveDays,
    int sortOrder = 0,
    int? maxCarryForward,
    String genderSpecific = 'all',
    bool isActive = true,
  }) async {
    final response = await _api.post(
      '/company/leave/types',
      data: {
        'name': name,
        'days_per_year': defaultDays,
        'color': ?color,
        'code': ?code,
        'is_paid': isPaid,
        'carry_forward': carryForward,
        'requires_document': requiresDocument,
        'is_prorated': isProrated,
        'minimum_tenure_days': minimumTenureDays,
        'allow_half_day': allowHalfDay,
        'notice_period_days': noticePeriodDays,
        'max_consecutive_days': maxConsecutiveDays,
        'sort_order': sortOrder,
        'max_carry_forward': maxCarryForward,
        'gender_specific': genderSpecific,
        'is_active': isActive,
      },
    );
    return LeaveTypeData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLeaveType(int id) async =>
      _api.delete('/company/leave/types/$id');

  // ── Shifts ──────────────────────────────────────────────────────────────
  Future<List<ShiftData>> getShifts() async {
    final response = await _api.get('/company/shifts');
    return _parseList(response.data, ShiftData.fromJson);
  }

  Future<void> createShift({
    required String name,
    required String startTime,
    required String endTime,
    String? code,
    int? breakDuration,
    int? gracePeriod,
    int? overtimeThreshold,
    List<String>? workDays,
    bool? isOvernight,
    bool? isActive,
    Map<String, dynamic>? schedule,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'code': ?code,
      'grace_period': ?gracePeriod,
      'overtime_threshold': ?overtimeThreshold,
      'is_overnight': ?isOvernight,
      'is_active': ?isActive,
    };
    // If schedule is provided, use the new format; otherwise fall back to old params
    if (schedule != null) {
      body['schedule'] = schedule;
    } else {
      body['start_time'] = startTime;
      body['end_time'] = endTime;
      if (breakDuration != null) body['break_duration'] = breakDuration;
      if (workDays != null) body['work_days'] = workDays;
    }
    await _api.post('/company/shifts', data: body);
  }

  Future<void> updateShift(
    int id, {
    required String name,
    required String startTime,
    required String endTime,
    String? code,
    int? breakDuration,
    int? gracePeriod,
    int? overtimeThreshold,
    List<String>? workDays,
    bool? isOvernight,
    bool? isActive,
    Map<String, dynamic>? schedule,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'code': ?code,
      'grace_period': ?gracePeriod,
      'overtime_threshold': ?overtimeThreshold,
      'is_overnight': ?isOvernight,
      'is_active': ?isActive,
    };
    if (schedule != null) {
      body['schedule'] = schedule;
    } else {
      body['start_time'] = startTime;
      body['end_time'] = endTime;
      if (breakDuration != null) body['break_duration'] = breakDuration;
      if (workDays != null) body['work_days'] = workDays;
    }
    await _api.put('/company/shifts/$id', data: body);
  }

  Future<void> deleteShift(int id) async => _api.delete('/company/shifts/$id');
  Future<void> assignShift(
    int shiftId,
    int? employeeId, {
    List<int>? employeeIds,
    String? effectiveDate,
    String? endDate,
  }) async => _api.post(
    '/company/shifts/$shiftId/assign',
    data: {
      if (employeeIds != null && employeeIds.isNotEmpty)
        'employee_ids': employeeIds
      else 'employee_id': ?employeeId,
      'effective_date':
          effectiveDate ?? DateTime.now().toIso8601String().substring(0, 10),
      if (endDate != null && endDate.trim().isNotEmpty)
        'end_date': endDate.trim(),
    },
  );

  Future<List<ShiftAssignmentData>> getShiftAssignments() async {
    final response = await _api.get('/company/shifts/assignments');
    return _parseList(response.data, ShiftAssignmentData.fromJson);
  }

  Future<void> updateShiftAssignment(int id, Map<String, dynamic> data) async =>
      _api.put('/company/shifts/assignments/$id', data: data);

  Future<void> deleteShiftAssignment(int id) async =>
      _api.delete('/company/shifts/assignments/$id');

  // ── Holidays ────────────────────────────────────────────────────────────
  Future<List<HolidayData>> getHolidays() async {
    final response = await _api.get('/company/holidays');
    return _parseList(response.data, HolidayData.fromJson);
  }

  Future<HolidayData> createHoliday({
    required String name,
    required String date,
    required String type,
    String? description,
    bool isRecurring = false,
  }) async {
    final response = await _api.post(
      '/company/holidays',
      data: {
        'name': name,
        'date': date,
        'type': type,
        'description': description,
        'is_recurring': isRecurring,
      },
    );
    return HolidayData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateHoliday(int id, Map<String, dynamic> data) async =>
      _api.put('/company/holidays/$id', data: data);

  Future<void> deleteHoliday(int id) async =>
      _api.delete('/company/holidays/$id');

  // ── Employees (for dropdowns) ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEmployees() async {
    final response = await _api.get('/company/employees');
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Expenses (Admin) ────────────────────────────────────────────────────
  Future<void> approveExpense(int id) async =>
      _api.post('/company/expenses/$id/approve');
  Future<void> rejectExpense(int id, {String? reason}) async =>
      _api.post('/company/expenses/$id/reject', data: {'reason': ?reason});
  Future<void> deleteExpense(int id) async =>
      _api.delete('/company/expenses/$id');
  Future<void> markExpensePaid(int id) async =>
      _api.post('/company/expenses/$id/pay');
  Future<void> updateExpense(int id, Map<String, dynamic> data) async =>
      _api.put('/company/expenses/$id', data: data);
  Future<void> updateLeaveType(int id, Map<String, dynamic> data) async =>
      _api.put('/company/leave/types/$id', data: data);

  // ── Leave Balances (Admin) ──────────────────────────────────────────────
  Future<List<LeaveBalanceData>> getLeaveBalances() async {
    final response = await _api.get('/company/leave/balances');

    dynamic data = response.data;
    if (data is Map<String, dynamic> && data['balances'] != null) {
      data = data['balances'];
    }

    return _parseList(data, LeaveBalanceData.fromJson);
  }

  Future<void> updateLeaveBalance(int id, Map<String, dynamic> data) async =>
      _api.put('/company/leave/balances/$id', data: data);

  Future<void> createLeaveBalance({
    required int employeeId,
    required int leaveTypeId,
    required int year,
    required double allocatedDays,
    double carriedForward = 0,
  }) async => _api.post(
    '/company/leave/balances',
    data: {
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'year': year,
      'allocated_days': allocatedDays,
      'carried_forward': carriedForward,
    },
  );

  Future<void> bulkAssignLeaveBalance({
    List<int> employeeIds = const [],
    bool assignAll = false,
    required int leaveTypeId,
    required int year,
    required double allocatedDays,
    double carriedForward = 0,
  }) async => _api.post(
    '/company/leave/balances/bulk-assign',
    data: {
      'employee_ids': employeeIds,
      'assign_all': assignAll,
      'leave_type_id': leaveTypeId,
      'year': year,
      'allocated_days': allocatedDays,
      'carried_forward': carriedForward,
    },
  );

  // ── Performance ─────────────────────────────────────────────────────────
  Future<List<PerformanceReviewData>> getReviews({int? branchId}) async {
    final queryParams = <String, dynamic>{};
    if (branchId != null) queryParams['branch_id'] = branchId;
    final response = await _api.get(
      '/company/performance/reviews',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return _parseList(response.data, PerformanceReviewData.fromJson);
  }

  Future<List<TrainingCourseData>> getTrainings() async {
    final response = await _api.get('/company/performance/trainings');
    return _parseList(response.data, TrainingCourseData.fromJson);
  }

  Future<TrainingCourseData> createTraining({
    required String title,
    String? description,
  }) async {
    final response = await _api.post(
      '/company/performance/trainings',
      data: {'title': title, 'description': ?description},
    );
    return TrainingCourseData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTraining(int id) async =>
      _api.delete('/company/performance/trainings/$id');
  Future<void> enrollEmployee(int trainingId, int employeeId) async =>
      _api.post(
        '/company/performance/trainings/$trainingId/enroll',
        data: {'employee_id': employeeId},
      );

  // ── Payroll (Admin) ─────────────────────────────────────────────────────
  Future<List<PayrollRunData>> getPayrollRuns() async {
    final response = await _api.get('/company/payroll/runs');
    return _parseList(response.data, PayrollRunData.fromJson);
  }

  Future<void> generatePayroll({
    required String periodStart,
    required String periodEnd,
  }) async {
    await _api.post(
      '/company/payroll/generate',
      data: {'period_start': periodStart, 'period_end': periodEnd},
    );
  }

  Future<void> updatePayrollRunStatus(int id, String status) async {
    await _api.post(
      '/company/payroll/runs/$id/status',
      data: {'status': status},
    );
  }

  Future<void> deletePayrollRun(int id) async {
    await _api.delete('/company/payroll/runs/$id');
  }

  Future<PayrollSettingsData> getPayrollSettings() async {
    final response = await _api.get('/company/payroll/settings');
    return PayrollSettingsData.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> updatePayrollSettings(Map<String, dynamic> data) async {
    await _api.put('/company/payroll/settings', data: data);
  }

  Future<PayrollSettingsData> getCompanyFormulas() async {
    final response = await _api.get('/company/payroll/formulas');
    return PayrollSettingsData.fromJson(response.data['data'] ?? response.data);
  }

  Future<PayrollSettingsData> getBranchPayrollSettings(int branchId) async {
    final response = await _api.get(
      '/company/branches/$branchId/payroll-settings',
    );
    return PayrollSettingsData.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> updateBranchPayrollSettings(
    int branchId,
    Map<String, dynamic> data,
  ) async {
    await _api.put('/company/branches/$branchId/payroll-settings', data: data);
  }

  Future<PayrollSettingsData> getBranchFormulas(int branchId) async {
    final response = await _api.get('/company/branches/$branchId/formulas');
    return PayrollSettingsData.fromJson(response.data['data'] ?? response.data);
  }

  Future<PayrollRunDetailData> getPayrollRunDetail(String period) async {
    final response = await _api.get('/company/payroll/payslips/$period');
    final data = response.data['payroll_run'] ?? response.data;
    return PayrollRunDetailData.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<List<AdminPayslipDetailData>> getPayslipsForRun(String period, {int? branchId}) async {
    final queryParams = <String, dynamic>{};
    if (branchId != null) queryParams['branch_id'] = branchId;
    final response = await _api.get(
      '/company/payroll/payslips/$period',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return _parseList(
      response.data['payslips'] ?? response.data,
      AdminPayslipDetailData.fromJson,
    );
  }

  Future<String> exportPayroll(String period) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'payroll_${period}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final savePath = '${dir.path}/$filename';

    await _api.download(
      '/company/payroll/export/$period',
      savePath,
      method: 'GET',
    );
    return savePath;
  }

  // ── Documents (Admin) ───────────────────────────────────────────────────
  Future<void> deleteDocument(int id) async =>
      _api.delete('/company/documents/$id');

  // ── Announcements (Admin) ───────────────────────────────────────────────
  Future<void> publishAnnouncement(int id) async =>
      _api.post('/company/announcements/$id/publish');
  Future<void> unpublishAnnouncement(int id) async =>
      _api.post('/company/announcements/$id/unpublish');

  // ── Policies (Admin) ────────────────────────────────────────────────────
  Future<void> publishPolicy(int id) async =>
      _api.post('/company/policies/$id/publish');
  Future<void> archivePolicy(int id) async =>
      _api.post('/company/policies/$id/archive');

  // ── Reports ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateReport({
    required String type,
    Map<String, dynamic>? params,
  }) async {
    final response = await _api.post(
      '/company/reports/generate',
      data: {'type': type, ...?params},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    // API returns { data: { type, total, records }, columns, summary } from web controller
    // or { data: { type, total, records } } from API controller
    // Normalize the structure
    final inner = data['data'] is Map
        ? data['data'] as Map<String, dynamic>
        : data;
    return {
      'type': inner['type'] ?? type,
      'total': inner['total'] ?? data['total'] ?? 0,
      'records': inner['records'] ?? data['records'] ?? data['data'] ?? [],
      'columns': data['columns'] ?? inner['columns'] ?? [],
      'summary': data['summary'] ?? inner['summary'] ?? [],
    };
  }

  Future<String> exportReport({
    required String type,
    String format = 'excel',
    Map<String, dynamic>? params,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = format == 'pdf' ? 'pdf' : (format == 'csv' ? 'csv' : 'xlsx');
    final filename =
        '${type}_report_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final savePath = '${dir.path}/$filename';

    await _api.download(
      '/company/reports/export',
      savePath,
      method: 'POST',
      data: {'type': type, 'format': format, ...?params},
    );
    return savePath;
  }

  // ── Report filter data ──────────────────────────────────────────────────
  Future<Map<String, List<Map<String, dynamic>>>> getReportFilters() async {
    final response = await _api.get('/company/reports/filters');
    final data = response.data as Map<String, dynamic>? ?? {};
    final inner = data['data'] is Map
        ? data['data'] as Map<String, dynamic>
        : data;
    return {
      'departments':
          (inner['departments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      'branches':
          (inner['branches'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      'employees':
          (inner['employees'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    };
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> sendNotification({
    required int userId,
    required String title,
    required String message,
    String? type,
  }) async {
    await _api.post(
      '/company/notifications/send',
      data: {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
