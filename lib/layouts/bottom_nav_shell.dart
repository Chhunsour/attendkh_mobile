import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Responsive navigation shell shared by employee and admin experiences.
///
/// Phones use a compact bottom bar. Tablets and desktop-sized windows switch
/// to a navigation rail and constrain the content so it remains readable.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.grey200;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final content = _buildContent(constraints);

        if (isWide) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            body: Row(
              children: [
                _buildNavigationRail(navBgColor, borderColor, isDark),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          body: content,
          bottomNavigationBar: _buildBottomNavigation(
            navBgColor,
            borderColor,
            isDark,
          ),
        );
      },
    );
  }

  Widget _buildContent(BoxConstraints constraints) {
    final stack = IndexedStack(
      index: _currentIndex,
      children: widget.items.asMap().entries.map((entry) {
        return ExcludeSemantics(
          excluding: entry.key != _currentIndex,
          child: entry.value.screen,
        );
      }).toList(),
    );

    if (constraints.maxWidth < 1200) return stack;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: SizedBox(width: double.infinity, child: stack),
      ),
    );
  }

  Widget _buildNavigationRail(
    Color backgroundColor,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        right: false,
        child: NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: backgroundColor,
          indicatorColor: isDark ? const Color(0x280052FF) : const Color(0x180052FF),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 24),
          unselectedIconTheme: IconThemeData(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            size: 24,
          ),
          selectedLabelTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          labelType: NavigationRailLabelType.all,
          groupAlignment: -0.75,
          minWidth: 96,
          destinations: widget.items.map((item) {
            return NavigationRailDestination(
              icon: Icon(item.outlineIcon),
              selectedIcon: Icon(item.filledIcon),
              label: Text(item.label),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    Color backgroundColor,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: widget.items.asMap().entries.map((entry) {
              return Expanded(
                child: _buildNavItem(
                  entry.key,
                  entry.value,
                  isDark,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavItem item, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF60A5FA) : AppColors.primary;
    final inactiveColor = isDark ? AppColors.grey400 : AppColors.grey500;
    final activePillBg = isDark ? const Color(0x302563EB) : const Color(0x180052FF);

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? activePillBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isSelected ? item.filledIcon : item.outlineIcon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? activeColor : inactiveColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10.5,
                      fontFamily: 'GoogleSans',
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
