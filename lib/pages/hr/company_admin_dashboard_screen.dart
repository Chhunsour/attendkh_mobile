import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'branch_payroll_settings_screen.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class CompanyAdminDashboardScreen extends ConsumerStatefulWidget {
  const CompanyAdminDashboardScreen({super.key});

  @override
  ConsumerState<CompanyAdminDashboardScreen> createState() => _CompanyAdminDashboardScreenState();
}

class _CompanyAdminDashboardScreenState extends ConsumerState<CompanyAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FcmService.instance.checkAndPromptNotificationPermission(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final branchSwitchState = ref.watch(branchSwitchProvider);
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        _buildMainScaffold(context, ref, authState, profileAsync, l10n),
        // Blur overlay when switching branches
        if (branchSwitchState.isSwitching) _buildBlurOverlay(l10n),
      ],
    );
  }

  Widget _buildBlurOverlay(AppLocalizations l10n) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.black.withAlpha(100),
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFEDD5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: Color(0xFFF97316),
                          backgroundColor: Color(0xFFFED7AA),
                          strokeWidth: 4.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.switchingBranchView,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                          fontFamily: 'Inter',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.loadingBranchData,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                          fontFamily: 'Inter',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScaffold(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    AsyncValue<ProfileData> profileAsync,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
              child: const Icon(
                Icons.business_center_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: !authState.isCompanyAdmin
                  ? Text(
                      l10n.hrDashboard,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : ref.watch(branchesProvider).when(
                        data: (branches) => branches.isEmpty
                            ? Text(
                                l10n.hrDashboard,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : PopupMenuButton<BranchData>(
                                tooltip: 'Select a branch to impersonate',
                                offset: const Offset(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                                elevation: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.hrDashboard,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l10n.selectBranch,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.primary,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onSelected: (branch) async {
                                  await ref.read(branchSwitchProvider.notifier).switchToBranch(branch);
                                  if (context.mounted) {
                                    context.push(AppRoutes.branchManagerView);
                                  }
                                },
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem<BranchData>(
                                      enabled: false,
                                      height: 30,
                                      child: Text(
                                        l10n.viewAsBranchManager,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.grey500,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                    ...branches.map(
                                      (b) => PopupMenuItem<BranchData>(
                                        value: b,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF97316).withAlpha(15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.business_rounded,
                                                color: Color(0xFFF97316),
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    b.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.grey800,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                  if (b.address != null)
                                                    Text(
                                                      b.address!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.grey500,
                                                        fontFamily: 'Inter',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                              ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, s) => const SizedBox.shrink(),
                      ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(unreadCountProvider);
              final unreadCount = unreadCountAsync.valueOrNull ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                    onPressed: () async {
                      await context.push(AppRoutes.notifications);
                      ref.invalidate(unreadCountProvider);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 8),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: profileAsync.value?.photoUrl != null
                      ? CachedNetworkImageProvider(profileAsync.value!.photoUrl!)
                      : null,
                  child: profileAsync.value?.photoUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                      : null,
                ),
              ),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(branchesProvider);
          return await ref.read(dashboardStatsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
          // ── Welcome Banner
          _buildWelcomeBanner(
            name: authState.userName ?? 'Manager',
            companyName: authState.companyName ?? 'My Company',
            l10n: l10n,
          ),
          const SizedBox(height: 24),

          // ── Dashboard KPIs
          ref
              .watch(dashboardStatsProvider)
              .when(
                data: (kpi) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.companyOverview,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            l10n.totalStaff,
                            kpi.totalEmployees.toString(),
                            Icons.people,
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            l10n.onLeave,
                            kpi.pendingLeaves.toString(),
                            Icons.event_busy,
                            const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            l10n.openJobs,
                            kpi.openJobs.toString(),
                            Icons.work,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            l10n.assets,
                            '${kpi.assignedAssets}/${kpi.totalAssets}',
                            Icons.devices,
                            const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${l10n.errorLoadingKpis}$e',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
          // ── Quick Operations Grid Menu
          Text(
            l10n.quickOperations,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.hrStructure,
                  description: l10n.deptsAndBranches,
                  icon: Icons.corporate_fare_rounded,
                  color: const Color(0xFF6366F1),
                  routePath: AppRoutes.hrStructure,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: l10n.kpis,
                  description: l10n.performanceGoals,
                  icon: Icons.track_changes_outlined,
                  color: AppColors.primary,
                  routePath: AppRoutes.kpi,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: l10n.employees,
                  description: l10n.manageStaff,
                  icon: Icons.people_rounded,
                  color: const Color(0xFF0EA5E9),
                  routePath: AppRoutes.adminEmployees,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: l10n.attendanceMenu,
                  description: l10n.viewLogs,
                  icon: Icons.fingerprint_rounded,
                  color: const Color(0xFF14B8A6), // Teal
                  routePath: AppRoutes.adminAttendance,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: l10n.shiftRules,
                  description: l10n.workSchedules,
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF10B981),
                  routePath: AppRoutes.adminShifts,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.holidays,
                  description: l10n.manageCompanyHolidays,
                  icon: Icons.celebration_rounded,
                  color: const Color(0xFFEAB308), // Yellow
                  routePath: AppRoutes.adminHolidays,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: l10n.leaveRequests,
                  description: l10n.reviewSubmissions,
                  icon: Icons.event_busy_rounded,
                  color: const Color(0xFFEF4444),
                  routePath: AppRoutes.adminLeave,
                ),
              if (authState.isBranchManager && !authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.branchSettings,
                  description: l10n.payrollAndRules,
                  icon: Icons.settings_applications_rounded,
                  color: const Color(0xFFF97316),
                  onTap: () {
                    final profile = ref.read(profileProvider).value;
                    if (profile != null && profile.branchId != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BranchPayrollSettingsScreen(
                          branchId: profile.branchId!,
                          branchName: profile.branchName ?? 'Branch',
                        ),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.branchInfoMissing)),
                      );
                    }
                  },
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.payroll,
                  description: l10n.processRuns,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFFF59E0B),
                  routePath: AppRoutes.adminPayroll,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.expenseClaims,
                  description: l10n.reviewClaims,
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFEC4899),
                  routePath: AppRoutes.adminExpenses,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.assets,
                  description: l10n.devicesAndStock,
                  icon: Icons.devices_rounded,
                  color: const Color(0xFF6B7280),
                  routePath: AppRoutes.adminAssets,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.announcements,
                  description: l10n.broadcastAlerts,
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF8B5CF6),
                  routePath: AppRoutes.adminSendNotification,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.recruitment,
                  description: l10n.jobsAndCandidates,
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFFF97316),
                  routePath: AppRoutes.adminRecruitment,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.performance,
                  description: l10n.reviewsAndTraining,
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFA855F7),
                  routePath: AppRoutes.adminPerformance,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.reports,
                  description: l10n.analyticsAndExports,
                  icon: Icons.assessment_rounded,
                  color: const Color(0xFF14B8A6),
                  routePath: AppRoutes.adminReports,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.documents,
                  description: l10n.companyFiles,
                  icon: Icons.folder_open_rounded,
                  color: const Color(0xFFF59E0B),
                  routePath: AppRoutes.adminDocuments,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.policies,
                  description: l10n.rulesAndGuidelines,
                  icon: Icons.book_rounded,
                  color: const Color(0xFF3B82F6),
                  routePath: AppRoutes.adminPolicies,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: l10n.notifications,
                  description: l10n.viewInbox,
                  icon: Icons.notifications_rounded,
                  color: const Color(0xFFEF4444),
                  routePath: AppRoutes.notifications,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── HR Manager Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.hrPortalActive,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.hrPortalDesc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                          height: 1.4,
                          fontFamily: 'Inter',
                        ),
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
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner({
    required String name,
    required String companyName,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '💼  ${l10n.companyAdministrator}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    String? routePath,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        if (routePath != null) context.push(routePath);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
