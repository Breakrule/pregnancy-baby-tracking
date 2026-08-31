import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/models.dart';
import '../content/providers.dart';
import '../domain/alerts/alert_engine.dart';
import '../domain/alerts/symptom_rules.dart';
import 'db/app_database.dart';
import 'repositories/pregnancy_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/symptom_repository.dart';
import 'repositories/weight_repository.dart';
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

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepository(ref.watch(appDatabaseProvider));
});

final symptomsStreamProvider = StreamProvider<List<Symptom>>((ref) {
  return ref.watch(symptomRepositoryProvider).watchAll();
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(ref.watch(appDatabaseProvider));
});

final weightsStreamProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(weightRepositoryProvider).watchAll();
});

// Safe to use valueOrNull: SymptomEntryScreen gates on contentProvider's
// loading/error states and only exposes Save once data has loaded.
final alertEngineProvider = Provider<AlertEngine>((ref) {
  final bundle = ref.watch(contentProvider).valueOrNull;
  final flags = <String, String>{
    for (final f in bundle?.redFlags ?? const <RedFlag>[]) f.key: f.message,
  };
  return AlertEngine([SymptomRedFlagRule(redFlagMessages: flags).rule]);
});
