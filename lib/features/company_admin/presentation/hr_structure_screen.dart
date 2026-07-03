import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/hr_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class HrStructureScreen extends ConsumerStatefulWidget {
  const HrStructureScreen({super.key});

  @override
  ConsumerState<HrStructureScreen> createState() => _HrStructureScreenState();
}

class _HrStructureScreenState extends ConsumerState<HrStructureScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Branches'),
              Tab(text: 'Depts'),
              Tab(text: 'Positions'),
              Tab(text: 'Teams'),
              Tab(text: 'Employees'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _BranchesTab(),
              _DepartmentsTab(),
              _PositionsTab(),
              _TeamsTab(),
              _EmployeesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Branches Tab ────────────────────────────────────────────────────────────
class _BranchesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    return branchesAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No branches', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _buildItem(context, ref, items[i]),
            ),
      loading: () => const LoadingIndicator(message: 'Loading branches...'),
      error: (e, _) => _errorWidget(ref, branchesProvider),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, BranchData item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.secondaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.business, color: AppColors.secondary, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              if (item.address != null) Text(item.address!, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
            ]),
          ),
          if (item.employeesCount != null)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text('${item.employeesCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteItem(context, ref, item.id, item.name)),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete branch "$name"?'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
      ]),
    );
    if (confirmed == true) {
      try {
        await HrRepository().deleteBranch(id);
        ref.invalidate(branchesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Branch deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Widget _errorWidget(WidgetRef ref, ProviderBase provider) {
    return Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(provider), icon: const Icon(Icons.refresh), label: const Text('Retry')));
  }
}

// ── Departments Tab ─────────────────────────────────────────────────────────
class _DepartmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);
    return deptsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No departments', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.corporate_fare, color: AppColors.info, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (item.headName != null) Text('Head: ${item.headName}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        ]),
                      ),
                      if (item.employeesCount != null)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text('${item.employeesCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading departments...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(departmentsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }
}

// ── Positions Tab ───────────────────────────────────────────────────────────
class _PositionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(positionsProvider);
    return posAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No positions', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.work_outline, color: AppColors.success, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (item.description != null) Text(item.description!, style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading positions...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(positionsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }
}

// ── Teams Tab ───────────────────────────────────────────────────────────────
class _TeamsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    return teamsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No teams', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.group_outlined, color: AppColors.warning, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (item.leaderName != null) Text('Leader: ${item.leaderName}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                      ])),
                      if (item.membersCount != null)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text('${item.membersCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading teams...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(teamsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }
}

// ── Employees Tab ───────────────────────────────────────────────────────────
class _EmployeesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empsAsync = ref.watch(employeesProvider);
    return empsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No employees', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                final initials = item.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text([item.department, item.position].where((s) => s != null && s.isNotEmpty).join(' · '), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.status == 'active' ? AppColors.successLight : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.status?.toUpperCase() ?? 'ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: item.status == 'active' ? AppColors.success : AppColors.warning)),
                      ),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading employees...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(employeesProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }
}