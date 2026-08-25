import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Language switcher with a flag thumbnail + ISO code chip.
///
/// Tapping cycles between Khmer (km) and English (en).
/// [compact] renders a tighter version for auth header bars.
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

    final String flagAsset = isKhmer
        ? 'assets/images/flag_km.svg'
        : 'assets/images/flag_en.svg';
    final String code = isKhmer ? 'KH' : 'EN';

    final Color fg = isDark ? Colors.white : AppColors.primaryDark;
    final Color bg = isDark
        ? Colors.white.withAlpha(35)
        : AppColors.primary.withAlpha(18);
    final Color border = isDark
        ? Colors.white.withAlpha(60)
        : AppColors.primary.withAlpha(45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final next = isKhmer ? const Locale('en') : const Locale('km');
          ref.read(localeProvider.notifier).setLocale(next);
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rounded flag thumbnail
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: fg.withAlpha(30),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.5),
                  child: SvgPicture.asset(
                    flagAsset,
                    width: 20,
                    height: 15,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // ISO code
              Text(
                code,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
