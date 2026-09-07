import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/utils/utils/date_format_utils.dart';

class CorrectionsTab extends ConsumerStatefulWidget {
  const CorrectionsTab({super.key});

  @override
  ConsumerState<CorrectionsTab> createState() => _CorrectionsTabState();
}

class _CorrectionsTabState extends ConsumerState<CorrectionsTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'pending' | 'approved' | 'rejected'

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _statusFilter = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return correctionsAsync.when(
      data: (items) {
        final totalCount = items.length;
        final pendingCount = items.where((c) => c.status == 'pending').length;
        final approvedCount = items.where((c) => c.status == 'approved').length;
        final rejectedCount = items.where((c) => c.status == 'rejected').length;

        final filteredItems = items.where((c) {
          if (_statusFilter != 'all' && c.status != _statusFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final name = c.employeeName.toLowerCase();
            final code = (c.employeeCode ?? '').toLowerCase();
            final date = c.date.toLowerCase();
            final reason = (c.reason ?? '').toLowerCase();
            if (!name.contains(_searchQuery) &&
                !code.contains(_searchQuery) &&
                !date.contains(_searchQuery) &&
                !reason.contains(_searchQuery)) {
              return false;
            }
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search and Status Tabs Bar
            Container(
              color: AppColors.surface(context),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(
                        () => _searchQuery = val.trim().toLowerCase(),
                      ),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search employee, ID, reason, date...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.grey400,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.grey700 : AppColors.grey200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildStatusChip('all', 'All', totalCount, const Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        _buildStatusChip('pending', 'Pending', pendingCount, const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _buildStatusChip('approved', 'Approved', approvedCount, const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildStatusChip('rejected', 'Rejected', rejectedCount, const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.grey200),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF10B981),
                onRefresh: () async =>
                    ref.invalidate(attendanceCorrectionsProvider),
                child: filteredItems.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty || _statusFilter != 'all'
                                        ? Icons.filter_alt_off_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 48,
                                    color: _searchQuery.isNotEmpty || _statusFilter != 'all'
                                        ? AppColors.grey400
                                        : const Color(0xFF10B981),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty || _statusFilter != 'all'
                                        ? 'No correction requests match your filters'
                                        : l10n.noPendingCorrections,
                                    style: const TextStyle(
                                      color: AppColors.grey600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty || _statusFilter != 'all') ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _clearFilters,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reset Filters',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = filteredItems[i];
                          final (statusColor, statusBg) = switch (c.status) {
                            'approved' => (
                              const Color(0xFF10B981),
                              const Color(0xFFECFDF5),
                            ),
                            'rejected' => (
                              const Color(0xFFEF4444),
                              const Color(0xFFFEF2F2),
                            ),
                            _ => (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                          };

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.grey200.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.employeeName.isNotEmpty
                                              ? c.employeeName.characters.first.toUpperCase()
                                              : 'E',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.employeeName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              if (c.employeeCode != null && c.employeeCode!.isNotEmpty) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    c.employeeCode!,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontFamily: 'monospace',
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.grey600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Text(
                                                formatDate(c.date),
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.grey500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c.status.isEmpty
                                            ? 'Unknown'
                                            : (c.status[0].toUpperCase() +
                                                  c.status.substring(1)),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (c.clockIn != null || c.clockOut != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        if (c.clockIn != null)
                                          Expanded(
                                            child: Text(
                                              '${l10n.inTime}: ${formatTime(c.clockIn)}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary(context),
                                              ),
                                            ),
                                          ),
                                        if (c.clockOut != null)
                                          Expanded(
                                            child: Text(
                                              '${l10n.outTime}: ${formatTime(c.clockOut)}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary(context),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (c.reason != null && c.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${l10n.reason}: ${c.reason}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.grey300 : AppColors.grey700,
                                      ),
                                    ),
                                  ),
                                ],
                                if (c.reviewerNotes != null && c.reviewerNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Notes: ${c.reviewerNotes}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                                if (c.status == 'pending') ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: OutlinedButton(
                                            onPressed: () => _confirmAction(
                                              context,
                                              ref,
                                              c.id,
                                              c.employeeName,
                                              false,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.danger,
                                              side: BorderSide(
                                                color: AppColors.danger.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              l10n.reject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: ElevatedButton(
                                            onPressed: () => _confirmAction(
                                              context,
                                              ref,
                                              c.id,
                                              c.employeeName,
                                              true,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              l10n.approve,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(attendanceCorrectionsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String key, String label, int count, Color activeColor) {
    final isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.grey800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.grey700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context,
    WidgetRef ref,
    int id,
    String employeeName,
    bool approve,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          approve ? 'Approve Correction?' : 'Reject Correction?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          approve
              ? 'Are you sure you want to approve the attendance correction request for $employeeName?'
              : 'Are you sure you want to reject the attendance correction request for $employeeName?',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? const Color(0xFF10B981) : AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(approve ? l10n.approve : l10n.reject),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _handleAction(context, ref, id, approve);
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    int id,
    bool approve,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (approve) {
        await ref.read(adminOpsRepositoryProvider).approveCorrection(id);
      } else {
        await ref.read(adminOpsRepositoryProvider).rejectCorrection(id);
      }
      ref.invalidate(attendanceCorrectionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? l10n.correctionApprovedSuccess
                  : l10n.correctionRejectedSuccess,
            ),
            backgroundColor: approve ? AppColors.success : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedMessage(e.toString())),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
