import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/overtime_providers.dart';
import 'package:mpg_hr_mobile_app/services/overtime_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

Color _statusColor(String s) {
  switch (s) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}

class AdminOvertimeScreen extends ConsumerStatefulWidget {
  const AdminOvertimeScreen({super.key});

  @override
  ConsumerState<AdminOvertimeScreen> createState() => _AdminOvertimeScreenState();
}

class _AdminOvertimeScreenState extends ConsumerState<AdminOvertimeScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: const Text('Overtime Approvals', style: TextStyle(color: AppColors.grey800, fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
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
          SnackBar(content: Text('Request $newStatus'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update request: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(managerOvertimeRequestsProvider);

    return asyncRequests.when(
      loading: () => LoadingIndicator(message: 'Loading requests...'),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.danger))),
      data: (allRequests) {
        final requests = allRequests.where((r) => r.status == status).toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No requests found', style: TextStyle(color: AppColors.grey500)));
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(managerOvertimeRequestsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                elevation: 0,
                color: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.grey200),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: request.employeeAvatar != null ? NetworkImage(request.employeeAvatar!) : null,
                            child: request.employeeAvatar == null
                                ? Text(request.employeeName?.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(color: AppColors.primary))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(request.employeeName ?? 'Unknown Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(request.date, style: const TextStyle(color: AppColors.grey600, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(request.status).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status.toUpperCase(),
                              style: TextStyle(color: _statusColor(request.status), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('${request.startTime} - ${request.endTime}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                            if (request.amount != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Amount', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('\$${request.amount!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (request.reason != null && request.reason!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Reason:', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(request.reason!, style: const TextStyle(fontSize: 14, color: AppColors.grey800)),
                      ],
                      if (status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(context, ref, request.id, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(context, ref, request.id, 'approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
