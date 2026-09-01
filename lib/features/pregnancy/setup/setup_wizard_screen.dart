import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import 'setup_form_state.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final _form = SetupFormState();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _submitting = false;

  // Controllers for text fields that need manual parsing.
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _clinicNameCtrl;
  late final TextEditingController _clinicPhoneCtrl;
  late final TextEditingController _hospitalNameCtrl;
  late final TextEditingController _hospitalAddressCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _clinicNameCtrl = TextEditingController();
    _clinicPhoneCtrl = TextEditingController();
    _hospitalNameCtrl = TextEditingController();
    _hospitalAddressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _clinicNameCtrl.dispose();
    _clinicPhoneCtrl.dispose();
    _hospitalNameCtrl.dispose();
    _hospitalAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 90)),
      firstDate: now.subtract(const Duration(days: 320)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _form.referenceDate = picked);
    }
  }

  /// Maps a locale-neutral validation issue to the localized message.
  String _issueText(SetupValidationIssue issue) {
    final l10n = context.l10n;
    return switch (issue) {
      SetupValidationIssue.dateMissing => l10n.setupErrChooseDate,
      SetupValidationIssue.dateInFuture => l10n.setupErrDateInPast,
      SetupValidationIssue.dateTooOld => l10n.setupErrDateTooOld,
      SetupValidationIssue.weightMissing => l10n.setupErrEnterWeight,
      SetupValidationIssue.weightOutOfRange => l10n.setupErrWeightRange,
      SetupValidationIssue.heightMissing => l10n.setupErrEnterHeight,
      SetupValidationIssue.heightOutOfRange => l10n.setupErrHeightRange,
    };
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        final err = _form.validateReferenceDate(
          _form.referenceDate,
          today: DateTime.now(),
        );
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_issueText(err))));
          return false;
        }
        return true;
      case 1:
        final w = double.tryParse(_weightCtrl.text.trim());
        final h = double.tryParse(_heightCtrl.text.trim());
        _form.prePregnancyWeightKg = w;
        _form.heightCm = h;
        final wErr = _form.validateWeight(w);
        if (wErr != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_issueText(wErr))));
          return false;
        }
        final hErr = _form.validateHeight(h);
        if (hErr != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_issueText(hErr))));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      // Sync optional text fields into form state.
      _form.clinicName = _clinicNameCtrl.text.trim().isEmpty
          ? null
          : _clinicNameCtrl.text.trim();
      _form.clinicPhone = _clinicPhoneCtrl.text.trim().isEmpty
          ? null
          : _clinicPhoneCtrl.text.trim();
      _form.hospitalName = _hospitalNameCtrl.text.trim().isEmpty
          ? null
          : _hospitalNameCtrl.text.trim();
      _form.hospitalAddress = _hospitalAddressCtrl.text.trim().isEmpty
          ? null
          : _hospitalAddressCtrl.text.trim();

      final repo = ref.read(pregnancyRepositoryProvider);
      await repo.create(
        lmpDate: utcDateOnly(_form.lmpDate!),
        dueDate: utcDateOnly(_form.dueDate!),
        source: _form.source,
        prePregnancyWeightKg: _form.prePregnancyWeightKg!,
        heightCm: _form.heightCm!,
        bloodType: _form.bloodType == 'Unknown' ? null : _form.bloodType,
        clinicName: _form.clinicName,
        clinicPhone: _form.clinicPhone,
        hospitalName: _form.hospitalName,
        hospitalAddress: _form.hospitalAddress,
      );
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static DateTime utcDateOnly(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.setupStepOf(_currentStep + 1)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_currentStep + 1) / 3),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildDatingStep(),
          _buildAboutYouStep(),
          _buildCareTeamStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: (_currentStep == 2 && _submitting) ? null : _next,
            child: Text(
              _currentStep == 2
                  ? context.l10n.setupStartTracking
                  : context.l10n.setupNext,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.setupWelcome,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SegmentedButton<ConceptionSource>(
            segments: [
              ButtonSegment(
                value: ConceptionSource.lmp,
                label: Text(context.l10n.setupSourceLmp),
              ),
              ButtonSegment(
                value: ConceptionSource.ultrasound,
                label: Text(context.l10n.setupSourceUltrasound),
              ),
            ],
            selected: {_form.source},
            onSelectionChanged: (values) {
              setState(() {
                _form.source = values.first;
                _form.referenceDate = null;
              });
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _form.referenceDate == null
                  ? context.l10n.setupChooseDate
                  : '${_form.referenceDate!.year}-${_form.referenceDate!.month.toString().padLeft(2, '0')}-${_form.referenceDate!.day.toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutYouStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.setupAboutYou,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _weightCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.setupPrePregnancyWeight,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightCtrl,
            decoration: InputDecoration(labelText: context.l10n.setupHeight),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildCareTeamStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.setupCareTeam,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _form.bloodType,
            decoration: InputDecoration(labelText: context.l10n.setupBloodType),
            items: const [
              'A+',
              'A-',
              'B+',
              'B-',
              'AB+',
              'AB-',
              'O+',
              'O-',
              'Unknown',
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _form.bloodType = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clinicNameCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.setupClinicName,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clinicPhoneCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.setupClinicPhone,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _hospitalNameCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.setupHospitalName,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _hospitalAddressCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.setupHospitalAddress,
            ),
          ),
        ],
      ),
    );
  }
}
