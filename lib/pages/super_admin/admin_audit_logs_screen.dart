
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_audit_logs_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.auditLogsTitle,
          style: const TextStyle(
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
          error: (err, _) => _buildError(context, err, ref, l10n),
          data: (logs) => _buildList(context, logs, l10n),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(l10n.failedToLoadAuditLogs,
                style: const TextStyle(
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
              label: Text(l10n.retry),
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

  Widget _buildList(BuildContext context, List<AdminAuditLog> logs, AppLocalizations l10n) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(l10n.noAuditLogsYet,
                style: const TextStyle(
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
          child: InkWell(
            onTap: () => _showDetails(context, log, l10n),
            borderRadius: BorderRadius.circular(12),
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
                                l10n.byUser(log.performedBy!),
                              if (log.createdAt != null) '• ${_formatDate(log.createdAt)}',
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

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  void _showDetails(BuildContext context, AdminAuditLog log, AppLocalizations l10n) {
    if (log.changes == null || log.changes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noDetailsAvailable),
          backgroundColor: AppColors.grey800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final changes = log.changes!;
    final attributes = changes['attributes'] as Map<String, dynamic>? ?? {};
    final old = changes['old'] as Map<String, dynamic>? ?? {};

    final hasStandardStructure = attributes.isNotEmpty || old.isNotEmpty;
    final dataToShow = hasStandardStructure ? attributes : changes;
    final keys = dataToShow.keys.where((k) => k != 'created_at' && k != 'updated_at').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.changesTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: keys.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.grey200, height: 1),
                  ),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final newValue = dataToShow[key]?.toString() ?? 'null';
                    final oldValue = hasStandardStructure ? (old[key]?.toString() ?? 'null') : null;
                    
                    final displayKey = key.replaceAll('_', ' ').replaceAllMapped(
                        RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayKey,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasStandardStructure && old.containsKey(key))
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  oldValue!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.danger,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.grey400),
                              ),
                              Expanded(
                                child: Text(
                                  newValue,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            newValue,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.grey800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.closeBtn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}