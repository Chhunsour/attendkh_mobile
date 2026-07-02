import 'package:flutter/material.dart';

/// A consistent full-screen scaffold with optional app bar and bottom navigation offset
class AppScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final PreferredSizeWidget? customAppBar;

  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showAppBar = true,
    this.customAppBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? (customAppBar ??
              AppBar(
                title: title != null ? Text(title!) : null,
                actions: actions,
              ))
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}