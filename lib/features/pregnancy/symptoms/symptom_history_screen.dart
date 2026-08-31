import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/db/app_database.dart';
import '../../../data/providers.dart';

class SymptomHistoryScreen extends ConsumerWidget {
  const SymptomHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Symptom History')),
      body: symptomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (symptoms) {
          if (symptoms.isEmpty) {
            return const Center(child: Text('No symptoms logged yet.'));
          }
          return _buildGroupedList(context, ref, symptoms);
        },
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<Symptom> symptoms,
  ) {
    final grouped = <String, List<Symptom>>{};
    final dateFormat = DateFormat.yMMMd();
    for (final s in symptoms) {
      final key = dateFormat.format(s.loggedAt.toLocal());
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateLabel = grouped.keys.elementAt(index);
        final items = grouped[dateLabel]!;
        return KeyedSubtree(
          key: ValueKey(dateLabel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  dateLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ...items.map((s) => _buildTile(context, ref, s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref, Symptom s) {
    final label = s.customLabel ?? s.typeKey;
    final timeFormat = DateFormat.Hm();
    final subtitle =
        '${s.severity.name} \u2022 ${timeFormat.format(s.loggedAt.toLocal())}'
        '${s.notes != null ? '\n${s.notes}' : ''}';

    return Dismissible(
      key: ValueKey(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade50,
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        ref.read(symptomRepositoryProvider).delete(s.id);
      },
      child: ListTile(
        title: Text(label),
        subtitle: Text(subtitle),
        leading: const Icon(Icons.assignment_outlined),
      ),
    );
  }
}
