import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setSheetState(() => selectedYear--),
                  ),
                  Text(
                    '$selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
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
                  childAspectRatio: 2.2,
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
                        color: isSelected
                            ? AppColors.primary
                            : (isCurrent
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.grey50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.grey200,
                        ),
                      ),
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isCurrent ? AppColors.primary : AppColors.grey800),
                          fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
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

  Future<void> _showCorrectionDialog(AppLocalizations l10n) async {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String correctionType = 'missed_clock_in';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.requestCorrection,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.grey500),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                l10n.requestCorrectionDesc,
                style: const TextStyle(color: AppColors.grey500, fontSize: 12),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.dateStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.selectDate,
                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.grey400),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                l10n.correctionType,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: correctionType,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey500),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined, size: 18, color: AppColors.grey400),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(value: 'missed_clock_in', child: Text(l10n.missedClockIn, style: const TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'missed_clock_out', child: Text(l10n.missedClockOut, style: const TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'wrong_time', child: Text(l10n.wrongTime, style: const TextStyle(fontSize: 14))),
                ],
                onChanged: (v) => setSheetState(() => correctionType = v!),
              ),
              const SizedBox(height: 14),

              Text(
                l10n.reason,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.explainCorrectionReason,
                  hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    l10n.submitRequest,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.correctionSubmitted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(attendanceHistoryProvider(_selectedMonth));
    final summaryAsync = ref.watch(attendanceSummaryProvider(_selectedMonth));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.attendanceHistory,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
            tooltip: l10n.requestCorrection,
            onPressed: () => _showCorrectionDialog(l10n),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(attendanceHistoryProvider(_selectedMonth));
              ref.invalidate(attendanceSummaryProvider(_selectedMonth));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceHistoryProvider(_selectedMonth));
          ref.invalidate(attendanceSummaryProvider(_selectedMonth));
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Month Selector Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showMonthYearPicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.grey200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _monthLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.grey500),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCorrectionDialog(l10n),
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: Text(l10n.requestCorrection),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Monthly Summary Stats Strip ──
              summaryAsync.when(
                data: (summary) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _SummaryGrid(summary: summary, l10n: l10n),
                ),
                loading: () => const SizedBox(
                  height: 70,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // ── Calendar View ──
              historyAsync.when(
                data: (records) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          markerSize: 5,
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final record = records.where((r) => r.date != null && isSameDay(DateTime.parse(r.date!), date)).firstOrNull;
                            if (record != null) {
                              Color markerColor;
                              switch (record.status) {
                                case 'present':
                                  markerColor = AppColors.success;
                                  break;
                                case 'absent':
                                  markerColor = AppColors.danger;
                                  break;
                                case 'late':
                                  markerColor = AppColors.warning;
                                  break;
                                case 'half_day':
                                  markerColor = AppColors.info;
                                  break;
                                default:
                                  markerColor = AppColors.grey400;
                              }
                              return Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: markerColor,
                                  ),
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
                loading: () => const SizedBox(
                  height: 280,
                  child: Center(child: LoadingIndicator(message: 'Loading calendar...')),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // ── Daily History Section Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDay != null ? 'Records for ${DateFormat('MMM d').format(_selectedDay!)}' : 'Daily Logs',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    if (_selectedDay != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDay = null),
                        child: const Text(
                          'Show All Month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Daily History List ──
              historyAsync.when(
                data: (records) {
                  final filteredRecords = _selectedDay == null
                      ? records
                      : records.where((r) => r.date != null && isSameDay(DateTime.parse(r.date!), _selectedDay)).toList();

                  if (filteredRecords.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          _selectedDay != null ? l10n.noRecordForThisDay : l10n.noRecordsThisMonth,
                          style: const TextStyle(color: AppColors.grey400),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: filteredRecords.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      return _HistoryCard(record: filteredRecords[i], l10n: l10n);
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
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(attendanceHistoryProvider(_selectedMonth)),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary Metrics Strip ───────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  final AttendanceSummary summary;
  final AppLocalizations l10n;
  const _SummaryGrid({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: l10n.present,
            value: '${summary.present}',
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: l10n.absent,
            value: '${summary.absent}',
            color: AppColors.danger,
            icon: Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: l10n.late,
            value: '${summary.late}',
            color: AppColors.warning,
            icon: Icons.access_time_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: l10n.halfDay,
            value: '${summary.halfDay}',
            color: AppColors.info,
            icon: Icons.timelapse_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Daily History Card ──────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final TodayAttendance record;
  final AppLocalizations l10n;
  const _HistoryCard({required this.record, required this.l10n});

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon Bubble
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              record.status == 'present'
                  ? Icons.check_circle_rounded
                  : record.status == 'absent'
                      ? Icons.cancel_rounded
                      : record.status == 'late'
                          ? Icons.alarm_rounded
                          : Icons.bookmark_added_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Date & Time Columns
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date != null ? formatDate(record.date) : l10n.unknownDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.grey900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 3),
                    Text(formatTime(record.clockIn), style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    const Icon(Icons.logout_rounded, size: 12, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(formatTime(record.clockOut), style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (record.breakMinutes != null && record.breakMinutes! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.coffee_outlined, size: 12, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text('${record.breakMinutes}${l10n.minsBreak}', style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                    ],
                  ),
                ],
                if ((record.earlyClockInMinutes ?? 0) > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '${l10n.earlyIn}${record.earlyClockInMinutes! ~/ 60}${l10n.hLabel}${record.earlyClockInMinutes! % 60}${l10n.mLabel}',
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if ((record.approvedPreShiftOtMinutes ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(l10n.otApproved, style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Total Hours & Status Pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (record.workHours != null)
                Text(
                  formatDurationHours(record.workHours),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey900),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (record.status ?? '').replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.3),
                ),
              ),
              if (record.status == 'late' && record.lateMinutes != null && record.lateMinutes != 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${formatDurationMinutes(record.lateMinutes)}${l10n.lateLabel}',
                  style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}