import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class PayslipData {
  final String period;
  final double netPay;
  final double grossPay;
  final String? payDate;

  const PayslipData({
    required this.period,
    required this.netPay,
    required this.grossPay,
    this.payDate,
  });

  factory PayslipData.fromJson(Map<String, dynamic> json) {
    return PayslipData(
      period: json['period'] as String? ?? json['pay_period'] as String? ?? '',
      netPay: (json['net_pay'] as num?)?.toDouble() ?? 0,
      grossPay: (json['gross_pay'] as num?)?.toDouble() ?? 0,
      payDate: json['pay_date'] as String? ?? json['paid_at'] as String?,
    );
  }
}

class PayslipRepository {
  final ApiRepository _api;
  PayslipRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<PayslipData>> getPayslips() async {
    final response = await _api.get('/company/payroll/runs');
    final data = response.data;
    if (data is List) return data.map((e) => PayslipData.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['payslips'] != null) {
      return (data['payslips'] as List).map((e) => PayslipData.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> downloadPayslip(String period) async {
    await _api.get('/company/payroll/export/$period');
  }
}
