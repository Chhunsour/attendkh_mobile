import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/payslip_repository.dart';
import 'package:mpg_hr_mobile_app/providers/payslip_provider.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class PayslipScreen extends ConsumerWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(payslipsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Payslips & Salary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(payslipsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(payslipsProvider),
        color: AppColors.primary,
        child: payslipsAsync.when(
          data: (payslips) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Hero Salary Statement Card ──
              SliverToBoxAdapter(
                child: _buildHeroCard(context, ref, payslips.isNotEmpty ? payslips.first : null, l10n),
              ),

              // ── Section Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                      if (payslips.isNotEmpty)
                        Text(
                          '${payslips.length} Statements',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Payslips List or Empty State ──
              if (payslips.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noPayslipsAvailable,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your generated monthly salary statements will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = payslips[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StatementCard(
                            payslip: p,
                            isLatest: i == 0,
                            onDownload: () => _handleDownload(context, p, l10n),
                          ),
                        );
                      },
                      childCount: payslips.length,
                    ),
                  ),
                ),
            ],
          ),
          loading: () => LoadingIndicator(message: l10n.loadingSecureWallet),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('Failed to load payslips', style: TextStyle(color: AppColors.grey600)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(payslipsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, WidgetRef ref, PayslipData? latest, AppLocalizations l10n) {
    final authState = ref.watch(authProvider);
    final employeeName = authState.userName ?? l10n.employee;
    final companyName = authState.companyName ?? 'MPG HR';
    final netAmount = latest != null ? latest.netPay.toStringAsFixed(2) : '0.00';
    final grossAmount = latest != null ? latest.grossPay.toStringAsFixed(2) : '0.00';
    final deductionsAmount = latest != null ? latest.totalDeductions.toStringAsFixed(2) : '0.00';
    final otAmount = latest != null ? latest.overtimePay.toStringAsFixed(2) : '0.00';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B), // Deep Indigo
            Color(0xFF312E81),
            Color(0xFF4338CA),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Company Name + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    employeeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (latest != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    latest.period,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Net Pay
          Text(
            l10n.lastNetPay.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$$netAmount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NET PAID',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Quick Snapshot Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroMetric('Gross Pay', '\$$grossAmount', Colors.white),
                Container(height: 24, width: 1, color: Colors.white24),
                _heroMetric('Deductions', '-\$$deductionsAmount', const Color(0xFFF87171)),
                Container(height: 24, width: 1, color: Colors.white24),
                _heroMetric('Overtime', '+\$$otAmount', const Color(0xFF60A5FA)),
              ],
            ),
          ),

          if (latest != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleDownload(context, latest, l10n),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Latest Statement (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E1B4B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _handleDownload(BuildContext context, PayslipData p, AppLocalizations l10n) async {
    try {
      final repo = PayslipRepository();
      await repo.downloadPayslip(p.id?.toString() ?? p.period);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.downloadStarted} for ${p.period}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _StatementCard extends StatefulWidget {
  final PayslipData payslip;
  final bool isLatest;
  final VoidCallback onDownload;

  const _StatementCard({
    required this.payslip,
    required this.isLatest,
    required this.onDownload,
  });

  @override
  State<_StatementCard> createState() => _StatementCardState();
}

class _StatementCardState extends State<_StatementCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.payslip.status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return AppColors.success;
      case 'processing':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payslip;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Clickable Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.period,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.grey900,
                              ),
                            ),
                            if (widget.isLatest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LATEST',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.payDate != null ? 'Paid on ${p.payDate}' : 'Date: Pending',
                          style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${p.netPay.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.grey400,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Breakdown Section
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earnings & Deductions Breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Earnings
                  _breakdownRow(l10n.basicSalary, '\$${p.basicSalary.toStringAsFixed(2)}'),
                  if (p.overtimePay > 0)
                    _breakdownRow(l10n.overtimePay, '+\$${p.overtimePay.toStringAsFixed(2)}', color: AppColors.info),
                  if (p.allowances > 0)
                    _breakdownRow(l10n.allowances, '+\$${p.allowances.toStringAsFixed(2)}', color: AppColors.success),
                  _breakdownRow(l10n.grossPay, '\$${p.grossPay.toStringAsFixed(2)}', isBold: true),

                  const Divider(height: 16, color: AppColors.grey100),

                  // Deductions
                  if (p.taxDeduction > 0)
                    _breakdownRow(l10n.tax, '-\$${p.taxDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                  if (p.insuranceDeduction > 0)
                    _breakdownRow(l10n.insurance, '-\$${p.insuranceDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                  if (p.lateDeduction > 0)
                    _breakdownRow(l10n.lateDeduction, '-\$${p.lateDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                  if (p.earlyLeaveDeduction > 0)
                    _breakdownRow(l10n.earlyLeaveDeduction, '-\$${p.earlyLeaveDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                  if (p.totalDeductions > 0)
                    _breakdownRow(l10n.totalDeductions, '-\$${p.totalDeductions.toStringAsFixed(2)}', color: AppColors.danger, isBold: true),

                  const Divider(height: 16, color: AppColors.grey100),

                  // Net Pay
                  _breakdownRow(l10n.netPay, '\$${p.netPay.toStringAsFixed(2)}', isBold: true, isNet: true),

                  const SizedBox(height: 14),

                  // Work Stats Chips
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Work Days', '${p.workingDays}', AppColors.primary),
                        _statItem('Present', '${p.presentDays}', AppColors.success),
                        _statItem('Late', '${p.lateDays}', AppColors.warning),
                        _statItem('OT Hours', '${p.overtimeHours}h', const Color(0xFF6366F1)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDownload,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(l10n.downloadPdf),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? color, bool isBold = false, bool isNet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isNet ? 14 : 12.5,
              fontWeight: (isBold || isNet) ? FontWeight.bold : FontWeight.w400,
              color: isNet ? AppColors.grey900 : AppColors.grey600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isNet ? 15 : 12.5,
              fontWeight: (isBold || isNet) ? FontWeight.bold : FontWeight.w600,
              color: isNet ? AppColors.success : (color ?? AppColors.grey800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.grey500),
        ),
      ],
    );
  }
}