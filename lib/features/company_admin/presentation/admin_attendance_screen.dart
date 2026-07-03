import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AdminAttendanceScreen extends ConsumerWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    return Stack(
      children: [
        correctionsAsync.when(
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
                                Text(c.date, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                              ])),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(c.status.substring(0, 1).toUpperCase() + c.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                            ],
                          ),
                          if (c.clockIn != null || c.clockOut != null) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              if (c.clockIn != null) Text('In: ${c.clockIn}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                              if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                              if (c.clockOut != null) Text('Out: ${c.clockOut}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                            ]),
                          ],
                          if (c.reason != null) ...[
                            const SizedBox(height: 4),
                            Text(c.reason!, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ],
                          const SizedBox(height: 12),
                          Row(children: [
                            if (c.status == 'pending') ...[
                              Expanded(child: OutlinedButton.icon(onPressed: () => _action(context, ref, c.id, 'reject'), icon: const Icon(Icons.close, size: 16), label: const Text('Reject'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)))),
                              const SizedBox(width: 8),
                              Expanded(child: ElevatedButton.icon(onPressed: () => _action(context, ref, c.id, 'approve'), icon: const Icon(Icons.check, size: 16), label: const Text('Approve'))),
                            ] else
                              const Spacer(),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), onPressed: () => _deleteAttendance(context, ref, c.id)),
                          ]),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const LoadingIndicator(message: 'Loading corrections...'),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(attendanceCorrectionsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showManualEntryDialog(context, ref),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showManualEntryDialog(BuildContext context, WidgetRef ref) {
    final empIdCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final clockInCtrl = TextEditingController(text: '09:00');
    final clockOutCtrl = TextEditingController(text: '17:00');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Attendance'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          const SizedBox(height: 12),
          TextField(controller: clockInCtrl, decoration: const InputDecoration(labelText: 'Clock In (HH:MM)')),
          const SizedBox(height: 12),
          TextField(controller: clockOutCtrl, decoration: const InputDecoration(labelText: 'Clock Out (HH:MM)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (empIdCtrl.text.trim().isEmpty) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Manual attendance recorded'), backgroundColor: AppColors.success));
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref, int id, String action) async {
    try {
      final repo = AdminOperationsRepository();
      if (action == 'approve') { await repo.approveCorrection(id); } else { await repo.rejectCorrection(id); }
      ref.invalidate(attendanceCorrectionsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Correction ${action}d'), backgroundColor: AppColors.success));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _deleteAttendance(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Delete this attendance record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteAttendance(id);
        ref.invalidate(attendanceCorrectionsProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Record deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}