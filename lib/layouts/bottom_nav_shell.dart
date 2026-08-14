import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Reusable bottom navigation shell with a fixed attached nav bar.
///
/// Each tab renders its [screens] via [IndexedStack] to preserve state.
/// The nav bar is fixed to the bottom edge with a top border separator.
class BottomNavShell extends StatefulWidget {
  final List<NavItem> items;
  final int initialIndex;

  const BottomNavShell({super.key, required this.items, this.initialIndex = 0});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.items.asMap().entries.map((e) {
          return ExcludeSemantics(
            excluding: e.key != _currentIndex,
            child: e.value.screen,
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.grey200, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.items.asMap().entries.map((e) {
                return _buildNavItem(
                  e.key,
                  e.value.outlineIcon,
                  e.value.filledIcon,
                  e.value.label,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final primaryColor = AppColors.primary;
    final unselectedColor = AppColors.grey400;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Describes a single bottom navigation tab.
class NavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final Widget screen;

  const NavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    required this.screen,
  });
}
