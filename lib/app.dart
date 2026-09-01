import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'features/shared/app_lock/lock_gate.dart';
import 'features/shared/settings/locale_provider.dart';
import 'features/shared/splash/app_bootstrap.dart';
import 'features/shared/splash/pending_route_provider.dart';
import 'features/shared/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Create a refresh notifier that listens to pregnancy changes.
  // We read the repo directly (not via watch) to avoid making this provider
  // rebuild when the stream emits. The stream subscription is cleaned up
  // via ref.onDispose below.
  final repo = ref.read(pregnancyRepositoryProvider);
  final refresh = RouterRefreshNotifier(repo.watchActive());
  final router = buildRouter(
    hasPregnancy: () => repo.hasActive(),
    refreshListenable: refresh,
  );
  ref.onDispose(router.dispose);
  ref.onDispose(refresh.dispose);
  return router;
});

/// Root widget: shows the animated splash while the bootstrap loads, a
/// retryable error screen if boot fails, and the real app once ready.
class NurtureApp extends ConsumerWidget {
  const NurtureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);
    return bootstrap.when(
      loading: () => const SplashScreen(),
      error: (error, _) => BootstrapErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(bootstrapProvider),
      ),
      data: (_) => const _ReadyApp(),
    );
  }
}

class _ReadyApp extends ConsumerStatefulWidget {
  const _ReadyApp();

  @override
  ConsumerState<_ReadyApp> createState() => _ReadyAppState();
}

class _ReadyAppState extends ConsumerState<_ReadyApp> {
  @override
  void initState() {
    super.initState();
    // Consume a pending deep link (e.g. app launched from a notification)
    // once the router is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ref.read(pendingRouteProvider);
      if (route != null) {
        ref.read(pendingRouteProvider.notifier).state = null;
        ref.read(routerProvider).go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LockGate(
      child: MaterialApp.router(
        title: 'Nurture',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.pregnancy(),
        locale: ref.watch(localeProvider),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
