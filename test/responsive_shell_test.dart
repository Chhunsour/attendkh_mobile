import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendkh/layouts/bottom_nav_shell.dart';

void main() {
  const items = [
    NavItem(
      outlineIcon: Icons.home_outlined,
      filledIcon: Icons.home,
      label: 'Home',
      screen: Text('Home screen'),
    ),
    NavItem(
      outlineIcon: Icons.person_outline,
      filledIcon: Icons.person,
      label: 'Profile',
      screen: Text('Profile screen'),
    ),
  ];

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: BottomNavShell(items: items)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses bottom navigation on phones', (tester) async {
    await pumpShell(tester, const Size(390, 844));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('uses navigation rail on tablet widths', (tester) async {
    await pumpShell(tester, const Size(800, 600));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
