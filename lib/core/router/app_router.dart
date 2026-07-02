import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/features/splash/presentation/splash_screen.dart';
import 'package:mpg_hr_mobile_app/features/auth/presentation/login_screen.dart';
import 'package:mpg_hr_mobile_app/features/auth/presentation/company_select_screen.dart';
import 'package:mpg_hr_mobile_app/features/main/presentation/main_shell.dart';
import 'package:mpg_hr_mobile_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/features/attendance/presentation/attendance_screen.dart';
import 'package:mpg_hr_mobile_app/features/leave/presentation/leave_list_screen.dart';
import 'package:mpg_hr_mobile_app/features/leave/presentation/leave_request_screen.dart';
import 'package:mpg_hr_mobile_app/features/payslip/presentation/payslip_screen.dart';
import 'package:mpg_hr_mobile_app/features/expense/presentation/expense_screen.dart';
import 'package:mpg_hr_mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:mpg_hr_mobile_app/features/directory/presentation/directory_screen.dart';
import 'package:mpg_hr_mobile_app/features/documents/presentation/documents_screen.dart';
import 'package:mpg_hr_mobile_app/features/announcements/presentation/announcements_screen.dart';
import 'package:mpg_hr_mobile_app/features/chat/presentation/chat_screen.dart';

// Admin imports
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_shell.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_companies_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_announcements_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_audit_logs_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_support_tickets_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_settings_screen.dart';

/// Route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
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

  // Super Admin
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminCompanies = '/admin/companies';
  static const adminAnnouncements = '/admin/announcements';
  static const adminAuditLogs = '/admin/audit-logs';
  static const adminSupportTickets = '/admin/support-tickets';
  static const adminSettings = '/admin/settings';
}

/// Go Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthPage = state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.companySelect;

      // Show splash first, always
      if (state.matchedLocation == AppRoutes.splash) {
        return null;
      }

      // Not logged in -> redirect to login
      if (!isLoggedIn && !isAuthPage) {
        return AppRoutes.login;
      }

      // Logged in but on auth page -> go to main
      if (isLoggedIn && isAuthPage) {
        return AppRoutes.dashboard;
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
        path: AppRoutes.companySelect,
        builder: (context, state) => const CompanySelectScreen(),
      ),

      // ---- Company-side (5-tab bottom nav) ----
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
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
            path: AppRoutes.payslip,
            builder: (context, state) => const PayslipScreen(),
          ),
          GoRoute(
            path: AppRoutes.expense,
            builder: (context, state) => const ExpenseScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
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
        ],
      ),

      // ---- Super Admin (drawer navigation) ----
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCompanies,
            builder: (context, state) => const AdminCompaniesScreen(),
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
            path: AppRoutes.adminSupportTickets,
            builder: (context, state) => const AdminSupportTicketsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminSettings,
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});