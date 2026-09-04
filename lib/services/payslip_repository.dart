import 'package:url_launcher/url_launcher.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

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
    this.overtimePay = 0,
    this.allowances = 0,
    this.taxDeduction = 0,
    this.insuranceDeduction = 0,
    this.lateDeduction = 0,
    this.earlyLeaveDeduction = 0,
    this.totalDeductions = 0,
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
      period: (json['payroll_period'] ?? json['period'] ?? '') as String,
      netPay: _parseDouble(json['net_salary'] ?? json['net_pay']),
      grossPay: _parseDouble(json['gross_salary'] ?? json['gross_pay']),
      basicSalary: _parseDouble(json['basic_salary'] ?? json['base_salary']),
      overtimePay: _parseDouble(json['overtime_pay']),
      allowances: _parseDouble(json['allowances']),
      taxDeduction: _parseDouble(json['tax_deduction']),
      insuranceDeduction: _parseDouble(json['insurance_deduction']),
      lateDeduction: _parseDouble(json['late_deduction']),
      earlyLeaveDeduction: _parseDouble(json['early_leave_deduction']),
      totalDeductions: _parseDouble(json['total_deductions']),
      payDate: json['pay_date'] as String?,
      status: (json['status'] ?? 'draft') as String,
      workingDays: _parseInt(json['working_days']),
      presentDays: _parseInt(json['present_days']),
      lateDays: _parseInt(json['late_days']),
      earlyLeaveDays: _parseInt(json['early_leave_days']),
      overtimeHours: _parseInt(json['overtime_hours']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'payroll_period': period,
    'net_salary': netPay,
    'gross_salary': grossPay,
    'basic_salary': basicSalary,
    'overtime_pay': overtimePay,
    'allowances': allowances,
    'tax_deduction': taxDeduction,
    'insurance_deduction': insuranceDeduction,
    'late_deduction': lateDeduction,
    'early_leave_deduction': earlyLeaveDeduction,
    'total_deductions': totalDeductions,
    'pay_date': payDate,
    'status': status,
    'working_days': workingDays,
    'present_days': presentDays,
    'late_days': lateDays,
    'early_leave_days': earlyLeaveDays,
    'overtime_hours': overtimeHours,
  };
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
      // Short-lived signed link. The long-lived bearer token must never reach a
      // URL, browser history or the server's access logs.
      final response =
          await _api.get('/company/my-payslips/$periodOrId/view-link');
      final body = response.data;
      final urlString = (body is Map && body['data'] is Map)
          ? body['data']['url'] as String?
          : null;
      if (urlString == null || urlString.isEmpty) {
        throw 'Could not create a payslip link.';
      }
      final uri = Uri.parse(urlString);

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      throw 'Download failed: $e';
    }
  }
}
