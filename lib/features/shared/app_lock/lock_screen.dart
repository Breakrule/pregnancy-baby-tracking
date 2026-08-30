import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_notifier.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String _error = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_submitting) return;
    _submitting = true;
    try {
      await ref.read(appLockNotifierProvider.notifier).unlockWithBiometric();
    } finally {
      if (mounted) _submitting = false;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _submitting = true;
    try {
      final ok = await ref
          .read(appLockNotifierProvider.notifier)
          .verifyPin(_pin);
      if (!ok && mounted) {
        setState(() {
          _error = 'Incorrect PIN';
          _pin = '';
        });
      }
    } finally {
      if (mounted) _submitting = false;
    }
  }

  void _press(String digit) {
    setState(() => _error = '');
    if (_pin.length >= 6) return;
    _pin += digit;
    setState(() {});
    if (_pin.length == 6) _submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text('Enter PIN', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('\u2022' * _pin.length, style: theme.textTheme.headlineSmall),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            _Keypad(
              onDigit: _press,
              onBackspace: () => setState(() {
                if (_pin.isNotEmpty) {
                  _pin = _pin.substring(0, _pin.length - 1);
                }
              }),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use fingerprint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap) => SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          textStyle: Theme.of(context).textTheme.headlineSmall,
        ),
        child: Text(label),
      ),
    );

    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d, () => onDigit(d))],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72, height: 72),
            key('0', () => onDigit('0')),
            key('\u232B', onBackspace),
          ],
        ),
      ],
    );
  }
}
