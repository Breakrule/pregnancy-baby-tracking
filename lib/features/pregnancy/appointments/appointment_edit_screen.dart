import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../data/providers.dart';
import 'appointment_types.dart';

class AppointmentEditScreen extends ConsumerStatefulWidget {
  const AppointmentEditScreen({super.key});

  @override
  ConsumerState<AppointmentEditScreen> createState() =>
      _AppointmentEditScreenState();
}

class _AppointmentEditScreenState extends ConsumerState<AppointmentEditScreen> {
  late DateTime _when;
  String _type = appointmentTypeKeys.first;
  final _providerController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _when = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  @override
  void dispose() {
    _providerController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _when = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _when.hour,
          _when.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (picked != null) {
      setState(() {
        _when = DateTime(
          _when.year,
          _when.month,
          _when.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final atUtc = _when.toUtc();
      String? trimOrNull(TextEditingController c) {
        final v = c.text.trim();
        return v.isEmpty ? null : v;
      }

      // Resolve the localized type before the awaits below (context use
      // across async gaps is not allowed).
      final typeLabel = appointmentTypeLabel(context, _type);

      final id = await ref
          .read(appointmentRepositoryProvider)
          .add(
            at: atUtc,
            type: _type,
            provider: trimOrNull(_providerController),
            location: trimOrNull(_locationController),
            notes: trimOrNull(_notesController),
          );

      await ref
          .read(reminderServiceProvider)
          .scheduleAppointment(
            appointmentId: id,
            type: typeLabel,
            at: atUtc,
          );

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addAppointmentTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('appointment-type-field'),
              initialValue: _type,
              decoration: InputDecoration(
                labelText: context.l10n.appointmentTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final t in appointmentTypeKeys)
                  DropdownMenuItem(
                    value: t,
                    child: Text(appointmentTypeLabel(context, t)),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('EEE, MMM d').format(_when)),
                    subtitle: Text(context.l10n.dateLabel),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(DateFormat('HH:mm').format(_when)),
                    subtitle: Text(context.l10n.timeLabel),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _providerController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.providerOptional,
                border: const OutlineInputBorder(),
                hintText: context.l10n.providerHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.locationOptional,
                border: const OutlineInputBorder(),
                hintText: context.l10n.locationHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.notesOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.apptReminderNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
