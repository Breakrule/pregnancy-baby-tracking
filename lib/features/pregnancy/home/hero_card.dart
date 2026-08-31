import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/gestational/gestational_calculator.dart';

/// Displays gestational age, trimester, countdown, and baby size at a glance.
class HeroCard extends ConsumerWidget {
  HeroCard({super.key, required this.pregnancy, DateTime? now})
    : now = now ?? DateTime.now();

  final Pregnancy pregnancy;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ga = GestationalCalculator.gestationalAgeAt(pregnancy.lmpDate, now);
    final trimester = GestationalCalculator.trimesterOf(ga);
    final daysLeft = GestationalCalculator.daysUntilDue(pregnancy.dueDate, now);

    final countdownText = daysLeft > 0
        ? '$daysLeft days to go'
        : daysLeft == 0
        ? 'Due today'
        : '${-daysLeft} days overdue';

    final trimesterLabel = switch (trimester) {
      Trimester.first => 'Trimester 1',
      Trimester.second => 'Trimester 2',
      Trimester.third => 'Trimester 3',
    };

    // Read content bundle for size info
    final contentAsync = ref.watch(contentProvider);
    final sizeLineWidget = contentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Text(
        'Could not load weekly content.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      data: (bundle) {
        final wc = bundle.weekFor(ga.weeks);
        if (wc == null) return const SizedBox.shrink();
        return Text(
          'Baby is the size of a ${wc.sizeObject} (~${wc.sizeCm.toStringAsFixed(1)} cm)',
        );
      },
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ga.label, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Chip(label: Text(trimesterLabel)),
            const SizedBox(height: 8),
            Text(countdownText),
            const SizedBox(height: 8),
            sizeLineWidget,
          ],
        ),
      ),
    );
  }
}
