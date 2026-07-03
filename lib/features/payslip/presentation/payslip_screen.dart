import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/payslip/data/payslip_repository.dart';
import 'package:mpg_hr_mobile_app/features/payslip/presentation/payslip_provider.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class PayslipScreen extends ConsumerWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(payslipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payslips')),
      body: payslipsAsync.when(
        data: (payslips) => payslips.isEmpty
            ? const Center(child: Text('No payslips available', style: TextStyle(color: AppColors.grey400)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payslips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = payslips[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long, color: AppColors.primary)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.period, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(p.payDate ?? 'Pending', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ]),
                        ),
                        Text('\$${p.netPay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.download_outlined, color: AppColors.primary, size: 22),
                          tooltip: 'Download PDF',
                          onPressed: () => _handleDownload(context, p.period),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const LoadingIndicator(message: 'Loading payslips...'),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.grey400), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => ref.invalidate(payslipsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))])),
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, String period) async {
    try {
      final repo = PayslipRepository();
      await repo.downloadPayslip(period);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📥 Downloading payslip...'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }
}