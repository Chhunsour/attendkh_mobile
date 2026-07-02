import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.grey200.withAlpha(128))),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(context, index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), activeIcon: Icon(Icons.access_time), label: 'Clock'),
            BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), activeIcon: Icon(Icons.event_note), label: 'Leave'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Pay'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.attendance)) return 1;
    if (location.startsWith(AppRoutes.leaveList)) return 2;
    if (location.startsWith(AppRoutes.payslip) || location.startsWith(AppRoutes.expense)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.attendance);
        break;
      case 2:
        context.go(AppRoutes.leaveList);
        break;
      case 3:
        context.go(AppRoutes.payslip);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }
}