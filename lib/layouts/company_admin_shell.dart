import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/layouts/bottom_nav_shell.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/hr/company_admin_dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/company_owner_profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/profile/profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/shared/more_screen.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';

/// Bottom navigation shell for Company Admin / Branch Manager.
///
/// Tabs: Home | People | Finance | More | Profile
class CompanyAdminShell extends ConsumerWidget {
  const CompanyAdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavShell(
      items: [
        NavItem(
          outlineIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: 'Home',
          screen: const CompanyAdminDashboardScreen(),
        ),
        NavItem(
          outlineIcon: Icons.people_outline_rounded,
          filledIcon: Icons.people_rounded,
          label: 'HR',
          screen: MoreScreen(
            title: 'HR',
            items: [
              MoreItem(
                title: 'Employees',
                icon: Icons.people_rounded,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminEmployees,
              ),
              MoreItem(
                title: 'HR Structure',
                icon: Icons.corporate_fare_rounded,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.hrStructure,
              ),
              MoreItem(
                title: 'Attendance',
                icon: Icons.fingerprint_rounded,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.adminAttendance,
              ),
              MoreItem(
                title: 'Leave',
                icon: Icons.event_busy_rounded,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.adminLeave,
              ),
              MoreItem(
                title: 'Overtime',
                icon: Icons.more_time_rounded,
                color: const Color(0xFFF97316),
                routePath: AppRoutes.adminOvertime,
              ),
              MoreItem(
                title: 'Shifts',
                icon: Icons.schedule_rounded,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminShifts,
              ),
            ],
          ),
        ),
        NavItem(
          outlineIcon: Icons.account_balance_wallet_outlined,
          filledIcon: Icons.account_balance_wallet_rounded,
          label: 'Payroll',
          screen: MoreScreen(
            title: 'Payroll',
            items: [
              MoreItem(
                title: 'Payroll',
                icon: Icons.payments_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminPayroll,
              ),
              MoreItem(
                title: 'Expenses',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFEC4899),
                routePath: AppRoutes.adminExpenses,
              ),
              MoreItem(
                title: 'Assets',
                icon: Icons.devices_rounded,
                color: const Color(0xFF6B7280),
                routePath: AppRoutes.adminAssets,
              ),
            ],
          ),
        ),

        NavItem(
          outlineIcon: Icons.person_outline,
          filledIcon: Icons.person,
          label: 'Profile',
          screen: _buildProfileScreen(ref),
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
                title: 'Recruitment',
                icon: Icons.work_outline_rounded,
                color: const Color(0xFF0052FF),
                routePath: AppRoutes.adminRecruitment,
              ),
              MoreItem(
                title: 'Performance',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFA855F7),
                routePath: AppRoutes.adminPerformance,
              ),
              MoreItem(
                title: 'KPIs',
                icon: Icons.track_changes_outlined,
                color: AppColors.primary,
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: 'Summary Reports',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.adminSummary,
              ),
              MoreItem(
                title: 'Reports',
                icon: Icons.assessment_rounded,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.adminReports,
              ),
              MoreItem(
                title: 'Documents',
                icon: Icons.folder_open_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminDocuments,
              ),
              MoreItem(
                title: 'Announcements',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF8B5CF6),
                routePath: AppRoutes.adminCompanyAnnouncements,
              ),
              MoreItem(
                title: 'Policies',
                icon: Icons.book_rounded,
                color: const Color(0xFF3B82F6),
                routePath: AppRoutes.adminPolicies,
              ),
              MoreItem(
                title: 'Holidays',
                icon: Icons.celebration_rounded,
                color: const Color(0xFFEAB308),
                routePath: AppRoutes.adminHolidays,
              ),
              MoreItem(
                title: 'Notifications',
                icon: Icons.notifications_rounded,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.notifications,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreen(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.isCompanyOwner) {
      return const CompanyOwnerProfileScreen(showBackButton: false);
    }
    return const ProfileScreen(showBackButton: false);
  }
}
