import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      setState(() => _nameError = 'Enter a medication name');
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
      appBar: AppBar(title: const Text('Add Medication')),
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
                labelText: 'Medication name',
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dose (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. 400 mcg',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
              ),
              subtitle: const Text('Start date'),
              onTap: _pickStartDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: Text(
                _reminderTime == null
                    ? 'No daily reminder'
                    : 'Reminder at ${_formatReminder(_reminderTime!)}',
              ),
              subtitle: const Text('Tap to set a daily reminder'),
              trailing: _reminderTime == null
                  ? null
                  : IconButton(
                      tooltip: 'Remove reminder',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _reminderTime = null),
                    ),
              onTap: _pickReminderTime,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
