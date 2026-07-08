import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_audit_logs_repository.dart';

final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<AdminAuditLog>>((ref) {
  return AdminAuditLogsRepository().getAuditLogs();
});

class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  static const _actionIcons = <String, IconData>{
    'login': Icons.login_rounded,
    'logout': Icons.logout_rounded,
    'update_company': Icons.business_rounded,
    'create_user': Icons.person_add_rounded,
    'delete_announcement': Icons.campaign_rounded,
    'update_settings': Icons.settings_rounded,
    'suspend_company': Icons.block_rounded,
    'approve_ticket': Icons.check_circle_rounded,
    'create_company': Icons.add_business_rounded,
    'delete': Icons.delete_forever_rounded,
    'update': Icons.edit_rounded,
    'create': Icons.add_circle_outline_rounded,
    'created': Icons.add_circle_outline_rounded,
    'updated': Icons.edit_rounded,
    'deleted': Icons.delete_forever_rounded,
  };

  static const _dangerActions = {
    'suspend_company',
    'delete_announcement',
    'delete',
    'deleted',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Audit Logs',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminAuditLogsProvider),
        child: logsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(context, err, ref),
          data: (logs) => _buildList(context, logs),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load audit logs',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminAuditLogsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AdminAuditLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text('No audit logs yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final actionLower = log.action.toLowerCase();
        final isDanger = _dangerActions.contains(actionLower);
        final icon = _actionIcons.entries
            .firstWhere(
              (e) => actionLower.contains(e.key),
              orElse: () => const MapEntry(
                  'default', Icons.info_outline_rounded),
            )
            .value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDanger
                        ? AppColors.dangerLight
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color:
                        isDanger ? AppColors.danger : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatAction(log.action),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.grey800,
                        ),
                      ),
                      if (log.performedBy != null || log.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            [
                              if (log.performedBy != null)
                                'By ${log.performedBy}',
                              if (log.createdAt != null) '• ${log.createdAt}',
                            ].join(' '),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (log.description != null && log.description!.isNotEmpty)
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.grey300),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'\b\w'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }
}