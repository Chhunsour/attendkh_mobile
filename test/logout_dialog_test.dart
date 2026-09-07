import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendkh/components/dialogs/logout_dialog.dart';
import 'package:attendkh/l10n/app_localizations.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester, TargetPlatform platform) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(platform: platform),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showLogoutConfirmation(ctx, ref),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('iOS gets a native alert with a destructive sign-out action', (
    tester,
  ) async {
    await pumpDialog(tester, TargetPlatform.iOS);

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.text('Log Out?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    final actions = tester
        .widgetList<CupertinoDialogAction>(find.byType(CupertinoDialogAction))
        .toList();
    expect(actions.length, 2);
    // Cancel is the preferred (bold) action; sign-out is destructive, never
    // the default target.
    expect(actions.first.isDefaultAction, isTrue);
    expect(actions.last.isDestructiveAction, isTrue);
    expect(actions.last.isDefaultAction, isFalse);
  });

  testWidgets('Android gets a Material alert, dismissible via Cancel', (
    tester,
  ) async {
    await pumpDialog(tester, TargetPlatform.android);

    // AlertDialog.adaptive renders a Material Dialog off-Apple.
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
