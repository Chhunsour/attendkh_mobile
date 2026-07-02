import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme mode state - persists user preference
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Whether dark mode is currently active
final isDarkModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeModeProvider);
  // This is reactive but doesn't know platform brightness automatically.
  // For platform-aware dark mode, use ThemeMode.system + MediaQuery in the widget.
  return mode == ThemeMode.dark;
});