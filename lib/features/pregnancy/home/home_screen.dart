import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/motion/entrance.dart';
import '../../../core/motion/pressable.dart';
import '../../../data/db/app_database.dart';
import '../../../data/providers.dart';
import 'hero_card.dart';

/// Counts how many active medications have been taken today. Null [taken]
/// means there are no medications at all. Locale-neutral: the UI formats it.
class MedsTakenSummary {
  const MedsTakenSummary({required this.taken, required this.total});

  final int? taken;
  final int total;
}

/// Today-card summary of active medications. Keyed by the screen clock so
/// tests can pin "today".
final medsDueTodayProvider =
    Provider.family<AsyncValue<MedsTakenSummary>, DateTime>((ref, now) {
      final medsAsync = ref.watch(activeMedsProvider);
      final logsAsync = ref.watch(medLogsProvider);

      return medsAsync.when(
        loading: () => const AsyncLoading<MedsTakenSummary>(),
        error: (e, st) => AsyncError<MedsTakenSummary>(e, st),
        data: (meds) => logsAsync.when(
          loading: () => const AsyncLoading<MedsTakenSummary>(),
          error: (e, st) => AsyncError<MedsTakenSummary>(e, st),
          data: (logs) {
            if (meds.isEmpty) {
              return const AsyncData(MedsTakenSummary(taken: null, total: 0));
            }
            final taken = meds.where((med) {
              return logs.any((log) {
                final local = log.takenAt.toLocal();
                return log.medicationId == med.id &&
                    local.year == now.year &&
                    local.month == now.month &&
                    local.day == now.day;
              });
            }).length;
            return AsyncData(
              MedsTakenSummary(taken: taken, total: meds.length),
            );
          },
        ),
      );
    });

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key, DateTime? now}) : now = now ?? DateTime.now();

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyAsync = ref.watch(activePregnancyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeTitle)),
      body: pregnancyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (pregnancy) {
          if (pregnancy == null) {
            return Center(child: Text(context.l10n.homeNoActivePregnancy));
          }
          return _buildContent(context, ref, pregnancy);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Pregnancy pregnancy,
  ) {
    final nextApptAsync = ref.watch(nextAppointmentProvider);
    final medsLineAsync = ref.watch(medsDueTodayProvider(now));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: staggerChildren([
          // 1. Hero card
          HeroCard(pregnancy: pregnancy, now: now),

          // 2. Today card
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeToday,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    nextApptAsync.when(
                      loading: () => Text(context.l10n.homeLoadingAppointments),
                      error: (e, _) => Text(context.l10n.commonError('$e')),
                      data: (appt) {
                        if (appt == null) {
                          return Text(context.l10n.homeNoUpcomingAppointments);
                        }
                        final local = appt.at.toLocal();
                        return Text(
                          context.l10n.homeNextAppointment(
                            appt.type,
                            DateFormat('EEE, MMM d').format(local),
                            DateFormat('HH:mm').format(local),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    medsLineAsync.when(
                      loading: () => Text(context.l10n.homeLoadingMedications),
                      error: (e, _) => Text(context.l10n.commonError('$e')),
                      data: (summary) {
                        if (summary.taken == null) {
                          return Text(context.l10n.homeNoMedications);
                        }
                        if (summary.taken == summary.total) {
                          return Text(context.l10n.homeAllMedicationsTaken);
                        }
                        return Text(
                          context.l10n.homeMedicationsTaken(
                            summary.taken!,
                            summary.total,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Quick actions row
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Row(
              children: [
                Expanded(
                  child: PressableScale(
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.go('/track/weight/new'),
                      icon: const Icon(Icons.scale),
                      label: Text(context.l10n.homeQuickWeight),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressableScale(
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.go('/track/symptoms/new'),
                      icon: const Icon(Icons.assignment),
                      label: Text(context.l10n.homeQuickSymptom),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressableScale(
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.go('/track/appointments/new'),
                      icon: const Icon(Icons.event),
                      label: Text(context.l10n.homeQuickAppointment),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Belly-photos shortcut
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: PressableScale(
              child: FilledButton.tonalIcon(
                key: const Key('home-belly-photos-button'),
                onPressed: () => context.go('/photos/belly'),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(context.l10n.homeBellyPhotos),
              ),
            ),
          ),

          // 5. Red-flags shortcut
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: PressableScale(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/learn/danger-signs'),
                icon: const Icon(Icons.warning_amber),
                label: Text(context.l10n.homeWhenToCallProvider),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
