import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/payslip_repository.dart';
import 'package:mpg_hr_mobile_app/providers/payslip_provider.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
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
        data: (payslips) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBankCard(context, ref, payslips.isNotEmpty ? payslips.first : null),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800),
                    ),
                  ),
                ],
              ),
            ),
            if (payslips.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('No payslips available', style: TextStyle(color: AppColors.grey400)),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p = payslips[i];
                    return _WalletCard(
                      payslip: p,
                      onDownload: () => _handleDownload(context, p),
                    );
                  },
                  childCount: payslips.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        loading: () => const LoadingIndicator(message: 'Loading secure wallet...'),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(payslipsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  Widget _buildBankCard(BuildContext context, WidgetRef ref, PayslipData? latest) {
    final authState = ref.watch(authProvider);
    final employeeName = authState.userName ?? 'Employee';
    final amount = latest != null ? latest.netPay.toStringAsFixed(2) : '0.00';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chip icon
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.memory, color: Colors.white, size: 20),
                ),
              ),
              // Contactless icon
              const Icon(Icons.contactless_outlined, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Last Net Pay',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$$amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                employeeName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'MPG HR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, PayslipData p) async {
    try {
      final repo = PayslipRepository();
      await repo.downloadPayslip(p.id?.toString() ?? p.period);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Download started'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _WalletCard extends StatefulWidget {
  final PayslipData payslip;
  final VoidCallback onDownload;

  const _WalletCard({required this.payslip, required this.onDownload});

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.payslip;
    final statusColor = p.status == 'completed'
        ? AppColors.success
        : p.status == 'processing'
            ? AppColors.info
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.grey200),
        ),
        color: AppColors.surfaceLight,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.period, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(p.payDate ?? 'Pending', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${p.netPay.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.status.substring(0, 1).toUpperCase() + p.status.substring(1),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.grey400, size: 20),
                  ],
                ),
                if (_expanded) ...[
                  const Divider(height: 20),
                  _detailRow('Basic Salary', '\$${p.basicSalary.toStringAsFixed(2)}'),
                  if (p.overtimePay > 0) _detailRow('Overtime Pay', '\$${p.overtimePay.toStringAsFixed(2)}', color: AppColors.info),
                  if (p.allowances > 0) _detailRow('Allowances', '\$${p.allowances.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _detailRow('Gross Pay', '\$${p.grossPay.toStringAsFixed(2)}', bold: true),
                  const SizedBox(height: 8),
                  if (p.taxDeduction > 0) _detailRow('Tax', '-\$${p.taxDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                  if (p.insuranceDeduction > 0) _detailRow('Insurance', '-\$${p.insuranceDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                  if (p.lateDeduction > 0) _detailRow('Late Deduction', '-\$${p.lateDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                  if (p.earlyLeaveDeduction > 0) _detailRow('Early Leave Deduction', '-\$${p.earlyLeaveDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                  const SizedBox(height: 4),
                  _detailRow('Total Deductions', '-\$${p.totalDeductions.toStringAsFixed(2)}', color: AppColors.danger, bold: true),
                  const Divider(height: 16),
                  _detailRow('Net Pay', '\$${p.netPay.toStringAsFixed(2)}', bold: true, netRow: true),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip('Working Days', p.workingDays.toString(), AppColors.primary),
                      _statChip('Present', p.presentDays.toString(), AppColors.success),
                      _statChip('Late', p.lateDays.toString(), AppColors.warning),
                      if (p.earlyLeaveDays > 0)
                        _statChip('Early Out', p.earlyLeaveDays.toString(), Colors.orange),
                      _statChip('OT Hours', p.overtimeHours.toString(), AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDownload,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool bold = false, bool netRow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: netRow ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.grey500)),
      ],
    );
  }
}