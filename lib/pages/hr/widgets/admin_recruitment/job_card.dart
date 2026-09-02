import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class JobCard extends StatelessWidget {
  final JobPostingData job;
  final VoidCallback onTap;
  final VoidCallback onViewCandidates;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.onViewCandidates,
    required this.onEdit,
    required this.onDelete,
  });

  Map<String, Color> _getStatusStyles(String status) {
    switch (status) {
      case 'open':
        return {
          'bg': const Color(0xFFECFDF5),
          'text': const Color(0xFF059669),
          'border': const Color(0xFFA7F3D0),
        };
      case 'closed':
        return {
          'bg': const Color(0xFFFFF1F2),
          'text': const Color(0xFFE11D48),
          'border': const Color(0xFFFECDD3),
        };
      case 'filled':
        return {
          'bg': AppColors.primaryLight,
          'text': AppColors.primary,
          'border': AppColors.primaryLight,
        };
      default: // draft
        return {
          'bg': AppColors.grey100,
          'text': AppColors.grey700,
          'border': AppColors.grey200,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusStyles = _getStatusStyles(job.status);
    final hasSalary = job.salaryMin != null || job.salaryMax != null;
    final salaryText = hasSalary
        ? '\$${job.salaryMin?.toStringAsFixed(0) ?? '0'} - \$${job.salaryMax?.toStringAsFixed(0) ?? '0'}/mo'
        : 'Salary Negotiable';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context).withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Department/Position tags & Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (job.department != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.department!.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (job.employmentType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.employmentType!.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: statusStyles['bg'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusStyles['border']!),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusStyles['text'],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                job.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: AppColors.textPrimary(context),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // Metadata Chips: Location + Salary
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (job.location != null && job.location!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.grey500),
                        const SizedBox(width: 3),
                        Text(
                          job.location!,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.grey600),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 3),
                      Text(
                        salaryText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Row: Badges (Vacancies, Applicants) & Action Buttons
              Row(
                children: [
                  // Vacancies badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${job.positionsAvailable} ${job.positionsAvailable == 1 ? "Vacancy" : "Vacancies"}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.grey700),
                    ),
                  ),
                  const Spacer(),

                  // Actions
                  InkWell(
                    onTap: onViewCandidates,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${job.candidatesCount} Applicants',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.grey600),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(28, 28),
                      backgroundColor: AppColors.grey100,
                    ),
                    tooltip: l10n.editJob,
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(28, 28),
                      backgroundColor: AppColors.danger.withAlpha(15),
                    ),
                    tooltip: l10n.delete,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
