import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/layouts/employee_shell.dart';
import 'package:mpg_hr_mobile_app/layouts/company_admin_shell.dart';
import 'package:mpg_hr_mobile_app/layouts/super_admin_shell.dart';
import 'package:mpg_hr_mobile_app/pages/auth/splash_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/login_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/register_company_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/company_select_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/verify_email_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/attendance_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/request_overtime_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/leave_list_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/leave_request_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/payslip_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/expense_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/training_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/kpi_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/holiday_calendar_screen.dart'
    as mpg_holiday;
import 'package:mpg_hr_mobile_app/pages/employee/policies_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/company_rules_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/documents_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/clock_in_screen.dart';
import 'package:mpg_hr_mobile_app/pages/profile/profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/profile/edit_profile_screen.dart';

// Super Admin imports
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_companies_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_announcements_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_audit_logs_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_support_tickets_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_settings_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/super_admin_roles_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_login_history_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_system_health_screen.dart';

// Company Admin imports
import 'package:mpg_hr_mobile_app/pages/hr/admin_holidays_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/hr_structure_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employees_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_attendance_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_leave_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_overtime_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_payroll_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_shifts_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_assets_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_expenses_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_recruitment_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_performance_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_reports_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_summary_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_top_employees_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_roles_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_resources_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_form_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_shift_form_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_send_notification_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_payroll_detail_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_documents_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_policies_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_company_announcements_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/company_owner_profile_screen.dart';
import 'package:mpg_hr_mobile_app/pages/notifications_screen.dart';
import 'package:mpg_hr_mobile_app/pages/notification_detail_screen.dart';
import 'package:mpg_hr_mobile_app/pages/support/user_support_tickets_screen.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/pages/shared/access_restricted_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/branch_manager_view_screen.dart';

/// Route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const String requestLeave = '/main/leave/request';
  static const String requestOvertime = '/request-overtime';
  static const String requestsManager = '/requests-manager';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const companySelect = '/company-select';
  static const accessRestricted = '/access-restricted';

  // Company-side
  static const main = '/main';
  static const clockIn = '/main/clock-in';
  static const attendance = '/main/attendance';
  static const leaveList = '/main/leave';
  static const leaveRequest = '/main/leave/request';
  static const payslip = '/main/payslip';
  static const expense = '/main/expense';
  static const training = '/main/training';
  static const kpi = '/main/kpi';
  static const profile = '/main/profile';
  static const editProfile = '/main/profile/edit';
  static const employeeHolidays = '/main/holidays';
  static const companyRules = '/main/company-rules';
  static const companyPolicies = '/main/policies';
  static const companyDocuments = '/main/documents';
  static const userSupportTickets = '/main/support-tickets';

  // Super Admin
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminProfile = '/admin/profile';
  static const superAdminRoles = '/admin/roles';

  // Company Admin / Owner
  static const companyAdmin = '/company-admin';
  static const companyOwnerProfile = '/company-admin/owner-profile';
  static const hrStructure = '/company-admin/hr-structure';
  static const adminHolidays = '/company-admin/holidays';
  static const adminEmployees = '/company-admin/employees';
  static const adminAttendance = '/company-admin/attendance';
  static const adminLeave = '/company-admin/leave';
  static const adminOvertime = '/company-admin/overtime';
  static const adminPayroll = '/company-admin/payroll';
  static const adminShifts = '/company-admin/shifts';
  static const adminAssets = '/company-admin/assets';
  static const adminExpenses = '/company-admin/expenses';
  static const adminRecruitment = '/company-admin/recruitment';
  static const adminPerformance = '/company-admin/performance';
  static const adminReports = '/company-admin/reports';
  static const adminSummary = '/company-admin/summary';
  static const adminTopEmployees = '/company-admin/top-employees';
  static const adminRoles = '/company-admin/roles';
  static const adminResources = '/company-admin/resources';
  static const adminEmployeeForm = '/company-admin/employee-form';
  static const adminShiftForm = '/company-admin/shift-form';
  static const adminSendNotification = '/company-admin/send-notification';
  static const adminPayrollDetail = '/company-admin/payroll/:period';
  static const adminDocuments = '/company-admin/documents';
  static const adminPolicies = '/company-admin/policies';
  static const adminCompanyAnnouncements = '/company-admin/announcements';
  static const notifications = '/notifications';
  static const notificationDetail = '/notifications/:id';
  static const adminCompanies = '/admin/companies';
  static const adminAnnouncements = '/admin/announcements';
  static const adminAuditLogs = '/admin/audit-logs';
  static const adminLoginHistory = '/admin/login-history';
  static const adminSystemHealth = '/admin/system-health';
  static const adminSupportTickets = '/admin/support-tickets';
  static const adminSettings = '/admin/settings';
  // Branch impersonation
  static const branchManagerView = '/company-admin/branch-view';
}

/// ChangeNotifier that listens to auth state — used as GoRouter refreshListenable.
/// This keeps the GoRouter instance stable (never recreated) while still
/// triggering redirect re-evaluation when auth changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Single stable GoRouter provider — never recreated.
/// Uses refreshListenable so redirect re-runs on auth changes without
/// rebuilding the GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Read current auth state (don't watch — that would rebuild the provider)
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      final isOnSplash = location == AppRoutes.splash;
      final isOnAuthPage =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.companySelect;

      // Always stay on splash while auth check is in progress
      if (isOnSplash && authState.isLoading) return null;

      // Splash done — redirect based on auth result
      if (isOnSplash && !authState.isLoading) {
        if (authState.isAuthenticated) {
          if (authState.isSuperAdmin) return AppRoutes.adminDashboard;
          if (authState.isCompanyAdmin) return AppRoutes.companyAdmin;
          return AppRoutes.main;
        }
        return AppRoutes.login;
      }

      // Not logged in — guard protected routes
      if (!authState.isAuthenticated && !isOnAuthPage) {
        return AppRoutes.login;
      }

      if (authState.isAuthenticated) {
        final isOnVerifyPage = location == AppRoutes.verifyEmail;
        // Logged in but sitting on an auth page or verify page — push into the app
        if (isOnAuthPage || isOnVerifyPage) {
          String target;
          if (authState.isSuperAdmin) {
            target = AppRoutes.adminDashboard;
          } else if (authState.isCompanyAdmin) {
            target = AppRoutes.companyAdmin;
          } else {
            target = AppRoutes.main;
          }
          debugPrint(
            '🔀 GoRouter redirect: isSuperAdmin=${authState.isSuperAdmin}, roles=${authState.roles}, → $target',
          );
          return target;
        }

        // Role-based route protection guards
        final isVisitingAdmin = location.startsWith('/admin');
        final isVisitingCompanyAdmin = location.startsWith('/company-admin');
        final isVisitingEmployee = location.startsWith('/main');

        if (isVisitingAdmin && !authState.isSuperAdmin) {
          final target = authState.isCompanyAdmin
              ? AppRoutes.companyAdmin
              : AppRoutes.main;
          debugPrint(
            '🚫 Security Alert: unauthorized access to admin route → redirect to $target',
          );
          return target;
        }
        if (isVisitingCompanyAdmin) {
          if (!(authState.isCompanyAdmin || authState.isManager)) {
            final target = authState.isSuperAdmin
                ? AppRoutes.adminDashboard
                : AppRoutes.main;
            debugPrint(
              '🚫 Security Alert: unauthorized access to company-admin route → redirect to $target',
            );
            return target;
          }

          // Granular submodule protection within /company-admin
          final isPayrollRoute = location == AppRoutes.adminPayroll ||
              location.startsWith('/company-admin/payroll') ||
              location == AppRoutes.adminExpenses ||
              location == AppRoutes.adminAssets ||
              location == AppRoutes.adminSummary ||
              location == AppRoutes.adminReports;

          final isStructureRoute = location == AppRoutes.hrStructure;
          final isOwnerRoute = location == AppRoutes.adminRoles ||
              location == AppRoutes.adminTopEmployees ||
              location == AppRoutes.companyOwnerProfile;

          if (isPayrollRoute && !authState.isCompanyAdmin) {
            return AppRoutes.accessRestricted;
          }
          if (isStructureRoute && !(authState.isCompanyAdmin || authState.isHrManager)) {
            return AppRoutes.accessRestricted;
          }
          if (isOwnerRoute && !(authState.isCompanyOwner || authState.isSuperAdmin)) {
            return AppRoutes.accessRestricted;
          }
        }
        if (isVisitingEmployee &&
            location != AppRoutes.kpi &&
            location != AppRoutes.profile &&
            location != AppRoutes.editProfile &&
            (authState.isSuperAdmin ||
                (authState.isCompanyAdmin && !authState.isManager))) {
          final target = authState.isSuperAdmin
              ? AppRoutes.adminDashboard
              : AppRoutes.companyAdmin;
          debugPrint(
            '🚫 Security Alert: unauthorized access to employee route → redirect to $target',
          );
          return target;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.accessRestricted,
        builder: (context, state) => const AccessRestrictedScreen(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterCompanyScreen(),
      ),
      GoRoute(
        path: AppRoutes.companySelect,
        builder: (context, state) => const CompanySelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // ---- Company-side (Bottom Nav Shell) ----
      GoRoute(
        path: AppRoutes.main,
        builder: (context, state) => const EmployeeShell(),
      ),
      GoRoute(
        path: AppRoutes.clockIn,
        builder: (context, state) {
          final args = (state.extra is ClockInArgs)
              ? (state.extra as ClockInArgs)
              : ClockInArgs(
                  isClockIn: true,
                  branchName: 'Main Office',
                  latitude: 0.0,
                  longitude: 0.0,
                  distance: 0.0,
                );
          return ClockInScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaveList,
        builder: (context, state) => const LeaveListScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaveRequest,
        builder: (context, state) => const LeaveRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestOvertime,
        builder: (context, state) => const RequestOvertimeScreen(),
      ),
      GoRoute(
        path: AppRoutes.payslip,
        builder: (context, state) => const PayslipScreen(),
      ),
      GoRoute(
        path: AppRoutes.expense,
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.training,
        builder: (context, state) => const TrainingScreen(),
      ),
      GoRoute(
        path: AppRoutes.kpi,
        builder: (context, state) => const KpiScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeHolidays,
        builder: (context, state) => const mpg_holiday.HolidayCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyRules,
        builder: (context, state) => const CompanyRulesScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyPolicies,
        builder: (context, state) => const PoliciesScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyDocuments,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.userSupportTickets,
        builder: (context, state) => const UserSupportTicketsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),

      // ---- Super Admin (Bottom Nav Shell) ----
      // Uses a single GoRoute (NOT ShellRoute) to avoid the Flutter
      // semantics bug (!semantics.parentDataDirty) caused by ShellRoute's
      // child-swap tearing down and rebuilding widget trees.
      // SuperAdminShell manages tab switching internally with IndexedStack.
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const SuperAdminShell(),
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCompanies,
        builder: (context, state) => const AdminCompaniesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSupportTickets,
        builder: (context, state) => const AdminSupportTicketsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAnnouncements,
        builder: (context, state) => const AdminAnnouncementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAuditLogs,
        builder: (context, state) => const AdminAuditLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLoginHistory,
        builder: (context, state) => const AdminLoginHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSystemHealth,
        builder: (context, state) => const AdminSystemHealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminRoles,
        builder: (context, state) => const SuperAdminRolesScreen(),
      ),

      // ---- Company Admin (Bottom Nav Shell) ----
      GoRoute(
        path: AppRoutes.companyAdmin,
        builder: (context, state) => const CompanyAdminShell(),
      ),
      GoRoute(
        path: AppRoutes.companyOwnerProfile,
        builder: (context, state) => const CompanyOwnerProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHolidays,
        builder: (context, state) => const AdminHolidaysScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrStructure,
        builder: (context, state) => const HrStructureScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployees,
        builder: (context, state) => const AdminEmployeesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAttendance,
        builder: (context, state) => const AdminAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLeave,
        builder: (context, state) => const AdminLeaveScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminOvertime,
        builder: (context, state) => const AdminOvertimeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayroll,
        builder: (context, state) => const AdminPayrollScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminShifts,
        builder: (context, state) => const AdminShiftsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAssets,
        builder: (context, state) => const AdminAssetsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminExpenses,
        builder: (context, state) => const AdminExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRecruitment,
        builder: (context, state) => const AdminRecruitmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPerformance,
        builder: (context, state) => const AdminPerformanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSummary,
        builder: (context, state) => const AdminSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminTopEmployees,
        builder: (context, state) => const TopEmployeesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRoles,
        builder: (context, state) => const AdminRolesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminResources,
        builder: (context, state) => const AdminResourcesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployeeForm,
        builder: (context, state) =>
            AdminEmployeeFormScreen(employee: state.extra as dynamic),
      ),
      GoRoute(
        path: AppRoutes.adminShiftForm,
        builder: (context, state) =>
            AdminShiftFormScreen(shift: state.extra as dynamic),
      ),
      GoRoute(
        path: AppRoutes.adminSendNotification,
        builder: (context, state) => const AdminSendNotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayrollDetail,
        builder: (context, state) =>
            AdminPayrollDetailScreen(period: state.pathParameters['period']!),
      ),
      GoRoute(
        path: AppRoutes.adminDocuments,
        builder: (context, state) => const AdminDocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPolicies,
        builder: (context, state) => const AdminPoliciesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCompanyAnnouncements,
        builder: (context, state) => const AdminCompanyAnnouncementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationDetail,
        builder: (context, state) {
          final notification = state.extra is NotificationItem
              ? (state.extra as NotificationItem)
              : NotificationItem(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  type: 'general',
                  title: 'Notification Details',
                  body: '',
                  isRead: true,
                  createdAt: '',
                );
          return NotificationDetailScreen(notification: notification);
        },
      ),
      // Branch impersonation view
      GoRoute(
        path: AppRoutes.branchManagerView,
        builder: (context, state) => const BranchManagerViewScreen(),
      ),
    ],
  );
});
