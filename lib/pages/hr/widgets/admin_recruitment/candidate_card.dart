import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class CandidateCard extends StatelessWidget {
  final CandidateData candidate;
  final ValueChanged<String> onStageChanged;
  final VoidCallback onScheduleInterview;
  final VoidCallback onConvertToEmployee;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onStageChanged,
    required this.onScheduleInterview,
    required this.onConvertToEmployee,
  });

  Map<String, Color> _getCandidateStatusStyles(String status) {
    switch (status) {
      case 'hired':
        return {
          'bg': const Color(0xFFECFDF5),
          'text': const Color(0xFF059669),
          'border': const Color(0xFFA7F3D0),
        };
      case 'interview':
        return {
          'bg': const Color(0xFFEFF6FF),
          'text': const Color(0xFF2563EB),
          'border': const Color(0xFFBFDBFE),
        };
      case 'offer':
        return {
          'bg': const Color(0xFFF5F3FF),
          'text': const Color(0xFF7C3AED),
          'border': const Color(0xFFDDD6FE),
        };
      case 'rejected':
        return {
          'bg': const Color(0xFFFFF1F2),
          'text': const Color(0xFFE11D48),
          'border': const Color(0xFFFECDD3),
        };
      case 'screening':
        return {
          'bg': const Color(0xFFFFFBEB),
          'text': const Color(0xFFD97706),
          'border': const Color(0xFFFDE68A),
        };
      default: // applied
        return {
          'bg': AppColors.grey100,
          'text': AppColors.grey700,
          'border': AppColors.grey200,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyles = _getCandidateStatusStyles(candidate.stage);
    final displayName = candidate.fullName ?? candidate.name;
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'CA';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context).withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name/Details + Stage Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusStyles['bg'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusStyles['border']!),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: statusStyles['text'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (candidate.nameKh != null && candidate.nameKh!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '(${candidate.nameKh!})',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (candidate.currentPosition != null && candidate.currentPosition!.isNotEmpty)
                        Text(
                          '${candidate.currentPosition!}${candidate.currentCompany != null ? ' @ ${candidate.currentCompany}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Stage Pill
                PopupMenuButton<String>(
                  tooltip: 'Update Candidate Stage',
                  onSelected: onStageChanged,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'applied', child: Text('Applied')),
                    PopupMenuItem(value: 'screening', child: Text('Screening')),
                    PopupMenuItem(value: 'interview', child: Text('Interview')),
                    PopupMenuItem(value: 'offer', child: Text('Offer')),
                    PopupMenuItem(value: 'hired', child: Text('Hired')),
                    PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusStyles['bg'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusStyles['border']!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          candidate.stage.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: statusStyles['text'],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: statusStyles['text']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Contact & Experience Info Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (candidate.email != null && candidate.email!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, size: 12, color: AppColors.grey500),
                      const SizedBox(width: 3),
                      Text(candidate.email!, style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
                    ],
                  ),
                if (candidate.phone != null && candidate.phone!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.grey500),
                      const SizedBox(width: 3),
                      Text(candidate.phone!, style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
                    ],
                  ),
                if (candidate.yearsOfExperience != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${candidate.yearsOfExperience} yrs exp',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey700),
                    ),
                  ),
                if (candidate.expectedSalary != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Exp \$${candidate.expectedSalary?.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFCA8A04)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Interview Action
                InkWell(
                  onTap: onScheduleInterview,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded, size: 13, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Interview',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Convert to Employee Action (if hired)
                if (candidate.stage == 'hired') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onConvertToEmployee,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.how_to_reg_rounded, size: 13, color: Color(0xFF7C3AED)),
                          SizedBox(width: 4),
                          Text(
                            'Convert',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
