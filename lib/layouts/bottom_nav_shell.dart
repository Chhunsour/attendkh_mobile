import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Responsive navigation shell shared by employee and admin experiences.
///
/// Phones use a modern animated bottom bar with haptic feedback and spring micro-interactions.
/// Tablets and desktop-sized windows switch to a navigation rail.
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
  void didUpdateWidget(covariant BottomNavShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

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
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final safeIndex = _currentIndex.clamp(0, widget.items.length - 1);
    final stack = IndexedStack(
      index: safeIndex,
      children: widget.items.asMap().entries.map((entry) {
        return ExcludeSemantics(
          excluding: entry.key != safeIndex,
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
    final safeIndex = _currentIndex.clamp(0, widget.items.isEmpty ? 0 : widget.items.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: SafeArea(
        right: false,
        child: NavigationRail(
          selectedIndex: safeIndex,
          onDestinationSelected: (index) {
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);
          },
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
            fontFamily: 'GoogleSansFlex',
            fontFamilyFallback: AppTheme.fontFallbacks,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(
            fontFamily: 'GoogleSansFlex',
            fontFamilyFallback: AppTheme.fontFallbacks,
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
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Row(
            children: widget.items.asMap().entries.map((entry) {
              return Expanded(
                child: _NavItemButton(
                  item: entry.value,
                  isSelected: _currentIndex == entry.key,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentIndex = entry.key);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// An interactive, spring-animated navigation button with modern capsule indicator
class _NavItemButton extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItemButton({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark ? const Color(0xFF60A5FA) : AppColors.primary;
    final inactiveColor = widget.isDark ? AppColors.grey400 : AppColors.grey500;
    final activePillBg = widget.isDark
        ? AppColors.primary.withValues(alpha: 0.22)
        : AppColors.primary.withValues(alpha: 0.10);
    final activePillBorder = widget.isDark
        ? AppColors.primary.withValues(alpha: 0.40)
        : AppColors.primary.withValues(alpha: 0.20);

    return Semantics(
      selected: widget.isSelected,
      button: true,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (mounted) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (mounted) setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon with Animated Floating Capsule Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isSelected ? 20 : 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? activePillBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected ? activePillBorder : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: widget.isDark ? 0.25 : 0.10,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.isSelected ? widget.item.filledIcon : widget.item.outlineIcon,
                    color: widget.isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                // Text Label with GoogleSansFlex & Kantumruy Fallback
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: widget.isSelected ? activeColor : inactiveColor,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11.0,
                        letterSpacing: widget.isSelected ? -0.1 : 0,
                        fontFamily: 'GoogleSansFlex',
                        fontFamilyFallback: AppTheme.fontFallbacks,
                      ),
                      child: Text(
                        widget.item.label,
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
