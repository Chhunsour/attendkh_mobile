import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
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
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
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
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthName = DateFormat(
                    'MMM',
                  ).format(DateTime(2000, month));
                  final isCurrent =
                      selectedYear == DateTime.now().year &&
                      month == DateTime.now().month;
                  final isSelected =
                      selectedYear == _focusedDay.year &&
                      month == _focusedDay.month;

                  return InkWell(
                    onTap: () =>
                        Navigator.pop(ctx, DateTime(selectedYear, month, 1)),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isCurrent
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : (isDark
                                        ? AppColors.surfaceDarkElevated
                                        : AppColors.grey50)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.grey200),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          monthName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isCurrent
                                      ? AppColors.primary
                                      : (isDark
                                            ? Colors.white
                                            : AppColors.grey800)),
                            fontWeight: isSelected || isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
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
    final clockInCtrl = TextEditingController();
    final clockOutCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String correctionType = 'missed_clock_in';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isSubmitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.requestCorrection,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.requestCorrectionDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.dateStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.grey300 : AppColors.grey700,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 60),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateCtrl.text =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  }
                },
                decoration: InputDecoration(
                  hintText: 'YYYY-MM-DD',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                l10n.correctionType,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.grey300 : AppColors.grey700,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: correctionType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                dropdownColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                items: [
                  DropdownMenuItem(
                    value: 'missed_clock_in',
                    child: Text(
                      l10n.missedClockIn,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'missed_clock_out',
                    child: Text(
                      l10n.missedClockOut,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'wrong_time',
                    child: Text(
                      l10n.wrongTime,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                onChanged: (v) => setSheetState(() => correctionType = v!),
              ),
              const SizedBox(height: 14),

              // Requested Times
              Row(
                children: [
                  if (correctionType != 'missed_clock_out') ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.inTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.grey300 : AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: clockInCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (picked != null) {
                                clockInCtrl.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'HH:MM',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.grey500 : AppColors.grey400,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                              suffixIcon: const Icon(Icons.access_time_rounded, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (correctionType == 'wrong_time') const SizedBox(width: 10),
                  if (correctionType != 'missed_clock_in') ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.outTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.grey300 : AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: clockOutCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (picked != null) {
                                clockOutCtrl.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'HH:MM',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.grey500 : AppColors.grey400,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                              suffixIcon: const Icon(Icons.access_time_rounded, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              Text(
                l10n.reason,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.grey300 : AppColors.grey700,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.explainCorrectionReason,
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (dateCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(l10n.selectDate)),
                                );
                                return;
                              }
                              if (reasonCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(l10n.fieldRequired)),
                                );
                                return;
                              }
                              setSheetState(() => isSubmitting = true);
                              try {
                                await ref.read(attendanceRepositoryProvider).requestCorrection(
                                  date: dateCtrl.text,
                                  type: correctionType,
                                  reason: reasonCtrl.text.trim(),
                                  clockIn: clockInCtrl.text.isNotEmpty ? clockInCtrl.text : null,
                                  clockOut: clockOutCtrl.text.isNotEmpty ? clockOutCtrl.text : null,
                                );
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                  setSheetState(() => isSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.submit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.correctionSubmitted),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = null;
    });
  }

  void _refresh() {
    ref.invalidate(attendanceHistoryProvider(_selectedMonth));
    ref.invalidate(attendanceSummaryProvider(_selectedMonth));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(attendanceSummaryProvider(_selectedMonth));
    final historyAsync = ref.watch(attendanceHistoryProvider(_selectedMonth));

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppColors.primary,
          // The hero runs under the status bar, so the spinner has to drop
          // below it rather than sit on the notch.
          edgeOffset: MediaQuery.paddingOf(context).top + 8,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, l10n, isDark, summaryAsync),

                const SizedBox(height: 18),

                // ── Calendar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: historyAsync.when(
                    data: (records) =>
                        _buildCalendarCard(context, l10n, isDark, records),
                    loading: () => Container(
                      height: 320,
                      decoration: _cardDecoration(context, isDark),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),

                const SizedBox(height: 22),

                // ── Daily logs ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedDay != null
                              ? DateFormat(
                                  'EEEE, d MMMM',
                                ).format(_selectedDay!)
                              : l10n.dailyLogs,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: AppColors.textPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedDay != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedDay = null),
                          icon: const Icon(Icons.close_rounded, size: 15),
                          label: Text(l10n.clear),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                historyAsync.when(
                  data: (records) {
                    final filtered = _selectedDay == null
                        ? records
                        : records
                              .where(
                                (r) =>
                                    r.date != null &&
                                    isSameDay(
                                      DateTime.parse(r.date!),
                                      _selectedDay,
                                    ),
                              )
                              .toList();

                    if (filtered.isEmpty) {
                      return _emptyLogs(context, l10n, isDark);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _HistoryCard(record: filtered[i], l10n: l10n),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context, bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Gradient hero: same slab as the dashboard. It carries the month
  // stepper and the month's tally, so the body is left to the calendar. ──
  Widget _buildHero(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    AsyncValue<AttendanceSummary> summaryAsync,
  ) {
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);
    final summary = summaryAsync.valueOrNull;

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
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _heroIconButton(
                      Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.main);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.attendanceHistory,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _heroIconButton(
                      Icons.add_rounded,
                      tooltip: l10n.requestCorrection,
                      onTap: () => _showCorrectionDialog(l10n),
                    ),
                    const SizedBox(width: 8),
                    _heroIconButton(Icons.refresh_rounded, onTap: _refresh),
                  ],
                ),

                const SizedBox(height: 20),

                // Month stepper: arrows for the common ±1 hop, the label
                // itself for jumping somewhere far away.
                Row(
                  children: [
                    _heroIconButton(
                      Icons.chevron_left_rounded,
                      size: 34,
                      onTap: () => _shiftMonth(-1),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _showMonthYearPicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _monthLabel,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _heroIconButton(
                      Icons.chevron_right_rounded,
                      size: 34,
                      onTap: () => _shiftMonth(1),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _heroStat(
                        l10n.present,
                        summary?.present,
                        const Color(0xFF6EE7B7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _heroStat(
                        l10n.absent,
                        summary?.absent,
                        const Color(0xFFFCA5A5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _heroStat(
                        l10n.late,
                        summary?.late,
                        const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _heroStat(
                        l10n.halfDay,
                        summary?.halfDay,
                        const Color(0xFF93C5FD),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(
    IconData icon, {
    required VoidCallback onTap,
    String? tooltip,
    double size = 38,
  }) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.47, color: Colors.white),
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip, child: button);
  }

  Widget _heroStat(String label, int? value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value?.toString() ?? '—',
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar card, now with a legend. The dots meant nothing before. ──
  Widget _buildCalendarCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    List<TodayAttendance> records,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      decoration: _cardDecoration(context, isDark),
      child: Column(
        children: [
          TableCalendar(
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
            daysOfWeekHeight: 26,
            rowHeight: 46,
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(5),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              defaultTextStyle: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
              weekendTextStyle: TextStyle(
                color: isDark ? AppColors.grey400 : AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
              outsideTextStyle: TextStyle(
                color: isDark ? AppColors.grey600 : AppColors.grey300,
              ),
              markersMaxCount: 1,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDark ? AppColors.grey400 : AppColors.grey500,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
              weekendStyle: TextStyle(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final record = records
                    .where(
                      (r) =>
                          r.date != null &&
                          isSameDay(DateTime.parse(r.date!), date),
                    )
                    .firstOrNull;
                if (record == null) return null;
                // A short underline reads as a status bar under the date and
                // survives being drawn over the selected-day fill.
                return Positioned(
                  bottom: 5,
                  child: Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _statusColor(record.status),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 18, thickness: 0.6),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _legendDot(l10n.present, AppColors.success, isDark),
                _legendDot(l10n.absent, AppColors.danger, isDark),
                _legendDot(l10n.late, AppColors.warning, isDark),
                _legendDot(l10n.halfDay, AppColors.info, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'late':
        return AppColors.warning;
      case 'half_day':
        return AppColors.info;
      default:
        return AppColors.grey400;
    }
  }

  Widget _legendDot(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _emptyLogs(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 50),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: _cardDecoration(context, isDark),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 26,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedDay != null
                  ? l10n.noRecordForThisDay
                  : l10n.noRecordsThisMonth,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                  record.date != null
                      ? formatDate(record.date)
                      : l10n.unknownDate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      formatTime(record.clockIn),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.grey300 : AppColors.grey700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.logout_rounded,
                      size: 12,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      formatTime(record.clockOut),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.grey300 : AppColors.grey700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (record.breakMinutes != null &&
                    record.breakMinutes! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.coffee_outlined,
                        size: 12,
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.breakMinutes}${l10n.minsBreak}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
                if ((record.earlyClockInMinutes ?? 0) > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${l10n.earlyIn}${record.earlyClockInMinutes! ~/ 60}${l10n.hLabel}${record.earlyClockInMinutes! % 60}${l10n.mLabel}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if ((record.approvedPreShiftOtMinutes ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.otApproved,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
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
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (record.status == 'late' &&
                  record.lateMinutes != null &&
                  record.lateMinutes != 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${formatDurationMinutes(record.lateMinutes)}${l10n.lateLabel}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
