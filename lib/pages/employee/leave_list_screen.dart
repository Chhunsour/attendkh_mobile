import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/leave_repository.dart';
import 'package:mpg_hr_mobile_app/providers/leave_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class LeaveListScreen extends ConsumerWidget {
  const LeaveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(leaveBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.leaveRequest),
          ),
        ],
      ),
      body: balancesAsync.when(
        data: (balances) => _buildContent(context, ref, balances),
        loading: () => const LoadingIndicator(message: 'Loading balances...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(leaveBalancesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<LeaveBalance> balances) {
    final requestsAsync = ref.watch(leaveRequestsProvider);

    return Column(
      children: [
        // Leave Balance Cards
        if (balances.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: balances.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _LeaveBalanceCard(balance: balances[i]),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('No leave balances found', style: TextStyle(color: AppColors.grey400)),
          ),

        // Leave History
        Expanded(
          child: requestsAsync.when(
            data: (requests) => requests.isEmpty
                ? const Center(child: Text('No leave history', style: TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _LeaveRequestCard(request: requests[i]),
                  ),
            loading: () => const LoadingIndicator(message: 'Loading history...'),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final LeaveBalance balance;
  const _LeaveBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remaining;
    final total = balance.allocated + balance.carriedForward;
    final color = Color(int.tryParse(balance.color?.replaceFirst('#', 'FF') ?? 'FFF97316') ?? 0xFFF97316);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Text(balance.typeName, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(remaining.toStringAsFixed(1), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text('/ ${total.toStringAsFixed(1)} days', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? (balance.used / total).clamp(0.0, 1.0) : 0,
            backgroundColor: color.withAlpha(26),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final LeaveRequest request;
  const _LeaveRequestCard({required this.request});

  Color get _statusColor {
    switch (request.status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.danger;
      case 'cancelled': return AppColors.grey400;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.event, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.leaveType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${request.startDate} → ${request.endDate}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
              ],
            ),
          ),
          if (request.status == 'pending')
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: AppColors.danger),
              tooltip: 'Cancel request',
              onPressed: () => _cancelRequest(context, ref),
            ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)),
            child: Text(
              request.status.substring(0, 1).toUpperCase() + request.status.substring(1),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = LeaveRepository();
        await repo.cancelRequest(request.id);
        ref.invalidate(leaveBalancesProvider);
        ref.invalidate(leaveRequestsProvider);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Leave request cancelled'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}