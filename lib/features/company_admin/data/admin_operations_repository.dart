import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

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

// ── Admin Leave Request ─────────────────────────────────────────────────────
class AdminLeaveRequestData {
  final int id;
  final String employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final double days;
  final String? reason;
  final String status;
  final String createdAt;

  const AdminLeaveRequestData({required this.id, required this.employeeName, required this.leaveType, required this.startDate, required this.endDate, required this.days, this.reason, required this.status, required this.createdAt});

  factory AdminLeaveRequestData.fromJson(Map<String, dynamic> json) {
    return AdminLeaveRequestData(
      id: json['id'] as int,
      employeeName: json['employee']?['name'] as String? ?? json['user']?['name'] as String? ?? '',
      leaveType: json['leave_type']?['name'] as String? ?? '',
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
  final double defaultDays;
  final String? color;
  final bool isActive;

  const LeaveTypeData({required this.id, required this.name, required this.defaultDays, this.color, this.isActive = true});

  factory LeaveTypeData.fromJson(Map<String, dynamic> json) {
    return LeaveTypeData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      defaultDays: (json['default_days'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

// ── Shift ───────────────────────────────────────────────────────────────────
class ShiftData {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String? days;
  final int? employeesCount;

  const ShiftData({required this.id, required this.name, required this.startTime, required this.endTime, this.days, this.employeesCount});

  factory ShiftData.fromJson(Map<String, dynamic> json) {
    return ShiftData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      days: json['days'] as String?,
      employeesCount: json['employees_count'] as int?,
    );
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
  final String name;
  final String? type;
  final String? serialNumber;
  final String status;
  final String? assignedTo;
  final String? assignedDate;

  const AssetData({required this.id, required this.name, this.type, this.serialNumber, required this.status, this.assignedTo, this.assignedDate});

  factory AssetData.fromJson(Map<String, dynamic> json) {
    return AssetData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? json['asset_type'] as String?,
      serialNumber: json['serial_number'] as String?,
      status: json['status'] as String? ?? 'available',
      assignedTo: json['assigned_to']?['name'] as String? ?? json['current_assignment']?['employee']?['name'] as String?,
      assignedDate: json['assigned_date'] as String?,
    );
  }
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
      period: json['period'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      employeesCount: json['employees_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
    );
  }
}

// ── Admin Operations Repository ─────────────────────────────────────────────
class AdminOperationsRepository {
  final ApiRepository _api;
  AdminOperationsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  // ── Attendance Corrections ──────────────────────────────────────────────
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

  // ── Leave Types ─────────────────────────────────────────────────────────
  Future<List<LeaveTypeData>> getLeaveTypes() async {
    final response = await _api.get('/company/leave/types');
    return _parseList(response.data, LeaveTypeData.fromJson);
  }

  Future<LeaveTypeData> createLeaveType({required String name, required double defaultDays, String? color}) async {
    final response = await _api.post('/company/leave/types', data: {'name': name, 'default_days': defaultDays, 'color': ?color});
    return LeaveTypeData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLeaveType(int id) async => _api.delete('/company/leave/types/$id');

  // ── Shifts ──────────────────────────────────────────────────────────────
  Future<List<ShiftData>> getShifts() async {
    final response = await _api.get('/company/shifts');
    return _parseList(response.data, ShiftData.fromJson);
  }

  Future<ShiftData> createShift({required String name, required String startTime, required String endTime, String? days}) async {
    final response = await _api.post('/company/shifts', data: {'name': name, 'start_time': startTime, 'end_time': endTime, 'days': ?days});
    return ShiftData.fromJson(response.data as Map<String, dynamic>);
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

  Future<AssetData> createAsset({required String name, String? type, String? serialNumber}) async {
    final response = await _api.post('/company/assets', data: {'name': name, 'type': ?type, 'serial_number': ?serialNumber});
    return AssetData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAsset(int id) async => _api.delete('/company/assets/$id');
  Future<void> assignAsset(int id, int employeeId) async => _api.post('/company/assets/$id/assign', data: {'employee_id': employeeId});
  Future<void> returnAsset(int id) async => _api.post('/company/assets/$id/return');

  Future<List<AssetAssignmentData>> getAssetHistory(int id) async {
    final response = await _api.get('/company/assets/$id/history');
    return _parseList(response.data, AssetAssignmentData.fromJson);
  }

  // ── Expenses (Admin) ────────────────────────────────────────────────────
  Future<void> approveExpense(int id) async => _api.post('/company/expenses/$id/approve');
  Future<void> rejectExpense(int id) async => _api.post('/company/expenses/$id/reject');
  Future<void> markExpensePaid(int id) async => _api.post('/company/expenses/$id/pay');
  Future<void> deleteExpense(int id) async => _api.delete('/company/expenses/$id');

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

  // ── Payroll ─────────────────────────────────────────────────────────────
  Future<List<PayrollRunData>> getPayrollRuns() async {
    final response = await _api.get('/company/payroll/runs');
    return _parseList(response.data, PayrollRunData.fromJson);
  }

  Future<void> generatePayroll({required String period}) async => _api.post('/company/payroll/generate', data: {'period': period});

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

  // ── Helpers ─────────────────────────────────────────────────────────────
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}