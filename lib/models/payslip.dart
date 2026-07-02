import 'package:equatable/equatable.dart';

class Payslip extends Equatable {
  final int id;
  final int userId;
  final String period;
  final String payDate;
  final double grossPay;
  final double netPay;
  final double totalDeductions;
  final double totalAllowances;
  final List<PayrollItem>? earnings;
  final List<PayrollItem>? deductions;
  final String? pdfUrl;

  const Payslip({
    required this.id,
    required this.userId,
    required this.period,
    required this.payDate,
    required this.grossPay,
    required this.netPay,
    required this.totalDeductions,
    required this.totalAllowances,
    this.earnings,
    this.deductions,
    this.pdfUrl,
  });

  @override
  List<Object?> get props => [id, userId, period];
}

class PayrollItem extends Equatable {
  final String name;
  final double amount;
  final String? category;

  const PayrollItem({
    required this.name,
    required this.amount,
    this.category,
  });

  @override
  List<Object?> get props => [name, amount];
}