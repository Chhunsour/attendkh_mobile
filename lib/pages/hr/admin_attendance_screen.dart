import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.attendanceLogsTitle,
                    style: const TextStyle(
                        color: AppColors.grey800,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
                Text(AppLocalizations.of(context)!.attendanceLogsSubtitle,
                    style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 11,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabDailyLogs),
            Tab(text: AppLocalizations.of(context)!.tabCorrections),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DailyLogsTab(),
          _CorrectionsTab(),
        ],
      ),
    );
  }
}


class _DailyLogsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allAttendanceLogsProvider);
    final l10n = AppLocalizations.of(context)!;
    return logsAsync.when(
      data: (items) => items.isEmpty
          ? Center(child: Text(l10n.noAttendanceRecords, style: const TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                final statusColor = c.status == 'present' ? AppColors.success : c.status == 'late' || c.status == 'early_leave' ? AppColors.warning : AppColors.danger;
                
                final hasUnapprovedEarlyIn = (c.earlyClockInMinutes ?? 0) > 0 && (c.approvedPreShiftOtMinutes ?? 0) == 0;
                
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
                          if (c.clockIn != null) Text('${l10n.inTime}: ${formatTime(c.clockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                          if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                          if (c.clockOut != null) Text('${l10n.outTime}: ${formatTime(c.clockOut)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ]),
                      ],
                      if ((c.earlyClockInMinutes ?? 0) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.withAlpha(26), borderRadius: BorderRadius.circular(4)),
                              child: Text('${l10n.earlyIn}: ${c.earlyClockInMinutes! ~/ 60}h ${c.earlyClockInMinutes! % 60}m', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
                            ),
                            if ((c.approvedPreShiftOtMinutes ?? 0) > 0)
                              Text('${l10n.approved}: ${c.approvedPreShiftOtMinutes! ~/ 60}h ${c.approvedPreShiftOtMinutes! % 60}m', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                      if (hasUnapprovedEarlyIn) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _handleApproveOt(context, ref, c.id),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 8)),
                            child: Text(l10n.approvePreShiftOT, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => LoadingIndicator(message: l10n.loadingLogs),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(allAttendanceLogsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ),
    );
  }

  Future<void> _handleApproveOt(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(adminOpsRepositoryProvider).approveOvertime(id);
      ref.invalidate(allAttendanceLogsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.preShiftOtApprovedSuccess), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.failedMessage(e.toString())), backgroundColor: AppColors.danger));
      }
    }
  }
}

class _CorrectionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    final l10n = AppLocalizations.of(context)!;
    return correctionsAsync.when(
      data: (items) => items.isEmpty
          ? Center(child: Text(l10n.noPendingCorrections, style: const TextStyle(color: AppColors.grey400)))
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
                          if (c.clockIn != null) Text('${l10n.inTime}: ${formatTime(c.clockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                          if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                          if (c.clockOut != null) Text('${l10n.outTime}: ${formatTime(c.clockOut)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ]),
                      ],
                      if (c.reason != null && c.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                          child: Text('${l10n.reason}: ${c.reason}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ),
                      ],
                      if (c.status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => _handleAction(context, ref, c.id, false), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), child: Text(l10n.reject))),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton(onPressed: () => _handleAction(context, ref, c.id, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: Text(l10n.approve))),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => LoadingIndicator(message: l10n.loadingLogs),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(attendanceCorrectionsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, int id, bool approve) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (approve) {
        await ref.read(adminOpsRepositoryProvider).approveCorrection(id);
      } else {
        await ref.read(adminOpsRepositoryProvider).rejectCorrection(id);
      }
      ref.invalidate(attendanceCorrectionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? l10n.correctionApprovedSuccess : l10n.correctionRejectedSuccess), backgroundColor: approve ? AppColors.success : AppColors.danger));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.failedMessage(e.toString())), backgroundColor: AppColors.danger));
      }
    }
  }
}