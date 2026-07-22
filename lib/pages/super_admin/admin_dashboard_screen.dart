import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_dashboard_repository.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';

// ── Riverpod provider ──────────────────────────────────────────────────────
final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) {
  return AdminDashboardRepository().getDashboard();
});

// ══════════════════════════════════════════════════════════════════════════════
//  Admin Dashboard Screen
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashAsync = ref.watch(adminDashboardProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

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
                Icons.shield_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Platform Admin',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black87),
                if (unreadCountAsync.valueOrNull != null && unreadCountAsync.valueOrNull! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${unreadCountAsync.valueOrNull}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            onPressed: () => showLogoutConfirmation(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: dashAsync.when(
          loading: () => _buildLoading(),
          error: (err, _) => _buildError(err, ref),
          data: (data) => _buildContent(context, data, authState),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _shimmerBox(height: 120, radius: 20),
        const SizedBox(height: 20),
        _shimmerBox(height: 240, radius: 16),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _shimmerBox(height: 110, radius: 16)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox(height: 110, radius: 16)),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox({required double height, double radius = 12}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const _ShimmerEffect(),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: AppColors.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey500,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminDashboardProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
  ) {
    final stats = data.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // ── Welcome banner
        _buildWelcomeBanner(auth.userName ?? 'Super Admin'),
        const SizedBox(height: 24),

        // ── Quick Operations Grid Menu
        const Text(
          'Quick Operations',
          style: TextStyle(
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
            _buildGridItem(
              context,
              title: 'Companies',
              description: 'Manage registers',
              icon: Icons.business_rounded,
              color: const Color(0xFF6366F1),
              routePath: AppRoutes.adminCompanies,
            ),
            _buildGridItem(
              context,
              title: 'Roles',
              description: 'Manage access',
              icon: Icons.shield_rounded,
              color: const Color(0xFF8B5CF6),
              routePath: AppRoutes.superAdminRoles,
            ),
            _buildGridItem(
              context,
              title: 'Support Tickets',
              description: 'User queries',
              icon: Icons.support_agent_rounded,
              color: const Color(0xFFF59E0B),
              routePath: AppRoutes.adminSupportTickets,
            ),
            _buildGridItem(
              context,
              title: 'KPIs',
              description: 'Performance goals',
              icon: Icons.track_changes_outlined,
              color: AppColors.primary,
              routePath: AppRoutes.kpi,
            ),

            _buildGridItem(
              context,
              title: 'Announcements',
              description: 'Broadcast alerts',
              icon: Icons.campaign_rounded,
              color: const Color(0xFF10B981),
              routePath: AppRoutes.adminAnnouncements,
            ),
            _buildGridItem(
              context,
              title: 'Audit Logs',
              description: 'System changes',
              icon: Icons.description_rounded,
              color: const Color(0xFF6B7280),
              routePath: AppRoutes.adminAuditLogs,
            ),
            _buildGridItem(
              context,
              title: 'Settings',
              description: 'Global configs',
              icon: Icons.settings_rounded,
              color: const Color(0xFF0F172A),
              routePath: AppRoutes.adminSettings,
            ),
            _buildGridItem(
              context,
              title: 'Admin Profile',
              description: 'Security & setup',
              icon: Icons.person_rounded,
              color: const Color(0xFF0284C7),
              routePath: AppRoutes.adminProfile,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Statistics Section Header
        const Text(
          'Platform Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),

        // ── KPI row 1
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Companies',
                value: stats.totalCompanies.toString(),
                sub: '${stats.activeCompanies} active',
                icon: Icons.business_rounded,
                color: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Total Users',
                value: _formatNumber(stats.totalUsers),
                sub: 'Across all tenants',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── KPI row 2
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Open Tickets',
                value: stats.openTickets.toString(),
                sub: 'Awaiting response',
                icon: Icons.support_agent_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Announcements',
                value: stats.publishedAnnouncements.toString(),
                sub: 'Published and active',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF6B7280),
                bgColor: const Color(0xFFF3F4F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Recent Company Signups
        if (data.recentSignups.isNotEmpty) ...[
          _buildSectionHeader(
            'Recent Company Signups',
            Icons.business_center_rounded,
          ),
          const SizedBox(height: 12),
          ...data.recentSignups.map(
            (item) => _ActivityTile(
              item: item,
              icon: Icons.business_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Recent Support Tickets
        if (data.recentTickets.isNotEmpty) ...[
          _buildSectionHeader(
            'Recent Support Tickets',
            Icons.support_agent_rounded,
          ),
          const SizedBox(height: 12),
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

  Widget _buildGridItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String routePath,
  }) {
    return InkWell(
      onTap: () => context.push(routePath),
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

  Widget _buildWelcomeBanner(String name) {
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
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
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
                  child: const Text(
                    '🛡️  Platform Administrator',
                    style: TextStyle(
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
              Icons.shield_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
            fontFamily: 'Inter',
          ),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey400,
              fontFamily: 'Inter',
            ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.action,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            item.date,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey400,
              fontFamily: 'Inter',
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

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
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
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
