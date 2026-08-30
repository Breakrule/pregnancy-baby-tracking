import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'repositories/pregnancy_repository.dart';
import 'repositories/settings_repository.dart';
import '../features/shared/app_lock/auth_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final pregnancyRepositoryProvider = Provider<PregnancyRepository>((ref) {
  return PregnancyRepository(ref.watch(appDatabaseProvider));
});

/// The active pregnancy record; null means the user has not completed setup.
final activePregnancyProvider = StreamProvider<Pregnancy?>((ref) {
  return ref.watch(pregnancyRepositoryProvider).watchActive();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final settingsProvider = FutureProvider<SettingsRow>((ref) {
  return ref.watch(settingsRepositoryProvider).get();
});

final authServiceProvider = Provider<AuthService>(
  (ref) => LocalAuthServiceImpl(),
);
