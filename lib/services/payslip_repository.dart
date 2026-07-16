import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
class PayslipData {
  final int? id;
  final String period;
  final double netPay;
  final double grossPay;
  final double basicSalary;
  final double overtimePay;
  final double allowances;
  final double taxDeduction;
  final double insuranceDeduction;
  final double lateDeduction;
  final double earlyLeaveDeduction;
  final double totalDeductions;
  final String? payDate;
  final String status;
  final int workingDays;
  final int presentDays;
  final int lateDays;
  final int earlyLeaveDays;
  final int overtimeHours;

  const PayslipData({
    this.id,
    required this.period,
    required this.netPay,
    required this.grossPay,
    required this.basicSalary,
    required this.overtimePay,
    required this.allowances,
    required this.taxDeduction,
    required this.insuranceDeduction,
    required this.lateDeduction,
    this.earlyLeaveDeduction = 0,
    required this.totalDeductions,
    this.payDate,
    this.status = 'draft',
    this.workingDays = 0,
    this.presentDays = 0,
    this.lateDays = 0,
    this.earlyLeaveDays = 0,
    this.overtimeHours = 0,
  });

  factory PayslipData.fromJson(Map<String, dynamic> json) {
    return PayslipData(
      id: json['id'] as int?,
      period: json['payroll_period'] as String? ?? json['pay_period'] as String? ?? json['period'] as String? ?? '',
      netPay: (json['net_salary'] as num?)?.toDouble() ?? (json['net_pay'] as num?)?.toDouble() ?? 0,
      grossPay: (json['gross_salary'] as num?)?.toDouble() ?? (json['gross_pay'] as num?)?.toDouble() ?? 0,
      basicSalary: (json['basic_salary'] as num?)?.toDouble() ?? 0,
      overtimePay: (json['overtime_pay'] as num?)?.toDouble() ?? 0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0,
      taxDeduction: (json['tax_deduction'] as num?)?.toDouble() ?? 0,
      insuranceDeduction: (json['insurance_deduction'] as num?)?.toDouble() ?? 0,
      lateDeduction: (json['late_deduction'] as num?)?.toDouble() ?? 0,
      earlyLeaveDeduction: (json['early_leave_deduction'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['total_deductions'] as num?)?.toDouble() ?? 0,
      payDate: json['pay_date'] as String? ?? json['paid_at'] as String?,
      status: json['status'] as String? ?? 'draft',
      workingDays: json['working_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
      lateDays: json['late_days'] as int? ?? 0,
      earlyLeaveDays: json['early_leave_days'] as int? ?? 0,
      overtimeHours: json['overtime_hours'] as int? ?? 0,
    );
  }
}

class PayslipRepository {
  final ApiRepository _api;
  PayslipRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<PayslipData>> getPayslips() async {
    final response = await _api.get('/company/my-payslips');
    final data = response.data;
    if (data is List) return data.map((e) => PayslipData.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) {
      return (data['data'] as List).map((e) => PayslipData.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> downloadPayslip(String periodOrId) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/payslip_$periodOrId.pdf';
    
    await _api.download(
      '/company/my-payslips/$periodOrId/download', 
      savePath, 
      method: 'GET',
    );
    
    await OpenFilex.open(savePath);
  }
}