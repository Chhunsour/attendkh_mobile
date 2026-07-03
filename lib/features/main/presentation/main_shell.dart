import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/attendance/presentation/attendance_screen.dart';
import 'package:mpg_hr_mobile_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/features/leave/presentation/leave_list_screen.dart';
import 'package:mpg_hr_mobile_app/features/payslip/presentation/payslip_screen.dart';
import 'package:mpg_hr_mobile_app/features/profile/presentation/profile_screen.dart';

/// Main shell with bottom navigation for company users.
///
/// Uses [IndexedStack] with local state instead of ShellRoute + context.go()
/// to avoid the Flutter semantics bug (!semantics.parentDataDirty assertion)
/// that occurs when GoRouter tears down and rebuilds widget trees during
/// ShellRoute child swaps.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  // Default to dashboard (index 0)
  static const initialIndex = 0;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = MainShell.initialIndex;

  /// The 5 bottom-navigation tabs (same order as BottomNavigationBar items)
  static const _tabScreens = <Widget>[
    DashboardScreen(),
    AttendanceScreen(),
    LeaveListScreen(),
    PayslipScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabScreens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.grey200.withAlpha(128)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined),
              activeIcon: Icon(Icons.access_time),
              label: 'Clock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Leave',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pay',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}