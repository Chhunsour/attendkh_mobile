import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:attendkh/providers/branch_switch_provider.dart';
import 'package:attendkh/providers/locale_provider.dart';
import 'package:attendkh/providers/theme_provider.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/utils/router/app_router.dart';
import 'package:attendkh/components/dialogs/logout_dialog.dart';
import 'package:attendkh/components/dialogs/delete_account_dialog.dart';

/// One calm rounded shape keeps the menu cards visually quiet and easy to scan.
const moreCardShape = BorderRadius.all(Radius.circular(22));

const _cardShape = moreCardShape;

/// A menu tab built as a focused list of tools with grouped account actions.
class MoreScreen extends ConsumerWidget {
  final String title;
  final List<MoreItem> items;
  final bool showLogout;
  final bool showPreferences;

  /// Optional live content above / below the tool list, so a menu tab can
  /// carry state instead of only links.
  final Widget? header;
  final Widget? footer;

  const MoreScreen({
    super.key,
    required this.title,
    required this.items,
    this.showLogout = false,
    this.showPreferences = false,
    this.header,
    this.footer,
  });

  /// The tab's signature colour. Call sites already lead with their most
  /// important tool, so its colour is the one that identifies the tab.
  Color get _accent => items.isEmpty ? AppColors.primary : items.first.color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bool displayPreferences = showPreferences || showLogout;
    final accent = _accent;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _MoreHeaderBar(title: title, isDark: isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (header != null) ...[header!, const SizedBox(height: 22)],

                // ── The tools, as one readable list ──
                ..._buildToolList(context, isDark),

                ?footer,

                if (displayPreferences) ...[
                  const SizedBox(height: 26),
                  MoreSectionHeader(title: l10n.preferences, accent: accent),
                  const SizedBox(height: 10),
                  _buildGroupCard(
                    isDark: isDark,
                    children: [
                      _buildThemeTile(context, ref, l10n, isDark),
                      _buildDivider(isDark),
                      _buildLanguageTile(context, ref, l10n, isDark),
                    ],
                  ),

                  const SizedBox(height: 26),
                  MoreSectionHeader(title: l10n.accountAndInfo, accent: accent),
                  const SizedBox(height: 10),
                  _buildGroupCard(
                    isDark: isDark,
                    children: [
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

                  const SizedBox(height: 26),
                  MoreSectionHeader(
                    title: l10n.accountActions,
                    accent: isDark ? const Color(0xFFF87171) : AppColors.danger,
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard(
                    isDark: isDark,
                    children: [
                      _buildSettingRow(
                        context: context,
                        icon: Icons.logout_rounded,
                        iconColor: isDark
                            ? const Color(0xFFF87171)
                            : AppColors.danger,
                        title: l10n.logOut,
                        subtitle: l10n.signOutSubtitle,
                        isDestructive: true,
                        isDark: isDark,
                        onTap: () => showLogoutConfirmation(context, ref),
                      ),
                      // Account deletion must be reachable by every role that
                      // can sign in — Apple Guideline 5.1.1(v).
                      _buildSettingRow(
                        context: context,
                        icon: Icons.delete_forever_rounded,
                        iconColor: isDark
                            ? const Color(0xFFF87171)
                            : AppColors.danger,
                        title: l10n.deleteAccount,
                        subtitle: l10n.deleteAccountSubtitle,
                        isDestructive: true,
                        isDark: isDark,
                        onTap: () => showDeleteAccountConfirmation(context, ref),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _buildAppMark(l10n, isDark, accent),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── The tools: one focused list with predictable tap targets ──
  List<Widget> _buildToolList(BuildContext context, bool isDark) {
    if (items.isEmpty) return const [];

    return [
      _buildGroupCard(
        isDark: isDark,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) _buildDivider(isDark, indent: 88),
            _ToolListRow(item: items[i], isDark: isDark),
          ],
        ],
      ),
    ];
  }

  // ── Group Card Container ──
  Widget _buildGroupCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: _cardShape,
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
      child: Column(children: children),
    );
  }

  Widget _buildAppMark(AppLocalizations l10n, bool isDark, Color accent) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
                bottomRight: Radius.circular(9),
                bottomLeft: Radius.circular(3),
              ),
              color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
            ),
            child: Icon(Icons.hive_rounded, size: 14, color: accent),
          ),
          const SizedBox(height: 8),
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
    );
  }

  // ── Theme Tile with Bottom Sheet Selector ──
  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final themeMode = ref.watch(themeModeProvider);

    final String modeLabel = switch (themeMode) {
      ThemeMode.light => l10n.lightTheme,
      ThemeMode.dark => l10n.darkTheme,
      ThemeMode.system => l10n.systemTheme,
    };

    final String badgeLabel = switch (themeMode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeAuto,
    };

    final IconData modeIcon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return _buildSettingRow(
      context: context,
      icon: modeIcon,
      iconColor: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
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

    return _buildSettingRow(
      context: context,
      icon: Icons.translate_rounded,
      iconColor: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
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
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
    String? badgeText,
    bool badgeIsAlert = false,
    bool isDestructive = false,
    bool isExternal = false,
  }) {
    final Color color = isDestructive
        ? (isDark ? const Color(0xFFF87171) : AppColors.danger)
        : iconColor;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconChip(color: color, icon: icon, size: 40),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? color
                          : (isDark ? Colors.white : AppColors.grey900),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: isDestructive
                            ? color.withValues(alpha: 0.8)
                            : (isDark ? AppColors.grey400 : AppColors.grey500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeText != null) ...[
              _Badge(text: badgeText, color: color, isAlert: badgeIsAlert),
              const SizedBox(width: 6),
            ],
            Icon(
              isExternal
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              size: isExternal ? 16 : 18,
              color: isDestructive
                  ? color.withValues(alpha: 0.65)
                  : (isDark ? AppColors.grey500 : AppColors.grey400),
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider ──
  Widget _buildDivider(bool isDark, {double indent = 62}) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: 0,
      color: isDark ? AppColors.borderDark : AppColors.grey100,
    );
  }

  // ── Theme Selection Bottom Sheet ──
  void _showThemeSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentMode = ref.read(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _SheetFrame(
          title: l10n.selectTheme,
          subtitle: l10n.themeSubtitle,
          isDark: isDark,
          children: [
            _buildSheetOption(
              icon: Icons.light_mode_rounded,
              title: l10n.lightTheme,
              subtitle: l10n.lightThemeDesc,
              isSelected: currentMode == ThemeMode.light,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _buildSheetOption(
              icon: Icons.dark_mode_rounded,
              title: l10n.darkTheme,
              subtitle: l10n.darkThemeDesc,
              isSelected: currentMode == ThemeMode.dark,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _buildSheetOption(
              icon: Icons.brightness_auto_rounded,
              title: l10n.systemTheme,
              subtitle: l10n.systemThemeDesc,
              isSelected: currentMode == ThemeMode.system,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
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
        return _SheetFrame(
          title: l10n.selectLanguage,
          subtitle: l10n.languageSubtitle,
          isDark: isDark,
          children: [
            _buildSheetOption(
              icon: Icons.translate_rounded,
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
        );
      },
    );
  }

  // ── Bottom Sheet Selection Option ──
  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

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
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF1E293B)
                          : AppColors.primaryLight)
                    : (isDark ? const Color(0xFF242424) : AppColors.grey100),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF93C5FD))
                      : (isDark ? const Color(0xFF333333) : AppColors.grey200),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 19),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

/// Quiet native app bar that keeps the list as the visual focus.
class _MoreHeaderBar extends ConsumerWidget {
  final String title;
  final bool isDark;

  const _MoreHeaderBar({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final branchSwitch = ref.watch(branchSwitchProvider);

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.grey900,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        if (branchSwitch.isActive)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(branchSwitchProvider.notifier).exitBranchView();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        branchSwitch.activeBranchName ?? '',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Editorial section header: accent tick, label, then a hairline rule that
/// runs out to the margin. Shared with the summary widgets so every menu tab
/// speaks the same language.
class MoreSectionHeader extends StatelessWidget {
  final String title;
  final Color accent;
  final VoidCallback? onTap;

  const MoreSectionHeader({
    super.key,
    required this.title,
    this.accent = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
                letterSpacing: 0.9,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 10),
              color: isDark ? AppColors.borderDark : AppColors.grey200,
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.grey400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tools
// ─────────────────────────────────────────────────────────────────────────────

void _openItem(BuildContext context, MoreItem item) {
  HapticFeedback.lightImpact();
  if (item.onTap != null) {
    item.onTap!();
  } else if (item.routePath != null) {
    context.push(item.routePath!);
  }
}

/// Soft glyph chip — the fastest thing to recognise in a menu.
class _IconChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const _IconChip({
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.11),
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

/// Full-width tool row matching the reference menu: soft icon tile, strong
/// label, quiet supporting copy, and a clear forward affordance.
class _ToolListRow extends StatelessWidget {
  final MoreItem item;
  final bool isDark;

  const _ToolListRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark
        ? Color.lerp(item.color, Colors.white, 0.16)!
        : item.color;
    final textColor = isDark ? Colors.white : AppColors.grey900;
    final secondaryColor = isDark ? AppColors.grey400 : AppColors.grey500;

    return InkWell(
      onTap: () => _openItem(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconChip(color: iconColor, icon: item.icon, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: textColor,
                    ),
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.badgeText != null) ...[
              const SizedBox(width: 8),
              _Badge(
                text: item.badgeText!,
                color: iconColor,
                isAlert: item.badgeIsAlert,
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isAlert;

  const _Badge({required this.text, required this.color, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isAlert
            ? color
            : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(20),
        border: isAlert
            ? null
            : Border.all(color: color.withValues(alpha: 0.3), width: 0.9),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: isAlert
              ? Colors.white
              : (isDark
                    ? Colors.white
                    : Color.alphaBlend(Colors.black26, color)),
        ),
      ),
    );
  }
}

/// Shared chrome for the two selection sheets — grabber, title, subtitle.
class _SheetFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Widget> children;

  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Describes a single item in the "More" list.
class MoreItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? routePath;
  final VoidCallback? onTap;

  /// Live count shown on the tile. [badgeIsAlert] fills it with the item's
  /// colour — reserve that for things that are actually waiting on someone.
  final String? badgeText;
  final bool badgeIsAlert;

  const MoreItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.routePath,
    this.onTap,
    this.badgeText,
    this.badgeIsAlert = false,
  });
}
