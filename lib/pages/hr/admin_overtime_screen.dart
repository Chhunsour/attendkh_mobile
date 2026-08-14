import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/overtime_providers.dart';
import 'package:mpg_hr_mobile_app/services/overtime_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class AdminOvertimeScreen extends ConsumerStatefulWidget {
  const AdminOvertimeScreen({super.key});

  @override
  ConsumerState<AdminOvertimeScreen> createState() => _AdminOvertimeScreenState();
}

class _AdminOvertimeScreenState extends ConsumerState<AdminOvertimeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncRequests = ref.watch(managerOvertimeRequestsProvider);
    final pendingCount = asyncRequests.maybeWhen(
      data: (items) => items.where((r) => r.status == 'pending').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Overtime Approvals',
          style: TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(managerOvertimeRequestsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_top_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('Pending'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Approved'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OvertimeListTab(status: 'pending'),
          _OvertimeListTab(status: 'approved'),
          _OvertimeListTab(status: 'rejected'),
        ],
      ),
    );
  }
}

class _OvertimeListTab extends ConsumerWidget {
  final String status;
  const _OvertimeListTab({required this.status});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id, String newStatus) async {
    try {
      await ref.read(overtimeRepositoryProvider).updateOvertimeStatus(id, newStatus);
      ref.invalidate(managerOvertimeRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved' ? '✅ Overtime request approved' : '❌ Overtime request rejected'),
            backgroundColor: newStatus == 'approved' ? AppColors.success : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update request: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(managerOvertimeRequestsProvider);

    return asyncRequests.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text('Error: $err', style: const TextStyle(color: AppColors.grey700)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(managerOvertimeRequestsProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
      data: (allRequests) {
        final pendingTotal = allRequests.where((r) => r.status == 'pending').length;
        final approvedTotal = allRequests.where((r) => r.status == 'approved').length;
        final rejectedTotal = allRequests.where((r) => r.status == 'rejected').length;

        final requests = allRequests.where((r) => r.status == status).toList();

        return RefreshIndicator(
          color: const Color(0xFFF59E0B),
          onRefresh: () async => ref.invalidate(managerOvertimeRequestsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ── Top Metric Cards ──
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pending',
                      value: '$pendingTotal',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Approved',
                      value: '$approvedTotal',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Rejected',
                      value: '$rejectedTotal',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (requests.isEmpty)
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
                      const Icon(Icons.more_time_rounded, size: 48, color: AppColors.grey300),
                      const SizedBox(height: 12),
                      Text(
                        'No $status overtime requests found',
                        style: const TextStyle(color: AppColors.grey600, fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...requests.map((request) {
                  final (statusColor, statusBg) = switch (request.status) {
                    'approved' => (const Color(0xFF10B981), const Color(0xFFECFDF5)),
                    'rejected' => (const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                    _ => (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.grey200.withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                              ),
                              child: request.employeeAvatar != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: request.employeeAvatar!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) => Center(
                                          child: Text(
                                            request.employeeName?.substring(0, 1).toUpperCase() ?? '?',
                                            style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        request.employeeName?.substring(0, 1).toUpperCase() ?? '?',
                                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.employeeName ?? 'Unknown Employee',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.grey900),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.grey400),
                                      const SizedBox(width: 4),
                                      Text(request.date, style: const TextStyle(color: AppColors.grey500, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                request.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Time & Compensation Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Overtime Window', style: TextStyle(color: AppColors.grey500, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${request.startTime} - ${request.endTime}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.grey900),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (request.amount != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Payable', style: TextStyle(color: Color(0xFF047857), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                      Text(
                                        '\$${request.amount!.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF047857)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (request.reason != null && request.reason!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.format_quote_rounded, size: 14, color: AppColors.grey400),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    request.reason!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.grey700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (status == 'pending') ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: OutlinedButton(
                                    onPressed: () => _updateStatus(context, ref, request.id, 'rejected'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: () => _updateStatus(context, ref, request.id, 'approved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
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
}
