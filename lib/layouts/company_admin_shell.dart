import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/layouts/bottom_nav_shell.dart';
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
            title: 'HR Operations',
            items: [
              MoreItem(
                title: 'Employees',
                subtitle: 'Directory & staff profiles',
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminEmployees,
              ),
              MoreItem(
                title: 'HR Structure',
                subtitle: 'Departments & designations',
                icon: Icons.account_tree_outlined,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.hrStructure,
              ),
              MoreItem(
                title: 'Attendance',
                subtitle: 'Daily check-in logs & scans',
                icon: Icons.fingerprint_rounded,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminAttendance,
              ),
              MoreItem(
                title: 'Leave Requests',
                subtitle: 'Time-off approvals & balance',
                icon: Icons.event_busy_outlined,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.adminLeave,
              ),
              MoreItem(
                title: 'Overtime',
                subtitle: 'Extra hours review & claims',
                icon: Icons.more_time_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminOvertime,
              ),
              MoreItem(
                title: 'Work Shifts',
                subtitle: 'Rosters & timing schedules',
                icon: Icons.schedule_outlined,
                color: const Color(0xFF8B5CF6),
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
            title: 'Finance & Assets',
            items: [
              MoreItem(
                title: 'Payroll Management',
                subtitle: 'Salaries & payslip generation',
                icon: Icons.payments_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminPayroll,
              ),
              MoreItem(
                title: 'Expense Claims',
                subtitle: 'Receipt review & payouts',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFEC4899),
                routePath: AppRoutes.adminExpenses,
              ),
              MoreItem(
                title: 'Company Assets',
                subtitle: 'Equipment & device tracking',
                icon: Icons.devices_outlined,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.adminAssets,
              ),
            ],
          ),
        ),

        NavItem(
          outlineIcon: Icons.apps_outlined,
          filledIcon: Icons.apps_rounded,
          label: 'More',
          screen: MoreScreen(
            title: 'Company Services',
            showLogout: true,
            items: [
              MoreItem(
                title: 'Recruitment & Jobs',
                subtitle: 'Job postings & applicants',
                icon: Icons.work_outline_rounded,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminRecruitment,
              ),
              MoreItem(
                title: 'Performance Reviews',
                subtitle: 'Appraisals & evaluations',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFA855F7),
                routePath: AppRoutes.adminPerformance,
              ),
              MoreItem(
                title: 'Company KPIs',
                subtitle: 'Strategic objectives & score',
                icon: Icons.track_changes_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: 'Summary Reports',
                subtitle: 'Executive monthly overview',
                icon: Icons.pie_chart_outline_rounded,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.adminSummary,
              ),
              MoreItem(
                title: 'Analytics Reports',
                subtitle: 'Exportable data spreadsheets',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.adminReports,
              ),
              MoreItem(
                title: 'Company Documents',
                subtitle: 'Files, contracts & handbook',
                icon: Icons.folder_open_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminDocuments,
              ),
              MoreItem(
                title: 'Announcements',
                subtitle: 'Company-wide notices',
                icon: Icons.campaign_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminCompanyAnnouncements,
              ),
              MoreItem(
                title: 'Company Policies',
                subtitle: 'Compliance & signatures',
                icon: Icons.book_outlined,
                color: const Color(0xFF3B82F6),
                routePath: AppRoutes.adminPolicies,
              ),
              MoreItem(
                title: 'Holiday Calendar',
                subtitle: 'Public & corporate holidays',
                icon: Icons.celebration_outlined,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminHolidays,
              ),
              MoreItem(
                title: 'Notifications',
                subtitle: 'Alerts & pending requests',
                icon: Icons.notifications_none_rounded,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.notifications,
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
