import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../content/providers.dart';
import '../../../core/l10n.dart';
import '../../../core/motion/animated_item_list.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';

class SymptomHistoryScreen extends ConsumerWidget {
  const SymptomHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.symptomHistoryTitle)),
      body: symptomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (symptoms) {
          if (symptoms.isEmpty) {
            return Center(child: Text(context.l10n.symptomNoEntries));
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

    // Date groups animate in/out as new days appear or become empty.
    return AnimatedItemStream<MapEntry<String, List<Symptom>>>(
      padding: const EdgeInsets.symmetric(vertical: 8),
      items: grouped.entries.toList(),
      itemId: (group) => group.key,
      itemBuilder: (context, group) {
        final dateLabel = group.key;
        final items = group.value;
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
    // Custom labels are user text; preset keys resolve to the localized
    // content label, falling back to the raw key.
    String label;
    if (s.customLabel != null) {
      label = s.customLabel!;
    } else {
      final preset = ref
          .watch(contentProvider)
          .valueOrNull
          ?.symptomPresets
          .where((p) => p.key == s.typeKey)
          .firstOrNull;
      label = preset?.label ?? s.typeKey;
    }
    final timeFormat = DateFormat.Hm();
    final severityLabel = switch (s.severity) {
      SymptomSeverity.mild => context.l10n.symptomSeverityMild,
      SymptomSeverity.moderate => context.l10n.symptomSeverityModerate,
      SymptomSeverity.severe => context.l10n.symptomSeveritySevere,
    };
    final subtitle =
        '$severityLabel \u2022 ${timeFormat.format(s.loggedAt.toLocal())}'
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
