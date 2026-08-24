import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class JobMetricsOverview extends StatelessWidget {
  final List<JobPostingData> jobs;

  const JobMetricsOverview({
    super.key,
    required this.jobs,
  });

  @override
  Widget build(BuildContext context) {
    final totalJobs = jobs.length;
    final openJobs = jobs.where((j) => j.status == 'open').length;
    final totalCandidates = jobs.fold<int>(0, (sum, j) => sum + j.candidatesCount);
    final filledJobs = jobs.where((j) => j.status == 'filled').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              context,
              title: 'Total Jobs',
              value: totalJobs.toString(),
              icon: Icons.business_center_rounded,
              color: AppColors.primary,
              bg: AppColors.primary.withAlpha(16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              context,
              title: 'Open Roles',
              value: openJobs.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF059669),
              bg: const Color(0xFFECFDF5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              context,
              title: 'Applicants',
              value: totalCandidates.toString(),
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF7C3AED),
              bg: const Color(0xFFF5F3FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              context,
              title: 'Filled',
              value: filledJobs.toString(),
              icon: Icons.how_to_reg_rounded,
              color: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context).withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
