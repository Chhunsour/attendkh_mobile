import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/employee/attendance_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/leave_list_screen.dart';
import 'package:mpg_hr_mobile_app/pages/employee/payslip_screen.dart';
import 'package:mpg_hr_mobile_app/pages/profile/profile_screen.dart';

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
      extendBody: true, // Allows body to extend behind the floating nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _tabScreens.asMap().entries.map((e) {
          return ExcludeSemantics(
            excluding: e.key != _currentIndex,
            child: e.value,
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
              _buildNavItem(1, Icons.access_time_outlined, Icons.access_time, 'Clock'),
              _buildNavItem(2, Icons.event_note_outlined, Icons.event_note, 'Leave'),
              _buildNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long, 'Pay'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = AppColors.grey400;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}