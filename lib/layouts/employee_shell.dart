import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/layouts/bottom_nav_shell.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/employee/dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/leave_list_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/payslip_screen.dart';
import 'package:mpg_hr_mobile_app/pages/shared/more_screen.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

/// Bottom navigation shell for Employees.
///
/// Tabs: Home | Leave | Payslip | More
class EmployeeShell extends ConsumerWidget {
  const EmployeeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return BottomNavShell(
      items: [
        NavItem(
          outlineIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: l10n.navHome,
          screen: const DashboardScreen(),
        ),
        NavItem(
          outlineIcon: Icons.event_note_outlined,
          filledIcon: Icons.event_note,
          label: l10n.navLeave,
          screen: const LeaveListScreen(),
        ),
        NavItem(
          outlineIcon: Icons.receipt_long_outlined,
          filledIcon: Icons.receipt_long,
          label: l10n.navPayslip,
          screen: const PayslipScreen(),
        ),
        NavItem(
          outlineIcon: Icons.apps_outlined,
          filledIcon: Icons.apps_rounded,
          label: l10n.navMore,
          screen: MoreScreen(
            title: l10n.moreServices,
            showPreferences: true,
            items: [
              MoreItem(
                title: l10n.filterAttendance,
                subtitle: l10n.itemAttendanceSubtitle,
                icon: Icons.access_time_rounded,
                color: AppColors.primary,
                routePath: AppRoutes.attendance,
              ),
              MoreItem(
                title: l10n.overtime,
                subtitle: l10n.itemOvertimeSubtitle,
                icon: Icons.timer_outlined,
                color: const Color(0xFF8B5CF6),
                routePath: AppRoutes.requestOvertime,
              ),
              MoreItem(
                title: l10n.expenses,
                subtitle: l10n.itemExpensesSubtitle,
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.expense,
              ),
              MoreItem(
                title: l10n.training,
                subtitle: l10n.itemTrainingSubtitle,
                icon: Icons.school_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.training,
              ),
              MoreItem(
                title: l10n.menuKPIs,
                subtitle: l10n.itemKpisSubtitle,
                icon: Icons.track_changes_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: l10n.holidayCalendar,
                subtitle: l10n.itemHolidaysSubtitle,
                icon: Icons.celebration_outlined,
                color: const Color(0xFFEAB308),
                routePath: AppRoutes.employeeHolidays,
              ),
              MoreItem(
                title: l10n.companyRules,
                subtitle: l10n.itemRulesSubtitle,
                icon: Icons.gavel_outlined,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.companyRules,
              ),
              MoreItem(
                title: l10n.policies,
                subtitle: l10n.itemPoliciesSubtitle,
                icon: Icons.policy_outlined,
                color: const Color(0xFFEC4899),
                routePath: AppRoutes.companyPolicies,
              ),
              MoreItem(
                title: l10n.documents,
                subtitle: l10n.companyDocuments,
                icon: Icons.folder_outlined,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.companyDocuments,
              ),
              MoreItem(
                title: l10n.notifications,
                subtitle: l10n.itemAnnouncementsSubtitle,
                icon: Icons.notifications_outlined,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.notifications,
              ),
              MoreItem(
                title: l10n.helpSupportDesk,
                subtitle: l10n.helpSupportSubtitle,
                icon: Icons.support_agent_rounded,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.userSupportTickets,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
