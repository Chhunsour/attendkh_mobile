import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/pages/shared/more_screen.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';

void main() {
  setUpAll(DioClient.init);

  testWidgets('service rows render title, subtitle and stay in bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => AuthNotifier(initialState: const AuthState()),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MoreScreen(
            title: 'HR Operations',
            items: [
              MoreItem(
                title: 'Employees',
                subtitle: 'Manage your people',
                icon: Icons.people_alt_outlined,
                color: Color(0xFF0EA5E9),
              ),
              MoreItem(
                title: 'Leave Requests',
                icon: Icons.event_busy_outlined,
                color: Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Manage your people'), findsOneWidget);
    // A row without a subtitle still renders, just without the second line
    expect(find.text('Leave Requests'), findsOneWidget);
  });
}
