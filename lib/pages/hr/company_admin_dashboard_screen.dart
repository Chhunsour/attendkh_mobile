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
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFDBEAFE),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                          strokeWidth: 3.5,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        l10n.switchingBranchView,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.corporate_fare_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: !authState.isCompanyAdmin
                  ? Text(
                      l10n.hrDashboard,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : ref
                        .watch(branchesProvider)
                        .when(
                          data: (branches) => branches.isEmpty
                              ? Text(
                                  l10n.hrDashboard,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : PopupMenuButton<BranchData?>(
                                  tooltip: 'Filter by branch',
                                  offset: const Offset(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  elevation: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.hrDashboard,
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              branchSwitchState.activeBranchName ?? l10n.selectBranch,
                                              style: const TextStyle(
                                                color: Color(0xFF6366F1),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF6366F1),
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onSelected: (branch) async {
                                    if (branch == null) {
                                      ref.read(branchSwitchProvider.notifier).exitBranchView();
                                    } else {
                                      await ref.read(branchSwitchProvider.notifier).switchToBranch(branch);
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
                                              Icon(Icons.clear, size: 16, color: AppColors.danger),
                                              SizedBox(width: 10),
                                              Text('Clear Filter', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
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
                                                  color: Color(0xFF6366F1).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.business_rounded, color: Color(0xFF6366F1), size: 16),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(b.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                                                    if (b.address != null)
                                                      Text(b.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
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
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.grey300 : AppColors.grey700,
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
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: GestureDetector(
              onTap: () => context.push(
                authState.isCompanyOwner ? AppRoutes.companyOwnerProfile : AppRoutes.profile,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      isDark ? AppColors.surfaceDarkElevated : AppColors.grey100,
                  backgroundImage: profileAsync.value?.photoUrl != null
                      ? CachedNetworkImageProvider(
                          profileAsync.value!.photoUrl!,
                          maxWidth: 120,
                          maxHeight: 120,
                        )
                      : null,
                  child: profileAsync.value?.photoUrl == null
                      ? const Icon(Icons.person, color: AppColors.grey600, size: 18)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(branchesProvider);
          return await ref.read(dashboardStatsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Executive Dark Hero Welcome Banner ──
            _buildWelcomeBanner(
              name: authState.userName ?? 'Manager',
              companyName: authState.companyName ?? 'My Company',
              l10n: l10n,
            ),

            const SizedBox(height: 18),

            // ── Dashboard Overview Metrics ──
            ref.watch(dashboardStatsProvider).when(
                  data: (kpi) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.companyOverview,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: Color(0xFF10B981), size: 6.5),
                                  SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Row 1 ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.totalStaff,
                              kpi.totalEmployees.toString(),
                              Icons.people_alt_rounded,
                              const Color(0xFF6366F1),
                              const Color(0xFFEEF2FF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.attendanceMenu,
                              kpi.todayAttendance.toString(),
                              Icons.fingerprint_rounded,
                              const Color(0xFF10B981),
                              const Color(0xFFECFDF5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Row 2 ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.leaveRequests,
                              kpi.pendingLeaves.toString(),
                              Icons.event_busy_rounded,
                              const Color(0xFFF59E0B),
                              const Color(0xFFFFFBEB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.expenseClaims,
                              kpi.pendingExpenses.toString(),
                              Icons.receipt_long_rounded,
                              const Color(0xFFEC4899),
                              const Color(0xFFFDF2F8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Row 3 ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.openJobs,
                              kpi.openJobs.toString(),
                              Icons.work_outline_rounded,
                              const Color(0xFF0EA5E9),
                              const Color(0xFFF0F9FF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.assets,
                              '${kpi.assignedAssets}/${kpi.totalAssets}',
                              Icons.devices_rounded,
                              const Color(0xFF8B5CF6),
                              const Color(0xFFF5F3FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Row 4 ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              l10n.payroll,
                              '\$${kpi.monthlyPayroll.toStringAsFixed(0)}',
                              Icons.payments_rounded,
                              const Color(0xFF059669),
                              const Color(0xFFECFDF5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ── Pending Actions ──
                      ..._buildPendingActions(context, kpi, l10n),

                      // ── Recent Activity ──
                      if (kpi.recentActivity.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: Color(0xFF6366F1)),
                              SizedBox(width: 6),
                              Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...kpi.recentActivity.map((a) => _buildActivityItem(context, a)),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${l10n.errorLoadingKpis}$e',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

            // ── HR Manager Note ──
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.hrPortalActive,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.hrPortalDesc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.grey500,
                            height: 1.3,
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

  Widget _buildActivityItem(BuildContext context, RecentActivity activity) {
    final (icon, color, bg) = switch (activity.type) {
      'hire' => (Icons.person_add_rounded, Color(0xFF10B981), Color(0xFFECFDF5)),
      'leave' => (Icons.event_busy_rounded, Color(0xFFF59E0B), Color(0xFFFFFBEB)),
      'expense' => (Icons.receipt_long_rounded, Color(0xFFEC4899), Color(0xFFFDF2F8)),
      _ => (Icons.history_rounded, Color(0xFF64748B), Color(0xFFF1F5F9)),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatActivityTime(activity.time),
                      style: const TextStyle(fontSize: 10.5, color: AppColors.grey400),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
          message: '${kpi.pendingLeaves} ${l10n.leaveRequests.toLowerCase()} awaiting approval',
          color: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFFFBEB),
          routePath: AppRoutes.adminLeave,
        ),
      );
    }

    if (kpi.pendingExpenses > 0) {
      actions.add(
        _buildPendingActionItem(
          context,
          icon: Icons.receipt_long_rounded,
          message: '${kpi.pendingExpenses} ${l10n.expenseClaims.toLowerCase()} to review',
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          routePath: AppRoutes.adminExpenses,
        ),
      );
    }

    if (kpi.openJobs > 0) {
      actions.add(
        _buildPendingActionItem(
          context,
          icon: Icons.work_outline_rounded,
          message: '${kpi.openJobs} active ${l10n.openJobs.toLowerCase()}',
          color: const Color(0xFF0EA5E9),
          bgColor: const Color(0xFFF0F9FF),
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
          bgColor: const Color(0xFFF5F3FF),
          routePath: AppRoutes.adminAssets,
        ),
      );
    }

    if (actions.isEmpty) return [];

    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFFF59E0B)),
            SizedBox(width: 6),
            Text(
              'Pending Actions',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ...actions,
      const SizedBox(height: 20),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        l10n.companyAdministrator.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  companyName,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Color(0xFFA5B4FC),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
