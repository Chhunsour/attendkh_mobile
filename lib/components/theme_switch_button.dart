import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/theme_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Modern Theme Switcher Button / Pill (☀️ Light / 🌙 Dark / 💻 System)
///
/// Designed to fit in Auth headers, AppBars, or Profile/Settings pages.
class ThemeSwitchButton extends ConsumerWidget {
  final bool isDarkHeader;
  final bool compact;

  const ThemeSwitchButton({
    super.key,
    this.isDarkHeader = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final IconData icon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };


    final Color effectiveFg = isDarkHeader
        ? Colors.white
        : (isDark ? Colors.white : AppColors.primaryDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showThemeSelectionSheet(context, ref),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          // Apple HIG: minimum 44pt hit target.
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDarkHeader
                ? Colors.white.withAlpha(35)
                : (isDark
                    ? AppColors.surfaceDarkElevated
                    : AppColors.primary.withAlpha(18)),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDarkHeader
                  ? Colors.white.withAlpha(60)
                  : (isDark
                      ? AppColors.borderDark
                      : AppColors.primary.withAlpha(45)),
              width: 1,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Icon(
              icon,
              key: ValueKey(themeMode),
              size: 16,
              color: isDarkHeader
                  ? Colors.amberAccent
                  : (themeMode == ThemeMode.light
                      ? const Color(0xFFF59E0B)
                      : effectiveFg),
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeSelectionSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey700 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your preferred app theme color scheme',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildThemeOptionTile(
                  context: ctx,
                  ref: ref,
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Light Mode',
                  subtitle: 'Bright theme with crisp white surfaces',
                  mode: ThemeMode.light,
                  isSelected: currentMode == ThemeMode.light,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  context: ctx,
                  ref: ref,
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF818CF8),
                  title: 'Dark Mode',
                  subtitle: 'Sleek dark theme that is easy on the eyes',
                  mode: ThemeMode.dark,
                  isSelected: currentMode == ThemeMode.dark,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  context: ctx,
                  ref: ref,
                  icon: Icons.brightness_auto_rounded,
                  iconColor: AppColors.primary,
                  title: 'System Default',
                  subtitle: 'Automatically matches your device system setting',
                  mode: ThemeMode.system,
                  isSelected: currentMode == ThemeMode.system,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(isDark ? 30 : 15)
              : (isDark ? AppColors.surfaceDarkElevated : AppColors.grey50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.grey200),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: isDark ? AppColors.grey600 : AppColors.grey300,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
