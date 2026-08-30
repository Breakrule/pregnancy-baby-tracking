import 'package:drift/drift.dart' hide isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/units.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import '../../../domain/gestational/gestational_calculator.dart';
import '../app_lock/app_lock_notifier.dart';
import '../app_lock/pin_hash.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];

  // ── Unit mapping helpers ──────────────────────────────────────────────

  WeightDisplay _toWeightDisplay(WeightUnit u) => switch (u) {
    WeightUnit.kg => WeightDisplay.kg,
    WeightUnit.lb => WeightDisplay.lb,
  };

  WeightUnit _fromWeightDisplay(WeightDisplay d) => switch (d) {
    WeightDisplay.kg => WeightUnit.kg,
    WeightDisplay.lb => WeightUnit.lb,
  };

  LengthDisplay _toLengthDisplay(LengthUnit u) => switch (u) {
    LengthUnit.cm => LengthDisplay.cm,
    LengthUnit.inch => LengthDisplay.inch,
  };

  LengthUnit _fromLengthDisplay(LengthDisplay d) => switch (d) {
    LengthDisplay.cm => LengthUnit.cm,
    LengthDisplay.inch => LengthUnit.inch,
  };

  GlucoseDisplay _toGlucoseDisplay(GlucoseUnit u) => switch (u) {
    GlucoseUnit.mgdl => GlucoseDisplay.mgdl,
    GlucoseUnit.mmoll => GlucoseDisplay.mmoll,
  };

  GlucoseUnit _fromGlucoseDisplay(GlucoseDisplay d) => switch (d) {
    GlucoseDisplay.mgdl => GlucoseUnit.mgdl,
    GlucoseDisplay.mmoll => GlucoseUnit.mmoll,
  };

  // ── PIN dialogs ───────────────────────────────────────────────────────

  Future<String?> _pinDialog({required String title}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<String?> _promptNewPin() async {
    String? first;
    String? second;
    while (second == null) {
      if (!mounted) return null;
      first = await _pinDialog(
        title: first == null
            ? 'Choose a 6-digit PIN'
            : 'PINs did not match. Try again',
      );
      if (first == null) return null;
      if (!RegExp(r'^\d{6}$').hasMatch(first)) {
        // Invalid format — re-prompt.
        continue;
      }
      if (!mounted) return null;
      second = await _pinDialog(title: 'Repeat the PIN');
      if (second == null) return null;
      if (first != second) {
        second = null;
      }
    }
    return first;
  }

  Future<String?> _promptVerifyPin() async {
    while (true) {
      if (!mounted) return null;
      final pin = await _pinDialog(title: 'Enter your current PIN');
      if (pin == null) return null;
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) continue;
      return pin;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _onWeightChanged(WeightDisplay value) async {
    await ref
        .read(settingsRepositoryProvider)
        .update(
          SettingsRowsCompanion(weightUnit: Value(_fromWeightDisplay(value))),
        );
    ref.invalidate(settingsProvider);
  }

  Future<void> _onLengthChanged(LengthDisplay value) async {
    await ref
        .read(settingsRepositoryProvider)
        .update(
          SettingsRowsCompanion(lengthUnit: Value(_fromLengthDisplay(value))),
        );
    ref.invalidate(settingsProvider);
  }

  Future<void> _onGlucoseChanged(GlucoseDisplay value) async {
    await ref
        .read(settingsRepositoryProvider)
        .update(
          SettingsRowsCompanion(glucoseUnit: Value(_fromGlucoseDisplay(value))),
        );
    ref.invalidate(settingsProvider);
  }

  bool _isTogglingLock = false;

  Future<void> _toggleLock(bool currentEnabled) async {
    if (_isTogglingLock) return;
    _isTogglingLock = true;
    var succeeded = false;
    try {
      if (!currentEnabled) {
        // Enabling lock — prompt for new PIN.
        final pin = await _promptNewPin();
        if (pin == null) return;
        final salt = PinHash.generateSalt();
        final hash = PinHash.hash(pin, salt);
        await ref
            .read(settingsRepositoryProvider)
            .update(
              SettingsRowsCompanion(
                lockEnabled: const Value(true),
                pinHash: Value(hash),
                pinSalt: Value(salt),
              ),
            );
        ref.invalidate(settingsProvider);
        await ref.read(appLockNotifierProvider.notifier).syncFromSettings();
        succeeded = true;
      } else {
        // Disabling lock — verify current PIN first.
        final settings = await ref.read(settingsRepositoryProvider).get();
        final storedSalt = settings.pinSalt;
        final storedHash = settings.pinHash;
        if (storedSalt == null || storedHash == null) return;

        final pin = await _promptVerifyPin();
        if (pin == null) return;
        if (!PinHash.verify(pin, storedSalt, storedHash)) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
          }
          return;
        }

        await ref
            .read(settingsRepositoryProvider)
            .update(
              SettingsRowsCompanion(
                lockEnabled: const Value(false),
                pinHash: const Value(null),
                pinSalt: const Value(null),
              ),
            );
        ref.invalidate(settingsProvider);
        await ref.read(appLockNotifierProvider.notifier).syncFromSettings();
        succeeded = true;
      }
    } finally {
      _isTogglingLock = false;
      if (!succeeded) ref.invalidate(settingsProvider);
    }
  }

  Future<void> _editPregnancyDetails(Pregnancy active) async {
    final dueDateController = TextEditingController();
    final bloodTypeController = TextEditingController(
      text: active.bloodType ?? '',
    );
    final clinicNameController = TextEditingController(
      text: active.clinicName ?? '',
    );
    final clinicPhoneController = TextEditingController(
      text: active.clinicPhone ?? '',
    );
    final hospitalNameController = TextEditingController(
      text: active.hospitalName ?? '',
    );
    final hospitalAddressController = TextEditingController(
      text: active.hospitalAddress ?? '',
    );

    DateTime? selectedDueDate = active.dueDate;
    dueDateController.text = _formatDate(selectedDueDate);

    final result =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              title: const Text('Pregnancy details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        dueDateController.text.isEmpty
                            ? 'Select due date'
                            : dueDateController.text,
                      ),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDueDate = picked;
                            dueDateController.text = _formatDate(picked);
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _bloodTypes.contains(bloodTypeController.text)
                          ? bloodTypeController.text
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Blood type',
                      ),
                      items: _bloodTypes
                          .map(
                            (bt) =>
                                DropdownMenuItem(value: bt, child: Text(bt)),
                          )
                          .toList(),
                      onChanged: (v) => bloodTypeController.text = v ?? '',
                    ),
                    TextField(
                      controller: clinicNameController,
                      decoration: const InputDecoration(
                        labelText: 'Clinic name',
                      ),
                    ),
                    TextField(
                      controller: clinicPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Clinic phone',
                      ),
                    ),
                    TextField(
                      controller: hospitalNameController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital name',
                      ),
                    ),
                    TextField(
                      controller: hospitalAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital address',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ).whenComplete(() {
          dueDateController.dispose();
          bloodTypeController.dispose();
          clinicNameController.dispose();
          clinicPhoneController.dispose();
          hospitalNameController.dispose();
          hospitalAddressController.dispose();
        });

    if (result == true && selectedDueDate != null) {
      final newLmp = GestationalCalculator.lmpFromDueDate(selectedDueDate!);
      await ref
          .read(pregnancyRepositoryProvider)
          .update(
            PregnanciesCompanion(
              id: Value(active.id),
              dueDate: Value(selectedDueDate!),
              lmpDate: Value(newLmp),
              bloodType: Value(
                bloodTypeController.text.isEmpty
                    ? null
                    : bloodTypeController.text,
              ),
              clinicName: Value(
                clinicNameController.text.isEmpty
                    ? null
                    : clinicNameController.text,
              ),
              clinicPhone: Value(
                clinicPhoneController.text.isEmpty
                    ? null
                    : clinicPhoneController.text,
              ),
              hospitalName: Value(
                hospitalNameController.text.isEmpty
                    ? null
                    : hospitalNameController.text,
              ),
              hospitalAddress: Value(
                hospitalAddressController.text.isEmpty
                    ? null
                    : hospitalAddressController.text,
              ),
            ),
          );
      ref.invalidate(activePregnancyProvider);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final pregnancyAsync = ref.watch(activePregnancyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          children: [
            // ── Units section ────────────────────────────────────────
            const _SectionHeader('Units'),
            DropdownButtonFormField<WeightDisplay>(
              key: const Key('weight-unit-dropdown'),
              initialValue: _toWeightDisplay(settings.weightUnit),
              decoration: const InputDecoration(labelText: 'Weight'),
              items: const [
                DropdownMenuItem(value: WeightDisplay.kg, child: Text('kg')),
                DropdownMenuItem(value: WeightDisplay.lb, child: Text('lb')),
              ],
              onChanged: (v) {
                if (v != null) _onWeightChanged(v);
              },
            ).withPadding(),
            DropdownButtonFormField<LengthDisplay>(
              key: const Key('length-unit-dropdown'),
              initialValue: _toLengthDisplay(settings.lengthUnit),
              decoration: const InputDecoration(labelText: 'Length / Height'),
              items: const [
                DropdownMenuItem(value: LengthDisplay.cm, child: Text('cm')),
                DropdownMenuItem(value: LengthDisplay.inch, child: Text('in')),
              ],
              onChanged: (v) {
                if (v != null) _onLengthChanged(v);
              },
            ).withPadding(),
            DropdownButtonFormField<GlucoseDisplay>(
              key: const Key('glucose-unit-dropdown'),
              initialValue: _toGlucoseDisplay(settings.glucoseUnit),
              decoration: const InputDecoration(labelText: 'Glucose'),
              items: const [
                DropdownMenuItem(
                  value: GlucoseDisplay.mgdl,
                  child: Text('mg/dL'),
                ),
                DropdownMenuItem(
                  value: GlucoseDisplay.mmoll,
                  child: Text('mmol/L'),
                ),
              ],
              onChanged: (v) {
                if (v != null) _onGlucoseChanged(v);
              },
            ).withPadding(),

            // ── App lock section ─────────────────────────────────────
            const _SectionHeader('Security'),
            SwitchListTile(
              key: const Key('app-lock-switch'),
              title: const Text('App lock'),
              subtitle: Text(
                settings.lockEnabled ? 'PIN protection enabled' : 'Off',
              ),
              value: settings.lockEnabled,
              onChanged: (_) => _toggleLock(settings.lockEnabled),
            ),

            // ── Pregnancy details section ────────────────────────────
            const _SectionHeader('Pregnancy'),
            pregnancyAsync.when(
              loading: () => const ListTile(title: Text('Loading...')),
              error: (e, _) => ListTile(title: Text('Error: $e')),
              data: (active) {
                if (active == null) {
                  return const ListTile(
                    title: Text('Pregnancy details'),
                    subtitle: Text('Complete setup first'),
                    enabled: false,
                  );
                }
                return ListTile(
                  title: const Text('Pregnancy details'),
                  subtitle: Text('Due: ${_formatDate(active.dueDate)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editPregnancyDetails(active),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

extension on Widget {
  Widget withPadding() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: this,
  );
}
