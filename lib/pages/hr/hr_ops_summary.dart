import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/pages/shared/more_screen.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Cut-corner motif shared with the dashboard and the menu tabs.
const _cardShape = moreCardShape;

/// Live state of the workforce, above the tools that act on it.
///
/// Reads the same provider the Home tab already loaded, so this costs nothing
/// beyond a rebuild.
class HrOpsSummary extends ConsumerWidget {
  const HrOpsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final kpi = ref.watch(dashboardStatsProvider).valueOrNull;
    final employeesList = ref.watch(allEmployeesProvider).valueOrNull;
    if (kpi == null) return const SizedBox(height: 96);

    final total = employeesList?.length ?? kpi.totalEmployees;
    final present = kpi.todayAttendance;
    final ratio = total > 0 ? (present / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: _cardShape,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  context,
                  value: '$present/$total',
                  label: l10n.todaysAttendance,
                  color: const Color(0xFF10B981),
                ),
              ),
              _divider(context),
              Expanded(
                child: _stat(
                  context,
                  value: '$total',
                  label: l10n.totalStaff,
                  color: AppColors.primary,
                ),
              ),
              _divider(context),
              Expanded(
                child: _stat(
                  context,
                  value: '${kpi.pendingLeaves}',
                  label: l10n.pendingLeaves,
                  color: kpi.pendingLeaves > 0
                      ? const Color(0xFFF59E0B)
                      : AppColors.grey400,
                  muted: kpi.pendingLeaves == 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: AppColors.border(context),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 30, color: AppColors.border(context));

  Widget _stat(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
    bool muted = false,
  }) {
    return Column(
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
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

/// The next few company holidays — the planning context an HR owner otherwise
/// has to open the calendar for. Absent when nothing is coming up.
class HrUpcomingHolidays extends ConsumerWidget {
  const HrUpcomingHolidays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final holidays = ref.watch(holidaysAdminProvider).valueOrNull;
    if (holidays == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final upcoming = <(HolidayData, DateTime)>[];
    for (final h in holidays) {
      final d = DateTime.tryParse(h.date);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(midnight)) continue;
      upcoming.add((h, day));
    }
    if (upcoming.isEmpty) return const SizedBox.shrink();
    upcoming.sort((a, b) => a.$2.compareTo(b.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        MoreSectionHeader(
          title: l10n.holidays,
          accent: const Color(0xFFF59E0B),
          onTap: () => context.push(AppRoutes.adminHolidays),
        ),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: _cardShape,
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              for (final (i, entry) in upcoming.take(3).indexed) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    color: AppColors.border(context),
                  ),
                _row(context, l10n, entry.$1, entry.$2, midnight),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l10n,
    HolidayData h,
    DateTime date,
    DateTime midnight,
  ) {
    final days = date.difference(midnight).inDays;
    // ponytail: no locale arg — the app never calls initializeDateFormatting,
    // so a non-en locale here would throw at runtime
    final isToday = days == 0;

    return InkWell(
      onTap: () => context.push(AppRoutes.adminHolidays),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Tear-off date block — scannable without reading the label
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat.MMM().format(date).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
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
                    DateFormat.EEEE().format(date),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isToday ? l10n.today : '${days}d',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isToday ? Colors.white : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
