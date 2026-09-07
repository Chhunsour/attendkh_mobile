import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/utils/router/app_router.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/locale_provider.dart';
import 'package:attendkh/providers/theme_provider.dart';

class AttendKHApp extends ConsumerWidget {
  const AttendKHApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AttendKH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('km'),
      ],
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: 'GoogleSansFlex',
            fontFamilyFallback: AppTheme.fontFallbacks,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}