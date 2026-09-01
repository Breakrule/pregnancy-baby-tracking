import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shared/settings/locale_provider.dart';
import 'content_loader.dart';
import 'models.dart';

/// Bundled content for the current UI locale. Re-loads when the language
/// changes (localeProvider feeds the settings row).
final contentProvider = FutureProvider<ContentBundle>((ref) {
  final locale = ref.watch(localeProvider);
  return ContentLoader.load(locale.languageCode);
});
