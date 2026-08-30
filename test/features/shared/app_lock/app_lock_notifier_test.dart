import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/app_lock_notifier.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';
import 'package:nurture/features/shared/app_lock/pin_hash.dart';

void main() {
  late AppDatabase db;

  ProviderContainer makeContainer({AuthService? auth}) {
    db = AppDatabase(NativeDatabase.memory());
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(auth ?? AlwaysAllowAuthService()),
      ],
    );
  }

  tearDown(() => db.close());

  Future<void> enablePin(ProviderContainer container, String pin) async {
    final salt = PinHash.generateSalt();
    await container
        .read(settingsRepositoryProvider)
        .update(
          SettingsRowsCompanion(
            lockEnabled: const Value(true),
            pinHash: Value(PinHash.hash(pin, salt)),
            pinSalt: Value(salt),
          ),
        );
  }

  test('starts unlocked when lock disabled', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(appLockNotifierProvider.notifier).syncFromSettings();
    expect(container.read(appLockNotifierProvider).isLocked, isFalse);
  });

  test('locks on startup when enabled, unlocks with correct pin', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await enablePin(container, '1234');
    await container.read(appLockNotifierProvider.notifier).syncFromSettings();
    expect(container.read(appLockNotifierProvider).isLocked, isTrue);

    final ok = await container
        .read(appLockNotifierProvider.notifier)
        .verifyPin('1234');
    expect(ok, isTrue);
    expect(container.read(appLockNotifierProvider).isLocked, isFalse);
  });

  test('wrong pin stays locked', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await enablePin(container, '1234');
    await container.read(appLockNotifierProvider.notifier).syncFromSettings();
    final ok = await container
        .read(appLockNotifierProvider.notifier)
        .verifyPin('0000');
    expect(ok, isFalse);
    expect(container.read(appLockNotifierProvider).isLocked, isTrue);
  });

  test('biometric unlock works when available', () async {
    final container = makeContainer(auth: AlwaysAllowAuthService());
    addTearDown(container.dispose);
    await enablePin(container, '1234');
    await container.read(appLockNotifierProvider.notifier).syncFromSettings();
    final ok = await container
        .read(appLockNotifierProvider.notifier)
        .unlockWithBiometric();
    expect(ok, isTrue);
    expect(container.read(appLockNotifierProvider).isLocked, isFalse);
  });

  test('lock() re-locks the app', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await enablePin(container, '1234');
    await container.read(appLockNotifierProvider.notifier).syncFromSettings();
    await container.read(appLockNotifierProvider.notifier).verifyPin('1234');
    container.read(appLockNotifierProvider.notifier).lock();
    expect(container.read(appLockNotifierProvider).isLocked, isTrue);
  });

  test('biometric unlock fails when unavailable', () async {
    final container = makeContainer(
      auth: AlwaysAllowAuthService(available: false),
    );
    addTearDown(container.dispose);
    await enablePin(container, '1234');
    await container.read(appLockNotifierProvider.notifier).syncFromSettings();
    final ok = await container
        .read(appLockNotifierProvider.notifier)
        .unlockWithBiometric();
    expect(ok, isFalse);
    expect(container.read(appLockNotifierProvider).isLocked, isTrue);
  });
}
