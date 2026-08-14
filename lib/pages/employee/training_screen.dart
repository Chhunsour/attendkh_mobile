import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';
import 'package:mpg_hr_mobile_app/providers/training_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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

  Future<void> _handleEnroll(TrainingCourseData training, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.enrollInTraining,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.grey900),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.enrollConfirm(training.title),
          style: const TextStyle(fontSize: 13.5, color: AppColors.grey700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(l10n.enroll, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            SnackBar(
              content: Text(l10n.enrolledSuccess),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.invalidate(availableTrainingsProvider);
          ref.invalidate(myTrainingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.enrolledFailed}: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncMyTrainings = ref.watch(myTrainingsProvider);
    final asyncAvailable = ref.watch(availableTrainingsProvider);

    final enrolledCount = asyncMyTrainings.maybeWhen(data: (l) => l.length, orElse: () => 0);
    final availableCount = asyncAvailable.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.myTraining,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(availableTrainingsProvider);
              ref.invalidate(myTrainingsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
          tabs: [
            Tab(text: '${l10n.availableCourses} ($availableCount)'),
            Tab(text: '${l10n.myEnrollments} ($enrolledCount)'),
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
    final asyncMyTrainings = ref.watch(myTrainingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return asyncTrainings.when(
      data: (trainings) {
        if (trainings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 56, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  l10n.noAvailableTrainings,
                  style: const TextStyle(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final myEnrolledIds = asyncMyTrainings.maybeWhen(
          data: (my) => my.map((e) => e['training_id'] as int).toList(),
          orElse: () => <int>[],
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableTrainingsProvider);
            ref.invalidate(myTrainingsProvider);
          },
          color: AppColors.primary,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: trainings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final t = trainings[index];
              final isEnrolled = myEnrolledIds.contains(t.id);

              return _CourseCard(
                training: t,
                isEnrolled: isEnrolled,
                onEnroll: () => _handleEnroll(t, l10n),
              );
            },
          ),
        );
      },
      loading: () => LoadingIndicator(message: l10n.loadingCourses),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
            const SizedBox(height: 8),
            Text('Failed to load courses: $e', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(availableTrainingsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTrainings() {
    final asyncMyTrainings = ref.watch(myTrainingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return asyncMyTrainings.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 56, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  l10n.noEnrolledTrainings,
                  style: const TextStyle(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Browse Courses', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myTrainingsProvider);
          },
          color: AppColors.primary,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: enrollments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
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
      loading: () => LoadingIndicator(message: l10n.loadingEnrollments),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
            const SizedBox(height: 8),
            Text('Failed to load enrollments: $e', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(myTrainingsProvider),
              child: Text(l10n.retry),
            ),
          ],
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Gradient Fallback
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: training.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: 'https://attendkh.com${training.coverImage}',
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholderIcon(),
                  )
                : _buildPlaceholderIcon(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        training.department?.name ?? l10n.companyWide,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (training.level != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          training.level!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.grey700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  training.title,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.grey900),
                ),
                if (training.description != null && training.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    training.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.grey600, height: 1.3),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (training.durationHours != null) ...[
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        '${training.durationHours} hrs',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 14),
                    ],
                    if (training.startDate != null) ...[
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        training.startDate!.split(' ')[0],
                        style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isEnrolled ? null : onEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnrolled ? AppColors.success : AppColors.primary,
                      disabledBackgroundColor: AppColors.success.withValues(alpha: 0.15),
                      disabledForegroundColor: AppColors.success,
                      elevation: isEnrolled ? 0 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEnrolled ? Icons.check_circle_rounded : Icons.login_rounded,
                          size: 18,
                          color: isEnrolled ? AppColors.success : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEnrolled ? l10n.enrolled : l10n.enrollNow,
                          style: TextStyle(
                            color: isEnrolled ? AppColors.success : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.school_rounded, size: 32, color: Color(0xFF0EA5E9)),
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
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = progress >= 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.4) : AppColors.grey200.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [
                        AppColors.success.withValues(alpha: 0.15),
                        const Color(0xFF10B981).withValues(alpha: 0.15),
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
              ),
            ),
            child: training.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: 'https://attendkh.com${training.coverImage}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        training.title,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.grey900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.courseProgress,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600),
                    ),
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100.0,
                    minHeight: 8,
                    backgroundColor: AppColors.grey100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.success : AppColors.primary,
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

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.school_rounded, size: 36, color: AppColors.primary),
    );
  }
}
