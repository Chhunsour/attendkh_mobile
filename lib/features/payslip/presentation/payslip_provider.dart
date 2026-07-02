import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/payslip/data/payslip_repository.dart';

final payslipRepositoryProvider = Provider<PayslipRepository>((ref) => PayslipRepository());
final payslipsProvider = FutureProvider.autoDispose<List<PayslipData>>((ref) async {
  return ref.watch(payslipRepositoryProvider).getPayslips();
});