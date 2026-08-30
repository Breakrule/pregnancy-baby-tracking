import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers.dart';
import '../../../core/widgets/disclaimer_footer.dart';

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
              _SectionHeader(title: 'Baby development'),
              ...wc.development.map((d) => _Bullet(text: d)),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Your body'),
              ...wc.bodyChanges.map((b) => _Bullet(text: b)),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Tips'),
              ...wc.tips.map((t) => _Bullet(text: t)),
              if (wc.checklist.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionHeader(title: 'Checklist'),
                ...wc.checklist.map((c) => _Bullet(text: c)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\u2022 '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
