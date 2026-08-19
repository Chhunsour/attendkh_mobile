import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/layouts/bottom_nav_shell.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/employee/dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/leave_list_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/payslip_screen.dart';
import 'package:mpg_hr_mobile_app/pages/profile/profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/shared/more_screen.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

/// Bottom navigation shell for Employees.
///
/// Tabs: Home | Leave | Pay | More | Profile
class EmployeeShell extends ConsumerWidget {
  const EmployeeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavShell(
      items: [
        NavItem(
          outlineIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: 'Home',
          screen: const DashboardScreen(),
        ),
        NavItem(
          outlineIcon: Icons.event_note_outlined,
          filledIcon: Icons.event_note,
          label: 'Leave',
          screen: const LeaveListScreen(),
        ),
        NavItem(
          outlineIcon: Icons.receipt_long_outlined,
          filledIcon: Icons.receipt_long,
          label: 'Payslip',
          screen: PayslipScreen(),
        ),
        NavItem(
          outlineIcon: Icons.apps_outlined,
          filledIcon: Icons.apps_rounded,
          label: 'More',
          screen: MoreScreen(
            title: 'More Services',
            showLogout: true,
            items: [
              MoreItem(
                title: 'Attendance',
                subtitle: 'History & clock logs',
                icon: Icons.access_time_rounded,
                color: AppColors.primary,
                routePath: AppRoutes.attendance,
              ),
              MoreItem(
                title: 'Overtime',
                subtitle: 'Request & track OT',
                icon: Icons.timer_outlined,
                color: const Color(0xFF8B5CF6),
                routePath: AppRoutes.requestOvertime,
              ),
              MoreItem(
                title: 'Expenses',
                subtitle: 'Claims & receipts',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.expense,
              ),
              MoreItem(
                title: 'Training',
                subtitle: 'Courses & skills',
                icon: Icons.school_outlined,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.training,
              ),
              MoreItem(
                title: 'My KPIs',
                subtitle: 'Performance goals',
                icon: Icons.track_changes_outlined,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.kpi,
              ),
              MoreItem(
                title: 'Holidays',
                subtitle: 'Company calendar',
                icon: Icons.celebration_outlined,
                color: const Color(0xFFEAB308),
                routePath: AppRoutes.employeeHolidays,
              ),
              MoreItem(
                title: 'Company Rules',
                subtitle: 'Regulations & guide',
                icon: Icons.gavel_outlined,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.companyRules,
              ),
              MoreItem(
                title: 'Policies',
                subtitle: 'Terms & conditions',
                icon: Icons.policy_outlined,
                color: const Color(0xFFEC4899),
                routePath: AppRoutes.companyPolicies,
              ),
              MoreItem(
                title: 'Documents',
                subtitle: 'Files & attachments',
                icon: Icons.folder_outlined,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.companyDocuments,
              ),
              MoreItem(
                title: 'Notifications',
                subtitle: 'Alerts & updates',
                icon: Icons.notifications_outlined,
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
          screen: const ProfileScreen(showBackButton: false),
        ),
      ],
    );
  }
}
