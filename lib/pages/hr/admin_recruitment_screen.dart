// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart' show DepartmentData;
import 'package:mpg_hr_mobile_app/services/hr_repository.dart' show PositionData;
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_recruitment/job_metrics_overview.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_recruitment/job_filter_bar.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_recruitment/job_card.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_recruitment/job_form_sheet.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_recruitment/job_candidates_sheet.dart';

class AdminRecruitmentScreen extends ConsumerStatefulWidget {
  const AdminRecruitmentScreen({super.key});

  @override
  ConsumerState<AdminRecruitmentScreen> createState() =>
      _AdminRecruitmentScreenState();
}

class _AdminRecruitmentScreenState
    extends ConsumerState<AdminRecruitmentScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = '';
  String _typeFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<JobPostingData> _applyFilters(List<JobPostingData> jobs) {
    var filtered = jobs;
    final search = _searchCtrl.text.trim().toLowerCase();
    if (search.isNotEmpty) {
      filtered = filtered.where((j) {
        final titleMatch = j.title.toLowerCase().contains(search);
        final deptMatch = j.department?.name.toLowerCase().contains(search) ?? false;
        final posMatch = j.position?.name.toLowerCase().contains(search) ?? false;
        final locMatch = j.location?.toLowerCase().contains(search) ?? false;
        return titleMatch || deptMatch || posMatch || locMatch;
      }).toList();
    }
    if (_statusFilter.isNotEmpty) {
      filtered = filtered.where((j) => j.status == _statusFilter).toList();
    }
    if (_typeFilter.isNotEmpty) {
      filtered = filtered.where((j) => j.employmentType == _typeFilter).toList();
    }
    return filtered;
  }

  void _showCandidates(BuildContext context, JobPostingData job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobCandidatesSheet(job: job),
    );
  }

  void _showJobForm(
    BuildContext context,
    WidgetRef ref,
    List<DepartmentData> depts,
    List<PositionData> pos, {
    JobPostingData? job,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobFormSheet(job: job, departments: depts, positions: pos),
    ).then((_) => ref.invalidate(recruitmentJobsProvider));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, JobPostingData job) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteJobPosting ?? 'Delete Job Posting'),
        content: Text(
          'Are you sure you want to delete "${job.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await RecruitmentRepository().deleteJob(job.id);
                ref.invalidate(recruitmentJobsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(recruitmentJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.recruitment,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(recruitmentJobsProvider),
          ),
        ],
      ),
      floatingActionButton: jobsAsync.maybeWhen(
        data: (data) => FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Post Job',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: () => _showJobForm(
            context,
            ref,
            data.departments,
            data.positions,
          ),
        ),
        orElse: () => null,
      ),
      body: jobsAsync.when(
        data: (data) {
          final allJobs = data.jobs;
          final items = _applyFilters(allJobs);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recruitmentJobsProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                // Top KPI Metrics Overview
                JobMetricsOverview(jobs: allJobs),

                // Sleek Search & Filters Bar
                JobFilterBar(
                  searchController: _searchCtrl,
                  statusFilter: _statusFilter,
                  typeFilter: _typeFilter,
                  allJobs: allJobs,
                  onStatusFilterChanged: (val) => setState(() => _statusFilter = val),
                  onTypeFilterChanged: (val) => setState(() => _typeFilter = val),
                  onSearchChanged: () => setState(() {}),
                ),

                // Job List Content
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.work_outline_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.noJobPostings,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try adjusting your search query or filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final j = items[i];
                        return JobCard(
                          job: j,
                          onTap: () => _showCandidates(context, j),
                          onViewCandidates: () => _showCandidates(context, j),
                          onEdit: () => _showJobForm(
                            context,
                            ref,
                            data.departments,
                            data.positions,
                            job: j,
                          ),
                          onDelete: () => _confirmDelete(context, ref, j),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => LoadingIndicator(message: l10n.loadingJobs),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text('Failed to load recruitment data: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(recruitmentJobsProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
