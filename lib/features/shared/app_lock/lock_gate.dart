import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_notifier.dart';
import 'lock_screen.dart';

/// Shows [LockScreen] over the app while locked, and re-locks
/// automatically when the app goes to the background.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLockNotifierProvider.notifier).syncFromSettings();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(appLockNotifierProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockNotifierProvider);
    return lockState.isLocked ? const LockScreen() : widget.child;
  }
}
