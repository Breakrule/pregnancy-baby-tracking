import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

class NurtureApp extends ConsumerWidget {
  const NurtureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Nurture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pregnancy(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
