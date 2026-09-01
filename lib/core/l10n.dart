import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Localized strings for the current locale. Requires the
  /// [AppLocalizations.localizationsDelegates] to be installed (done once in
  /// `app.dart`), so every screen can simply use `context.l10n`.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
