import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/motion/pressable.dart';
import '../../../data/db/app_database.dart';
import '../../../data/providers.dart';

/// Whether [medicationId] has been taken today; recomputes when any dose is
/// logged or unlogged.
final medTakenTodayProvider = FutureProvider.family<bool, int>((
  ref,
  medicationId,
) async {
  ref.watch(medLogsProvider);
  return ref
      .watch(medicationRepositoryProvider)
      .takenToday(medicationId, DateTime.now());
});

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(activeMedsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.medicationsTitle)),
      floatingActionButton: PressableScale(
        child: FloatingActionButton(
          onPressed: () => context.push('/track/medications/new'),
          child: const Icon(Icons.add),
        ),
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (meds) {
          if (meds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.medicationsNoEntries,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            children: meds.map((med) => _MedTile(med: med)).toList(),
          );
        },
      ),
    );
  }
}

class _MedTile extends ConsumerWidget {
  const _MedTile({required this.med});

  final Medication med;

  Future<void> _toggleTaken(WidgetRef ref, bool taken) async {
    final repo = ref.read(medicationRepositoryProvider);
    if (taken) {
      await repo.untakeToday(med.id, DateTime.now());
    } else {
      await repo.logTaken(med.id, DateTime.now().toUtc());
    }
  }

  Future<void> _deactivate(BuildContext context, WidgetRef ref) async {
    await ref.read(medicationRepositoryProvider).setActive(med.id, false);
    await ref.read(reminderServiceProvider).cancelMedication(med.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takenAsync = ref.watch(medTakenTodayProvider(med.id));

    return CheckboxListTile(
      key: ValueKey('med-${med.id}'),
      value: takenAsync.valueOrNull ?? false,
      onChanged: takenAsync.hasValue
          ? (v) => _toggleTaken(ref, v ?? false)
          : null,
      title: Text(med.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((med.dose ?? '').isNotEmpty) Text(med.dose!),
          if (med.reminderTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.alarm, size: 14),
                  const SizedBox(width: 4),
                  Text(context.l10n.medicationReminderAt(med.reminderTime!)),
                ],
              ),
            ),
        ],
      ),
      secondary: IconButton(
        tooltip: context.l10n.medicationStopTooltip,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _deactivate(context, ref),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
