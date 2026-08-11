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
final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) {
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
                Icons.shield_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.platformAdminTitle,
                style: const TextStyle(
                  color: AppColors.grey800,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  
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
                const Icon(Icons.notifications_outlined, color: AppColors.grey800),
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
                          color: AppColors.surfaceLight,
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
                      ? CachedNetworkImageProvider(
                          profileAsync.value!.photoUrl!,
                          maxWidth: 120,
                          maxHeight: 120,
                        )
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
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: dashAsync.when(
          loading: () => _buildLoading(),
          error: (err, _) => _buildError(err, ref, l10n),
          data: (data) => _buildContent(context, data, authState, l10n),
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
        color: AppColors.surfaceLight,
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.failedToLoadDashboard,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
                
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey500,
                
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminDashboardProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
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
    AppLocalizations l10n,
  ) {
    final stats = data.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // ── Welcome banner
        _buildWelcomeBanner(auth.userName ?? 'Super Admin', l10n),
        const SizedBox(height: 24),

        // ── Quick Operations Grid Menu
        Text(
          l10n.quickOperations,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
            
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
              title: l10n.menuCompanies,
              description: l10n.menuCompaniesDesc,
              icon: Icons.business_rounded,
              color: const Color(0xFF6366F1),
              routePath: AppRoutes.adminCompanies,
            ),
            _buildGridItem(
              context,
              title: l10n.menuRoles,
              description: l10n.menuRolesDesc,
              icon: Icons.shield_rounded,
              color: const Color(0xFF8B5CF6),
              routePath: AppRoutes.superAdminRoles,
            ),
            _buildGridItem(
              context,
              title: l10n.menuSupportTickets,
              description: l10n.menuSupportTicketsDesc,
              icon: Icons.support_agent_rounded,
              color: const Color(0xFFF59E0B),
              routePath: AppRoutes.adminSupportTickets,
            ),
            _buildGridItem(
              context,
              title: l10n.menuKPIs,
              description: l10n.menuKPIsDesc,
              icon: Icons.track_changes_outlined,
              color: AppColors.primary,
              routePath: AppRoutes.kpi,
            ),

            _buildGridItem(
              context,
              title: l10n.menuAnnouncements,
              description: l10n.menuAnnouncementsDesc,
              icon: Icons.campaign_rounded,
              color: const Color(0xFF10B981),
              routePath: AppRoutes.adminAnnouncements,
            ),
            _buildGridItem(
              context,
              title: l10n.menuAuditLogs,
              description: l10n.menuAuditLogsDesc,
              icon: Icons.description_rounded,
              color: const Color(0xFF6B7280),
              routePath: AppRoutes.adminAuditLogs,
            ),
            _buildGridItem(
              context,
              title: l10n.menuSettings,
              description: l10n.menuSettingsDesc,
              icon: Icons.settings_rounded,
              color: const Color(0xFF0F172A),
              routePath: AppRoutes.adminSettings,
            ),
            _buildGridItem(
              context,
              title: l10n.menuAdminProfile,
              description: l10n.menuAdminProfileDesc,
              icon: Icons.person_rounded,
              color: const Color(0xFF0284C7),
              routePath: AppRoutes.profile,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Statistics Section Header
        Text(
          l10n.platformStatistics,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
            
          ),
        ),
        const SizedBox(height: 12),

        // ── KPI row 1
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

        // ── KPI row 2
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
            l10n.recentCompanySignups,
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
            l10n.recentSupportTickets,
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
          color: AppColors.surfaceLight,
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
                    
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey500,
                    
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String name, AppLocalizations l10n) {
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
                  l10n.welcomeBack,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                    
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.surfaceLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    
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
                  child: Text(
                    l10n.platformAdministratorBadge,
                    style: const TextStyle(
                      color: AppColors.surfaceLight,
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
              Icons.shield_rounded,
              color: AppColors.surfaceLight,
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
        color: AppColors.surfaceLight,
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
              
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
              
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey400,
              
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
        color: AppColors.surfaceLight,
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
                    
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.action,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    
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
