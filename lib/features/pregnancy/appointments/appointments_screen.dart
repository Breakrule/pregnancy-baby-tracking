import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/motion/pressable.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/appointment_repository.dart';
import 'appointment_types.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  static String formatWhen(DateTime utc) {
    final local = utc.toLocal();
    return '${DateFormat('EEE, MMM d').format(local)} · '
        '${DateFormat('HH:mm').format(local)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final pastAsync = ref.watch(pastAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appointmentsTitle)),
      floatingActionButton: PressableScale(
        child: FloatingActionButton(
          onPressed: () => context.push('/track/appointments/new'),
          child: const Icon(Icons.add),
        ),
      ),
      body: upcomingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (upcoming) => pastAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
          data: (past) => ListView(
            children: [
              _sectionHeader(context, context.l10n.appointmentsUpcomingSection),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.appointmentsNoUpcoming),
                )
              else
                for (final appt in upcoming) _UpcomingTile(appt: appt),
              _sectionHeader(context, context.l10n.appointmentsPastSection),
              if (past.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.appointmentsNoPast),
                )
              else
                for (final appt in past) _PastTile(appt: appt),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _UpcomingTile extends ConsumerWidget {
  const _UpcomingTile({required this.appt});

  final Appointment appt;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(AppointmentRepository) action,
  ) async {
    await action(ref.read(appointmentRepositoryProvider));
    await ref.read(reminderServiceProvider).cancelAppointment(appt.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(appointmentTypeLabel(sheetContext, appt.type)),
              subtitle: Text(AppointmentsScreen.formatWhen(appt.at)),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(sheetContext.l10n.appointmentsMarkCompleted),
              onTap: () => _setStatus(
                sheetContext,
                ref,
                (repo) => repo.markCompleted(appt.id),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: Text(sheetContext.l10n.appointmentsCancelVisit),
              onTap: () =>
                  _setStatus(sheetContext, ref, (repo) => repo.cancel(appt.id)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: ValueKey('appointment-${appt.id}'),
      leading: const Icon(Icons.event),
      title: Text(appointmentTypeLabel(context, appt.type)),
      subtitle: Text(
        [
          AppointmentsScreen.formatWhen(appt.at),
          if ((appt.provider ?? '').isNotEmpty) appt.provider!,
          if ((appt.location ?? '').isNotEmpty) appt.location!,
        ].join('\n'),
      ),
      isThreeLine: true,
      onTap: () => _showActions(context, ref),
    );
  }
}

class _PastTile extends StatelessWidget {
  const _PastTile({required this.appt});

  final Appointment appt;

  @override
  Widget build(BuildContext context) {
    final label = switch (appt.status) {
      AppointmentStatus.completed => context.l10n.appointmentsStatusCompleted,
      AppointmentStatus.cancelled => context.l10n.appointmentsStatusCancelled,
      AppointmentStatus.upcoming => context.l10n.appointmentsStatusMissed,
    };
    return ListTile(
      key: ValueKey('appointment-past-${appt.id}'),
      leading: const Icon(Icons.history),
      title: Text(appointmentTypeLabel(context, appt.type)),
      subtitle: Text('${AppointmentsScreen.formatWhen(appt.at)} · $label'),
    );
  }
}
