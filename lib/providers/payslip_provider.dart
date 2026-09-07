import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/services/payslip_repository.dart';

final payslipRepositoryProvider = Provider<PayslipRepository>((ref) => PayslipRepository());
final payslipsProvider = FutureProvider.autoDispose<List<PayslipData>>((ref) async {
  return ref.watch(payslipRepositoryProvider).getPayslips();
});