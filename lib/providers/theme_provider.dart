import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing and persisting the application ThemeMode (system, light, dark).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// StateNotifier that handles theme changes and persists user preference.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_themeKey);
      if (modeStr != null) {
        switch (modeStr) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      // Fallback to system on error
    }
  }

  /// Explicitly set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;

    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_themeKey, modeStr);
    } catch (_) {}
  }

  /// Toggle between Light and Dark mode
  Future<void> toggleTheme() async {
    final nextMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

/// Helper provider to check if Dark Mode is active (reactive to current ThemeMode setting)
final isDarkModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == ThemeMode.dark) return true;
  if (mode == ThemeMode.light) return false;
  // If ThemeMode.system, defaults to standard system brightness check
  return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;
});