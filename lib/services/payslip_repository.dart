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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory PayslipData.fromJson(Map<String, dynamic> json) {
    return PayslipData(
      id: _parseInt(json['id']),
      period:
          json['payroll_period'] as String? ??
          json['pay_period'] as String? ??
          json['period'] as String? ??
          '',
      netPay: _parseDouble(json['net_salary'] ?? json['net_pay']),
      grossPay: _parseDouble(json['gross_salary'] ?? json['gross_pay']),
      basicSalary: _parseDouble(json['basic_salary']),
      overtimePay: _parseDouble(json['overtime_pay']),
      allowances: _parseDouble(json['allowances']),
      taxDeduction: _parseDouble(json['tax_deduction']),
      insuranceDeduction: _parseDouble(json['insurance_deduction']),
      lateDeduction: _parseDouble(json['late_deduction']),
      earlyLeaveDeduction: _parseDouble(json['early_leave_deduction']),
      totalDeductions: _parseDouble(json['total_deductions']),
      payDate: json['pay_date'] as String? ?? json['paid_at'] as String?,
      status: json['status'] as String? ?? 'draft',
      workingDays: _parseInt(json['working_days']),
      presentDays: _parseInt(json['present_days']),
      lateDays: _parseInt(json['late_days']),
      earlyLeaveDays: _parseInt(json['early_leave_days']),
      overtimeHours: _parseInt(json['overtime_hours']),
    );
  }
}

class PayslipRepository {
  final ApiRepository _api;
  PayslipRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<PayslipData>> getPayslips() async {
    final response = await _api.get('/company/my-payslips');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => PayslipData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List)
          .map((e) => PayslipData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> downloadPayslip(String periodOrId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // Clean identifier for filename
      final safeId = periodOrId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final savePath = '${tempDir.path}/payslip_$safeId.pdf';

      await _api.download(
        '/company/my-payslips/$periodOrId/download',
        savePath,
        method: 'GET',
      );

      final result = await OpenFilex.open(savePath, type: "application/pdf");
      if (result.type != ResultType.done) {
        throw 'Could not open PDF: ${result.message}';
      }
    } catch (e) {
      throw 'Download failed: $e';
    }
  }
}
