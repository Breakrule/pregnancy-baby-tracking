import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import 'content_widgets.dart';

class WeekDetailScreen extends ConsumerWidget {
  const WeekDetailScreen({super.key, required this.week});

  final int week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Week $week')),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load content: $e')),
        data: (bundle) {
          final wc = bundle.weekFor(week);
          if (wc == null) {
            return const Center(
              child: Text('Content for this week is not yet available.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Size of a ${wc.sizeObject} (~${wc.sizeCm} cm)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ContentSectionHeader(title: 'Baby development'),
              ...wc.development.map((d) => ContentBullet(text: d)),
              const SizedBox(height: 12),
              ContentSectionHeader(title: 'Your body'),
              ...wc.bodyChanges.map((b) => ContentBullet(text: b)),
              const SizedBox(height: 12),
              ContentSectionHeader(title: 'Tips'),
              ...wc.tips.map((t) => ContentBullet(text: t)),
              if (wc.checklist.isNotEmpty) ...[
                const SizedBox(height: 12),
                ContentSectionHeader(title: 'Checklist'),
                ...wc.checklist.map((c) => ContentBullet(text: c)),
              ],
              const SizedBox(height: 16),
              const DisclaimerFooter(),
            ],
          );
        },
      ),
    );
  }
}
