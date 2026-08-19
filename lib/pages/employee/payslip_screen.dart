import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
    final payslips = payslipsAsync.valueOrNull ?? const <PayslipData>[];
    final latest = payslips.isNotEmpty ? payslips.first : null;
    final bool empty = payslips.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(payslipsProvider),
          color: AppColors.primary,
          // The hero runs under the status bar, so the spinner has to drop
          // below it rather than sit on the notch.
          edgeOffset: MediaQuery.paddingOf(context).top + 8,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHero(
                  context,
                  ref,
                  latest,
                  l10n,
                  loading: payslipsAsync.isLoading && empty,
                ),
              ),

              if (payslipsAsync.hasError && empty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _errorState(ref, l10n),
                )
              else if (payslipsAsync.isLoading && empty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingIndicator(message: l10n.loadingSecureWallet),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (payslips.isNotEmpty)
                          Text(
                            '${payslips.length} ${payslips.length == 1 ? 'statement' : 'statements'}',
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

                if (empty)
                  SliverToBoxAdapter(child: _emptyState(context, l10n))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList.separated(
                      itemCount: payslips.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _StatementCard(
                        payslip: payslips[i],
                        isLatest: i == 0,
                        onDownload: () =>
                            _handleDownload(context, payslips[i], l10n),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient hero: same slab as the dashboard, carrying the pay summary
  // instead of stacking a separate indigo card under a white app bar. ──
  Widget _buildHero(
    BuildContext context,
    WidgetRef ref,
    PayslipData? latest,
    AppLocalizations l10n, {
    required bool loading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final employeeName = authState.userName ?? l10n.employee;
    final companyName = authState.companyName ?? 'MPG HR';
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    String money(double? v) => '\$${(v ?? 0).toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 8,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Shown only when this screen was pushed — as a bottom-nav
                    // tab there is nothing to go back to.
                    if (context.canPop()) ...[
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.pop(),
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        'Payslips & Salary',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => ref.invalidate(payslipsProvider),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Who the statement belongs to, and which period it covers.
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            employeeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (latest != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          latest.period,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 22),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    l10n.lastNetPay.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            money(latest?.netPay),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NET PAID',
                            style: TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _heroMetric(
                          'Gross Pay',
                          money(latest?.grossPay),
                          const Color(0xFF93C5FD),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _heroMetric(
                          'Deductions',
                          '-${money(latest?.totalDeductions)}',
                          const Color(0xFFFCA5A5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _heroMetric(
                          'Overtime',
                          '+${money(latest?.overtimePay)}',
                          const Color(0xFF7DD3FC),
                        ),
                      ),
                    ],
                  ),

                  if (latest != null) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleDownload(context, latest, l10n),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download Latest Statement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: baseColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Glass tile: the label sits above the figure so three of them fit the width
  // without the dividers the old single-row layout needed.
  Widget _heroMetric(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your generated monthly salary statements will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _errorState(WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          const Text(
            'Failed to load payslips',
            style: TextStyle(color: AppColors.grey600),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(payslipsProvider),
            child: Text(l10n.retry),
          ),
        ],
      ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.period,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
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
            Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.grey100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings & Deductions Breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.grey700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Earnings
                  _breakdownRow(context, l10n.basicSalary, '\$${p.basicSalary.toStringAsFixed(2)}'),
                  if (p.overtimePay > 0)
                    _breakdownRow(context, l10n.overtimePay, '+\$${p.overtimePay.toStringAsFixed(2)}', color: AppColors.info),
                  if (p.allowances > 0)
                    _breakdownRow(context, l10n.allowances, '+\$${p.allowances.toStringAsFixed(2)}', color: AppColors.success),
                  _breakdownRow(context, l10n.grossPay, '\$${p.grossPay.toStringAsFixed(2)}', isBold: true),

                  Divider(height: 16, color: isDark ? AppColors.borderDark : AppColors.grey100),

                  // Deductions
                  if (p.taxDeduction > 0)
                    _breakdownRow(context, l10n.tax, '-\$${p.taxDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                  if (p.insuranceDeduction > 0)
                    _breakdownRow(context, l10n.insurance, '-\$${p.insuranceDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                  if (p.lateDeduction > 0)
                    _breakdownRow(context, l10n.lateDeduction, '-\$${p.lateDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                  if (p.earlyLeaveDeduction > 0)
                    _breakdownRow(context, l10n.earlyLeaveDeduction, '-\$${p.earlyLeaveDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                  if (p.totalDeductions > 0)
                    _breakdownRow(context, l10n.totalDeductions, '-\$${p.totalDeductions.toStringAsFixed(2)}', color: AppColors.danger, isBold: true),

                  Divider(height: 16, color: isDark ? AppColors.borderDark : AppColors.grey100),

                  // Net Pay
                  _breakdownRow(context, l10n.netPay, '\$${p.netPay.toStringAsFixed(2)}', isBold: true, isNet: true),

                  const SizedBox(height: 14),

                  // Work Stats Chips
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
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

  Widget _breakdownRow(BuildContext context, String label, String value, {Color? color, bool isBold = false, bool isNet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isNet ? (isDark ? Colors.white : AppColors.grey900) : (isDark ? AppColors.grey300 : AppColors.grey600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isNet ? 15 : 12.5,
              fontWeight: (isBold || isNet) ? FontWeight.bold : FontWeight.w600,
              color: isNet ? AppColors.success : (color ?? (isDark ? Colors.white : AppColors.grey800)),
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