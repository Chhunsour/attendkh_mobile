import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:attendkh/providers/holiday_provider.dart';
import 'package:attendkh/services/holidays_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class HolidayCalendarScreen extends ConsumerStatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  ConsumerState<HolidayCalendarScreen> createState() =>
      _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState
    extends ConsumerState<HolidayCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Holiday> _getHolidaysForDay(List<Holiday> allHolidays, DateTime day) {
    return allHolidays.where((holiday) {
      final hDate = DateTime.tryParse(holiday.date);
      if (hDate == null) return false;

      if (holiday.isRecurring == true) {
        return hDate.month == day.month && hDate.day == day.day;
      } else {
        return hDate.year == day.year &&
            hDate.month == day.month &&
            hDate.day == day.day;
      }
    }).toList();
  }

  List<Holiday> _getHolidaysForMonth(
    List<Holiday> allHolidays,
    DateTime month,
  ) {
    return allHolidays.where((holiday) {
      final hDate = DateTime.tryParse(holiday.date);
      if (hDate == null) return false;
      return hDate.month == month.month &&
          (holiday.isRecurring == true || hDate.year == month.year);
    }).toList();
  }

  Holiday? _getNextUpcomingHoliday(List<Holiday> allHolidays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Holiday? upcoming;
    DateTime? upcomingDate;

    for (final h in allHolidays) {
      final parsed = DateTime.tryParse(h.date);
      if (parsed == null) continue;

      final targetDate = h.isRecurring == true
          ? DateTime(today.year, parsed.month, parsed.day)
          : parsed;

      if (!targetDate.isBefore(today)) {
        if (upcomingDate == null || targetDate.isBefore(upcomingDate)) {
          upcomingDate = targetDate;
          upcoming = h;
        }
      }
    }
    return upcoming;
  }

  String _getCountdownText(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today 🎉';
    if (diff == 1) return 'Tomorrow';
    if (diff > 1) return 'in $diff days';
    return 'Passed';
  }

  void _refresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(employeeHolidaysProvider);
  }

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(employeeHolidaysProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : const Color(0xFFF8FAFC),
        body: holidaysAsync.when(
          data: (allHolidays) {
            final monthHolidays = _getHolidaysForMonth(allHolidays, _focusedDay);
            final nextHoliday = _getNextUpcomingHoliday(allHolidays);

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Royal Blue Curved Hero Header (Matches Home / Profile) ──
                    _buildRoyalHeroHeader(
                      context: context,
                      l10n: l10n,
                      nextHoliday: nextHoliday,
                      totalHolidaysCount: allHolidays.length,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Modern Calendar Card ──
                          _buildCalendarCard(
                            context: context,
                            allHolidays: allHolidays,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),

                          // ── Monthly Holidays Section ──
                          _buildMonthlyHolidaysSection(
                            context: context,
                            monthHolidays: monthHolidays,
                            l10n: l10n,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Center(
            child: LoadingIndicator(message: l10n.holidayCalendar),
          ),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: isDark ? AppColors.grey600 : AppColors.grey400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load holidays: $e',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Royal Blue Curved Hero Header with Upcoming Holiday Spotlight ──
  Widget _buildRoyalHeroHeader({
    required BuildContext context,
    required AppLocalizations l10n,
    required Holiday? nextHoliday,
    required int totalHolidaysCount,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038B8), // Royal Blue Deep
            Color(0xFF0052FF), // Royal Blue Main
            Color(0xFF1E6BFF), // Royal Blue Light Glow
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x550052FF),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Column(
                children: [
                  // ── Top Navigation Bar ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (context.canPop())
                        _frostedHeroButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          l10n.holidayCalendar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      _frostedHeroButton(
                        icon: Icons.refresh_rounded,
                        tooltip: l10n.refresh,
                        onTap: _refresh,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Next Upcoming Holiday Frosted Spotlight Card ──
                  if (nextHoliday != null)
                    _buildFrostedUpcomingSpotlight(nextHoliday)
                  else
                    _buildFrostedYearSummary(totalHolidaysCount),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedUpcomingSpotlight(Holiday holiday) {
    final l10n = AppLocalizations.of(context)!;
    final hDate = DateTime.tryParse(holiday.date) ?? DateTime.now();
    final now = DateTime.now();
    final displayDate = holiday.isRecurring == true
        ? DateTime(now.year, hDate.month, hDate.day)
        : hDate;
    final countdown = _getCountdownText(displayDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Celebration Icon Squircle with Amber Glow
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Color(0xFF78350F),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Details Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.nextUpcomingHoliday,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFEF08A),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        countdown,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  holiday.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(displayDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedYearSummary(int totalHolidays) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateTime.now().year} HOLIDAY SCHEDULE',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFEF08A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalHolidays Public & Company Holidays Scheduled',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _frostedHeroButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Modern Calendar Card ──
  Widget _buildCalendarCard({
    required BuildContext context,
    required List<Holiday> allHolidays,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: TableCalendar<Holiday>(
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2050, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
        eventLoader: (day) => _getHolidaysForDay(allHolidays, day),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.2,
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white : AppColors.grey800,
              size: 20,
            ),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white : AppColors.grey800,
              size: 20,
            ),
          ),
        ),
        daysOfWeekHeight: 28,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          weekendStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEF4444),
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.40),
              width: 1.5,
            ),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : AppColors.grey900,
            fontWeight: FontWeight.w600,
          ),
          weekendTextStyle: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
          outsideTextStyle: TextStyle(
            color: isDark ? AppColors.grey600 : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          markerSize: 5.5,
          markersMaxCount: 1,
          markerDecoration: const BoxDecoration(
            color: Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // ── Monthly Holidays Section ──
  Widget _buildMonthlyHolidaysSection({
    required BuildContext context,
    required List<Holiday> monthHolidays,
    required AppLocalizations l10n,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('MMMM yyyy').format(_focusedDay)} Holidays',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.grey900,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${monthHolidays.length} Holidays',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // List / Empty State
        if (monthHolidays.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8)
                        .withValues(alpha: isDark ? 0.18 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 32,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noHolidaysThisMonth,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.regularScheduleEnjoy,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ),
              ],
            ),
          )
        else
          ...monthHolidays.map((holiday) {
            final hDate = DateTime.tryParse(holiday.date) ?? DateTime.now();
            final displayDate = holiday.isRecurring == true
                ? DateTime(_focusedDay.year, hDate.month, hDate.day)
                : hDate;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildHolidayCard(holiday, displayDate, isDark),
            );
          }),
      ],
    );
  }

  Widget _buildHolidayCard(Holiday holiday, DateTime date, bool isDark) {
    final countdown = _getCountdownText(date);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Squircle Badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF78350F).withValues(alpha: 0.40),
                        const Color(0xFFB45309).withValues(alpha: 0.25),
                      ]
                    : [
                        const Color(0xFFFEF3C7),
                        const Color(0xFFFDE68A),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B)
                    .withValues(alpha: isDark ? 0.30 : 0.20),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFB45309),
                  ),
                ),
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF78350F),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDarkElevated
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (holiday.type.isNotEmpty
                                ? holiday.type
                                : 'Public Holiday')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.grey300 : AppColors.grey600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE').format(date),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Countdown Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: countdown == 'Today 🎉'
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : (isDark
                      ? AppColors.surfaceDarkElevated
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              countdown,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: countdown == 'Today 🎉'
                    ? const Color(0xFF10B981)
                    : (isDark ? AppColors.grey300 : AppColors.grey600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
