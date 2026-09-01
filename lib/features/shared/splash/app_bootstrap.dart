import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers.dart';
import '../../../data/providers.dart';
import 'pending_route_provider.dart';

/// Emitted by [bootstrapProvider] once the app is ready to show its UI.
class AppBootstrapState {
  const AppBootstrapState({required this.ready});

  final bool ready;
}

/// Minimum time the splash stays visible so its animation can play, even
/// when data loads instantly. Overridable in tests.
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1400),
);

/// Pure helper: how much longer the splash must stay visible.
Duration remainingSplashDelay(Duration elapsed, Duration minDuration) =>
    elapsed >= minDuration ? Duration.zero : minDuration - elapsed;

/// Loads everything the app needs before showing real UI: warms the DB,
/// reads settings, loads bundled content, and initializes reminders.
///
/// Reminders are non-critical: some emulators/devices cannot initialize the
/// notification plugin (e.g. no Google Play). The app must still boot, so
/// failures there are swallowed.
final bootstrapProvider = FutureProvider<AppBootstrapState>((ref) async {
  final started = DateTime.now();

  await Future.wait<Object?>([
    // Warm the database connection so the first screen doesn't stall on it.
    ref.read(appDatabaseProvider).customSelect('SELECT 1').get(),
    ref.read(settingsRepositoryProvider).get(),
    ref.read(contentProvider.future),
  ]);

  try {
    await ref.read(reminderServiceProvider).initialize();
    // Requested without awaiting so a system permission dialog can never
    // block startup; reminders keep working once permission is granted.
    final reminders = ref.read(reminderServiceProvider);
    unawaited(reminders.requestPermission().catchError((Object e) {}));
    final route = reminders.initialRoute();
    if (route != null) {
      ref.read(pendingRouteProvider.notifier).state = route;
    }
  } catch (_) {
    // Non-critical: keep booting without notifications.
  }

  await Future<void>.delayed(
    remainingSplashDelay(
      DateTime.now().difference(started),
      ref.read(splashMinDurationProvider),
    ),
  );
  return const AppBootstrapState(ready: true);
});
