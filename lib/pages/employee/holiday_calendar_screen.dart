import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mpg_hr_mobile_app/providers/holiday_provider.dart';
import 'package:mpg_hr_mobile_app/services/holidays_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class HolidayCalendarScreen extends ConsumerStatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  ConsumerState<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends ConsumerState<HolidayCalendarScreen> {
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
        return hDate.year == day.year && hDate.month == day.month && hDate.day == day.day;
      }
    }).toList();
  }

  List<Holiday> _getHolidaysForMonth(List<Holiday> allHolidays, DateTime month) {
    return allHolidays.where((holiday) {
      final hDate = DateTime.tryParse(holiday.date);
      if (hDate == null) return false;
      return hDate.month == month.month && (holiday.isRecurring == true || hDate.year == month.year);
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

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(employeeHolidaysProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.holidayCalendar,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(employeeHolidaysProvider),
          ),
        ],
      ),
      body: holidaysAsync.when(
        data: (allHolidays) {
          final monthHolidays = _getHolidaysForMonth(allHolidays, _focusedDay);
          final nextHoliday = _getNextUpcomingHoliday(allHolidays);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(employeeHolidaysProvider),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Upcoming Holiday Banner ──
                  if (nextHoliday != null) ...[
                    _buildUpcomingHeroBanner(nextHoliday),
                    SizedBox(height: 14),
                  ],

                  // ── Modern Calendar Card ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                    child: TableCalendar<Holiday>(
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2050, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
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
                        titleTextStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.grey700),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.grey700),
                      ),
                      daysOfWeekHeight: 24,
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500),
                        weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        markerSize: 5,
                        markersMaxCount: 1,
                        markerDecoration: BoxDecoration(
                          color: Color(0xFFEAB308),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Section Header ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${DateFormat('MMMM yyyy').format(_focusedDay)} Holidays',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAB308).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${monthHolidays.length} Holidays',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  // ── Month Holidays List ──
                  if (monthHolidays.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 40, color: AppColors.grey300),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noHolidaysThisMonth,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.grey500, fontWeight: FontWeight.w500),
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildHolidayCard(holiday, displayDate),
                      );
                    }),
                ],
              ),
            ),
          );
        },
        loading: () => LoadingIndicator(message: l10n.loadingHolidays),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
              const SizedBox(height: 8),
              Text('Failed to load holidays: $e', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(employeeHolidaysProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingHeroBanner(Holiday holiday) {
    final hDate = DateTime.tryParse(holiday.date) ?? DateTime.now();
    final now = DateTime.now();
    final displayDate = holiday.isRecurring == true
        ? DateTime(now.year, hDate.month, hDate.day)
        : hDate;
    final countdown = _getCountdownText(displayDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textPrimary(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Color(0xFFD97706),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEXT UPCOMING HOLIDAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.4,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        countdown,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  holiday.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(displayDate),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF92400E),
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

  Widget _buildHolidayCard(Holiday holiday, DateTime date) {
    final countdown = _getCountdownText(date);

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAB308).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                Text(
                  DateFormat('d').format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),

          // Title & Type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (holiday.type.isNotEmpty ? holiday.type : 'Public Holiday').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE').format(date),
                      style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Countdown tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: countdown == 'Today 🎉'
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              countdown,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: countdown == 'Today 🎉' ? AppColors.success : AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
