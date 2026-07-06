import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/pages/auth/splash_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/login_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/register_company_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/company_select_screen.dart';
import 'package:mpg_hr_mobile_app/pages/auth/verify_email_screen.dart';
import 'package:mpg_hr_mobile_app/layouts/main_shell.dart';
import 'package:mpg_hr_mobile_app/pages/employee/leave_request_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/expense_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/directory_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/documents_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/announcements_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/chat_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/notifications_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/policies_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/holidays_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/shifts_screen.dart';

// Super Admin imports
import 'package:mpg_hr_mobile_app/layouts/admin_shell.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_profile_screen.dart';

// Company Admin imports
import 'package:mpg_hr_mobile_app/layouts/company_admin_shell.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_form_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_shift_form_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_send_notification_screen.dart';

/// Route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const companySelect = '/company-select';

  // Company-side
  static const main = '/main';
  static const dashboard = '/main/dashboard';
  static const attendance = '/main/attendance';
  static const leaveList = '/main/leave';
  static const leaveRequest = '/main/leave/request';
  static const payslip = '/main/payslip';
  static const expense = '/main/expense';
  static const profile = '/main/profile';
  static const directory = '/main/directory';
  static const documents = '/main/documents';
  static const announcements = '/main/announcements';
  static const chat = '/main/chat';
  static const notifications = '/main/notifications';
  static const policies = '/main/policies';
  static const holidays = '/main/holidays';
  static const shifts = '/main/shifts';

  // Super Admin
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminProfile = '/admin/profile';

  // Company Admin
  static const companyAdmin = '/company-admin';
  static const adminEmployeeForm = '/company-admin/employee-form';
  static const adminShiftForm = '/company-admin/shift-form';
  static const adminSendNotification = '/company-admin/send-notification';
  static const adminCompanies = '/admin/companies';
  static const adminAnnouncements = '/admin/announcements';
  static const adminAuditLogs = '/admin/audit-logs';
  static const adminSupportTickets = '/admin/support-tickets';
  static const adminSettings = '/admin/settings';
}

/// ChangeNotifier that listens to auth state — used as GoRouter refreshListenable.
/// This keeps the GoRouter instance stable (never recreated) while still
/// triggering redirect re-evaluation when auth changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

/// Single stable GoRouter provider — never recreated.
/// Uses refreshListenable so redirect re-runs on auth changes without
/// rebuilding the GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Read current auth state (don't watch — that would rebuild the provider)
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      final isOnSplash = location == AppRoutes.splash;
      final isOnAuthPage = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.companySelect;

      // Always stay on splash while auth check is in progress
      if (isOnSplash && authState.isLoading) return null;

      // Splash done — redirect based on auth result
      if (isOnSplash && !authState.isLoading) {
        if (authState.isAuthenticated) {
          return authState.isSuperAdmin
              ? AppRoutes.adminDashboard
              : AppRoutes.dashboard;
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
          final target = authState.isSuperAdmin
              ? AppRoutes.adminDashboard
              : AppRoutes.dashboard;
          debugPrint('🔀 GoRouter redirect: isSuperAdmin=${authState.isSuperAdmin}, roles=${authState.roles}, → $target');
          return target;
        }
      }

      return null;
    },
    routes: [
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

      // ---- Company-side (5-tab bottom nav) ----
      // Uses a single GoRoute (NOT ShellRoute) to avoid the Flutter
      // semantics bug (!semantics.parentDataDirty) caused by ShellRoute's
      // child-swap tearing down and rebuilding widget trees.
      // MainShell manages tab switching internally with IndexedStack.
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const MainShell(),
      ),
      // Sub-screens navigable from within tabs (push/pop on top of MainShell)
      GoRoute(
        path: AppRoutes.leaveRequest,
        builder: (context, state) => const LeaveRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.expense,
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.directory,
        builder: (context, state) => const DirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.policies,
        builder: (context, state) => const PoliciesScreen(),
      ),
      GoRoute(
        path: AppRoutes.holidays,
        builder: (context, state) => const HolidaysScreen(),
      ),
      GoRoute(
        path: AppRoutes.shifts,
        builder: (context, state) => const ShiftsScreen(),
      ),

      // ---- Super Admin (drawer navigation) ----
      // Uses a single GoRoute (NOT ShellRoute) to avoid the Flutter
      // semantics bug (!semantics.parentDataDirty) caused by ShellRoute's
      // child-swap tearing down and rebuilding widget trees.
      // AdminShell manages tab switching internally with IndexedStack.
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),

      // ---- Company Admin (drawer navigation for HR management) ----
      GoRoute(
        path: AppRoutes.companyAdmin,
        builder: (context, state) => const CompanyAdminShell(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployeeForm,
        builder: (context, state) => AdminEmployeeFormScreen(
          employee: state.extra as dynamic,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminShiftForm,
        builder: (context, state) => AdminShiftFormScreen(
          shift: state.extra as dynamic,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminSendNotification,
        builder: (context, state) => const AdminSendNotificationScreen(),
      ),
    ],
  );
});