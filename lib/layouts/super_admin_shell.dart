import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/layouts/bottom_nav_shell.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_companies_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/shared/more_screen.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

/// Bottom navigation shell for Super Admin.
///
/// Tabs: Home | Companies | More | Profile
class SuperAdminShell extends ConsumerWidget {
  const SuperAdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return BottomNavShell(
      items: [
        NavItem(
          outlineIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: l10n.navHome,
          screen: const AdminDashboardScreen(),
        ),
        NavItem(
          outlineIcon: Icons.business_outlined,
          filledIcon: Icons.business_rounded,
          label: l10n.navCompanies,
          screen: const AdminCompaniesScreen(),
        ),
        NavItem(
          outlineIcon: Icons.apps_outlined,
          filledIcon: Icons.apps_rounded,
          label: l10n.navMore,
          screen: MoreScreen(
            title: l10n.navMore,
            showPreferences: true,
            items: [
              MoreItem(
                title: l10n.itemRolesPermissions,
                subtitle: l10n.itemRolesPermissionsSubtitle,
                icon: Icons.shield_outlined,
                color: const Color(0xFF8B5CF6),
                routePath: AppRoutes.superAdminRoles,
              ),
              MoreItem(
                title: l10n.itemSupportTickets,
                subtitle: l10n.itemSupportTicketsSubtitle,
                icon: Icons.support_agent_outlined,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminSupportTickets,
              ),
              MoreItem(
                title: l10n.itemPlatformHealth,
                subtitle: l10n.itemPlatformHealthSubtitle,
                icon: Icons.track_changes_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: l10n.announcements,
                subtitle: l10n.itemGlobalAnnouncementsSubtitle,
                icon: Icons.campaign_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminAnnouncements,
              ),
              const MoreItem(
                title: 'Login History & Security',
                subtitle: 'Track IP addresses and device authentication logs',
                icon: Icons.key_rounded,
                color: Color(0xFF0EA5E9),
                routePath: AppRoutes.adminLoginHistory,
              ),
              const MoreItem(
                title: 'System Health & Server',
                subtitle: 'Monitor Cloudways server, storage and queue jobs',
                icon: Icons.health_and_safety_outlined,
                color: Color(0xFF10B981),
                routePath: AppRoutes.adminSystemHealth,
              ),
              MoreItem(
                title: l10n.itemAuditLogs,
                subtitle: l10n.itemAuditLogsSubtitle,
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.adminAuditLogs,
              ),
              MoreItem(
                title: l10n.itemPlatformSettings,
                subtitle: l10n.itemPlatformSettingsSubtitle,
                icon: Icons.settings_outlined,
                color: const Color(0xFF64748B),
                routePath: AppRoutes.adminSettings,
              ),
            ],
          ),
        ),
        NavItem(
          outlineIcon: Icons.person_outline,
          filledIcon: Icons.person,
          label: l10n.navProfile,
          screen: const AdminProfileScreen(showBackButton: false),
        ),
      ],
    );
  }
}
