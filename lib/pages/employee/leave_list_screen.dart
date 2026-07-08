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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: balances.length,
                clipBehavior: Clip.none,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
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
    final used = total - remaining;
    final color = Color(int.tryParse(balance.color?.replaceFirst('#', 'FF') ?? 'FFF97316') ?? 0xFFF97316);
    final value = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withAlpha(20), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2)),
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
                  strokeWidth: 6,
                  color: color.withAlpha(20),
                ),
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
                Center(
                  child: Text(
                    remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            balance.typeName,
            style: const TextStyle(fontSize: 13, color: AppColors.grey700, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${used.toStringAsFixed(used % 1 == 0 ? 0 : 1)} used',
            style: const TextStyle(fontSize: 11, color: AppColors.grey400),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: _statusColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(Icons.event_available_rounded, color: _statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.leaveType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.grey800)),
                const SizedBox(height: 4),
                Text('${request.startDate} → ${request.endDate}', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor, letterSpacing: 0.5),
                ),
              ),
              if (request.status == 'pending') ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _cancelRequest(context, ref),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]
            ],
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