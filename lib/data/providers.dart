import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../content/models.dart';
import '../content/providers.dart';
import '../domain/alerts/alert_engine.dart';
import '../domain/alerts/symptom_rules.dart';
import '../features/shared/photos/photo_service.dart';
import '../features/shared/reminders/reminder_service.dart';
import 'backup/backup_service.dart';
import 'db/app_database.dart';
import 'db/tables.dart';
import 'repositories/appointment_repository.dart';
import 'repositories/medication_repository.dart';
import 'repositories/photo_repository.dart';
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

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(ref.watch(appDatabaseProvider));
});

/// Active medications, ordered by name.
final activeMedsProvider = StreamProvider<List<Medication>>((ref) {
  return ref.watch(medicationRepositoryProvider).watchActiveMeds();
});

/// All medication logs; watching this lets derived values (e.g. the home
/// "medications taken" count) refresh when a dose is logged.
final medLogsProvider = StreamProvider<List<MedLog>>((ref) {
  return ref.watch(medicationRepositoryProvider).watchLogs();
});

/// Always overridden in main() with an initialized ReminderService.
/// Throwing here surfaces missing wiring loudly instead of silently
/// scheduling nothing.
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => throw UnimplementedError(
    'reminderServiceProvider must be overridden in main',
  ),
);

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(appDatabaseProvider));
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(appDatabaseProvider));
});

/// Photo files live in app-private storage (not Documents), so the media
/// scanner and other apps never see them.
final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService(
    ImagePicker(),
    () async {
      final dir = await getApplicationSupportDirectory();
      return Directory(p.join(dir.path, 'photos'));
    },
  );
});

/// Photos of one category, oldest first.
final photosProvider =
    StreamProvider.family<List<Photo>, PhotoCategory>((ref, category) {
      return ref.watch(photoRepositoryProvider).watchByCategory(category);
    });

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

/// Open appointments from now onward, soonest first.
final upcomingAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchUpcoming(DateTime.now());
});

/// Past and closed appointments, most recent first.
final pastAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchPast(DateTime.now());
});

/// The soonest open appointment, or null — shown on the home Today card.
final nextAppointmentProvider = StreamProvider<Appointment?>((ref) {
  return ref
      .watch(appointmentRepositoryProvider)
      .watchUpcoming(DateTime.now())
      .map((list) => list.isEmpty ? null : list.first);
});
