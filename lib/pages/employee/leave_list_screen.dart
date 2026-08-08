import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/leave_repository.dart';
import 'package:mpg_hr_mobile_app/providers/leave_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class LeaveListScreen extends ConsumerWidget {
  const LeaveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(leaveBalancesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaveManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
                // Just to refresh the page or show history
                ref.invalidate(leaveRequestsProvider);
                ref.invalidate(leaveBalancesProvider);
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(80),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.leaveRequest),
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                   const SizedBox(width: 8),
                  Text(l10n.requestLeave, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: balancesAsync.when(
        data: (balances) => _buildContent(context, ref, balances, l10n),
        loading: () => LoadingIndicator(message: l10n.loadingBalances),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(leaveBalancesProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<LeaveBalance> balances, AppLocalizations l10n) {
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
                itemBuilder: (context, i) => _LeaveBalanceCard(balance: balances[i], l10n: l10n),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noLeaveBalances, style: const TextStyle(color: AppColors.grey400)),
          ),

        // Leave History
        Expanded(
          child: requestsAsync.when(
            data: (requests) => requests.isEmpty
                ? Center(child: Text(l10n.noLeaveHistory, style: const TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _LeaveRequestCard(request: requests[i], l10n: l10n),
                  ),
            loading: () => LoadingIndicator(message: l10n.loadingHistory),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ),
      ],
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
    final baseColor = Color(int.tryParse(balance.color?.replaceFirst('#', 'FF') ?? 'FFF97316') ?? 0xFFF97316);
    final color = baseColor.withValues(alpha: 1.0);
    final value = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(30), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(25), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  color: color.withAlpha(20),
                ),
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
                Center(
                  child: Text(
                    remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            balance.typeName.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            balance.accruedToDate != null
                ? '${balance.accruedToDate!.toStringAsFixed(1)}d Accrued'
                : '${used.toStringAsFixed(used % 1 == 0 ? 0 : 1)} / ${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)}${l10n.usedLabel}',
            style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final LeaveRequest request;
  final AppLocalizations l10n;
  const _LeaveRequestCard({required this.request, required this.l10n});

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
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_note_rounded, color: _statusColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        request.leaveType, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (request.isHalfDay) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(l10n.halfLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(formatDateRange(request.startDate, request.endDate), style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                  ],
                ),
                if (request.documentUrl != null && request.documentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(l10n.attachmentIncluded, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ]
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor, letterSpacing: 0.5),
                ),
              ),
              if (request.status == 'pending') ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _cancelRequest(context, ref, l10n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.danger.withAlpha(100)), borderRadius: BorderRadius.circular(12)),
                    child: Text(l10n.cancel, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequest),
        content: Text(l10n.cancelLeaveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.yesCancel)),
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
          SnackBar(content: Text(l10n.leaveRequestCancelled), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
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