import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surfaceLight,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Daily Logs'),
              Tab(text: 'Corrections'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DailyLogsTab(),
              _CorrectionsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyLogsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allAttendanceLogsProvider);
    return logsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No attendance records', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                final statusColor = c.status == 'present' ? AppColors.success : c.status == 'late' || c.status == 'early_leave' ? AppColors.warning : AppColors.danger;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.access_time, color: statusColor, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(formatDate(c.date), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(c.status.substring(0, 1).toUpperCase() + c.status.substring(1).replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                        ],
                      ),
                      if (c.clockIn != null || c.clockOut != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          if (c.clockIn != null) Text('In: ${formatTime(c.clockIn)}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                          if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                          if (c.clockOut != null) Text('Out: ${formatTime(c.clockOut)}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ]),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading logs...'),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(allAttendanceLogsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}

class _CorrectionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    return correctionsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No pending corrections', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                final statusColor = c.status == 'approved' ? AppColors.success : c.status == 'rejected' ? AppColors.danger : AppColors.warning;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.access_time, color: statusColor, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(formatDate(c.date), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(c.status.substring(0, 1).toUpperCase() + c.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                        ],
                      ),
                      if (c.clockIn != null || c.clockOut != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          if (c.clockIn != null) Text('In: ${formatTime(c.clockIn)}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                          if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                          if (c.clockOut != null) Text('Out: ${formatTime(c.clockOut)}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ]),
                      ],
                      if (c.reason != null && c.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                          child: Text('Reason: ${c.reason}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ),
                      ],
                      if (c.status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => _handleAction(context, ref, c.id, false), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('Reject'))),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton(onPressed: () => _handleAction(context, ref, c.id, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text('Approve'))),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading corrections...'),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(attendanceCorrectionsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, int id, bool isApprove) async {
    try {
      if (isApprove) {
        await ref.read(adminOpsRepositoryProvider).approveCorrection(id);
      } else {
        await ref.read(adminOpsRepositoryProvider).rejectCorrection(id);
      }
      ref.invalidate(attendanceCorrectionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isApprove ? '✅ Correction approved' : '❌ Correction rejected'), backgroundColor: isApprove ? AppColors.success : AppColors.danger));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger));
    }
  }
}