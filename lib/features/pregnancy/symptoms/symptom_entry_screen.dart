import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/models.dart';
import '../../../content/providers.dart';
import '../../../core/l10n.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import '../../../domain/alerts/alert.dart';
import '../../../domain/alerts/symptom_rules.dart';

class SymptomEntryScreen extends ConsumerStatefulWidget {
  const SymptomEntryScreen({super.key});

  @override
  ConsumerState<SymptomEntryScreen> createState() => _SymptomEntryScreenState();
}

class _SymptomEntryScreenState extends ConsumerState<SymptomEntryScreen> {
  String? _selectedKey;
  String? _customLabel;
  SymptomSeverity _severity = SymptomSeverity.mild;
  final _notesController = TextEditingController();
  bool _showCustomField = false;
  bool _saving = false;

  /// True when a symptom is selected (or custom text entered) and no save is
  /// in progress. Used by both the Save button's enabled state and as an
  /// early-return guard inside [_save].
  bool get _canSave =>
      !_saving &&
      (_selectedKey != null ||
          (_showCustomField && (_customLabel?.trim().isNotEmpty ?? false)));

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(contentProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.logSymptomTitle)),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (bundle) => _buildBody(bundle),
      ),
    );
  }

  Widget _buildBody(ContentBundle bundle) {
    final presets = bundle.symptomPresets;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Light spotting informational banner
          if (_selectedKey == 'light_spotting')
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.l10n.symptomSpottingInfo)),
                ],
              ),
            ),

          Text(
            context.l10n.symptomFieldLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in presets)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: _selectedKey == preset.key && !_showCustomField,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedKey = preset.key;
                        _showCustomField = false;
                        _customLabel = null;
                      } else {
                        _selectedKey = null;
                      }
                    });
                  },
                ),
              ChoiceChip(
                label: Text(context.l10n.symptomOther),
                selected: _showCustomField,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _showCustomField = true;
                      _selectedKey = null;
                    } else {
                      _showCustomField = false;
                      _customLabel = null;
                    }
                  });
                },
              ),
            ],
          ),
          if (_showCustomField) ...[
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.symptomDescribe,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _customLabel = v,
            ),
          ],
          const SizedBox(height: 16),

          Text(
            context.l10n.symptomSeverityLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<SymptomSeverity>(
            segments: [
              ButtonSegment(
                value: SymptomSeverity.mild,
                label: Text(context.l10n.symptomSeverityMild),
              ),
              ButtonSegment(
                value: SymptomSeverity.moderate,
                label: Text(context.l10n.symptomSeverityModerate),
              ),
              ButtonSegment(
                value: SymptomSeverity.severe,
                label: Text(context.l10n.symptomSeveritySevere),
              ),
            ],
            selected: {_severity},
            onSelectionChanged: (set) => setState(() => _severity = set.first),
          ),
          const SizedBox(height: 16),

          Text(
            context.l10n.notesOptional,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: context.l10n.anyAdditionalDetails,
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _canSave ? () => _save(bundle) : null,
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _save(ContentBundle bundle) async {
    if (!_canSave) return;

    setState(() => _saving = true);
    var stayOnScreen = false;
    try {
      final typeKey = _showCustomField ? '_custom_' : _selectedKey!;
      final customLabel = _showCustomField ? _customLabel?.trim() : null;
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final repo = ref.read(symptomRepositoryProvider);
      await repo.add(
        loggedAt: DateTime.now().toUtc(),
        typeKey: typeKey,
        customLabel: customLabel,
        severity: _severity,
        notes: notes,
      );

      // Evaluate alert engine
      final engine = ref.read(alertEngineProvider);
      final alert = engine.evaluate(SymptomLogged(typeKey: typeKey));

      if (!mounted) return;

      if (alert != null && alert.severity == AlertSeverity.urgent) {
        await _showUrgentDialog(alert);
      } else if (alert != null && alert.severity == AlertSeverity.warning) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alert.message),
            backgroundColor: Colors.amber.shade700,
          ),
        );
        // Leave screen up so the SnackBar is visible; disable further saves.
        stayOnScreen = true;
      } else {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted && !stayOnScreen) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showUrgentDialog(Alert alert) async {
    final pregnancy = await ref.read(activePregnancyProvider.future);
    final clinicPhone = pregnancy?.clinicPhone;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.symptomRedFlagTitle,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        content: Text(alert.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (clinicPhone != null) {
                // No telephony package; just show the number in a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.symptomProviderPhone(clinicPhone),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.symptomNoProviderPhone)),
                );
              }
            },
            child: Text(context.l10n.symptomCallProvider),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }
}
