class MonthlyAttendanceEmployee {
  final int id;
  final String fullName;
  final String? khmerName;
  final String? employeeId;
  final String? photoUrl;
  final String branch;
  final String department;

  const MonthlyAttendanceEmployee({
    required this.id,
    required this.fullName,
    this.khmerName,
    this.employeeId,
    this.photoUrl,
    required this.branch,
    required this.department,
  });

  factory MonthlyAttendanceEmployee.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceEmployee(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? 'Employee',
      khmerName: json['khmer_name'] as String?,
      employeeId: json['employee_id'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['avatar'] as String?,
      branch: json['branch'] as String? ?? '-',
      department: json['department'] as String? ?? '-',
    );
  }
}

class MonthlyAttendanceTotals {
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int onLeave;
  final int holiday;
  final int weekend;

  const MonthlyAttendanceTotals({
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.onLeave,
    required this.holiday,
    required this.weekend,
  });

  factory MonthlyAttendanceTotals.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceTotals(
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      onLeave: json['on_leave'] as int? ?? 0,
      holiday: json['holiday'] as int? ?? 0,
      weekend: json['weekend'] as int? ?? 0,
    );
  }
}

class MonthlyAttendanceEmployeeSummary {
  final MonthlyAttendanceEmployee employee;
  final Map<int, String?> days;
  final MonthlyAttendanceTotals totals;

  const MonthlyAttendanceEmployeeSummary({
    required this.employee,
    required this.days,
    required this.totals,
  });

  factory MonthlyAttendanceEmployeeSummary.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as Map<String, dynamic>? ?? {};
    final days = <int, String?>{};
    rawDays.forEach((k, v) {
      final dayInt = int.tryParse(k);
      if (dayInt != null) {
        days[dayInt] = v as String?;
      }
    });

    return MonthlyAttendanceEmployeeSummary(
      employee: MonthlyAttendanceEmployee.fromJson(
        json['employee'] as Map<String, dynamic>? ?? {},
      ),
      days: days,
      totals: MonthlyAttendanceTotals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class CompanyMonthlyAttendanceData {
  final List<MonthlyAttendanceEmployeeSummary> summaryData;
  final String currentMonth;
  final int daysInMonth;

  const CompanyMonthlyAttendanceData({
    required this.summaryData,
    required this.currentMonth,
    required this.daysInMonth,
  });

  factory CompanyMonthlyAttendanceData.fromJson(Map<String, dynamic> json) {
    final list = (json['summaryData'] as List?) ?? [];
    return CompanyMonthlyAttendanceData(
      summaryData: list
          .whereType<Map<String, dynamic>>()
          .map(MonthlyAttendanceEmployeeSummary.fromJson)
          .toList(),
      currentMonth: json['currentMonth'] as String? ?? '',
      daysInMonth: json['daysInMonth'] as int? ?? 30,
    );
  }
}
