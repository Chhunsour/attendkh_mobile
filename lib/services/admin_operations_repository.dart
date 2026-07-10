import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:path_provider/path_provider.dart';

// ── Common Models ────────────────────────────────────────────────────────────
// ── Attendance Correction ───────────────────────────────────────────────────
class AttendanceCorrectionData {
  final int id;
  final String employeeName;
  final String date;
  final String? reason;
  final String status;
  final String? clockIn;
  final String? clockOut;

  const AttendanceCorrectionData({required this.id, required this.employeeName, required this.date, this.reason, required this.status, this.clockIn, this.clockOut});

  factory AttendanceCorrectionData.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionData(
      id: json['id'] as int,
      employeeName: json['employee']?['name'] as String? ?? json['user']?['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      clockIn: json['clock_in'] as String? ?? json['requested_clock_in'] as String?,
      clockOut: json['clock_out'] as String? ?? json['requested_clock_out'] as String?,
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

  const AdminAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
    this.workHours,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceRecord(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      employeeName: json['employee']?['user']?['name'] ?? json['employee']?['first_name'] ?? 'Unknown',
      date: json['date'] as String? ?? '',
      clockIn: json['clock_in'] as String?,
      clockOut: json['clock_out'] as String?,
      status: json['status'] as String? ?? 'absent',
      workHours: (json['work_hours'] as num?)?.toDouble(),
    );
  }
}

// ── Admin Leave Request ─────────────────────────────────────────────────────
class AdminLeaveRequestData {
  final int id;
  final String employeeName;
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
    return AdminLeaveRequestData(
      id: json['id'] as int,
      employeeName: json['employee']?['name'] as String? ?? json['user']?['name'] as String? ?? '',
      leaveType: json['leave_type']?['name'] as String? ?? '',
      leaveTypeName: json['leave_type']?['name'] as String? ?? '',
      leaveTypeColor: json['leave_type']?['color'] as String?,
      halfDay: json['half_day'] as bool? ?? false,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      days: (json['days'] as num?)?.toDouble() ?? (json['total_days'] as num?)?.toDouble() ?? 0,
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
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      defaultDays: (json['default_days'] as num?)?.toDouble() ?? (json['days_per_year'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isPaid: json['is_paid'] as bool? ?? true,
      carryForward: json['carry_forward'] as bool? ?? false,
      requiresDocument: json['requires_document'] as bool? ?? false,
      isProrated: json['is_prorated'] as bool? ?? false,
      minimumTenureDays: json['minimum_tenure_days'] as int?,
      allowHalfDay: json['allow_half_day'] as bool? ?? false,
      noticePeriodDays: json['notice_period_days'] as int? ?? 0,
      maxConsecutiveDays: json['max_consecutive_days'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      maxCarryForward: json['max_carry_forward'] as int?,
      genderSpecific: json['gender_specific'] as String? ?? 'all',
    );
  }
}

// ── Leave Balance ───────────────────────────────────────────────────────────
class LeaveBalanceData {
  final int id;
  final String employeeName;
  final String leaveTypeName;
  final int year;
  final double allocatedDays;
  final double carriedForward;
  final double usedDays;

  const LeaveBalanceData({required this.id, required this.employeeName, required this.leaveTypeName, required this.year, required this.allocatedDays, required this.carriedForward, required this.usedDays});

  factory LeaveBalanceData.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceData(
      id: json['id'] as int,
      employeeName: json['employee']?['name'] as String? ?? '',
      leaveTypeName: json['leave_type']?['name'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      allocatedDays: (json['allocated_days'] as num?)?.toDouble() ?? 0,
      carriedForward: (json['carried_forward'] as num?)?.toDouble() ?? 0,
      usedDays: (json['used_days'] as num?)?.toDouble() ?? 0,
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
        (k, v) => MapEntry(k, DailySchedule.fromJson(v as Map<String, dynamic>)),
      );
    }
    return ShiftData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      schedule: schedule,
      gracePeriod: json['grace_period'] as int? ?? 15,
      overtimeThreshold: json['overtime_threshold'] as int? ?? 30,
      isOvernight: json['is_overnight'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      employeesCount: json['employees_count'] as int? ?? json['assignments_count'] as int?,
    );
  }

  /// Convenience: list of working day names (e.g. ['monday', 'tuesday', ...])
  List<String> get workDays =>
      schedule?.entries.where((e) => e.value.isWorking).map((e) => e.key).toList() ?? [];

  /// Number of working days
  int get workingDaysCount => workDays.length;

  /// First working day's start time (convenience for single-shift-day UIs)
  String get startTime {
    final s = schedule;
    if (s == null) return '09:00';
    final entry = s.entries.cast<MapEntry<String, DailySchedule>>().firstWhere(
      (e) => e.value.isWorking,
      orElse: () => const MapEntry('monday', DailySchedule(isWorking: true, start: '09:00', end: '17:00')),
    );
    return entry.value.start;
  }

  /// First working day's end time
  String get endTime {
    final s = schedule;
    if (s == null) return '17:00';
    final entry = s.entries.cast<MapEntry<String, DailySchedule>>().firstWhere(
      (e) => e.value.isWorking,
      orElse: () => const MapEntry('monday', DailySchedule(isWorking: true, start: '09:00', end: '17:00')),
    );
    return entry.value.end;
  }

  /// Break duration in minutes derived from first working day
  int? get breakDuration {
    final s = schedule;
    if (s == null) return null;
    final entry = s.entries.cast<MapEntry<String, DailySchedule>>().firstWhere(
      (e) => e.value.isWorking && e.value.breakStart != null && e.value.breakEnd != null,
      orElse: () => const MapEntry('', DailySchedule(isWorking: true, start: '', end: '')),
    );
    if (entry.key.isEmpty || entry.value.breakStart == null || entry.value.breakEnd == null) return null;
    final startParts = entry.value.breakStart!.split(':').map(int.parse).toList();
    final endParts = entry.value.breakEnd!.split(':').map(int.parse).toList();
    return (endParts[0] * 60 + endParts[1]) - (startParts[0] * 60 + startParts[1]);
  }
}

// ── Holiday ─────────────────────────────────────────────────────────────────
class HolidayData {
  final int id;
  final String name;
  final String date;
  final String? description;
  final bool isRecurring;

  const HolidayData({required this.id, required this.name, required this.date, this.description, this.isRecurring = false});

  factory HolidayData.fromJson(Map<String, dynamic> json) {
    return HolidayData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
    );
  }
}

// ── Asset ───────────────────────────────────────────────────────────────────
class AssetData {
  final int id;
  final String assetCode;
  final String name;
  final String? category;
  final String? description;
  final String? serialNumber;
  final String? model;
  final String? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final double? calculatedCurrentValue;
  final int? depreciationMonths;
  final String? warrantyExpiryDate;
  final String condition;
  final String status;
  final String? notes;
  final String? assignedTo;
  final String? assignedDate;

  const AssetData({
    required this.id,
    required this.assetCode,
    required this.name,
    this.category,
    this.description,
    this.serialNumber,
    this.model,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.calculatedCurrentValue,
    this.depreciationMonths,
    this.warrantyExpiryDate,
    required this.condition,
    required this.status,
    this.notes,
    this.assignedTo,
    this.assignedDate,
  });

  factory AssetData.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) => v != null ? (v as num).toDouble() : null;

    return AssetData(
      id: json['id'] as int,
      assetCode: json['asset_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      description: json['description'] as String?,
      serialNumber: json['serial_number'] as String?,
      model: json['model'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      purchasePrice: parseDouble(json['purchase_price']),
      currentValue: parseDouble(json['current_value']),
      calculatedCurrentValue: parseDouble(json['calculated_current_value']),
      depreciationMonths: json['depreciation_months'] as int?,
      warrantyExpiryDate: json['warranty_expiry_date'] as String?,
      condition: json['condition'] as String? ?? 'good',
      status: json['status'] as String? ?? 'available',
      notes: json['notes'] as String?,
      assignedTo: json['assigned_to']?['name'] as String? ?? json['current_assignment']?['employee']?['name'] as String?,
      assignedDate: json['assigned_date'] as String?,
    );
  }

  double get displayValue => calculatedCurrentValue ?? currentValue ?? 0.0;
}

// ── Asset Assignment History ────────────────────────────────────────────────
class AssetAssignmentData {
  final int id;
  final String employeeName;
  final String assignedDate;
  final String? returnedDate;
  final String? notes;

  const AssetAssignmentData({required this.id, required this.employeeName, required this.assignedDate, this.returnedDate, this.notes});

  factory AssetAssignmentData.fromJson(Map<String, dynamic> json) {
    return AssetAssignmentData(
      id: json['id'] as int,
      employeeName: json['employee']?['name'] as String? ?? '',
      assignedDate: json['assigned_date'] as String? ?? json['created_at'] as String? ?? '',
      returnedDate: json['returned_date'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

// ── Job Posting ─────────────────────────────────────────────────────────────
class JobPostingData {
  final int id;
  final String title;
  final String? department;
  final String? location;
  final String status;
  final int candidatesCount;
  final String? createdAt;

  const JobPostingData({required this.id, required this.title, this.department, this.location, required this.status, this.candidatesCount = 0, this.createdAt});

  factory JobPostingData.fromJson(Map<String, dynamic> json) {
    return JobPostingData(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      department: json['department']?['name'] as String? ?? json['department'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'open',
      candidatesCount: json['candidates_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }
}

// ── Candidate ──────────────────────────────────────────────────────────────
class CandidateData {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String stage;
  final String? appliedJob;

  const CandidateData({required this.id, required this.name, this.email, this.phone, required this.stage, this.appliedJob});

  factory CandidateData.fromJson(Map<String, dynamic> json) {
    return CandidateData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      stage: json['stage'] as String? ?? json['status'] as String? ?? 'applied',
      appliedJob: json['job']?['title'] as String?,
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

  const PerformanceReviewData({required this.id, required this.employeeName, this.period, this.score, required this.status, this.reviewDate});

  factory PerformanceReviewData.fromJson(Map<String, dynamic> json) {
    return PerformanceReviewData(
      id: json['id'] as int,
      employeeName: json['employee']?['name'] as String? ?? '',
      period: json['period'] as String?,
      score: (json['score'] as num?)?.toDouble(),
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

  const TrainingCourseData({required this.id, required this.title, this.description, this.enrolledCount, required this.status});

  factory TrainingCourseData.fromJson(Map<String, dynamic> json) {
    return TrainingCourseData(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      enrolledCount: json['enrolled_count'] as int?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

// ── Payroll Run ─────────────────────────────────────────────────────────────
class PayrollRunData {
  final int id;
  final String period;
  final double totalAmount;
  final int employeesCount;
  final String status;

  const PayrollRunData({required this.id, required this.period, required this.totalAmount, required this.employeesCount, required this.status});

  factory PayrollRunData.fromJson(Map<String, dynamic> json) {
    return PayrollRunData(
      id: json['id'] as int,
      period: json['period'] as String? ?? json['payroll_period'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? (json['net_salary'] as num?)?.toDouble() ?? 0,
      employeesCount: json['employees_count'] as int? ?? 0,
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
      totalGross: (json['total_gross'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['total_deductions'] as num?)?.toDouble() ?? 0,
      totalNet: (json['total_net'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'draft',
      totalEmployees: json['total_employees'] as int? ?? 0,
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
    required this.otherDeductions,
    required this.totalDeductions,
    required this.workingDays,
    required this.presentDays,
    required this.lateDays,
    required this.overtimeHours,
  });

  factory AdminPayslipDetailData.fromJson(Map<String, dynamic> json) {
    return AdminPayslipDetailData(
      employeeName: json['employee_name'] as String? ?? json['employee']?['name'] as String? ?? '',
      department: json['department'] as String? ?? json['employee']?['department']?['name'] as String? ?? '',
      netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0,
      basicSalary: (json['basic_salary'] as num?)?.toDouble() ?? 0,
      overtimePay: (json['overtime_pay'] as num?)?.toDouble() ?? 0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0,
      otherEarnings: (json['other_earnings'] as num?)?.toDouble() ?? 0,
      grossSalary: (json['gross_salary'] as num?)?.toDouble() ?? 0,
      taxDeduction: (json['tax_deduction'] as num?)?.toDouble() ?? 0,
      insuranceDeduction: (json['insurance_deduction'] as num?)?.toDouble() ?? 0,
      lateDeduction: (json['late_deduction'] as num?)?.toDouble() ?? 0,
      otherDeductions: (json['other_deductions'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['total_deductions'] as num?)?.toDouble() ?? 0,
      workingDays: json['working_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
      lateDays: json['late_days'] as int? ?? 0,
      overtimeHours: json['overtime_hours'] as int? ?? 0,
    );
  }
}

// ── Payroll Settings ────────────────────────────────────────────────────────
class PayrollSettingsData {
  final bool overtimeEnabled;
  final double overtimeMultiplier;
  final double overtimeThreshold;
  final double weekendOvertimeMultiplier;
  final double holidayOvertimeMultiplier;
  final int maxOvertimeHoursPerDay;
  final int maxOvertimeHoursPerWeek;
  final bool lateDeductionEnabled;
  final double lateDeductionPerMinute;
  final double lateDeductionAmount;
  final String lateDeductionCalculation;
  final int gracePeriodMinutes;
  final String payrollPeriod;
  final int payrollStartDay;
  final int payrollWorkingDays;
  final String currency;
  final String currencySymbol;
  final double halfDayHours;
  final double halfDayDeductionPercentage;

  const PayrollSettingsData({
    required this.overtimeEnabled,
    required this.overtimeMultiplier,
    required this.overtimeThreshold,
    required this.weekendOvertimeMultiplier,
    required this.holidayOvertimeMultiplier,
    required this.maxOvertimeHoursPerDay,
    required this.maxOvertimeHoursPerWeek,
    required this.lateDeductionEnabled,
    required this.lateDeductionPerMinute,
    required this.lateDeductionAmount,
    required this.lateDeductionCalculation,
    required this.gracePeriodMinutes,
    required this.payrollPeriod,
    required this.payrollStartDay,
    required this.payrollWorkingDays,
    required this.currency,
    required this.currencySymbol,
    required this.halfDayHours,
    required this.halfDayDeductionPercentage,
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
      overtimeEnabled: json['overtime_enabled'] == 1 || json['overtime_enabled'] == true,
      overtimeMultiplier: parseDouble(json['overtime_multiplier'], 1.5),
      overtimeThreshold: parseDouble(json['overtime_threshold'], 1.0),
      weekendOvertimeMultiplier: parseDouble(json['weekend_overtime_multiplier'], 2.0),
      holidayOvertimeMultiplier: parseDouble(json['holiday_overtime_multiplier'], 3.0),
      maxOvertimeHoursPerDay: parseInt(json['max_overtime_hours_per_day'], 4),
      maxOvertimeHoursPerWeek: parseInt(json['max_overtime_hours_per_week'], 20),
      lateDeductionEnabled: json['late_deduction_enabled'] == 1 || json['late_deduction_enabled'] == true,
      lateDeductionPerMinute: parseDouble(json['late_deduction_per_minute'], 0.0),
      lateDeductionAmount: parseDouble(json['late_deduction_amount'], 0.0),
      lateDeductionCalculation: json['late_deduction_calculation'] as String? ?? 'flat',
      gracePeriodMinutes: parseInt(json['grace_period_minutes'], 15),
      payrollPeriod: json['payroll_period'] as String? ?? 'monthly',
      payrollStartDay: parseInt(json['payroll_start_day'], 1),
      payrollWorkingDays: parseInt(json['payroll_working_days'], 22),
      currency: json['currency'] as String? ?? 'USD',
      currencySymbol: json['currency_symbol'] as String? ?? '\$',
      halfDayHours: parseDouble(json['half_day_hours'], 4.0),
      halfDayDeductionPercentage: parseDouble(json['half_day_deduction_percentage'], 50.0),
    );
  }
}

// ── Admin Operations Repository ─────────────────────────────────────────────
class AdminOperationsRepository {
  final ApiRepository _api;
  AdminOperationsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  // ── Attendance Corrections ──────────────────────────────────────────────
  Future<List<AdminAttendanceRecord>> getAllAttendanceLogs() async {
    final response = await _api.get('/company/attendance');
    // The response returns { data: { attendances: [...] } }
    final dynamic data = response.data['data']?['attendances'] ?? [];
    return _parseList(data, AdminAttendanceRecord.fromJson);
  }

  Future<List<AttendanceCorrectionData>> getAttendanceCorrections() async {
    final response = await _api.get('/company/attendance/corrections');
    return _parseList(response.data, AttendanceCorrectionData.fromJson);
  }

  Future<void> approveCorrection(int id) async => _api.post('/company/attendance/corrections/$id/approve');
  Future<void> rejectCorrection(int id) async => _api.post('/company/attendance/corrections/$id/reject');
  Future<void> deleteAttendance(int id) async => _api.delete('/company/attendance/$id');

  // ── Leave Requests (Admin) ──────────────────────────────────────────────
  Future<List<AdminLeaveRequestData>> getAllLeaveRequests({String? status}) async {
    final response = await _api.get('/company/leave/requests', queryParameters: {'status': ?status});
    return _parseList(response.data, AdminLeaveRequestData.fromJson);
  }

  Future<void> approveLeaveRequest(int id) async => _api.put('/company/leave/requests/$id/action', data: {'action': 'approve'});
  Future<void> rejectLeaveRequest(int id, {String? reason}) async => _api.put('/company/leave/requests/$id/action', data: {'action': 'reject', 'rejection_reason': ?reason});

  Future<void> createLeaveRequest({
    required int employeeId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    required bool halfDay,
    String? halfDayPeriod,
  }) async => _api.post('/company/leave/requests', data: {
    'employee_id': employeeId,
    'leave_type_id': leaveTypeId,
    'start_date': startDate,
    'end_date': endDate,
    'reason': reason,
    'half_day': halfDay,
    if (halfDay && halfDayPeriod != null) 'half_day_period': halfDayPeriod,
  });

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
    final response = await _api.post('/company/leave/types', data: {
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
    });
    return LeaveTypeData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLeaveType(int id) async => _api.delete('/company/leave/types/$id');

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

  Future<void> updateShift(int id, {
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
  Future<void> assignShift(int shiftId, int employeeId) async => _api.post('/company/shifts/$shiftId/assign', data: {'employee_id': employeeId});

  // ── Holidays ────────────────────────────────────────────────────────────
  Future<List<HolidayData>> getHolidays() async {
    final response = await _api.get('/company/holidays');
    return _parseList(response.data, HolidayData.fromJson);
  }

  Future<HolidayData> createHoliday({required String name, required String date, String? description, bool isRecurring = false}) async {
    final response = await _api.post('/company/holidays', data: {'name': name, 'date': date, 'description': ?description, 'is_recurring': isRecurring});
    return HolidayData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteHoliday(int id) async => _api.delete('/company/holidays/$id');

  // ── Assets ──────────────────────────────────────────────────────────────
  Future<List<AssetData>> getAssets() async {
    final response = await _api.get('/company/assets');
    return _parseList(response.data, AssetData.fromJson);
  }

  Future<AssetData> createAsset({
    required String assetCode,
    required String name,
    String? category,
    String? description,
    String? serialNumber,
    String? model,
    String? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    int? depreciationMonths,
    String? warrantyExpiryDate,
    String? condition,
    String? notes,
  }) async {
    final response = await _api.post('/company/assets', data: {
      'asset_code': assetCode,
      'name': name,
      'category': category,
      'description': description,
      'serial_number': serialNumber,
      'model': model,
      'purchase_date': purchaseDate,
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'depreciation_months': depreciationMonths,
      'warranty_expiry_date': warrantyExpiryDate,
      'condition': condition ?? 'new',
      'notes': notes,
    });
    return AssetData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssetData> updateAsset(int id, {
    String? assetCode,
    String? name,
    String? category,
    String? description,
    String? serialNumber,
    String? model,
    String? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    int? depreciationMonths,
    String? warrantyExpiryDate,
    String? condition,
    String? notes,
  }) async {
    final response = await _api.put('/company/assets/$id', data: {
      'asset_code': ?assetCode,
      'name': ?name,
      'category': ?category,
      'description': ?description,
      'serial_number': ?serialNumber,
      'model': ?model,
      'purchase_date': ?purchaseDate,
      'purchase_price': ?purchasePrice,
      'current_value': ?currentValue,
      'depreciation_months': ?depreciationMonths,
      'warranty_expiry_date': ?warrantyExpiryDate,
      'condition': ?condition,
      'notes': ?notes,
    });
    return AssetData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAsset(int id) async => _api.delete('/company/assets/$id');

  Future<void> assignAsset(int id, int employeeId, {String? conditionAtAssignment}) async =>
      _api.post('/company/assets/$id/assign', data: {
        'employee_id': employeeId,
        'condition_at_assignment': ?conditionAtAssignment,
      });

  Future<void> returnAsset(int id) async => _api.post('/company/assets/$id/return');

  Future<List<AssetAssignmentData>> getAssetHistory(int id) async {
    final response = await _api.get('/company/assets/$id/history');
    return _parseList(response.data, AssetAssignmentData.fromJson);
  }

  // ── Employees (for dropdowns) ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEmployees() async {
    final response = await _api.get('/company/employees');
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['data'] != null) return (data['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  // ── Expenses (Admin) ────────────────────────────────────────────────────
  Future<void> approveExpense(int id) async => _api.post('/company/expenses/$id/approve');
  Future<void> rejectExpense(int id, {String? reason}) async => _api.post('/company/expenses/$id/reject', data: {'reason': ?reason});
  Future<void> deleteExpense(int id) async => _api.delete('/company/expenses/$id');
  Future<void> markExpensePaid(int id) async => _api.post('/company/expenses/$id/pay');
  Future<void> updateExpense(int id, Map<String, dynamic> data) async => _api.put('/company/expenses/$id', data: data);
  Future<void> updateLeaveType(int id, Map<String, dynamic> data) async => _api.put('/company/leave/types/$id', data: data);

  // ── Leave Balances (Admin) ──────────────────────────────────────────────
  Future<List<LeaveBalanceData>> getLeaveBalances() async {
    final response = await _api.get('/company/leave/balances');
    return _parseList(response.data, LeaveBalanceData.fromJson);
  }

  Future<void> updateLeaveBalance(int id, Map<String, dynamic> data) async => _api.put('/company/leave/balances/$id', data: data);

  Future<void> createLeaveBalance({
    required int employeeId,
    required int leaveTypeId,
    required int year,
    required double allocatedDays,
    double carriedForward = 0,
  }) async => _api.post('/company/leave/balances', data: {
    'employee_id': employeeId,
    'leave_type_id': leaveTypeId,
    'year': year,
    'allocated_days': allocatedDays,
    'carried_forward': carriedForward,
  });

  // ── Recruitment ─────────────────────────────────────────────────────────
  Future<List<JobPostingData>> getJobPostings() async {
    final response = await _api.get('/company/recruitment/jobs');
    return _parseList(response.data, JobPostingData.fromJson);
  }

  Future<JobPostingData> createJobPosting({required String title, String? department, String? location, String? description}) async {
    final response = await _api.post('/company/recruitment/jobs', data: {'title': title, 'department': ?department, 'location': ?location, 'description': ?description});
    return JobPostingData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteJobPosting(int id) async => _api.delete('/company/recruitment/jobs/$id');

  Future<List<CandidateData>> getCandidates(int jobId) async {
    final response = await _api.get('/company/recruitment/jobs/$jobId/candidates');
    return _parseList(response.data, CandidateData.fromJson);
  }

  Future<void> updateCandidateStatus(int id, String stage) async => _api.post('/company/recruitment/candidates/$id/status', data: {'stage': stage});

  // ── Performance ─────────────────────────────────────────────────────────
  Future<List<PerformanceReviewData>> getReviews() async {
    final response = await _api.get('/company/performance/reviews');
    return _parseList(response.data, PerformanceReviewData.fromJson);
  }

  Future<List<TrainingCourseData>> getTrainings() async {
    final response = await _api.get('/company/performance/trainings');
    return _parseList(response.data, TrainingCourseData.fromJson);
  }

  Future<TrainingCourseData> createTraining({required String title, String? description}) async {
    final response = await _api.post('/company/performance/trainings', data: {'title': title, 'description': ?description});
    return TrainingCourseData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTraining(int id) async => _api.delete('/company/performance/trainings/$id');
  Future<void> enrollEmployee(int trainingId, int employeeId) async => _api.post('/company/performance/trainings/$trainingId/enroll', data: {'employee_id': employeeId});

  // ── Payroll (Admin) ─────────────────────────────────────────────────────
  Future<List<PayrollRunData>> getPayrollRuns() async {
    final response = await _api.get('/company/payroll/runs');
    return _parseList(response.data, PayrollRunData.fromJson);
  }

  Future<void> generatePayroll({required String periodStart, required String periodEnd}) async {
    await _api.post('/company/payroll/generate', data: {
      'period_start': periodStart,
      'period_end': periodEnd,
    });
  }

  Future<PayrollSettingsData> getPayrollSettings() async {
    final response = await _api.get('/company/payroll/settings');
    return PayrollSettingsData.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> updatePayrollSettings(Map<String, dynamic> data) async {
    await _api.put('/company/payroll/settings', data: data);
  }

  Future<PayrollRunDetailData> getPayrollRunDetail(String period) async {
    final response = await _api.get('/company/payroll/runs/$period');
    final data = response.data['data'] ?? response.data;
    return PayrollRunDetailData.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<List<AdminPayslipDetailData>> getPayslipsForRun(String period) async {
    final response = await _api.get('/company/payroll/runs/$period/payslips');
    return _parseList(response.data, AdminPayslipDetailData.fromJson);
  }

  Future<String> exportPayroll(String period) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'payroll_${period}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final savePath = '${dir.path}/$filename';

    await _api.download(
      '/company/payroll/runs/$period/export',
      savePath,
      data: {'format': 'excel'},
    );
    return savePath;
  }

  // ── Documents (Admin) ───────────────────────────────────────────────────
  Future<void> deleteDocument(int id) async => _api.delete('/company/documents/$id');

  // ── Announcements (Admin) ───────────────────────────────────────────────
  Future<void> publishAnnouncement(int id) async => _api.post('/company/announcements/$id/publish');
  Future<void> unpublishAnnouncement(int id) async => _api.post('/company/announcements/$id/unpublish');

  // ── Policies (Admin) ────────────────────────────────────────────────────
  Future<void> publishPolicy(int id) async => _api.post('/company/policies/$id/publish');
  Future<void> archivePolicy(int id) async => _api.post('/company/policies/$id/archive');

  // ── Reports ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateReport({required String type, Map<String, dynamic>? params}) async {
    final response = await _api.post('/company/reports/generate', data: {'type': type, ...?params});
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<String> exportReport({required String type, Map<String, dynamic>? params}) async {
    final format = 'excel';
    final dir = await getApplicationDocumentsDirectory();
    final filename = '${type}_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final savePath = '${dir.path}/$filename';
    
    await _api.download(
      '/company/reports/export',
      savePath,
      data: {'type': type, 'format': format, ...?params},
    );
    return savePath;
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> sendNotification({required int userId, required String title, required String message, String? type}) async {
    await _api.post('/company/notifications/send', data: {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }

}