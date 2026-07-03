import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AdminRecruitmentScreen extends ConsumerWidget {
  const AdminRecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobPostingsProvider);
    return jobsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No job postings', style: TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final j = items[i];
                final statusColor = j.status == 'open' ? AppColors.success : j.status == 'closed' ? AppColors.danger : AppColors.warning;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.work, color: AppColors.primary, size: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(j.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (j.department != null) Text(j.department!, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        if (j.location != null) Text(j.location!, style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(j.status.substring(0, 1).toUpperCase() + j.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                        const SizedBox(height: 4),
                        Text('${j.candidatesCount} candidates', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                      ]),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading jobs...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(jobPostingsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }
}