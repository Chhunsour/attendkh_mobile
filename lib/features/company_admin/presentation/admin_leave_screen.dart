import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AdminLeaveScreen extends ConsumerStatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  ConsumerState<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends ConsumerState<AdminLeaveScreen> with SingleTickerProviderStateMixin {
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
    return Column(
      children: [
        Container(
          color: AppColors.surfaceLight,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: 'Requests'), Tab(text: 'Balances'), Tab(text: 'Leave Types')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_RequestsTab(), _LeaveBalancesTab(), _LeaveTypesTab()],
          ),
        ),
      ],
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(allLeaveRequestsProvider);
    return requestsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No leave requests', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = items[i];
                final statusColor = r.status == 'approved' ? AppColors.success : r.status == 'rejected' ? AppColors.danger : AppColors.warning;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.event_note, color: statusColor, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${r.leaveType} · ${r.startDate} → ${r.endDate}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${r.days}d', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(r.status.substring(0, 1).toUpperCase() + r.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                          ]),
                        ],
                      ),
                      if (r.reason != null && r.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(r.reason!, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                      ],
                      if (r.status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => _action(context, ref, r.id, 'reject'), icon: const Icon(Icons.close, size: 16), label: const Text('Reject'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton.icon(onPressed: () => _action(context, ref, r.id, 'approve'), icon: const Icon(Icons.check, size: 16), label: const Text('Approve'))),
                        ]),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading requests...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(allLeaveRequestsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref, int id, String action) async {
    try {
      final repo = AdminOperationsRepository();
      if (action == 'approve') { await repo.approveLeaveRequest(id); } else { await repo.rejectLeaveRequest(id); }
      ref.invalidate(allLeaveRequestsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Request ${action}d'), backgroundColor: AppColors.success));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }
}

class _LeaveTypesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(leaveTypesProvider);
    return Stack(
      children: [
        typesAsync.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No leave types', style: TextStyle(color: AppColors.grey400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    final color = Color(int.tryParse(t.color?.replaceFirst('#', 'FF') ?? 'FFF97316') ?? 0xFFF97316);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                      child: Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.event, color: color, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${t.defaultDays} days/year', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ])),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteType(context, ref, t.id, t.name)),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const LoadingIndicator(message: 'Loading types...'),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(leaveTypesProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showCreateDialog(context, ref),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '12');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Leave Type'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Annual Leave')),
          const SizedBox(height: 12),
          TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'Default Days'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().createLeaveType(name: nameCtrl.text.trim(), defaultDays: double.tryParse(daysCtrl.text) ?? 12);
              ref.invalidate(leaveTypesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Leave type created'), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _deleteType(BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete leave type "$name"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteLeaveType(id);
        ref.invalidate(leaveTypesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Leave type deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}

class _LeaveBalancesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(leaveBalancesProvider);
    return Stack(
      children: [
        balancesAsync.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No leave balances found', style: TextStyle(color: AppColors.grey400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final b = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                      child: Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${b.leaveTypeName} · ${b.year}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                            const SizedBox(height: 4),
                            Text('Allocated: ${b.allocatedDays} | Carried: ${b.carriedForward} | Used: ${b.usedDays}', style: TextStyle(fontSize: 11, color: AppColors.grey600)),
                          ])),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary), onPressed: () => _editBalance(context, ref, b)),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const LoadingIndicator(message: 'Loading balances...'),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(leaveBalancesProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
        ),
      ],
    );
  }

  void _editBalance(BuildContext context, WidgetRef ref, LeaveBalanceData b) {
    final allocatedCtrl = TextEditingController(text: b.allocatedDays.toString());
    final carriedCtrl = TextEditingController(text: b.carriedForward.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Balance: ${b.employeeName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: allocatedCtrl, decoration: const InputDecoration(labelText: 'Allocated Days'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            TextField(controller: carriedCtrl, decoration: const InputDecoration(labelText: 'Carried Forward'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await AdminOperationsRepository().updateLeaveBalance(b.id, {
                  'allocated_days': double.parse(allocatedCtrl.text),
                  'carried_forward': double.parse(carriedCtrl.text),
                });
                ref.invalidate(leaveBalancesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Leave balance updated'), backgroundColor: AppColors.success));
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
