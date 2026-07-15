import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';
import 'package:mpg_hr_mobile_app/providers/training_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _handleEnroll(TrainingCourseData training) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enroll in Training'),
        content: Text('Are you sure you want to enroll in "${training.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enroll', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(performanceRepoProvider);
        await repo.selfEnroll(training.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully enrolled!'), backgroundColor: AppColors.success),
          );
          // Refresh both providers
          ref.invalidate(availableTrainingsProvider);
          ref.invalidate(myTrainingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to enroll: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Training'),
        elevation: 0,
        backgroundColor: AppColors.backgroundLight,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Available Courses'),
            Tab(text: 'My Enrollments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableTrainings(),
          _buildMyTrainings(),
        ],
      ),
    );
  }

  Widget _buildAvailableTrainings() {
    final asyncTrainings = ref.watch(availableTrainingsProvider);
    final asyncMyTrainings = ref.watch(myTrainingsProvider); // Need this to check if already enrolled

    return asyncTrainings.when(
      data: (trainings) {
        if (trainings.isEmpty) {
          return const Center(child: Text('No available trainings.', style: TextStyle(color: AppColors.grey500)));
        }

        // We check enrollment status from myTrainingsProvider
        final myEnrolledIds = asyncMyTrainings.maybeWhen(
          data: (my) => my.map((e) => e['training_id'] as int).toList(),
          orElse: () => <int>[],
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableTrainingsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trainings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final t = trainings[index];
              final isEnrolled = myEnrolledIds.contains(t.id);

              return _CourseCard(
                training: t,
                isEnrolled: isEnrolled,
                onEnroll: () => _handleEnroll(t),
              );
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading courses...'),
      error: (e, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(availableTrainingsProvider),
          child: const Text('Retry'),
        ),
      ),
    );
  }

  Widget _buildMyTrainings() {
    final asyncMyTrainings = ref.watch(myTrainingsProvider);

    return asyncMyTrainings.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return const Center(child: Text('You have not enrolled in any trainings.', style: TextStyle(color: AppColors.grey500)));
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myTrainingsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final enrollment = enrollments[index];
              final tData = enrollment['training'];
              if (tData == null) return const SizedBox.shrink();
              
              final t = TrainingCourseData.fromJson(tData);
              final progress = (enrollment['progress'] as num?)?.toInt() ?? 0;

              return _MyEnrollmentCard(training: t, progress: progress);
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading enrollments...'),
      error: (e, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(myTrainingsProvider),
          child: const Text('Retry'),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final TrainingCourseData training;
  final bool isEnrolled;
  final VoidCallback onEnroll;

  const _CourseCard({required this.training, required this.isEnrolled, required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Container(
            height: 140,
            width: double.infinity,
            color: AppColors.grey100,
            child: training.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: 'http://127.0.0.1:8000${training.coverImage}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.menu_book, size: 40, color: AppColors.grey300),
                  )
                : const Icon(Icons.menu_book, size: 50, color: AppColors.grey300),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        training.department?.name ?? 'Company-Wide',
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (training.level != null)
                      Text(
                        training.level!.toUpperCase(),
                        style: const TextStyle(color: AppColors.grey500, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  training.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900),
                ),
                if (training.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    training.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey500),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (training.durationHours != null) ...[
                      const Icon(Icons.access_time, size: 14, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text('${training.durationHours}h', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                      const SizedBox(width: 16),
                    ],
                    if (training.startDate != null) ...[
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(training.startDate!.split(' ')[0], style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isEnrolled ? null : onEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnrolled ? AppColors.success : AppColors.grey900,
                      disabledBackgroundColor: AppColors.success.withAlpha(150),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isEnrolled ? 'Enrolled' : 'Enroll Now',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyEnrollmentCard extends StatelessWidget {
  final TrainingCourseData training;
  final int progress;

  const _MyEnrollmentCard({required this.training, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1), // Highlight enrolled ones
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            color: AppColors.grey100,
            child: training.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: 'http://127.0.0.1:8000${training.coverImage}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.menu_book, size: 40, color: AppColors.grey300),
                  )
                : const Icon(Icons.menu_book, size: 40, color: AppColors.grey300),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  training.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Course Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                    Text('$progress%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
