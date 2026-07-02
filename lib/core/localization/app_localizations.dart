import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/localization/app_localizations_en.dart';
import 'package:mpg_hr_mobile_app/core/localization/app_localizations_km.dart';

/// Locale provider - manages app language
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// All supported locales
class AppLocales {
  static const english = Locale('en');
  static const khmer = Locale('km');

  static const List<Locale> supported = [english, khmer];

  static const List<LocalizationsDelegate<dynamic>> delegates = [
    AppLocalizations.delegate,
  ];
}

/// Custom localizations class for the app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Singleton maps for translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enTranslations,
    'km': kmTranslations,
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String translate(String key) => get(key);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'km'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

/// Extension for easy access from BuildContext
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String t(String key) => AppLocalizations.of(this).get(key);
}