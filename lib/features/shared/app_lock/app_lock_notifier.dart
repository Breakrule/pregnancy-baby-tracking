import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/settings_repository.dart';
import 'pin_hash.dart';

class AppLockState {
  const AppLockState({
    required this.isLocked,
    required this.lockEnabled,
    this.synced = true,
  });

  /// Before settings are read once at startup we are NOT synced; the gate
  /// must not show protected content until then.
  const AppLockState.booting()
    : this(isLocked: true, lockEnabled: false, synced: false);

  final bool isLocked;
  final bool lockEnabled;
  final bool synced;
}

class AppLockNotifier extends Notifier<AppLockState> {
  @override
  AppLockState build() => const AppLockState.booting();

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  /// Called once at startup: locks the app if a PIN is configured.
  Future<void> syncFromSettings() async {
    final row = await _settings.get();
    state = AppLockState(
      isLocked: row.lockEnabled,
      lockEnabled: row.lockEnabled,
    );
  }

  Future<bool> verifyPin(String pin) async {
    final row = await _settings.get();
    final salt = row.pinSalt;
    final hash = row.pinHash;
    if (salt == null || hash == null) return false;
    if (!PinHash.verify(pin, salt, hash)) return false;
    state = AppLockState(isLocked: false, lockEnabled: true);
    return true;
  }

  Future<bool> unlockWithBiometric() async {
    final auth = ref.read(authServiceProvider);
    if (!await auth.isBiometricAvailable()) return false;
    if (!await auth.authenticate()) return false;
    state = AppLockState(isLocked: false, lockEnabled: true);
    return true;
  }

  void lock() {
    if (state.lockEnabled) {
      state = AppLockState(isLocked: true, lockEnabled: true);
    }
  }
}

final appLockNotifierProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
