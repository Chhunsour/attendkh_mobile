class CompanyLeaveSummaryItem {
  final String fullName;
  final String empCode;
  final String department;
  final String branch;
  final String leaveType;
  final bool isPaid;
  final double allocatedDays;
  final double usedDays;
  final double carriedForward;
  final double remainingDays;
  final int period;
  final int pendingRequests;

  const CompanyLeaveSummaryItem({
    required this.fullName,
    required this.empCode,
    required this.department,
    required this.branch,
    required this.leaveType,
    required this.isPaid,
    required this.allocatedDays,
    required this.usedDays,
    required this.carriedForward,
    required this.remainingDays,
    required this.period,
    required this.pendingRequests,
  });

  factory CompanyLeaveSummaryItem.fromJson(Map<String, dynamic> json) {
    return CompanyLeaveSummaryItem(
      fullName: json['full_name'] as String? ?? 'Employee',
      empCode: json['emp_code']?.toString() ?? '-',
      department: json['department'] as String? ?? '-',
      branch: json['branch'] as String? ?? '-',
      leaveType: json['leave_type'] as String? ?? 'Annual Leave',
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true || json['is_paid'] == '1',
      allocatedDays: double.tryParse(json['allocated_days']?.toString() ?? '0') ?? 0,
      usedDays: double.tryParse(json['used_days']?.toString() ?? '0') ?? 0,
      carriedForward: double.tryParse(json['carried_forward']?.toString() ?? '0') ?? 0,
      remainingDays: double.tryParse(json['remaining_days']?.toString() ?? '0') ?? 0,
      period: int.tryParse(json['period']?.toString() ?? '2026') ?? DateTime.now().year,
      pendingRequests: int.tryParse(json['pending_requests']?.toString() ?? '0') ?? 0,
    );
  }

  double get totalAvailable => allocatedDays + carriedForward;
  double get usagePercent => totalAvailable > 0 ? (usedDays / totalAvailable) * 100 : 0;
}
