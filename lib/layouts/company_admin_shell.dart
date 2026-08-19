import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return BottomNavShell(
      items: [
        NavItem(
          outlineIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: l10n.navHome,
          screen: const CompanyAdminDashboardScreen(),
        ),
        NavItem(
          outlineIcon: Icons.people_outline_rounded,
          filledIcon: Icons.people_rounded,
          label: l10n.navHR,
          screen: MoreScreen(
            title: l10n.hrOperations,
            items: [
              MoreItem(
                title: l10n.itemEmployees,
                subtitle: l10n.itemEmployeesSubtitle,
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminEmployees,
              ),
              MoreItem(
                title: l10n.itemHrStructure,
                subtitle: l10n.itemHrStructureSubtitle,
                icon: Icons.account_tree_outlined,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.hrStructure,
              ),
              MoreItem(
                title: l10n.filterAttendance,
                subtitle: l10n.itemAdminAttendanceSubtitle,
                icon: Icons.fingerprint_rounded,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminAttendance,
              ),
              MoreItem(
                title: l10n.leaveRequests,
                subtitle: l10n.itemAdminLeaveSubtitle,
                icon: Icons.event_busy_outlined,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.adminLeave,
              ),
              MoreItem(
                title: l10n.overtime,
                subtitle: l10n.itemAdminOvertimeSubtitle,
                icon: Icons.more_time_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminOvertime,
              ),
              MoreItem(
                title: l10n.workShifts,
                subtitle: l10n.itemAdminShiftsSubtitle,
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
          label: l10n.navPayroll,
          screen: MoreScreen(
            title: l10n.financeAndAssets,
            items: [
              MoreItem(
                title: l10n.payroll,
                subtitle: l10n.itemAdminPayrollSubtitle,
                icon: Icons.payments_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminPayroll,
              ),
              MoreItem(
                title: l10n.expenses,
                subtitle: l10n.itemAdminExpensesSubtitle,
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFEC4899),
                routePath: AppRoutes.adminExpenses,
              ),
              MoreItem(
                title: l10n.companyAssets,
                subtitle: l10n.manageAssignedAssets,
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
          label: l10n.navMore,
          screen: MoreScreen(
            title: l10n.companyServices,
            showPreferences: true,
            items: [
              MoreItem(
                title: l10n.recruitment,
                subtitle: l10n.recruitmentJobsDesc,
                icon: Icons.work_outline_rounded,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminRecruitment,
              ),
              MoreItem(
                title: l10n.performanceReviews,
                subtitle: l10n.performanceReviewsDesc,
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFA855F7),
                routePath: AppRoutes.adminPerformance,
              ),
              MoreItem(
                title: l10n.menuKPIs,
                subtitle: l10n.itemKpisSubtitle,
                icon: Icons.track_changes_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: l10n.summaryReports,
                subtitle: l10n.summaryReportsDesc,
                icon: Icons.pie_chart_outline_rounded,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.adminSummary,
              ),
              MoreItem(
                title: l10n.analyticsReports,
                subtitle: l10n.analyticsReportsDesc,
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.adminReports,
              ),
              MoreItem(
                title: l10n.companyDocuments,
                subtitle: l10n.viewCompanyDocuments,
                icon: Icons.folder_open_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminDocuments,
              ),
              MoreItem(
                title: l10n.announcements,
                subtitle: l10n.itemAnnouncementsSubtitle,
                icon: Icons.campaign_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminCompanyAnnouncements,
              ),
              MoreItem(
                title: l10n.companyPolicies,
                subtitle: l10n.itemCompanyPoliciesSubtitle,
                icon: Icons.book_outlined,
                color: const Color(0xFF3B82F6),
                routePath: AppRoutes.adminPolicies,
              ),
              MoreItem(
                title: l10n.holidayCalendar,
                subtitle: l10n.itemHolidayCalendarSubtitle,
                icon: Icons.celebration_outlined,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminHolidays,
              ),
              MoreItem(
                title: l10n.notifications,
                subtitle: l10n.notifications,
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
          label: l10n.navProfile,
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
