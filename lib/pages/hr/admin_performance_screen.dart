import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';

class AdminPerformanceScreen extends ConsumerStatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  ConsumerState<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends ConsumerState<AdminPerformanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            tabs: const [Tab(text: 'Reviews'), Tab(text: 'Training')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_ReviewsTab(), _TrainingTab()],
          ),
        ),
      ],
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(performanceReviewsProvider);
    return reviewsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No reviews', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = items[i];
                final statusColor = r.status == 'completed' ? AppColors.success : r.status == 'submitted' ? AppColors.info : AppColors.warning;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.assessment, color: statusColor, size: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (r.period != null) Text(r.period!, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        if (r.score != null) Text('${r.score!.toStringAsFixed(1)}/5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(r.status.substring(0, 1).toUpperCase() + r.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                      ]),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading reviews...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(performanceReviewsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }
}

class _TrainingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingsAsync = ref.watch(trainingCoursesProvider);
    return Stack(
      children: [
        trainingsAsync.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No training courses', style: TextStyle(color: AppColors.grey400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.secondaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.school, color: AppColors.secondary, size: 22)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                if (t.description != null) Text(t.description!, style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              if (t.enrolledCount != null)
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text('${t.enrolledCount} enrolled', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showEnrollDialog(context, ref, t.id, t.title),
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Enroll Employee'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                onPressed: () => _deleteTraining(context, ref, t.id, t.title),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const LoadingIndicator(message: 'Loading trainings...'),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(trainingCoursesProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
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
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Training'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (titleCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().createTraining(title: titleCtrl.text.trim(), description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null);
              ref.invalidate(trainingCoursesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Training created'), backgroundColor: AppColors.success));
            } catch (e) {
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  void _showEnrollDialog(BuildContext context, WidgetRef ref, int trainingId, String title) {
    final empIdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enroll in $title'),
        content: TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (empIdCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().enrollEmployee(trainingId, int.parse(empIdCtrl.text));
              ref.invalidate(trainingCoursesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Enrolled successfully'), backgroundColor: AppColors.success));
            } catch (e) {
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Enroll')),
        ],
      ),
    );
  }

  Future<void> _deleteTraining(BuildContext context, WidgetRef ref, int id, String title) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete "$title"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteTraining(id);
        ref.invalidate(trainingCoursesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}