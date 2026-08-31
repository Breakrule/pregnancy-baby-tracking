import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/units.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';

class WeightEntryScreen extends ConsumerStatefulWidget {
  const WeightEntryScreen({super.key});

  @override
  ConsumerState<WeightEntryScreen> createState() => _WeightEntryScreenState();
}

class _WeightEntryScreenState extends ConsumerState<WeightEntryScreen> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toUtc();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Validates the weight input and returns the canonical kg value, or null
  /// if invalid. Sets [_errorText] on failure.
  double? _validateAndConvert(String raw, WeightDisplay unit) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null) {
      setState(() => _errorText = 'Enter a valid number');
      return null;
    }

    final kgValue = unit == WeightDisplay.lb
        ? UnitConverter.lbToKg(parsed)
        : parsed;

    if (kgValue < 30 || kgValue > 250) {
      setState(
        () => _errorText =
            'Weight must be between ${UnitConverter.formatWeight(30, unit)} and ${UnitConverter.formatWeight(250, unit)}',
      );
      return null;
    }

    setState(() => _errorText = null);
    return kgValue;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;
    final unit = settings.weightUnit == WeightUnit.lb
        ? WeightDisplay.lb
        : WeightDisplay.kg;

    final kgValue = _validateAndConvert(_weightController.text, unit);
    if (kgValue == null) return;

    setState(() => _saving = true);
    try {
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      await ref
          .read(weightRepositoryProvider)
          .add(date: _selectedDate, weightKg: kgValue, notes: notes);

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Weight')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          final unit = settings.weightUnit == WeightUnit.lb
              ? WeightDisplay.lb
              : WeightDisplay.kg;
          final label = unit == WeightDisplay.lb
              ? 'Weight (lb)'
              : 'Weight (kg)';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  subtitle: const Text('Tap to change date'),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),

                // Weight field
                TextField(
                  key: const Key('weight-field'),
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                  ),
                ),
                const SizedBox(height: 16),

                // Notes field
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Any additional details...',
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
