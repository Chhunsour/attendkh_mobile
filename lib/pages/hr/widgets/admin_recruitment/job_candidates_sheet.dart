import 'package:attendkh/l10n/app_localizations.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/recruitment_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/pages/hr/widgets/admin_recruitment/add_candidate_sheet.dart';
import 'package:attendkh/pages/hr/widgets/admin_recruitment/schedule_interview_sheet.dart';
import 'package:attendkh/pages/hr/widgets/admin_recruitment/candidate_card.dart';

class JobCandidatesSheet extends ConsumerStatefulWidget {
  final JobPostingData job;

  const JobCandidatesSheet({
    super.key,
    required this.job,
  });

  @override
  ConsumerState<JobCandidatesSheet> createState() => _JobCandidatesSheetState();
}

class _JobCandidatesSheetState extends ConsumerState<JobCandidatesSheet> {
  String _selectedStage = '';
  final TextEditingController _candidateSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _candidateSearchCtrl.dispose();
    super.dispose();
  }

  void _showAddCandidateForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCandidateSheet(jobId: widget.job.id),
    );
  }

  void _showScheduleInterviewForm(BuildContext context, int candidateId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleInterviewSheet(
        jobId: widget.job.id,
        candidateId: candidateId,
      ),
    );
  }

  Future<void> _updateCandidateStage(int candidateId, String newStage) async {
    try {
      await RecruitmentRepository().updateCandidateStatus(candidateId, newStage);
      ref.invalidate(jobCandidatesProvider(widget.job.id));
      ref.invalidate(recruitmentJobsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _convertToEmployee(int candidateId) async {
    try {
      await RecruitmentRepository().convertToEmployee(candidateId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidate successfully converted to Employee.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidatesAsync = ref.watch(jobCandidatesProvider(widget.job.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Job Info & Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.candidatesPipeline,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.job.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCandidateForm(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: Text(
                    AppLocalizations.of(context)?.addCandidate ?? 'Add',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Candidate Search & Stage Filter Tabs
          candidatesAsync.maybeWhen(
            data: (items) {
              final stageCounts = {
                '': items.length,
                'applied': items.where((c) => c.stage == 'applied').length,
                'screening': items.where((c) => c.stage == 'screening').length,
                'interview': items.where((c) => c.stage == 'interview').length,
                'offer': items.where((c) => c.stage == 'offer').length,
                'hired': items.where((c) => c.stage == 'hired').length,
                'rejected': items.where((c) => c.stage == 'rejected').length,
              };

              final stageTabs = [
                {'key': '', 'label': l10n.all, 'count': stageCounts['']},
                {'key': 'applied', 'label': 'Applied', 'count': stageCounts['applied']},
                {'key': 'screening', 'label': l10n.screening, 'count': stageCounts['screening']},
                {'key': 'interview', 'label': l10n.interview, 'count': stageCounts['interview']},
                {'key': 'offer', 'label': 'Offer', 'count': stageCounts['offer']},
                {'key': 'hired', 'label': l10n.hired, 'count': stageCounts['hired']},
                {'key': 'rejected', 'label': l10n.rejected, 'count': stageCounts['rejected']},
              ];

              return Column(
                children: [
                  // Candidate Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context).withAlpha(100)),
                      ),
                      child: TextField(
                        controller: _candidateSearchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: l10n.searchCandidatesHint,
                          hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.grey400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.grey400),
                          suffixIcon: _candidateSearchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 14, color: AppColors.grey400),
                                  onPressed: () {
                                    _candidateSearchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Horizontal Stage Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: stageTabs.map((tab) {
                        final isSel = _selectedStage == tab['key'];
                        final count = tab['count'] as int;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedStage = tab['key'] as String),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : AppColors.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? AppColors.primary : AppColors.border(context).withAlpha(90),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tab['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                      color: isSel ? Colors.white : AppColors.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSel ? Colors.white.withAlpha(40) : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : AppColors.grey700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox(),
          ),
          const SizedBox(height: 10),

          // Candidate List
          Expanded(
            child: candidatesAsync.when(
              data: (items) {
                final query = _candidateSearchCtrl.text.trim().toLowerCase();
                var filtered = items;

                if (_selectedStage.isNotEmpty) {
                  filtered = filtered.where((c) => c.stage == _selectedStage).toList();
                }

                if (query.isNotEmpty) {
                  filtered = filtered.where((c) {
                    final nameMatch = (c.fullName ?? c.name).toLowerCase().contains(query);
                    final nameKhMatch = c.nameKh?.toLowerCase().contains(query) ?? false;
                    final emailMatch = c.email?.toLowerCase().contains(query) ?? false;
                    final posMatch = c.currentPosition?.toLowerCase().contains(query) ?? false;
                    return nameMatch || nameKhMatch || emailMatch || posMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.person_search_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noCandidatesFound,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)?.addCandidatesOrSwitchTabs ?? 'Add candidates or switch filter tabs',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    return CandidateCard(
                      candidate: c,
                      onStageChanged: (newStage) => _updateCandidateStage(c.id, newStage),
                      onScheduleInterview: () => _showScheduleInterviewForm(context, c.id),
                      onConvertToEmployee: () => _convertToEmployee(c.id),
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(message: 'Loading candidates...'),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}