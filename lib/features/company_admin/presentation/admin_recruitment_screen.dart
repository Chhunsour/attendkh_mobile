import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
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
                return InkWell(
                  onTap: () => _showCandidates(context, j),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                  ),
                );
              },
            ),
      loading: () => const LoadingIndicator(message: 'Loading jobs...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(jobPostingsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }

  void _showCandidates(BuildContext context, JobPostingData job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _JobCandidatesSheet(job: job),
    );
  }
}

class _JobCandidatesSheet extends ConsumerWidget {
  final JobPostingData job;
  const _JobCandidatesSheet({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(jobCandidatesProvider(job.id));
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Candidates: ${job.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: candidatesAsync.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No candidates applied yet.', style: TextStyle(color: AppColors.grey500)))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = items[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.grey200), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              if (c.email != null) Text(c.email!, style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                              if (c.phone != null) Text(c.phone!, style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text('Stage: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Expanded(
                                    child: DropdownButton<String>(
                                      value: ['applied', 'interviewing', 'offered', 'hired', 'rejected'].contains(c.stage) ? c.stage : 'applied',
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(value: 'applied', child: Text('Applied')),
                                        DropdownMenuItem(value: 'interviewing', child: Text('Interviewing')),
                                        DropdownMenuItem(value: 'offered', child: Text('Offered')),
                                        DropdownMenuItem(value: 'hired', child: Text('Hired')),
                                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                      ],
                                      onChanged: (val) async {
                                        if (val != null && val != c.stage) {
                                          try {
                                            await AdminOperationsRepository().updateCandidateStatus(c.id, val);
                                            ref.invalidate(jobCandidatesProvider(job.id));
                                          } catch (e) {
                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const LoadingIndicator(message: 'Loading candidates...'),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}