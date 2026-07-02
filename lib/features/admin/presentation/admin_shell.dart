import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

/// Shell for Super Admin navigation — drawer-based
class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Super Admin';
    // initials: take up to first 2 words' first letters
    final initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      body: child,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials.isNotEmpty ? initials : 'SA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Name
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withAlpha(100)),
                      ),
                      child: Text(
                        'Platform Administrator',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(220),
                          fontFamily: 'Inter',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Menu Items ──────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  children: [
                    _sectionLabel('PLATFORM'),
                    _AdminDrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      route: AppRoutes.adminDashboard,
                    ),
                    _AdminDrawerItem(
                      icon: Icons.business_rounded,
                      label: 'Companies',
                      route: AppRoutes.adminCompanies,
                    ),
                    _AdminDrawerItem(
                      icon: Icons.campaign_rounded,
                      label: 'Announcements',
                      route: AppRoutes.adminAnnouncements,
                    ),
                    const SizedBox(height: 8),
                    _sectionLabel('MONITORING'),
                    _AdminDrawerItem(
                      icon: Icons.history_rounded,
                      label: 'Audit Logs',
                      route: AppRoutes.adminAuditLogs,
                    ),
                    _AdminDrawerItem(
                      icon: Icons.support_agent_rounded,
                      label: 'Support Tickets',
                      route: AppRoutes.adminSupportTickets,
                    ),
                    const SizedBox(height: 8),
                    _sectionLabel('CONFIGURATION'),
                    _AdminDrawerItem(
                      icon: Icons.tune_rounded,
                      label: 'Platform Settings',
                      route: AppRoutes.adminSettings,
                    ),
                    const Divider(height: 28, thickness: 0.5),
                    _AdminDrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Switch to Company',
                      route: AppRoutes.dashboard,
                      isSecondary: true,
                    ),
                  ],
                ),
              ),

              // ── Logout ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      Navigator.pop(context); // close drawer first
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
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

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.grey400,
          letterSpacing: 1.2,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSecondary;

  const _AdminDrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isActive = currentRoute == route ||
        (route != AppRoutes.adminDashboard && currentRoute.startsWith(route));

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.go(route);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withAlpha(18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AppColors.primary
                      : isSecondary
                          ? AppColors.grey500
                          : AppColors.grey600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : isSecondary
                              ? AppColors.grey500
                              : AppColors.grey700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}