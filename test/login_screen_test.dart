import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/pages/auth/login_screen.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

Widget _harness({ThemeMode mode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      // Idle auth state — the splash route owns the "checking session" spinner.
      authProvider.overrideWith(
        (ref) => AuthNotifier(initialState: const AuthState()),
      ),
    ],
    child: MaterialApp(
      themeMode: mode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  setUpAll(DioClient.init);

  testWidgets('login screen shows identity, password and recovery affordances',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Email, Phone, or Employee ID'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('empty submit surfaces both validation errors', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump();

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('forgot password opens the reset sheet', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
  });
}
