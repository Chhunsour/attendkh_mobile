import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_dashboard_repository.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

// ── Riverpod provider ──────────────────────────────────────────────────────
final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((ref) {
  return AdminDashboardRepository().getDashboard();
});

// ══════════════════════════════════════════════════════════════════════════════
//  Admin Dashboard Screen
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
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
    final dashAsync = ref.watch(adminDashboardProvider);
    final profileAsync = ref.watch(profileProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final l10n = AppLocalizations.of(context)!;
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
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.platformAdminTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Super Admin Platform Control',
                  style: TextStyle(
                    color: AppColors.grey500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: isDark ? AppColors.grey300 : AppColors.grey700,
                ),
                if (unreadCountAsync.valueOrNull != null && unreadCountAsync.valueOrNull! > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${unreadCountAsync.valueOrNull}',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              context.push(AppRoutes.notifications).then((_) {
                ref.invalidate(unreadCountProvider);
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.adminProfile),
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
          ref.invalidate(adminDashboardProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: dashAsync.when(
          loading: () => _buildLoading(context),
          error: (err, _) => _buildError(err, ref, l10n),
          data: (data) => _buildContent(context, data, authState, l10n),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _shimmerBox(context, height: 120, radius: 22),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _shimmerBox(context, height: 110, radius: 18)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox(context, height: 110, radius: 18)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _shimmerBox(context, height: 110, radius: 18)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox(context, height: 110, radius: 18)),
          ],
        ),
        const SizedBox(height: 20),
        _shimmerBox(context, height: 180, radius: 18),
      ],
    );
  }

  Widget _shimmerBox(
    BuildContext context, {
    required double height,
    double radius = 12,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const _ShimmerEffect(),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(Object err, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 32),
            ),
            SizedBox(height: 16),
            Text(
              l10n.failedToLoadDashboard,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminDashboardProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    AdminDashboardData data,
    AuthState auth,
    AppLocalizations l10n,
  ) {
    final stats = data.stats;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Executive Dark Hero Welcome Banner ──
        _buildWelcomeBanner(auth.userName ?? 'Super Admin', l10n),

        const SizedBox(height: 18),

        // ── Quick Platform Shortcuts ──
        _buildQuickActionsBar(context),

        SizedBox(height: 20),

        // ── Statistics Section Header ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.platformStatistics,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                    SizedBox(width: 5),
                    Text(
                      'Live Metrics',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── KPI row 1 ──
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n.statCompanies,
                value: stats.totalCompanies.toString(),
                sub: l10n.statCompaniesActive(stats.activeCompanies.toString()),
                icon: Icons.business_rounded,
                color: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: l10n.statTotalUsers,
                value: _formatNumber(stats.totalUsers),
                sub: l10n.statUsersDesc,
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── KPI row 2 ──
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n.statOpenTickets,
                value: stats.openTickets.toString(),
                sub: l10n.statTicketsDesc,
                icon: Icons.support_agent_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: l10n.statAnnouncements,
                value: stats.publishedAnnouncements.toString(),
                sub: l10n.statAnnouncementsDesc,
                icon: Icons.campaign_rounded,
                color: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFFF0F9FF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Recent Company Signups ──
        if (data.recentSignups.isNotEmpty) ...[
          _buildSectionHeader(l10n.recentCompanySignups, Icons.business_center_rounded, const Color(0xFF6366F1)),
          const SizedBox(height: 10),
          ...data.recentSignups.map(
            (item) => _ActivityTile(
              item: item,
              icon: Icons.business_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Recent Support Tickets ──
        if (data.recentTickets.isNotEmpty) ...[
          _buildSectionHeader(l10n.recentSupportTickets, Icons.support_agent_rounded, const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          ...data.recentTickets.map(
            (item) => _ActivityTile(
              item: item,
              icon: Icons.confirmation_number_rounded,
              iconBg: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWelcomeBanner(String name, AppLocalizations l10n) {
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
                        l10n.platformAdministratorBadge.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-Company HR Tenant & Global System Administration',
                  style: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFFA5B4FC),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            title: 'Companies',
            icon: Icons.business_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => context.push(AppRoutes.adminCompanies),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            title: 'Health KPIs',
            icon: Icons.track_changes_rounded,
            color: const Color(0xFF10B981),
            onTap: () => context.push(AppRoutes.kpi),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            title: 'Announce',
            icon: Icons.campaign_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: () => context.push(AppRoutes.adminCompanyAnnouncements),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            title: 'Support',
            icon: Icons.support_agent_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => context.push(AppRoutes.adminSupportTickets),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  KPI Card
// ══════════════════════════════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Activity Tile
// ══════════════════════════════════════════════════════════════════════════════
class _ActivityTile extends StatelessWidget {
  final AdminActivityItem item;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _ActivityTile({
    required this.item,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.action,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.date,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey600),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Shimmer Effect
// ══════════════════════════════════════════════════════════════════════════════
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFFF8FAFC),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
