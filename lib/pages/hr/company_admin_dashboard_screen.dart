import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class CompanyAdminDashboardScreen extends ConsumerStatefulWidget {
  const CompanyAdminDashboardScreen({super.key});

  @override
  ConsumerState<CompanyAdminDashboardScreen> createState() =>
      _CompanyAdminDashboardScreenState();
}

class _CompanyAdminDashboardScreenState
    extends ConsumerState<CompanyAdminDashboardScreen> {
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
        _buildMainScaffold(
          context,
          ref,
          authState,
          branchSwitchState,
          profileAsync,
          l10n,
        ),
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
                      color: const Color(0xFFDBEAFE),
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
                          color: Color(0xFF0052FF),
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

                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.loadingBranchData,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,

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
    BranchSwitchState branchSwitchState,
    AsyncValue<ProfileData> profileAsync,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
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
                        color: AppColors.grey800,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : ref
                        .watch(branchesProvider)
                        .when(
                          data: (branches) => branches.isEmpty
                              ? Text(
                                  l10n.hrDashboard,
                                  style: const TextStyle(
                                    color: AppColors.grey800,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : PopupMenuButton<BranchData?>(
                                  tooltip: 'Filter by branch',
                                  offset: const Offset(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.white,
                                  elevation: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.hrDashboard,
                                        style: const TextStyle(
                                          color: AppColors.grey800,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            branchSwitchState
                                                    .activeBranchName ??
                                                l10n.selectBranch,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
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
                                    if (branch == null) {
                                      ref
                                          .read(branchSwitchProvider.notifier)
                                          .exitBranchView();
                                    } else {
                                      await ref
                                          .read(branchSwitchProvider.notifier)
                                          .switchToBranch(branch);
                                    }
                                    ref.invalidate(dashboardStatsProvider);
                                  },
                                  itemBuilder: (context) {
                                    return [
                                      PopupMenuItem<BranchData?>(
                                        enabled: false,
                                        height: 30,
                                        child: Text(
                                          l10n.viewAsBranchManager,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                      ),
                                      if (branchSwitchState.isActive)
                                        const PopupMenuItem<BranchData?>(
                                          value: null,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.clear,
                                                size: 16,
                                                color: AppColors.danger,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Clear Filter',
                                                style: TextStyle(
                                                  color: AppColors.danger,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ...branches.map(
                                        (b) => PopupMenuItem<BranchData?>(
                                          value: b,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF0052FF,
                                                  ).withAlpha(15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.business_rounded,
                                                  color: Color(0xFF0052FF),
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      b.name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.grey800,
                                                      ),
                                                    ),
                                                    if (b.address != null)
                                                      Text(
                                                        b.address!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              AppColors.grey500,
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
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                    ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
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
              onTap: () => context.push(
                authState.isCompanyOwner
                    ? AppRoutes.companyOwnerProfile
                    : AppRoutes.profile,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: profileAsync.value?.photoUrl != null
                      ? CachedNetworkImageProvider(
                          profileAsync.value!.photoUrl!,
                          maxWidth: 120,
                          maxHeight: 120,
                        )
                      : null,
                  child: profileAsync.value?.photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
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
                              l10n.attendanceMenu,
                              kpi.todayAttendance.toString(),
                              Icons.fingerprint,
                              const Color(0xFF14B8A6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              l10n.leaveRequests,
                              kpi.pendingLeaves.toString(),
                              Icons.event_busy,
                              const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              l10n.expenseClaims,
                              kpi.pendingExpenses.toString(),
                              Icons.receipt_long,
                              const Color(0xFFEC4899),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              l10n.payroll,
                              '\$${kpi.monthlyPayroll.toStringAsFixed(0)}',
                              Icons.payments,
                              const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Pending Actions
                      ..._buildPendingActions(context, kpi, l10n),

                      // ── Recent Activity
                      if (kpi.recentActivity.isNotEmpty) ...[
                        Text(
                          'Recent Activity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...kpi.recentActivity.map((a) => _buildActivityItem(a)),
                        const SizedBox(height: 24),
                      ],
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.hrPortalDesc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                            height: 1.4,
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

  Widget _buildActivityItem(RecentActivity activity) {
    final (icon, color) = switch (activity.type) {
      'hire' => (Icons.person_add_rounded, const Color(0xFF10B981)),
      'leave' => (Icons.event_busy_rounded, const Color(0xFFF59E0B)),
      'expense' => (Icons.receipt_long_rounded, const Color(0xFFEC4899)),
      _ => (Icons.history_rounded, AppColors.grey400),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activity.time.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatActivityTime(activity.time),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.grey400,
                        ),
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

  String _formatActivityTime(String time) {
    try {
      final dt = DateTime.parse(time);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return time;
    }
  }

  List<Widget> _buildPendingActions(
    BuildContext context,
    DashboardKpiData kpi,
    AppLocalizations l10n,
  ) {
    final actions = <Widget>[];

    if (kpi.pendingLeaves > 0) {
      actions.add(
        _buildPendingActionItem(
          context,
          icon: Icons.event_busy_rounded,
          message: '${kpi.pendingLeaves} ${l10n.leaveRequests.toLowerCase()}',
          color: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFEF3C7),
          routePath: AppRoutes.adminLeave,
        ),
      );
    }

    if (kpi.pendingExpenses > 0) {
      actions.add(
        _buildPendingActionItem(
          context,
          icon: Icons.receipt_long_rounded,
          message: '${kpi.pendingExpenses} ${l10n.expenseClaims.toLowerCase()}',
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEE2E2),
          routePath: AppRoutes.adminExpenses,
        ),
      );
    }

    if (kpi.openJobs > 0) {
      actions.add(
        _buildPendingActionItem(
          context,
          icon: Icons.work_outline_rounded,
          message: '${kpi.openJobs} ${l10n.openJobs.toLowerCase()}',
          color: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFDBEAFE),
          routePath: AppRoutes.adminRecruitment,
        ),
      );
    }

    final unassignedAssets = kpi.totalAssets - kpi.assignedAssets;
    if (unassignedAssets > 0) {
      actions.add(
        _buildPendingActionItem(
          context,
          icon: Icons.devices_rounded,
          message: '$unassignedAssets unassigned ${l10n.assets.toLowerCase()}',
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFEDE9FE),
          routePath: AppRoutes.adminAssets,
        ),
      );
    }

    if (actions.isEmpty) return [];

    return [
      Text(
        'Pending Actions',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.grey800,
        ),
      ),
      const SizedBox(height: 12),
      ...actions,
      const SizedBox(height: 24),
    ];
  }

  Widget _buildPendingActionItem(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
    required Color bgColor,
    required String routePath,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(routePath),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
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
}
