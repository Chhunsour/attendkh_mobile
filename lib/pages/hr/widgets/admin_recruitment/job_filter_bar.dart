import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class JobFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final String typeFilter;
  final List<JobPostingData> allJobs;
  final ValueChanged<String> onStatusFilterChanged;
  final ValueChanged<String> onTypeFilterChanged;
  final VoidCallback onSearchChanged;

  const JobFilterBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.typeFilter,
    required this.allJobs,
    required this.onStatusFilterChanged,
    required this.onTypeFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = allJobs.length;
    final openCount = allJobs.where((j) => j.status == 'open').length;
    final draftCount = allJobs.where((j) => j.status == 'draft').length;
    final closedCount = allJobs.where((j) => j.status == 'closed').length;
    final filledCount = allJobs.where((j) => j.status == 'filled').length;

    final filterPills = [
      {'key': '', 'label': 'All', 'count': totalCount},
      {'key': 'open', 'label': 'Open', 'count': openCount},
      {'key': 'draft', 'label': 'Draft', 'count': draftCount},
      {'key': 'closed', 'label': 'Closed', 'count': closedCount},
      {'key': 'filled', 'label': 'Filled', 'count': filledCount},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search row + Type filter popup
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context).withAlpha(120)),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => onSearchChanged(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search jobs, department, location...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.grey400),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.grey400),
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Filter by Employment Type',
                initialValue: typeFilter,
                onSelected: onTypeFilterChanged,
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: '', child: Text('All Types')),
                  PopupMenuItem(value: 'full_time', child: Text('Full Time')),
                  PopupMenuItem(value: 'part_time', child: Text('Part Time')),
                  PopupMenuItem(value: 'contract', child: Text('Contract')),
                  PopupMenuItem(value: 'internship', child: Text('Internship')),
                ],
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: typeFilter.isNotEmpty ? AppColors.primary.withAlpha(20) : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: typeFilter.isNotEmpty ? AppColors.primary : AppColors.border(context).withAlpha(120),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: typeFilter.isNotEmpty ? AppColors.primary : AppColors.grey600,
                      ),
                      if (typeFilter.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          typeFilter.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Status Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterPills.map((pill) {
                final isSelected = statusFilter == pill['key'];
                final count = pill['count'] as int;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onStatusFilterChanged(pill['key'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border(context).withAlpha(100),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pill['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withAlpha(40) : AppColors.grey100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.grey700,
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
      ),
    );
  }
}
