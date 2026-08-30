import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'features/shared/app_lock/lock_gate.dart';

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

class NurtureApp extends ConsumerWidget {
  const NurtureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LockGate(
      child: MaterialApp.router(
        title: 'Nurture',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.pregnancy(),
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
