import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Modern Cambodian Language Switcher Pill (🇰🇭 ខ្មែរ / 🇬🇧 EN)
///
/// Easily placed on auth headers, splash, login, or registration bars.
class LanguageSwitchButton extends ConsumerWidget {
  final bool isDark;

  const LanguageSwitchButton({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isKhmer = currentLocale.languageCode == 'km';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final nextLocale = isKhmer ? const Locale('en') : const Locale('km');
          ref.read(localeProvider.notifier).setLocale(nextLocale);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              Text(
                isKhmer ? '🇰🇭' : '🇬🇧',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                isKhmer ? 'ភាសាខ្មែរ' : 'English',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.swap_horiz_rounded,
                size: 14,
                color: isDark
                    ? Colors.white.withAlpha(180)
                    : AppColors.primaryDark.withAlpha(180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
