import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpg_hr_mobile_app/providers/theme_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/theme_switch_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier & Provider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial theme mode is ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialMode = container.read(themeModeProvider);
      expect(initialMode, equals(ThemeMode.system));
    });

    test(
      'setThemeMode updates state and persists in SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(themeModeProvider.notifier);
        await notifier.setThemeMode(ThemeMode.dark);

        expect(container.read(themeModeProvider), equals(ThemeMode.dark));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_theme_mode'), equals('dark'));

        await notifier.setThemeMode(ThemeMode.light);
        expect(container.read(themeModeProvider), equals(ThemeMode.light));
        expect(prefs.getString('app_theme_mode'), equals('light'));
      },
    );

    test('toggleTheme alternates between light and dark', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      await notifier.toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      await notifier.toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });
  });

  group('ThemeData Tokens Tests', () {
    test('lightTheme has correct brightness and surfaces', () {
      final light = AppTheme.lightTheme;
      expect(light.brightness, equals(Brightness.light));
      expect(light.scaffoldBackgroundColor, equals(AppColors.backgroundLight));
      expect(light.cardColor, equals(AppColors.surfaceLight));
      expect(light.colorScheme.primary, equals(AppColors.primary));
    });

    test('darkTheme has correct brightness and surfaces', () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, equals(Brightness.dark));
      expect(dark.scaffoldBackgroundColor, equals(AppColors.backgroundDark));
      expect(dark.cardColor, equals(AppColors.surfaceDark));
      expect(dark.colorScheme.primary, equals(AppColors.primary));
      expect(dark.colorScheme.surface, equals(AppColors.surfaceDark));
    });
  });

  group('ThemeSwitchButton Widget Tests', () {
    testWidgets('ThemeSwitchButton renders with current mode label', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ThemeSwitchButton())),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ThemeSwitchButton), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('Tapping ThemeSwitchButton opens bottom sheet with 3 options', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ThemeSwitchButton())),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(ThemeSwitchButton));
      await tester.pumpAndSettle();

      expect(find.text('Choose Appearance'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
    });
  });
}
