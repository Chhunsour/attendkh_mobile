import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String get _selectedMonth => DateFormat('yyyy-MM').format(_focusedDay);
  String get _monthLabel => DateFormat('MMMM yyyy').format(_focusedDay);

  Future<void> _showMonthYearPicker() async {
    int selectedYear = _focusedDay.year;
    
    final newDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setSheetState(() => selectedYear--),
                  ),
                  Text('$selectedYear', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setSheetState(() => selectedYear++),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthName = DateFormat('MMM').format(DateTime(2000, month));
                  final isCurrent = selectedYear == DateTime.now().year && month == DateTime.now().month;
                  final isSelected = selectedYear == _focusedDay.year && month == _focusedDay.month;

                  return InkWell(
                    onTap: () => Navigator.pop(ctx, DateTime(selectedYear, month, 1)),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isCurrent ? AppColors.primary.withAlpha(26) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey200),
                      ),
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isCurrent ? AppColors.primary : AppColors.grey700),
                          fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (newDate != null) {
      setState(() {
        _focusedDay = newDate;
        _selectedDay = null;
      });
    }
  }

  Future<void> _showCorrectionDialog(BuildContext context) async {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String correctionType = 'missed_clock_in';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Request Correction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('Submit a request to correct an anomaly in your attendance log.', style: TextStyle(color: AppColors.grey500, fontSize: 14)),
              const SizedBox(height: 24),
              
              const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey700)),
              const SizedBox(height: 8),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Select date',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.grey500),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Correction Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: correctionType,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey500),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined, size: 20, color: AppColors.grey500),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'missed_clock_in', child: Text('Missed Clock In', style: TextStyle(fontSize: 15))),
                  DropdownMenuItem(value: 'missed_clock_out', child: Text('Missed Clock Out', style: TextStyle(fontSize: 15))),
                  DropdownMenuItem(value: 'wrong_time', child: Text('Wrong Time', style: TextStyle(fontSize: 15))),
                ],
                onChanged: (v) => setSheetState(() => correctionType = v!),
              ),
              const SizedBox(height: 20),

              const Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey700)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Explain why you are requesting this correction...',
                  hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true), 
                  child: const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5))
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );

    if (result == true && dateCtrl.text.isNotEmpty) {
      try {
        final repo = ref.read(attendanceRepositoryProvider);
        await repo.requestCorrection(
          date: dateCtrl.text.trim(),
          type: correctionType,
          reason: reasonCtrl.text.trim().isEmpty ? 'No reason provided' : reasonCtrl.text.trim(),
        );
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Correction request submitted'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider(_selectedMonth));
    final summaryAsync = ref.watch(attendanceSummaryProvider(_selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Column(
        children: [
          // Month picker
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: InkWell(
              onTap: _showMonthYearPicker,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_monthLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.grey600),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Summary Grid
                  summaryAsync.when(
                    data: (summary) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SummaryGrid(summary: summary),
                    ),
                    loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // Calendar Grid
                  historyAsync.when(
                    data: (records) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                                _selectedDay = null;
                              });
                            },
                            headerVisible: false,
                            daysOfWeekHeight: 24,
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              selectedDecoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              markerSize: 6,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                final record = records.where((r) => r.date != null && isSameDay(DateTime.parse(r.date!), date)).firstOrNull;
                                if (record != null) {
                                  Color markerColor;
                                  switch (record.status) {
                                    case 'present': markerColor = AppColors.success; break;
                                    case 'absent': markerColor = AppColors.danger; break;
                                    case 'late': markerColor = AppColors.warning; break;
                                    case 'half_day': markerColor = AppColors.info; break;
                                    default: markerColor = AppColors.grey400;
                                  }
                                  return Positioned(
                                    bottom: 6,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: markerColor),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 300, child: LoadingIndicator(message: 'Loading calendar...')),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Correction request button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCorrectionDialog(context),
                        icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                        label: const Text('Request Correction'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // History list
                  historyAsync.when(
                    data: (records) {
                      final filteredRecords = _selectedDay == null 
                          ? records 
                          : records.where((r) => r.date != null && isSameDay(DateTime.parse(r.date!), _selectedDay)).toList();

                      if (filteredRecords.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(child: Text(_selectedDay != null ? 'No record for this day' : 'No attendance records this month', style: const TextStyle(color: AppColors.grey400))),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredRecords.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _HistoryCard(record: filteredRecords[i]);
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(onPressed: () => ref.invalidate(attendanceHistoryProvider(_selectedMonth)), icon: const Icon(Icons.refresh), label: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  final AttendanceSummary summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Present', value: '${summary.present}', color: AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Absent', value: '${summary.absent}', color: AppColors.danger)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Late', value: '${summary.late}', color: AppColors.warning)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Half-Day', value: '${summary.halfDay}', color: AppColors.info)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TodayAttendance record;
  const _HistoryCard({required this.record});


  @override
  Widget build(BuildContext context) {
    final statusColor = record.status == 'present'
        ? AppColors.success
        : record.status == 'absent'
            ? AppColors.danger
            : record.status == 'late'
                ? AppColors.warning
                : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              record.status == 'present'
                  ? Icons.check_circle_outline
                  : record.status == 'absent'
                      ? Icons.cancel_outlined
                      : record.status == 'late'
                          ? Icons.access_time_filled_outlined
                          : Icons.bookmark_added_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date != null
                      ? formatDate(record.date)
                      : 'Unknown date',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('In: ${formatTime(record.clockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                    const SizedBox(width: 12),
                    Text('Out: ${formatTime(record.clockOut)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                  ],
                ),
                if (record.breakMinutes != null && record.breakMinutes! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.coffee_outlined, size: 12, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text('${record.breakMinutes} mins break', style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                    ],
                  ),
                ],
                if ((record.earlyClockInMinutes ?? 0) > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.blue.withAlpha(26), borderRadius: BorderRadius.circular(4)),
                        child: Text('Early In: ${record.earlyClockInMinutes! ~/ 60}h ${record.earlyClockInMinutes! % 60}m', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
                      ),
                      if ((record.approvedPreShiftOtMinutes ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.success.withAlpha(26), borderRadius: BorderRadius.circular(4)),
                          child: Text('OT Approved', style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (record.workHours != null)
                Text(formatDurationHours(record.workHours), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (record.status ?? '').replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              if (record.status == 'late' && record.lateMinutes != null && record.lateMinutes != 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${formatDurationMinutes(record.lateMinutes)} late',
                  style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}