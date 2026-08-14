import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_audit_logs_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final adminAuditLogsProvider =
    FutureProvider.autoDispose<AdminAuditLogsPayload>((ref) {
      return AdminAuditLogsRepository().getAuditLogs();
    });

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _eventFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    'delete': Icons.delete_outline_rounded,
    'update': Icons.edit_rounded,
    'create': Icons.add_circle_outline_rounded,
    'created': Icons.add_circle_outline_rounded,
    'updated': Icons.edit_rounded,
    'deleted': Icons.delete_outline_rounded,
  };

  Color _eventColor(String? event) {
    switch (event?.toLowerCase()) {
      case 'created':
        return const Color(0xFF10B981);
      case 'updated':
        return const Color(0xFF6366F1);
      case 'deleted':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _eventBgColor(String? event) {
    switch (event?.toLowerCase()) {
      case 'created':
        return const Color(0xFFECFDF5);
      case 'updated':
        return const Color(0xFFEEF2FF);
      case 'deleted':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.auditLogsTitle,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminAuditLogsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminAuditLogsProvider),
        child: logsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(err, l10n),
          data: (payload) => _buildContent(payload, l10n),
        ),
      ),
    );
  }

  Widget _buildError(Object err, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadAuditLogs,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminAuditLogsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AdminAuditLogsPayload payload, AppLocalizations l10n) {
    final createCount = payload.logs.where((l) => l.event == 'created').length;
    final updateCount = payload.logs.where((l) => l.event == 'updated').length;
    final deleteCount = payload.logs.where((l) => l.event == 'deleted').length;

    var filtered = payload.logs.where((log) {
      final matchesSearch =
          _searchTerm.isEmpty ||
          log.action.toLowerCase().contains(_searchTerm) ||
          (log.performedBy?.toLowerCase().contains(_searchTerm) ?? false) ||
          (log.subjectType?.toLowerCase().contains(_searchTerm) ?? false) ||
          (log.event?.toLowerCase().contains(_searchTerm) ?? false);
      final matchesEvent = _eventFilter == 'all' || log.event == _eventFilter;
      return matchesSearch && matchesEvent;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Overview Metric Cards ──
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Logs',
                value: '${payload.logs.length}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Created',
                value: '$createCount',
                icon: Icons.add_circle_outline_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Updated',
                value: '$updateCount',
                icon: Icons.edit_rounded,
                color: const Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Deleted',
                value: '$deleteCount',
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Search Field ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchTerm = val.trim().toLowerCase()),
            style: const TextStyle(fontSize: 13.5, color: AppColors.grey900),
            decoration: InputDecoration(
              hintText: 'Search action, user, or model...',
              hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 18),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.grey400, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchTerm = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Event Filter Chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All (${payload.logs.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Created ($createCount)', 'created'),
              const SizedBox(width: 8),
              _buildFilterChip('Updated ($updateCount)', 'updated'),
              const SizedBox(width: 8),
              _buildFilterChip('Deleted ($deleteCount)', 'deleted'),
              ...payload.events
                  .where((e) => e != 'created' && e != 'updated' && e != 'deleted')
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildFilterChip(e[0].toUpperCase() + e.substring(1), e),
                      )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── List of Logs ──
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  _searchTerm.isNotEmpty ? 'No audit records matching "$_searchTerm"' : l10n.noAuditLogsYet,
                  style: const TextStyle(color: AppColors.grey600, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.map((log) => _buildLogCard(log, l10n)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _eventFilter == value;
    return InkWell(
      onTap: () => setState(() => _eventFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(AdminAuditLog log, AppLocalizations l10n) {
    final actionLower = log.action.toLowerCase();
    final evColor = _eventColor(log.event);
    final evBg = _eventBgColor(log.event);
    final icon = _actionIcons.entries
        .firstWhere(
          (e) => actionLower.contains(e.key),
          orElse: () => const MapEntry('default', Icons.receipt_long_rounded),
        )
        .value;

    final hasChanges = log.changes != null && log.changes!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasChanges ? () => _showDetails(log, l10n) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: evBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: evColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _formatAction(log.action),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.grey900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (log.event != null && log.event!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: evBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log.event!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: evColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (log.performedBy != null) ...[
                            const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.grey500),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                log.performedBy!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (log.subjectType != null && log.subjectType!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: AppColors.grey400, fontSize: 11)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                log.subjectType!,
                                style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (log.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(log.createdAt),
                          style: const TextStyle(fontSize: 10.5, color: AppColors.grey400),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasChanges) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.grey400,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year} $hour:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return rawDate;
    }
  }

  void _showDetails(AdminAuditLog log, AppLocalizations l10n) {
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
    final keys = dataToShow.keys
        .where((k) => k != 'created_at' && k != 'updated_at')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AUDIT DIFF',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.changesTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.grey500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: keys.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.grey200, height: 16),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final newValue = dataToShow[key]?.toString() ?? 'null';
                    final oldValue = hasStandardStructure
                        ? (old[key]?.toString() ?? 'null')
                        : null;

                    final displayKey = key
                        .replaceAll('_', ' ')
                        .replaceAllMapped(
                          RegExp(r'\b\w'),
                          (m) => m.group(0)!.toUpperCase(),
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayKey,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
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
                                    fontSize: 13,
                                    color: AppColors.danger,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.grey400,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  newValue,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            newValue,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.closeBtn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
