import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mpg_hr_mobile_app/providers/holiday_provider.dart';
import 'package:mpg_hr_mobile_app/services/holidays_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

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

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(employeeHolidaysProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Holiday Calendar'),
        centerTitle: true,
      ),
      body: holidaysAsync.when(
        data: (allHolidays) {
          final monthHolidays = _getHolidaysForMonth(allHolidays, _focusedDay);
          
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grey200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
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
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: AppColors.grey200,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Holidays this month',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900),
                  ),
                ),
              ),
              Expanded(
                child: monthHolidays.isEmpty
                    ? const Center(child: Text('No holidays this month', style: TextStyle(color: AppColors.grey500)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: monthHolidays.length,
                        itemBuilder: (context, index) {
                          final holiday = monthHolidays[index];
                          final hDate = DateTime.tryParse(holiday.date) ?? DateTime.now();
                          // Adjust year for recurring holidays so they sort correctly
                          final displayDate = holiday.isRecurring == true
                              ? DateTime(_focusedDay.year, hDate.month, hDate.day)
                              : hDate;

                          return Card(
                            elevation: 0,
                            color: AppColors.grey50,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.celebration_rounded, color: AppColors.danger, size: 20),
                              ),
                              title: Text(holiday.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(holiday.type.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.grey500)),
                              trailing: Text(
                                DateFormat('MMM d').format(displayDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading holidays...'),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(employeeHolidaysProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}
