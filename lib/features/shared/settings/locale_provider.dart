import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';

/// The UI locale, persisted in the settings row. Defaults to English;
/// falls back to English for any unknown/unsupported tag.
final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  final tag = settings?.locale ?? 'en';
  final locale = Locale.fromSubtags(languageCode: tag.split('-').first);
  if (AppLocalizations.supportedLocales.contains(locale)) {
    return locale;
  }
  return AppLocalizations.supportedLocales.first;
});
