import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/attendance/data/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/features/attendance/presentation/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAttendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: todayAsync.when(
        data: (today) => _buildContent(context, ref, today),
        loading: () => const LoadingIndicator(message: 'Loading...'),
        error: (error, _) => _buildError(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            const Text('Failed to load attendance', style: TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(todayAttendanceProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TodayAttendance? today) {
    final isClockedIn = today?.clockIn != null && today?.clockOut == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Clock In/Out Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isClockedIn
                    ? [AppColors.success, const Color(0xFF16A34A)]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isClockedIn ? AppColors.success : AppColors.primary).withAlpha(51),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isClockedIn ? Icons.timer : Icons.access_time,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  today?.date ?? 'Today',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (isClockedIn) ...[
                  Text(
                    'Clocked in at ${_formatTime(today!.clockIn!)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (today.workHours != null)
                    Text(
                      'Working: ${today.workHours!.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                ] else if (today?.clockOut != null) ...[
                  const Text(
                    'Shift completed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (today!.workHours != null)
                    Text(
                      '${today.workHours!.toStringAsFixed(1)} hours today',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                ] else ...[
                  const Text(
                    'Not clocked in yet',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isClockedIn ? null : () => _handleClockIn(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Clock In'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: isClockedIn ? () => _handleClockOut(context, ref) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Clock Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today's Log
          const Text('Today\'s Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
          const SizedBox(height: 12),
          if (today == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: const Center(
                child: Text('No records yet — tap Clock In to start', style: TextStyle(color: AppColors.grey400)),
              ),
            )
          else ...[
            _LogRow(label: 'Clock In', value: _formatTime(today.clockIn)),
            if (today.clockOut != null) _LogRow(label: 'Clock Out', value: _formatTime(today.clockOut!)),
            if (today.status != null) _LogRow(label: 'Status', value: (today.status ?? '').replaceAll('_', ' ')),
            if (today.workHours != null) _LogRow(label: 'Work Hours', value: '${today.workHours!.toStringAsFixed(1)}h'),
          ],
        ],
      ),
    );
  }

  Future<void> _handleClockIn(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.clockIn();
      ref.invalidate(todayAttendanceProvider);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Clocked in successfully'), backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _handleClockOut(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.clockOut();
      ref.invalidate(todayAttendanceProvider);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Clocked out successfully'), backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      // Handle both "HH:mm:ss" and "YYYY-MM-DD HH:mm:ss" formats
      final parts = timeStr.split(' ');
      final timePart = parts.length > 1 ? parts[1] : parts[0];
      final time = timePart.split(':');
      final hour = int.parse(time[0]);
      final minute = time[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return timeStr;
    }
  }
}

class _LogRow extends StatelessWidget {
  final String label;
  final String? value;
  const _LogRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey500)),
            Text(value ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey800)),
          ],
        ),
      ),
    );
  }
}