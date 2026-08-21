import 'dart:ui';
import 'package:intl/intl.dart';
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

/// One cut corner on every card — the motif that ties the page together.
const _cardShape = BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
  bottomRight: Radius.circular(20),
  bottomLeft: Radius.circular(6),
);

/// Icon chips echo the card shape one size down.
const _chipShape = BorderRadius.only(
  topLeft: Radius.circular(14),
  topRight: Radius.circular(14),
  bottomRight: Radius.circular(14),
  bottomLeft: Radius.circular(5),
);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
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
                          color: AppColors.primary,
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 18),
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
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        // Blends into the page so the hero card is the first hard edge you see
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.hrDashboard,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (authState.isCompanyAdmin)
              ref
                  .watch(branchesProvider)
                  .when(
                    data: (branches) => branches.isEmpty
                        ? const SizedBox.shrink()
                        : _buildBranchSelector(
                            context,
                            ref,
                            branches,
                            branchSwitchState,
                            l10n,
                            isDark,
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, s) => const SizedBox.shrink(),
                  ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCount =
                  ref.watch(unreadCountProvider).valueOrNull ?? 0;
              return _buildHeaderAction(
                context,
                isDark: isDark,
                icon: Icons.notifications_none_rounded,
                badge: unreadCount == 0
                    ? null
                    : (unreadCount > 99 ? '99+' : '$unreadCount'),
                onTap: () async {
                  await context.push(AppRoutes.notifications);
                  ref.invalidate(unreadCountProvider);
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () => context.push(
                authState.isCompanyOwner
                    ? AppRoutes.companyOwnerProfile
                    : AppRoutes.profile,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface(context),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.grey100,
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
                          color: AppColors.grey600,
                          size: 18,
                        )
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
          ref.invalidate(holidaysAdminProvider);
          return await ref.read(dashboardStatsProvider.future);
        },
        child: Consumer(
          builder: (context, ref, _) {
            final statsAsync = ref.watch(dashboardStatsProvider);
            final kpi = statsAsync.valueOrNull;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _buildTodayCard(
                  name: authState.userName ?? 'Manager',
                  kpi: kpi,
                  l10n: l10n,
                ),
                const SizedBox(height: 22),

                if (statsAsync.hasError)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${l10n.errorLoadingKpis}${statsAsync.error}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (kpi == null)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else ...[
                  // ── Approvals only: things that stay blocked until you act ──
                  ..._buildApprovals(context, kpi, l10n),

                  _buildSectionHeader(context, l10n.companyOverview),
                  const SizedBox(height: 10),
                  _buildOverviewGrid(context, kpi, l10n),
                  const SizedBox(height: 12),

                  _buildNextHoliday(context, l10n),

                  if (kpi.recentActivity.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, l10n.recentActivity),
                    const SizedBox(height: 10),
                    ...kpi.recentActivity
                        .take(5)
                        .map((a) => _buildActivityItem(context, a)),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Squared icon button in the cut-corner chip shape, with a ringed badge so
  /// the count never smears into the glyph behind it.
  Widget _buildHeaderAction(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: AppColors.surface(context),
      borderRadius: _chipShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: _chipShape,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: _chipShape,
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -7,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Branch scope as a filter chip, not blue text — a link-blue label with a
  /// caret reads as broken, and hides that this is the page's active scope.
  Widget _buildBranchSelector(
    BuildContext context,
    WidgetRef ref,
    List<BranchData> branches,
    BranchSwitchState branchSwitchState,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final scoped = branchSwitchState.isActive;
    final label = branchSwitchState.activeBranchName ?? l10n.allBranchesLabel;
    final tint = scoped ? AppColors.primary : AppColors.textSecondary(context);

    return PopupMenuButton<BranchData?>(
      tooltip: l10n.selectBranch,
      offset: const Offset(0, 40),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 6,
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: scoped ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tint.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scoped ? Icons.business_rounded : Icons.filter_list_rounded,
              size: 12,
              color: tint,
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded, color: tint, size: 14),
          ],
        ),
      ),
      onSelected: (branch) async {
        if (branch == null) {
          ref.read(branchSwitchProvider.notifier).exitBranchView();
        } else {
          await ref.read(branchSwitchProvider.notifier).switchToBranch(branch);
        }
        ref.invalidate(dashboardStatsProvider);
      },
      itemBuilder: (context) => [
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
          PopupMenuItem<BranchData?>(
            value: null,
            child: Row(
              children: [
                const Icon(Icons.clear, size: 16, color: AppColors.danger),
                const SizedBox(width: 10),
                Text(
                  l10n.clearFilters,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        b.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
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
    );
  }

  Widget _buildActivityItem(BuildContext context, RecentActivity activity) {
    final (icon, color) = switch (activity.type) {
      'hire' => (Icons.person_add_rounded, const Color(0xFF10B981)),
      'leave' => (Icons.event_busy_rounded, const Color(0xFFF59E0B)),
      'expense' => (Icons.receipt_long_rounded, const Color(0xFFEC4899)),
      _ => (Icons.history_rounded, const Color(0xFF64748B)),
    };
    final name = activity.name?.isNotEmpty == true ? activity.name! : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: _cardShape,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildActivityAvatar(context, activity, icon, color, name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null)
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  activity.action,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: name == null
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: name == null
                        ? AppColors.textPrimary(context)
                        : AppColors.textSecondary(context),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (activity.time.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              _formatActivityTime(activity.time),
              style: const TextStyle(fontSize: 10.5, color: AppColors.grey400),
            ),
          ],
        ],
      ),
    );
  }

  /// Employee photo with a small badge for the activity type. Falls back to
  /// initials, then to the type icon, so an empty `photo` still looks intentional.
  Widget _buildActivityAvatar(
    BuildContext context,
    RecentActivity activity,
    IconData icon,
    Color color,
    String? name,
  ) {
    final photo = activity.photo;
    final initials = name
        ?.split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return SizedBox(
      width: 44,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            backgroundImage: photo != null && photo.isNotEmpty
                ? CachedNetworkImageProvider(
                    photo,
                    maxWidth: 120,
                    maxHeight: 120,
                  )
                : null,
            child: photo != null && photo.isNotEmpty
                ? null
                : (initials != null && initials.isNotEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        )
                      : Icon(icon, color: color, size: 18)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface(context),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 9),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: AppColors.textSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  String _compactAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  /// Only approvals live here — reference numbers belong in the overview grid,
  /// so nothing is counted twice on the same screen.
  List<Widget> _buildApprovals(
    BuildContext context,
    DashboardKpiData kpi,
    AppLocalizations l10n,
  ) {
    final actions = <Widget>[];

    if (kpi.pendingLeaves > 0) {
      actions.add(
        _buildApprovalRow(
          context,
          icon: Icons.event_busy_rounded,
          count: kpi.pendingLeaves,
          title: l10n.leaveRequests,
          color: const Color(0xFFF59E0B),
          routePath: AppRoutes.adminLeave,
        ),
      );
    }

    if (kpi.pendingExpenses > 0) {
      actions.add(
        _buildApprovalRow(
          context,
          icon: Icons.receipt_long_rounded,
          count: kpi.pendingExpenses,
          title: l10n.expenseClaims,
          color: const Color(0xFFEF4444),
          routePath: AppRoutes.adminExpenses,
        ),
      );
    }

    return [
      _buildSectionHeader(context, l10n.actionRequired),
      const SizedBox(height: 10),
      if (actions.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: _cardShape,
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.allCaughtUp,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        )
      else
        ...actions,
      const SizedBox(height: 22),
    ];
  }

  Widget _buildApprovalRow(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String title,
    required Color color,
    required String routePath,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface(context),
        borderRadius: _cardShape,
        child: InkWell(
          onTap: () => context.push(routePath),
          borderRadius: _cardShape,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: _cardShape,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // urgency rail — the row's colour reads before the text does
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                                bottomLeft: Radius.circular(5),
                              ),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One slab, hairline-divided — same construction as the employee quick
  /// grid, so every cell is identically sized and the four read as one block.
  Widget _buildOverviewGrid(
    BuildContext context,
    DashboardKpiData kpi,
    AppLocalizations l10n,
  ) {
    final line = AppColors.border(context);
    final idle = kpi.totalAssets - kpi.assignedAssets;

    final cells = [
      _buildMetricCell(
        context,
        label: l10n.totalStaff,
        value: kpi.totalEmployees.toString(),
        icon: Icons.people_alt_rounded,
        color: AppColors.primary,
        route: AppRoutes.adminEmployees,
      ),
      _buildMetricCell(
        context,
        label: l10n.payroll,
        value: '\$${_compactAmount(kpi.monthlyPayroll)}',
        icon: Icons.payments_rounded,
        color: const Color(0xFF059669),
        route: AppRoutes.adminPayroll,
        isZero: kpi.monthlyPayroll == 0,
      ),
      _buildMetricCell(
        context,
        label: l10n.openJobs,
        value: kpi.openJobs.toString(),
        icon: Icons.work_outline_rounded,
        color: const Color(0xFF0EA5E9),
        route: AppRoutes.adminRecruitment,
      ),
      _buildMetricCell(
        context,
        label: l10n.assets,
        value: '${kpi.assignedAssets}/${kpi.totalAssets}',
        icon: Icons.devices_rounded,
        color: const Color(0xFF8B5CF6),
        route: AppRoutes.adminAssets,
        isZero: kpi.totalAssets == 0,
        // Surfacing what is idle is more useful than the raw ratio
        footnote: idle > 0 ? '$idle unassigned' : null,
      ),
    ];

    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: line),
        borderRadius: _cardShape,
      ),
      child: Column(
        children: [
          for (int r = 0; r < 2; r++) ...[
            if (r > 0) Container(height: 1, color: line),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cells[r * 2]),
                  Container(width: 1, color: line),
                  Expanded(child: cells[r * 2 + 1]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Every cell reserves the same vertical slots — chip, value, label,
  /// footnote — so the numbers and labels line up across the whole grid
  /// whether or not a cell has a footnote.
  Widget _buildMetricCell(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String route,
    bool? isZero,
    String? footnote,
  }) {
    final muted = isZero ?? value == '0';

    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 13, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: muted ? 0.07 : 0.12),
                    borderRadius: _chipShape,
                  ),
                  child: Icon(
                    icon,
                    color: muted ? color.withValues(alpha: 0.45) : color,
                    size: 17,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: AppColors.grey400.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.1,
                    color: muted
                        ? AppColors.grey400
                        : AppColors.textPrimary(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Reserved slot — keeps every cell the same height
            SizedBox(
              height: 15,
              child: footnote == null
                  ? null
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        footnote,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Next upcoming holiday — planning context an HR owner otherwise has to
  /// go hunting for. Silently absent when there is nothing coming up.
  Widget _buildNextHoliday(BuildContext context, AppLocalizations l10n) {
    final holidays = ref.watch(holidaysAdminProvider).valueOrNull;
    if (holidays == null) return const SizedBox.shrink();

    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    HolidayData? next;
    DateTime? nextDate;
    for (final h in holidays) {
      final d = DateTime.tryParse(h.date);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(midnight)) continue;
      if (nextDate == null || day.isBefore(nextDate)) {
        next = h;
        nextDate = day;
      }
    }
    if (next == null || nextDate == null) return const SizedBox.shrink();

    final days = nextDate.difference(midnight).inDays;
    // ponytail: no locale arg — app never calls initializeDateFormatting,
    // so a non-en locale here would throw at runtime
    final when = days == 0
        ? DateFormat.MMMd().format(nextDate)
        : '${DateFormat.MMMd().format(nextDate)} · ${days}d';

    return Material(
      color: AppColors.surface(context),
      borderRadius: _cardShape,
      child: InkWell(
        onTap: () => context.push(AppRoutes.adminHolidays),
        borderRadius: _cardShape,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: _cardShape,
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.holidays,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    Text(
                      next.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                when,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard({
    required String name,
    required DashboardKpiData? kpi,
    required AppLocalizations l10n,
  }) {
    final total = kpi?.totalEmployees ?? 0;
    final present = kpi?.todayAttendance ?? 0;
    final absent = (total - present).clamp(0, total);
    final ratio = total > 0 ? (present / total).clamp(0.0, 1.0) : 0.0;
    // Same deep-blue slab as the employee home hero
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, AppColors.primary, 0.65)!],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
          bottomLeft: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Off-canvas halo — depth without another asset to ship
          Positioned(
            right: -46,
            top: -56,
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: -70,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat.MMMMEEEEd().format(DateTime.now()),
                    style: const TextStyle(
                      color: Color(0xFFDBEAFE),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                // ponytail: explicit white — this card stays dark in both themes
                Text(
                  '${l10n.welcomeBack} $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),

                InkWell(
                  onTap: () => context.push(AppRoutes.adminAttendance),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                    bottomLeft: Radius.circular(6),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                        bottomLeft: Radius.circular(6),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildAttendanceRing(ratio, present, total),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.todaysAttendance,
                                style: const TextStyle(
                                  color: Color(0xFFBFDBFE),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              _buildTodayLegend(
                                const Color(0xFF34D399),
                                l10n.present,
                                present,
                              ),
                              const SizedBox(height: 6),
                              _buildTodayLegend(
                                const Color(0xFF94A3B8),
                                l10n.absent,
                                absent,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF93C5FD),
                          size: 20,
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

  /// Ring instead of a bar: it carries the ratio and the headcount in the
  /// same 78px, which is what the owner actually opens this screen for.
  Widget _buildAttendanceRing(double ratio, int present, int total) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF34D399)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$present',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/$total',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF6EE7B7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLegend(Color dot, String label, int value) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
