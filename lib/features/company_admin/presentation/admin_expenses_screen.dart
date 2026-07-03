import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/expense/presentation/expense_provider.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AdminExpensesScreen extends ConsumerWidget {
  const AdminExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    return expensesAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No expense claims', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = items[i];
                final statusColor = e.status == 'approved' ? AppColors.success : e.status == 'rejected' ? AppColors.danger : e.status == 'paid' ? AppColors.info : AppColors.warning;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.receipt_outlined, color: statusColor, size: 22)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(e.date, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\$${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(e.status.substring(0, 1).toUpperCase() + e.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                          ]),
                        ],
                      ),
                      if (e.status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => _action(context, ref, e.id, 'reject'), icon: const Icon(Icons.close, size: 16), label: const Text('Reject'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)))),
                          const SizedBox(width: 8),
                          Expanded(child: ElevatedButton.icon(onPressed: () => _action(context, ref, e.id, 'approve'), icon: const Icon(Icons.check, size: 16), label: const Text('Approve'))),
                        ]),
                      ],
                      if (e.status == 'approved') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => _action(context, ref, e.id, 'pay'), icon: const Icon(Icons.payment, size: 16), label: const Text('Mark as Paid'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.info, side: const BorderSide(color: AppColors.info)))),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), onPressed: () => _deleteExpense(context, ref, e.id)),
                        ]),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading expenses...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(expensesProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(title: const Text('Delete Claim'), content: const Text('Delete this expense claim?'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
      ]),
    );
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteExpense(id);
        ref.invalidate(expensesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Claim deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _action(BuildContext context, WidgetRef ref, int id, String action) async {
    try {
      final repo = AdminOperationsRepository();
      if (action == 'approve') { await repo.approveExpense(id); }
      else if (action == 'reject') { await repo.rejectExpense(id); }
      else if (action == 'pay') { await repo.markExpensePaid(id); }
      ref.invalidate(expensesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Expense ${action}d'), backgroundColor: AppColors.success));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }
}