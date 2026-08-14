class OvertimeRequest {
  final int id;
  final int employeeId;
  final String date;
  final String startTime;
  final String endTime;
  final double? amount;
  final String? reason;
  final String status;
  final String? employeeName;
  final String? employeeAvatar;

  OvertimeRequest({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.amount,
    this.reason,
    required this.status,
    this.employeeName,
    this.employeeAvatar,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    String? employeeName;
    String? employeeAvatar;
    if (json['employee'] != null) {
      final employee = json['employee'];
      employeeName = employee['full_name'] != null 
          ? '${employee['full_name']} ${employee['khmer_name'] ?? ''}'.trim()
          : null;
      employeeAvatar = employee['photo_url'];
    }

    return OvertimeRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      reason: json['reason'],
      status: json['status'],
      employeeName: employeeName,
      employeeAvatar: employeeAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'amount': amount,
      'reason': reason,
      'status': status,
    };
  }
}
