import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/pages/shared/more_screen.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:attendkh/utils/router/app_router.dart';
import 'package:attendkh/utils/theme/theme.dart';

/// Cut-corner motif shared with the dashboard and the menu tabs.
const _cardShape = moreCardShape;

String _money(double v) {
  if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 10000) return '\$${(v / 1000).toStringAsFixed(1)}K';
  return '\$${NumberFormat('#,##0').format(v)}';
}

/// Where the money stands, above the tools that move it. Reads the provider
/// the Home tab already loaded, so it costs nothing beyond a rebuild.
class FinanceOpsSummary extends ConsumerWidget {
  const FinanceOpsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final kpi = ref.watch(dashboardStatsProvider).valueOrNull;
    if (kpi == null) return const SizedBox(height: 78);

    final line = AppColors.border(context);
    final idle = kpi.totalAssets - kpi.assignedAssets;

    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: line),
        borderRadius: _cardShape,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _cell(
                context,
                value: _money(kpi.monthlyPayroll),
                label: l10n.payroll,
                color: const Color(0xFF059669),
                muted: kpi.monthlyPayroll == 0,
                route: AppRoutes.adminPayroll,
              ),
            ),
            Container(width: 1, color: line),
            Expanded(
              child: _cell(
                context,
                value: '${kpi.pendingExpenses}',
                label: l10n.pendingExpenses,
                color: const Color(0xFFEC4899),
                muted: kpi.pendingExpenses == 0,
                route: AppRoutes.adminExpenses,
              ),
            ),
            Container(width: 1, color: line),
            Expanded(
              child: _cell(
                context,
                value: '${kpi.assignedAssets}/${kpi.totalAssets}',
                label: l10n.assets,
                color: const Color(0xFF6366F1),
                muted: kpi.totalAssets == 0,
                // Idle kit is the actionable half of the ratio
                note: idle > 0 ? '$idle idle' : null,
                route: AppRoutes.adminAssets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
    required String route,
    bool muted = false,
    String? note,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  height: 1.1,
                  color: muted ? AppColors.grey400 : color,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
            // Reserved slot — keeps all three cells the same height
            SizedBox(
              height: 13,
              child: note == null
                  ? null
                  : Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The last few payroll runs — the history you'd otherwise open the payroll
/// screen to check. Absent until there is one.
class FinanceRecentRuns extends ConsumerWidget {
  const FinanceRecentRuns({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final runs = ref.watch(payrollRunsProvider).valueOrNull;
    if (runs == null || runs.isEmpty) return const SizedBox.shrink();

    final recent = List.of(runs)..sort((a, b) => b.id.compareTo(a.id));
    final line = AppColors.border(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        MoreSectionHeader(
          title: l10n.payrollRuns,
          accent: const Color(0xFF059669),
          onTap: () => context.push(AppRoutes.adminPayroll),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.surface(context),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: line),
            borderRadius: _cardShape,
          ),
          child: Column(
            children: [
              for (final (i, run) in recent.take(3).indexed) ...[
                if (i > 0) Container(height: 1, color: line),
                _runRow(context, l10n, run),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _runRow(
    BuildContext context,
    AppLocalizations l10n,
    PayrollRunData run,
  ) {
    final color = switch (run.status) {
      'completed' => AppColors.success,
      'processing' => AppColors.info,
      'cancelled' => AppColors.danger,
      _ => AppColors.warning,
    };

    return InkWell(
      onTap: () => context.push(AppRoutes.adminPayroll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.period,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${run.employeesCount} ${l10n.employees.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(run.totalAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    run.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
