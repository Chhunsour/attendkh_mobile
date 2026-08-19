import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';
import 'package:mpg_hr_mobile_app/providers/theme_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';

/// A modern, executive "More" screen that displays secondary navigation items
/// in a clean grid alongside grouped preference and account management sections.
class MoreScreen extends ConsumerWidget {
  final String title;
  final List<MoreItem> items;
  final bool showLogout;
  final bool showPreferences;

  const MoreScreen({
    super.key,
    required this.title,
    required this.items,
    this.showLogout = false,
    this.showPreferences = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final bool displayPreferences = showPreferences || showLogout;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Section 1: Company Services & Tools Launchpad ──
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.companyServicesAndTools,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey800,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDarkElevated
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    l10n.featuresCount(items.length),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.grey300 : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Clean 4-Column Quick Services Card ──
          Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.grey200.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _buildLaunchpadItem(context, items[index], isDark),
            ),
          ),

          if (displayPreferences) ...[
            const SizedBox(height: 24),

            // ── Section 2: Preferences & Display ──
            _buildSectionHeader(l10n.preferences, isDark),
            const SizedBox(height: 8),
            _buildGroupCard(
              context: context,
              isDark: isDark,
              children: [
                _buildThemeTile(context, ref, l10n, isDark),
                _buildDivider(isDark),
                _buildLanguageTile(context, ref, l10n, isDark),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section 3: Account & Information ──
            _buildSectionHeader(l10n.accountAndInfo, isDark),
            const SizedBox(height: 8),
            _buildGroupCard(
              context: context,
              isDark: isDark,
              children: [
                if (authState.isSuperAdmin || authState.isCompanyAdmin) ...[
                  _buildSettingRow(
                    context: context,
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: l10n.returnToAdminConsole,
                    subtitle: l10n.returnToAdminSubtitle,
                    isDark: isDark,
                    onTap: () {
                      if (authState.isSuperAdmin) {
                        context.go(AppRoutes.adminDashboard);
                      } else {
                        context.go(AppRoutes.companyAdmin);
                      }
                    },
                  ),
                  _buildDivider(isDark),
                ],
                _buildSettingRow(
                  context: context,
                  icon: Icons.edit_note_rounded,
                  iconColor: AppColors.primary,
                  title: l10n.editProfile,
                  subtitle: l10n.editProfileSubtitle,
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  context: context,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFF0284C7),
                  title: l10n.privacyPolicy,
                  subtitle: l10n.privacyPolicySubtitle,
                  isExternal: true,
                  isDark: isDark,
                  onTap: () => launchUrl(
                    Uri.parse('https://attendkh.com/privacy-policy'),
                    mode: LaunchMode.inAppBrowserView,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section 4: Account Actions / Security ──
            _buildSectionHeader(l10n.accountActions, isDark),
            const SizedBox(height: 8),
            _buildGroupCard(
              context: context,
              isDark: isDark,
              children: [
                _buildSettingRow(
                  context: context,
                  icon: Icons.logout_rounded,
                  iconColor: isDark ? const Color(0xFFF87171) : AppColors.danger,
                  title: l10n.logOut,
                  subtitle: l10n.signOutSubtitle,
                  titleColor: isDark ? const Color(0xFFF87171) : AppColors.danger,
                  isDestructive: true,
                  isDark: isDark,
                  onTap: () => showLogoutConfirmation(context, ref),
                ),
              ],
            ),

            // ── App Footer / Version Info ──
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Text(
                    'AttendKH Mobile',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.attendkhAppVersion,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.grey600 : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Grouped Section Header ──
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.grey400 : AppColors.grey500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Group Card Container ──
  Widget _buildGroupCard({
    required BuildContext context,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.grey200.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // ── Theme Tile with Bottom Sheet Selector ──
  Widget _buildThemeTile(BuildContext context, WidgetRef ref, AppLocalizations l10n, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);

    final String modeLabel = switch (themeMode) {
      ThemeMode.light => l10n.lightTheme,
      ThemeMode.dark => l10n.darkTheme,
      ThemeMode.system => l10n.systemTheme,
    };

    final String badgeLabel = switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'Auto',
    };

    final IconData modeIcon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    return _buildSettingRow(
      context: context,
      icon: modeIcon,
      iconColor: iconColor,
      title: l10n.themeAndAppearance,
      subtitle: modeLabel,
      badgeText: badgeLabel,
      isDark: isDark,
      onTap: () => _showThemeSelectionSheet(context, ref, l10n),
    );
  }

  // ── Language Tile with Bottom Sheet Selector ──
  Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final currentLang = ref.watch(localeProvider).languageCode;
    final isKhmer = currentLang == 'km';
    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    return _buildSettingRow(
      context: context,
      icon: Icons.translate_rounded,
      iconColor: iconColor,
      title: l10n.language,
      subtitle: isKhmer ? 'ភាសាខ្មែរ (Khmer)' : 'English (US)',
      badgeText: isKhmer ? 'ខ្មែរ' : 'EN',
      isDark: isDark,
      onTap: () => _showLanguageSelectionSheet(context, ref, l10n),
    );
  }

  // ── Standard Setting Item Row ──
  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    String? badgeText,
    Color? titleColor,
    bool isDestructive = false,
    bool isExternal = false,
  }) {
    // Senior UX/UI Palette: Cohesive neutral squircle container
    final Color rowIconBg = isDestructive
        ? (isDark ? const Color(0xFF2E1818) : const Color(0xFFFEE2E2))
        : (isDark ? const Color(0xFF242424) : const Color(0xFFF1F5F9));

    final Color rowIconBorder = isDestructive
        ? (isDark ? const Color(0xFF482020) : const Color(0xFFFECACA))
        : (isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0));

    final Color finalIconColor = isDestructive
        ? (isDark ? const Color(0xFFF87171) : AppColors.danger)
        : (isDark ? const Color(0xFF93C5FD) : AppColors.primary);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: rowIconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rowIconBorder,
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 19, color: finalIconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ??
                          (isDestructive
                              ? (isDark ? const Color(0xFFF87171) : AppColors.danger)
                              : (isDark ? Colors.white : AppColors.grey900)),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDestructive
                          ? (isDark
                              ? const Color(0xFFF87171).withValues(alpha: 0.75)
                              : AppColors.danger.withValues(alpha: 0.8))
                          : (isDark ? AppColors.grey400 : AppColors.grey500),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.primary.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              isExternal ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
              size: isExternal ? 16 : 18,
              color: isDestructive
                  ? (isDark ? const Color(0xFFF87171).withValues(alpha: 0.7) : AppColors.danger.withValues(alpha: 0.6))
                  : (isDark ? AppColors.grey500 : AppColors.grey400),
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider ──
  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 62,
      endIndent: 0,
      color: isDark ? AppColors.borderDark : AppColors.grey100,
    );
  }

  // ── Theme Selection Bottom Sheet ──
  void _showThemeSelectionSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey700 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.selectTheme,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.themeSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetOption(
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: l10n.lightTheme,
                  subtitle: l10n.lightThemeDesc,
                  isSelected: currentMode == ThemeMode.light,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildSheetOption(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF818CF8),
                  title: l10n.darkTheme,
                  subtitle: l10n.darkThemeDesc,
                  isSelected: currentMode == ThemeMode.dark,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildSheetOption(
                  icon: Icons.brightness_auto_rounded,
                  iconColor: AppColors.primary,
                  title: l10n.systemTheme,
                  subtitle: l10n.systemThemeDesc,
                  isSelected: currentMode == ThemeMode.system,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Language Selection Bottom Sheet ──
  void _showLanguageSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentLang = ref.read(localeProvider).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey700 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.selectLanguage,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.languageSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetOption(
                  icon: Icons.translate_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: l10n.english,
                  subtitle: l10n.englishDesc,
                  isSelected: currentLang == 'en',
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildSheetOption(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: l10n.khmer,
                  subtitle: l10n.khmerDesc,
                  isSelected: currentLang == 'km',
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(localeProvider.notifier).setLocale(const Locale('km'));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bottom Sheet Selection Option ──
  Widget _buildSheetOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Color optIconBg = isSelected
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE))
        : (isDark ? const Color(0xFF242424) : const Color(0xFFF1F5F9));
    final Color optIconBorder = isSelected
        ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD))
        : (isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0));
    final Color finalIconColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? AppColors.surfaceDarkElevated : AppColors.grey50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.6 : 0.4)
                : (isDark ? AppColors.borderDark : AppColors.grey200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: optIconBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: optIconBorder, width: 1),
              ),
              child: Icon(icon, color: finalIconColor, size: 19),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 11.5,
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
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaunchpadItem(BuildContext context, MoreItem item, bool isDark) {
    // Senior UX/UI Palette: Cohesive, elegant brand styling (no chaotic rainbow colors)
    final Color iconBg = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFF1F5F9);
    final Color iconBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);
    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (item.onTap != null) {
            item.onTap!();
          } else if (item.routePath != null) {
            context.push(item.routePath!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.grey200 : AppColors.grey800,
                  height: 1.2,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Describes a single item in the "More" grid.
class MoreItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? routePath;
  final VoidCallback? onTap;

  const MoreItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.routePath,
    this.onTap,
  });
}
