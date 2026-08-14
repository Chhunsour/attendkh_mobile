import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/layouts/bottom_nav_shell.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
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
    return BottomNavShell(
      items: [
        NavItem(
          outlineIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: 'Home',
          screen: const AdminDashboardScreen(),
        ),
        NavItem(
          outlineIcon: Icons.business_outlined,
          filledIcon: Icons.business_rounded,
          label: 'Companies',
          screen: const AdminCompaniesScreen(),
        ),
         NavItem(
          outlineIcon: Icons.person_outline,
          filledIcon: Icons.person,
          label: 'Profile',
          screen: const AdminProfileScreen(showBackButton: false),
        ),
        NavItem(
          outlineIcon: Icons.apps_outlined,
          filledIcon: Icons.apps_rounded,
          label: 'More',
          screen: MoreScreen(
            title: 'More',
            showLogout: true,
            items: [
              MoreItem(
                title: 'Roles',
                icon: Icons.shield_rounded,
                color: const Color(0xFF8B5CF6),
                routePath: AppRoutes.superAdminRoles,
              ),
              MoreItem(
                title: 'Support',
                icon: Icons.support_agent_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminSupportTickets,
              ),
              MoreItem(
                title: 'KPIs',
                icon: Icons.track_changes_outlined,
                color: AppColors.primary,
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: 'Announcements',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminAnnouncements,
              ),
              MoreItem(
                title: 'Audit Logs',
                icon: Icons.description_rounded,
                color: const Color(0xFF6B7280),
                routePath: AppRoutes.adminAuditLogs,
              ),
              MoreItem(
                title: 'Settings',
                icon: Icons.settings_rounded,
                color: const Color(0xFF0F172A),
                routePath: AppRoutes.adminSettings,
              ),
            ],
          ),
        ),
       
      ],
    );
  }
}
