import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_attendance_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employees_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_leave_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_more_screen.dart';
import 'package:mpg_hr_mobile_app/pages/hr/company_admin_dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

/// Unread notification count provider — polled every 60 seconds.
final _unreadCountProvider = StateProvider<int>((ref) => 0);

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedIndex = 0;
  Timer? _pollTimer;

  List<String> _getTitles(AppLocalizations l10n) {
    return [
      l10n.hrDashboard,
      l10n.employees,
      l10n.attendanceMenu,
      l10n.leaveRequests,
      l10n.more,
    ];
  }

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    // Poll every 60 seconds for new notifications
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetchUnreadCount());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final api = ApiRepository();
      final response = await api.get('/company/notifications/latest');
      final data = response.data;
      if (data is Map && data['unread_count'] != null) {
        ref.read(_unreadCountProvider.notifier).state = data['unread_count'] as int;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(_unreadCountProvider);
    final branchSwitchState = ref.watch(branchSwitchProvider);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: _buildAppBar(context, unreadCount, l10n),
          body: IndexedStack(
            index: _selectedIndex,
            children: const [
              CompanyAdminDashboardScreen(),
              AdminEmployeesScreen(),
              _AttendanceShell(),
              AdminLeaveScreen(),
              AdminMoreScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(l10n),
        ),
        // Branch-switching blur overlay
        if (branchSwitchState.isSwitching) _buildBlurOverlay(l10n),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int unreadCount, AppLocalizations l10n) {
    final titles = _getTitles(l10n);
    return AppBar(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(20),
            ),
            child: const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            titles[_selectedIndex],
            style: const TextStyle(
              color: AppColors.grey800,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              
            ),
          ),
        ],
      ),
      actions: [
        // ── Notification Bell with Badge ──
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.grey800, size: 26),
                onPressed: () async {
                  context.push(AppRoutes.notifications);
                  // Reset count after viewing
                  await Future.delayed(const Duration(milliseconds: 300));
                  _fetchUnreadCount();
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    const activeColor = Color(0xFFF97316);
    const inactiveColor = Color(0xFF9CA3AF);
    const bgColor = Color(0xFF1A1A1A);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(index: 0, selectedIndex: _selectedIndex, icon: Icons.home_rounded, label: l10n.home, activeColor: activeColor, inactiveColor: inactiveColor, onTap: _onTabTapped),
              _NavItem(index: 1, selectedIndex: _selectedIndex, icon: Icons.people_rounded, label: l10n.employees, activeColor: activeColor, inactiveColor: inactiveColor, onTap: _onTabTapped),
              _NavItem(index: 2, selectedIndex: _selectedIndex, icon: Icons.fingerprint_rounded, label: l10n.attendanceMenu, activeColor: activeColor, inactiveColor: inactiveColor, onTap: _onTabTapped),
              _NavItem(index: 3, selectedIndex: _selectedIndex, icon: Icons.event_busy_rounded, label: l10n.leave, activeColor: activeColor, inactiveColor: inactiveColor, onTap: _onTabTapped),
              _NavItem(index: 4, selectedIndex: _selectedIndex, icon: Icons.apps_rounded, label: l10n.more, activeColor: activeColor, inactiveColor: inactiveColor, onTap: _onTabTapped),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBlurOverlay(AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(100),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.grey900.withAlpha(30), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
                ),
                const SizedBox(height: 16),
                Text(l10n.switchingBranchView, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom bottom nav item with active indicator dot above icon
class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin wrapper that gives AdminAttendanceScreen its own Scaffold context
/// needed for TabController inside an IndexedStack.
class _AttendanceShell extends StatelessWidget {
  const _AttendanceShell();

  @override
  Widget build(BuildContext context) {
    return const AdminAttendanceScreen();
  }
}
