import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Language switcher pill (Khmer / English).
///
/// [compact] renders an icon-sized chip with just the ISO code — for headers
/// where the brand lockup already owns the horizontal space.
///
/// ponytail: no flag emoji — emoji flags render as letter boxes on Android
/// and as inconsistent glyphs across OS versions. Icon + ISO code always works.
class LanguageSwitchButton extends ConsumerWidget {
  final bool isDark;
  final bool compact;

  const LanguageSwitchButton({
    super.key,
    this.isDark = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isKhmer = currentLocale.languageCode == 'km';

    final fg = isDark ? Colors.white : AppColors.primaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final nextLocale = isKhmer ? const Locale('en') : const Locale('km');
          ref.read(localeProvider.notifier).setLocale(nextLocale);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // Apple HIG: minimum 44pt hit target.
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(35)
                : AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(60)
                  : AppColors.primary.withAlpha(50),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, size: 15, color: fg),
              SizedBox(width: compact ? 5 : 6),
              Text(
                // Compact shows the ISO code; full shows the endonym so the
                // language is readable to a speaker who can't read the other.
                compact
                    ? (isKhmer ? 'KH' : 'EN')
                    : (isKhmer ? 'ភាសាខ្មែរ' : 'English'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 14,
                  color: fg.withAlpha(180),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
