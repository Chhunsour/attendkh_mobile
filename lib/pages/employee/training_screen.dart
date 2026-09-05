import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/performance_repository.dart';
import 'package:attendkh/providers/training_provider.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleEnroll(
    TrainingCourseData training,
    AppLocalizations l10n,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.enrollInTraining,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enrollConfirm(training.title),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
                height: 1.4,
              ),
            ),
            if (training.durationHours != null || training.startDate != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDarkElevated
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (training.durationHours != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${training.durationHours} hrs',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    if (training.startDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            training.startDate!.split(' ')[0],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: isDark ? AppColors.grey400 : AppColors.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              l10n.enroll,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(performanceRepoProvider);
        await repo.selfEnroll(training.id);

        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.enrolledSuccess,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  void _refresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(availableTrainingsProvider);
    ref.invalidate(myTrainingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncMyTrainings = ref.watch(myTrainingsProvider);
    final asyncAvailable = ref.watch(availableTrainingsProvider);

    final enrolledCount = asyncMyTrainings.maybeWhen(
      data: (l) => l.length,
      orElse: () => 0,
    );
    final availableCount = asyncAvailable.maybeWhen(
      data: (l) => l.length,
      orElse: () => 0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // ── Royal Blue Curved Hero Header (Matches Home / Profile) ──
            _buildRoyalHeroHeader(
              context: context,
              l10n: l10n,
              availableCount: availableCount,
              enrolledCount: enrolledCount,
              isDark: isDark,
            ),

            // ── Tab Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableTrainings(l10n, isDark),
                  _buildMyTrainings(l10n, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Royal Blue Curved Hero Header ──
  Widget _buildRoyalHeroHeader({
    required BuildContext context,
    required AppLocalizations l10n,
    required int availableCount,
    required int enrolledCount,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038B8), // Royal Blue Deep
            Color(0xFF0052FF), // Royal Blue Main
            Color(0xFF1E6BFF), // Royal Blue Light Glow
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x550052FF),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  // ── Top Navigation Bar ──
                  Row(
                    children: [
                      if (context.canPop())
                        _frostedHeroButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          l10n.myTraining,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _frostedHeroButton(
                        icon: Icons.refresh_rounded,
                        tooltip: l10n.refresh,
                        onTap: _refresh,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Overview Stat Badges ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStatCard(
                          icon: Icons.auto_stories_rounded,
                          title: l10n.availableCourses,
                          count: availableCount.toString(),
                          isSelected: _tabController.index == 0,
                          onTap: () => _tabController.animateTo(0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHeroStatCard(
                          icon: Icons.workspace_premium_rounded,
                          title: l10n.myEnrollments,
                          count: enrolledCount.toString(),
                          isSelected: _tabController.index == 1,
                          onTap: () => _tabController.animateTo(1),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Frosted Capsule Segmented TabBar ──
                  Container(
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.88),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        letterSpacing: -0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        letterSpacing: -0.1,
                      ),
                      dividerHeight: 0,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.availableCourses,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              _tabBadge(
                                availableCount,
                                isSelected: _tabController.index == 0,
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.myEnrollments,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              _tabBadge(
                                enrolledCount,
                                isSelected: _tabController.index == 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBadge(int count, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: isSelected ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeroStatCard({
    required IconData icon,
    required String title,
    required String count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isSelected ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: isSelected ? 0.40 : 0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        count,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frostedHeroButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Available Trainings ──
  Widget _buildAvailableTrainings(AppLocalizations l10n, bool isDark) {
    final asyncTrainings = ref.watch(availableTrainingsProvider);
    final asyncMyTrainings = ref.watch(myTrainingsProvider);

    return asyncTrainings.when(
      data: (trainings) {
        if (trainings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_rounded,
            title: l10n.noAvailableTrainings,
            subtitle: l10n.newCoursesPublishedDesc,
            actionLabel: l10n.refreshCourses,
            onAction: _refresh,
            isDark: isDark,
          );
        }

        final myEnrolledIds = asyncMyTrainings.maybeWhen(
          data: (my) => my.map((e) => e['training_id'] as int).toList(),
          orElse: () => <int>[],
        );

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
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
      error: (e, _) => _buildErrorState(
        message: 'Failed to load courses: $e',
        onRetry: _refresh,
        isDark: isDark,
        l10n: l10n,
      ),
    );
  }

  // ── Tab 2: My Enrollments ──
  Widget _buildMyTrainings(AppLocalizations l10n, bool isDark) {
    final asyncMyTrainings = ref.watch(myTrainingsProvider);

    return asyncMyTrainings.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.menu_book_rounded,
            title: l10n.noEnrolledTrainings,
            subtitle: l10n.noTrainingsEnrolledDesc,
            actionLabel: l10n.browseAvailableCourses,
            onAction: () => _tabController.animateTo(0),
            isDark: isDark,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
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
      error: (e, _) => _buildErrorState(
        message: 'Failed to load enrollments: $e',
        onRetry: _refresh,
        isDark: isDark,
        l10n: l10n,
      ),
    );
  }

  // ── Modern Executive Empty State ──
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isDark,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.20 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.20),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 38,
                color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAction();
              },
              icon: const Icon(Icons.explore_rounded, size: 17),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.surfaceDarkElevated
                    : AppColors.primaryLight,
                foregroundColor: isDark ? const Color(0xFF93C5FD) : AppColors.primaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : const Color(0xFFBFDBFE),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Polished Course Card ──
class _CourseCard extends StatelessWidget {
  final TrainingCourseData training;
  final bool isEnrolled;
  final VoidCallback onEnroll;

  const _CourseCard({
    required this.training,
    required this.isEnrolled,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Rich Gradient Fallback
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.25 : 0.15),
                  const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (training.coverImage != null && training.coverImage!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: training.coverImage!,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholderIcon(isDark),
                  )
                else
                  _buildPlaceholderIcon(isDark),

                // Category Badge (safe from collision with Level badge)
                Positioned(
                  top: 12,
                  left: 12,
                  right: training.level != null ? 100 : 12,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: Text(
                        training.department?.name ?? l10n.companyWide,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // Level Badge
                if (training.level != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.40),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        training.level!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  training.title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                    letterSpacing: -0.2,
                  ),
                ),
                if (training.description != null &&
                    training.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    training.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Details strip using Wrap to prevent horizontal overflow on narrow screens
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (training.durationHours != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${training.durationHours} hrs',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.grey300 : AppColors.grey700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (training.startDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            training.startDate!.split(' ')[0],
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.grey300 : AppColors.grey700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isEnrolled ? null : onEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isEnrolled ? const Color(0xFF10B981) : AppColors.primary,
                      disabledBackgroundColor:
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                      disabledForegroundColor: const Color(0xFF10B981),
                      elevation: isEnrolled ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEnrolled
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                          color: isEnrolled
                              ? const Color(0xFF10B981)
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isEnrolled ? l10n.enrolled : l10n.enrollNow,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholderIcon(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.school_rounded,
          size: 36,
          color: Color(0xFF0052FF),
        ),
      ),
    );
  }
}

// ── Polished My Enrollment Card ──
class _MyEnrollmentCard extends StatelessWidget {
  final TrainingCourseData training;
  final int progress;

  const _MyEnrollmentCard({required this.training, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = progress >= 100;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [
                        const Color(0xFF10B981).withValues(alpha: 0.15),
                        const Color(0xFF34D399).withValues(alpha: 0.15),
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.12),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      ],
              ),
            ),
            child: training.coverImage != null && training.coverImage!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: training.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.courseProgress,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100.0,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.surfaceDarkElevated
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? const Color(0xFF10B981) : AppColors.primary,
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
      child: Icon(Icons.school_rounded, size: 38, color: AppColors.primary),
    );
  }
}
