import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  String get _monthLabel {
    try {
      final parts = _selectedMonth.split('-');
      final m = int.parse(parts[1]);
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[m - 1]} ${parts[0]}';
    } catch (_) {
      return _selectedMonth;
    }
  }

  void _changeMonth(int delta) {
    final parts = _selectedMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]) + delta;
    final newDate = DateTime(year, month);
    setState(() => _selectedMonth = DateFormat('yyyy-MM').format(newDate));
  }

  Future<void> _showCorrectionDialog(BuildContext context) async {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String correctionType = 'missed_clock_in';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Correction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: correctionType,
                decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                items: const [
                  DropdownMenuItem(value: 'missed_clock_in', child: Text('Missed Clock In')),
                  DropdownMenuItem(value: 'missed_clock_out', child: Text('Missed Clock Out')),
                  DropdownMenuItem(value: 'wrong_time', child: Text('Wrong Time')),
                ],
                onChanged: (v) => setDialogState(() => correctionType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Reason', prefixIcon: Icon(Icons.description)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Expanded(
                  child: Text(_monthLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),

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
          Expanded(
            child: historyAsync.when(
              data: (records) => records.isEmpty
                ? const Center(child: Text('No attendance records this month', style: TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = records[i];
                      return _HistoryCard(record: r);
                    },
                  ),
              loading: () => const LoadingIndicator(message: 'Loading history...'),
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

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

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
                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(record.date!))
                      : '—',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('In: ${_formatTime(record.clockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                    const SizedBox(width: 12),
                    Text('Out: ${_formatTime(record.clockOut)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (record.workHours != null)
                Text('${record.workHours!.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
            ],
          ),
        ],
      ),
    );
  }
}