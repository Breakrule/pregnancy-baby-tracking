import 'package:drift/drift.dart' hide isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
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
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l10n.commonOk),
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
            ? context.l10n.pinChooseTitle
            : context.l10n.pinMismatchTitle,
      );
      if (first == null) return null;
      if (!RegExp(r'^\d{6}$').hasMatch(first)) {
        // Invalid format — re-prompt.
        continue;
      }
      if (!mounted) return null;
      second = await _pinDialog(title: context.l10n.pinRepeatTitle);
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
      final pin = await _pinDialog(title: context.l10n.pinEnterCurrentTitle);
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
            ).showSnackBar(SnackBar(content: Text(context.l10n.pinIncorrect)));
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

  Future<void> _onLocaleChanged(String value) async {
    await ref
        .read(settingsRepositoryProvider)
        .update(SettingsRowsCompanion(locale: Value(value)));
    ref.invalidate(settingsProvider);
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
              title: Text(context.l10n.settingsPregnancyDetails),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        dueDateController.text.isEmpty
                            ? context.l10n.settingsSelectDueDate
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
                      decoration: InputDecoration(
                        labelText: context.l10n.setupBloodType,
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
                      decoration: InputDecoration(
                        labelText: context.l10n.setupClinicName,
                      ),
                    ),
                    TextField(
                      controller: clinicPhoneController,
                      decoration: InputDecoration(
                        labelText: context.l10n.setupClinicPhone,
                      ),
                    ),
                    TextField(
                      controller: hospitalNameController,
                      decoration: InputDecoration(
                        labelText: context.l10n.setupHospitalName,
                      ),
                    ),
                    TextField(
                      controller: hospitalAddressController,
                      decoration: InputDecoration(
                        labelText: context.l10n.setupHospitalAddress,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.l10n.commonSave),
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
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (settings) => ListView(
          children: [
            // ── Language section ─────────────────────────────────────
            _SectionHeader(context.l10n.settingsLanguageSection),
            RadioGroup<String>(
              groupValue: settings.locale,
              onChanged: (v) {
                if (v != null) _onLocaleChanged(v);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    key: const Key('language-en'),
                    title: Text(context.l10n.languageEnglish),
                    value: 'en',
                  ),
                  RadioListTile<String>(
                    key: const Key('language-id'),
                    title: Text(context.l10n.languageIndonesian),
                    value: 'id',
                  ),
                ],
              ),
            ),

            // ── Units section ────────────────────────────────────────
            _SectionHeader(context.l10n.settingsUnitsSection),
            DropdownButtonFormField<WeightDisplay>(
              key: const Key('weight-unit-dropdown'),
              initialValue: _toWeightDisplay(settings.weightUnit),
              decoration: InputDecoration(
                labelText: context.l10n.settingsWeightUnit,
              ),
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
              decoration: InputDecoration(
                labelText: context.l10n.settingsLengthUnit,
              ),
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
              decoration: InputDecoration(
                labelText: context.l10n.settingsGlucoseUnit,
              ),
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
            _SectionHeader(context.l10n.settingsSecuritySection),
            SwitchListTile(
              key: const Key('app-lock-switch'),
              title: Text(context.l10n.settingsAppLock),
              subtitle: Text(
                settings.lockEnabled
                    ? context.l10n.settingsPinEnabled
                    : context.l10n.settingsOff,
              ),
              value: settings.lockEnabled,
              onChanged: (_) => _toggleLock(settings.lockEnabled),
            ),

            // ── Data section ─────────────────────────────────────────
            _SectionHeader(context.l10n.settingsDataSection),
            ListTile(
              key: const Key('backup-tile'),
              leading: const Icon(Icons.backup),
              title: Text(context.l10n.settingsBackupTitle),
              subtitle: Text(context.l10n.settingsBackupSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/more/settings/backup'),
            ),

            // ── Pregnancy details section ────────────────────────────
            _SectionHeader(context.l10n.settingsPregnancySection),
            pregnancyAsync.when(
              loading: () => ListTile(title: Text(context.l10n.commonLoading)),
              error: (e, _) =>
                  ListTile(title: Text(context.l10n.commonError('$e'))),
              data: (active) {
                if (active == null) {
                  return ListTile(
                    title: Text(context.l10n.settingsPregnancyDetails),
                    subtitle: Text(context.l10n.settingsCompleteSetupFirst),
                    enabled: false,
                  );
                }
                return ListTile(
                  title: Text(context.l10n.settingsPregnancyDetails),
                  subtitle: Text(
                    context.l10n.settingsDueDate(_formatDate(active.dueDate)),
                  ),
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
