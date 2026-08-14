import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/leave_repository.dart';
import 'package:mpg_hr_mobile_app/providers/leave_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'

  Future<void> _refresh() async {
    ref.invalidate(leaveBalancesProvider);
    ref.invalidate(leaveRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(leaveBalancesProvider);
    final requestsAsync = ref.watch(leaveRequestsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          l10n.leaveManagement,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.leaveRequest),
        backgroundColor: AppColors.primary,
        elevation: 4,
        highlightElevation: 8,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: Text(
          l10n.requestLeave,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Section 1: Leave Balances Horizontal Carousel ──
            SliverToBoxAdapter(
              child: balancesAsync.when(
                data: (balances) => _buildBalancesSection(balances, l10n),
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),

            // ── Section 2: Filter Tabs & Header ──
            SliverToBoxAdapter(
              child: requestsAsync.maybeWhen(
                data: (requests) => _buildFilterBar(requests, l10n),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            // ── Section 3: Leave Requests List ──
            requestsAsync.when(
              data: (requests) {
                final filtered = _filterRequests(requests);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(l10n),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LeaveRequestCard(
                            request: filtered[index],
                            l10n: l10n,
                            onCancelled: _refresh,
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: LoadingIndicator(message: 'Loading requests...'),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load leave history',
                        style: const TextStyle(color: AppColors.grey600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LeaveRequest> _filterRequests(List<LeaveRequest> requests) {
    if (_selectedFilter == 'all') return requests;
    return requests.where((r) => r.status.toLowerCase() == _selectedFilter).toList();
  }

  Widget _buildBalancesSection(List<LeaveBalance> balances, AppLocalizations l10n) {
    if (balances.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.leaveBalances} (${DateTime.now().year})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  '${balances.length} Types',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 165,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: balances.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _LeaveBalanceCard(balance: balances[i], l10n: l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<LeaveRequest> requests, AppLocalizations l10n) {
    final int allCount = requests.length;
    final int pendingCount = requests.where((r) => r.status.toLowerCase() == 'pending').length;
    final int approvedCount = requests.where((r) => r.status.toLowerCase() == 'approved').length;
    final int rejectedCount = requests.where((r) => r.status.toLowerCase() == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.history,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _filterChip('all', 'All ($allCount)', null),
                const SizedBox(width: 8),
                _filterChip('pending', 'Pending ($pendingCount)', AppColors.warning),
                const SizedBox(width: 8),
                _filterChip('approved', 'Approved ($approvedCount)', AppColors.success),
                const SizedBox(width: 8),
                _filterChip('rejected', 'Rejected ($rejectedCount)', AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label, Color? dotColor) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.grey900 : AppColors.grey200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.grey900.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all' ? l10n.noLeaveHistory : 'No ${_selectedFilter.toUpperCase()} requests',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFilter == 'all'
                  ? 'Your requested leaves and balances will appear here.'
                  : 'There are no leave requests under this filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
            if (_selectedFilter == 'all') ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.leaveRequest),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.requestLeave),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final LeaveBalance balance;
  final AppLocalizations l10n;
  const _LeaveBalanceCard({required this.balance, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remaining;
    final total = balance.allocated + balance.carriedForward;
    final used = total - remaining;
    final baseColor = Color(
      int.tryParse(balance.color?.replaceFirst('#', 'FF') ?? 'FF0052FF') ??
          0xFF0052FF,
    );
    final color = baseColor.withValues(alpha: 1.0);
    final value = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6.5,
                  color: color.withValues(alpha: 0.12),
                ),
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6.5,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
                Center(
                  child: Text(
                    remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            balance.typeName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey800,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            balance.accruedToDate != null
                ? '${balance.accruedToDate!.toStringAsFixed(1)}d Accrued'
                : '${used.toStringAsFixed(used % 1 == 0 ? 0 : 1)} / ${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)} used',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  final AppLocalizations l10n;
  final VoidCallback onCancelled;

  const _LeaveRequestCard({
    required this.request,
    required this.l10n,
    required this.onCancelled,
  });

  Color get _statusColor {
    switch (request.status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'cancelled':
        return AppColors.grey400;
      default:
        return AppColors.warning;
    }
  }

  IconData get _statusIcon {
    switch (request.status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final totalDaysStr = request.days.toStringAsFixed(request.days % 1 == 0 ? 0 : 1);

    return InkWell(
      onTap: () => _showDetailModal(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type, Status, Total Days
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.leaveType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.grey900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 13, color: AppColors.grey400),
                            const SizedBox(width: 4),
                            Text(
                              formatDateRange(request.startDate, request.endDate),
                              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.isHalfDay ? 'Half Day' : '$totalDaysStr ${request.days == 1 ? "day" : "days"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Reason & Notes snippet (if provided)
            if (request.reason != null && request.reason!.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"${request.reason!}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.grey600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],

            // Action / Info Bar: Document attached + Cancel button
            if (request.status.toLowerCase() == 'pending' || (request.documentUrl != null && request.documentUrl!.isNotEmpty))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.grey100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (request.documentUrl != null && request.documentUrl!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.attachmentIncluded,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    if (request.status.toLowerCase() == 'pending')
                      InkWell(
                        onTap: () => _confirmCancel(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                              const SizedBox(width: 4),
                              Text(
                                l10n.cancel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(BuildContext context) {
    final statusColor = _statusColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    request.leaveType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.calendar_month_rounded, 'Date Range', formatDateRange(request.startDate, request.endDate)),
              _detailRow(Icons.timer_outlined, 'Total Duration', request.isHalfDay ? 'Half Day' : '${request.days} days'),
              if (request.createdAt.isNotEmpty)
                _detailRow(Icons.access_time_rounded, 'Applied On', _formatDate(request.createdAt)),
              if (request.approvedBy != null && request.approvedBy!.isNotEmpty)
                _detailRow(Icons.verified_user_outlined, 'Reviewed By', request.approvedBy!),
              if (request.reason != null && request.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Text(request.reason!, style: const TextStyle(fontSize: 13, color: AppColors.grey800)),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grey500),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey900)),
        ],
      ),
    );
  }

  String _formatDate(String dtStr) {
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequest),
        content: Text(l10n.cancelLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.yesCancel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = LeaveRepository();
        await repo.cancelRequest(request.id);
        onCancelled();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.leaveRequestCancelled),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${e.toString()}'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
