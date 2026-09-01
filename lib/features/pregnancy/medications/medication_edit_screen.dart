import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../data/providers.dart';

class MedicationEditScreen extends ConsumerStatefulWidget {
  const MedicationEditScreen({super.key});

  @override
  ConsumerState<MedicationEditScreen> createState() =>
      _MedicationEditScreenState();
}

class _MedicationEditScreenState extends ConsumerState<MedicationEditScreen> {
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  late DateTime _startDate;
  TimeOfDay? _reminderTime;
  bool _saving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().toUtc();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  String _formatReminder(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.medicationNameError);
      return;
    }

    setState(() {
      _nameError = null;
      _saving = true;
    });
    try {
      final dose = _doseController.text.trim();
      final reminder = _reminderTime;

      final id = await ref
          .read(medicationRepositoryProvider)
          .add(
            name: name,
            dose: dose.isEmpty ? null : dose,
            reminderTime: reminder == null ? null : _formatReminder(reminder),
            startDate: _startDate,
          );

      if (reminder != null) {
        await ref
            .read(reminderServiceProvider)
            .scheduleDailyMedication(
              medicationId: id,
              name: name,
              dose: dose,
              hour: reminder.hour,
              minute: reminder.minute,
            );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addMedicationTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('med-name-field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.medicationNameLabel,
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doseController,
              decoration: InputDecoration(
                labelText: context.l10n.medicationDoseOptional,
                border: const OutlineInputBorder(),
                hintText: context.l10n.medicationDoseHint,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
              ),
              subtitle: Text(context.l10n.medicationStartDate),
              onTap: _pickStartDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: Text(
                _reminderTime == null
                    ? context.l10n.medicationNoReminder
                    : context.l10n.medicationReminderAt(
                        _formatReminder(_reminderTime!),
                      ),
              ),
              subtitle: Text(context.l10n.medicationSetReminder),
              trailing: _reminderTime == null
                  ? null
                  : IconButton(
                      tooltip: context.l10n.medicationRemoveReminderTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _reminderTime = null),
                    ),
              onTap: _pickReminderTime,
            ),
            const SizedBox(height: 24),
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
