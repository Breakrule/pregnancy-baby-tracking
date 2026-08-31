import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/app_database.dart';
import '../../../data/providers.dart';
import 'hero_card.dart';

// replaced in Task 13
final medsDueTodayProvider = Provider<String>(
  (ref) => 'Medications appear here soon',
);

// replaced in Task 14
final nextAppointmentProvider = StreamProvider<Appointment?>(
  (ref) => Stream.value(null),
);

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key, DateTime? now}) : now = now ?? DateTime.now();

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyAsync = ref.watch(activePregnancyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: pregnancyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pregnancy) {
          if (pregnancy == null) {
            return const Center(child: Text('No active pregnancy'));
          }
          return _buildContent(context, ref, pregnancy);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Pregnancy pregnancy,
  ) {
    final nextApptAsync = ref.watch(nextAppointmentProvider);
    final medsLine = ref.watch(medsDueTodayProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero card
          HeroCard(pregnancy: pregnancy, now: now),

          // 2. Today card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  nextApptAsync.when(
                    loading: () => const Text('Loading appointments…'),
                    error: (e, _) => Text('Error: $e'),
                    data: (appt) => Text(
                      appt != null
                          ? 'Next: ${appt.type} on ${appt.at.month}/${appt.at.day}'
                          : 'No upcoming appointments',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(medsLine),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Quick actions row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.go('/track/weight/new'),
                    icon: const Icon(Icons.scale),
                    label: const Text('Weight'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.go('/track/symptoms/new'),
                    icon: const Icon(Icons.assignment),
                    label: const Text('Symptom'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.go('/track/appointments/new'),
                    icon: const Icon(Icons.event),
                    label: const Text('Appt'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Red-flags shortcut
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/learn/danger-signs'),
              icon: const Icon(Icons.warning_amber),
              label: const Text('When to call your provider'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
