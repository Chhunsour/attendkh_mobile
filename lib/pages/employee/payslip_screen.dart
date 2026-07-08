import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/payslip_repository.dart';
import 'package:mpg_hr_mobile_app/providers/payslip_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class PayslipScreen extends ConsumerWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(payslipsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Digital Wallet'),
        elevation: 0,
        backgroundColor: AppColors.backgroundLight,
        centerTitle: true,
      ),
      body: payslipsAsync.when(
        data: (payslips) => payslips.isEmpty
            ? const Center(child: Text('No payslips available', style: TextStyle(color: AppColors.grey400)))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Payslips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey800)),
                          const SizedBox(height: 8),
                          Text('Manage your payroll documents securely.', style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = payslips[i];
                        return _WalletCard(
                          period: p.period,
                          payDate: p.payDate ?? 'Pending',
                          netPay: p.netPay,
                          onDownload: () => _handleDownload(context, p.period),
                        );
                      },
                      childCount: payslips.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for nav bar
                ],
              ),
        loading: () => const LoadingIndicator(message: 'Loading secure wallet...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(payslipsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, String period) async {
    try {
      final repo = PayslipRepository();
      await repo.downloadPayslip(period);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Downloading payslip...'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _WalletCard extends StatelessWidget {
  final String period;
  final String payDate;
  final double netPay;
  final VoidCallback onDownload;

  const _WalletCard({
    required this.period,
    required this.payDate,
    required this.netPay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top portion (Bank Card Aesthetic)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF334155), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(period.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text('\$${netPay.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(20), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          
          // Bottom portion (Details & Action)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deposit Date', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                    const SizedBox(height: 2),
                    Text(payDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey800)),
                  ],
                ),
                TextButton.icon(
                  onPressed: onDownload,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: AppColors.primary.withAlpha(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Save PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}