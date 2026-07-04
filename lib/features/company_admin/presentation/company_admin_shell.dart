import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/hr_structure_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_attendance_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_leave_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_payroll_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_assets_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_expenses_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_recruitment_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_performance_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_reports_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_roles_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_resources_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_employees_screen.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_shifts_screen.dart';

/// Shell for Company Admin navigation — drawer-based.
/// Provides access to all admin management features.
class CompanyAdminShell extends ConsumerStatefulWidget {
  const CompanyAdminShell({super.key});

  static const initialTab = 'hr_structure';
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  ConsumerState<CompanyAdminShell> createState() => _CompanyAdminShellState();
}

class _CompanyAdminShellState extends ConsumerState<CompanyAdminShell> {
  String _activeTab = CompanyAdminShell.initialTab;

  static final _tabScreens = <String, Widget>{
    'hr_structure': const HrStructureScreen(),
    'attendance': const AdminAttendanceScreen(),
    'leave': const AdminLeaveScreen(),
    'payroll': const AdminPayrollScreen(),
    'assets': const AdminAssetsScreen(),
    'expenses': const AdminExpensesScreen(),
    'recruitment': const AdminRecruitmentScreen(),
    'performance': const AdminPerformanceScreen(),
    'reports': const AdminReportsScreen(),
    'roles': const AdminRolesScreen(),
    'employees': const AdminEmployeesScreen(),
    'shifts': const AdminShiftsScreen(),
    'resources': const AdminResourcesScreen(),
  };

  void _navigateTo(String tab) {
    setState(() => _activeTab = tab);
    CompanyAdminShell.scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Admin';
    final initials = userName.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Scaffold(
      key: CompanyAdminShell.scaffoldKey,
      appBar: AppBar(
        title: Text(_getTabTitle(_activeTab)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => CompanyAdminShell.scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Dashboard',
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabScreens.keys.toList().indexOf(_activeTab),
        children: _tabScreens.entries.map((e) {
          return ExcludeSemantics(
            excluding: e.key != _activeTab,
            child: e.value,
          );
        }).toList(),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withAlpha(90), width: 1.5),
                      ),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials.isNotEmpty ? initials : 'AD',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(userName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondary.withAlpha(90)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 12, color: AppColors.secondary),
                          const SizedBox(width: 5),
                          Text('Company Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(230))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Menu Items ──────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                  children: [
                    _sectionLabel('HR MANAGEMENT'),
                    _DrawerItem(icon: Icons.business_outlined, label: 'HR Structure', tab: 'hr_structure', isActive: _activeTab == 'hr_structure', onTap: () => _navigateTo('hr_structure')),
                    _DrawerItem(icon: Icons.people_alt_outlined, label: 'Employees', tab: 'employees', isActive: _activeTab == 'employees', onTap: () => _navigateTo('employees')),
                    _DrawerItem(icon: Icons.shield_outlined, label: 'Roles & Permissions', tab: 'roles', isActive: _activeTab == 'roles', onTap: () => _navigateTo('roles')),
                    const SizedBox(height: 10),
                    _sectionLabel('OPERATIONS'),
                    _DrawerItem(icon: Icons.access_time_outlined, label: 'Attendance', tab: 'attendance', isActive: _activeTab == 'attendance', onTap: () => _navigateTo('attendance')),
                    _DrawerItem(icon: Icons.schedule_outlined, label: 'Shifts', tab: 'shifts', isActive: _activeTab == 'shifts', onTap: () => _navigateTo('shifts')),
                    _DrawerItem(icon: Icons.event_note_outlined, label: 'Leave', tab: 'leave', isActive: _activeTab == 'leave', onTap: () => _navigateTo('leave')),
                    _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Payroll', tab: 'payroll', isActive: _activeTab == 'payroll', onTap: () => _navigateTo('payroll')),
                    _DrawerItem(icon: Icons.receipt_outlined, label: 'Expenses', tab: 'expenses', isActive: _activeTab == 'expenses', onTap: () => _navigateTo('expenses')),
                    const SizedBox(height: 10),
                    _sectionLabel('RESOURCES'),
                    _DrawerItem(icon: Icons.inventory_2_outlined, label: 'Assets', tab: 'assets', isActive: _activeTab == 'assets', onTap: () => _navigateTo('assets')),
                    _DrawerItem(icon: Icons.work_outline, label: 'Recruitment', tab: 'recruitment', isActive: _activeTab == 'recruitment', onTap: () => _navigateTo('recruitment')),
                    _DrawerItem(icon: Icons.assessment_outlined, label: 'Performance', tab: 'performance', isActive: _activeTab == 'performance', onTap: () => _navigateTo('performance')),
                    _DrawerItem(icon: Icons.bar_chart_outlined, label: 'Reports', tab: 'reports', isActive: _activeTab == 'reports', onTap: () => _navigateTo('reports')),
                    _DrawerItem(icon: Icons.more_horiz_outlined, label: 'Resources', tab: 'resources', isActive: _activeTab == 'resources', onTap: () => _navigateTo('resources')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, thickness: 1, color: AppColors.grey400.withAlpha(60)),
                    ),
                    _DrawerItem(
                      icon: Icons.send,
                      label: 'Send Notification',
                      tab: 'notification',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/company-admin/send-notification');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back to Dashboard',
                      tab: 'back',
                      isActive: false,
                      isSecondary: true,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.dashboard);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTabTitle(String tab) {
    switch (tab) {
      case 'hr_structure': return 'HR Structure';
      case 'attendance': return 'Attendance';
      case 'leave': return 'Leave Management';
      case 'payroll': return 'Payroll';
      case 'assets': return 'Assets';
      case 'expenses': return 'Expenses';
      case 'recruitment': return 'Recruitment';
      case 'performance': return 'Performance';
      case 'reports': return 'Reports';
      case 'roles': return 'Roles & Permissions';
      case 'resources': return 'Resources';
      default: return 'Admin';
    }
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.grey400, letterSpacing: 1.4)),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tab;
  final bool isActive;
  final bool isSecondary;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.tab, required this.isActive, required this.onTap, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withAlpha(16) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isActive ? Border.all(color: AppColors.primary.withAlpha(50)) : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withAlpha(28) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: isActive ? AppColors.primary : isSecondary ? AppColors.grey500 : AppColors.grey600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? AppColors.primary : isSecondary ? AppColors.grey500 : AppColors.grey700)),
                ),
                if (isActive) Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}