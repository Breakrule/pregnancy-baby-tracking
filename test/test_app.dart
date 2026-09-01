import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nurture/l10n/app_localizations.dart';

/// Wraps a screen in a [MaterialApp] with the app's localization delegates,
/// so widgets can resolve `context.l10n` in tests.
MaterialApp localizedApp(Widget home) {
  return MaterialApp(
    home: home,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

/// Localization delegates for tests that build their own MaterialApp.router
/// or MaterialApp instances.
const List<LocalizationsDelegate<dynamic>> testLocalizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
