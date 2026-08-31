import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models.dart';
import '../../../content/providers.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../data/db/app_database.dart';
import '../../../data/providers.dart';
import '../../../domain/gestational/gestational_calculator.dart';
import 'content_widgets.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider);
    final pregnancyAsync = ref.watch(activePregnancyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load content: $e')),
        data: (bundle) => pregnancyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (pregnancy) => ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _ThisWeekCard(
                bundle: bundle,
                pregnancy: pregnancy,
                now: now ?? DateTime.now(),
              ),
              const SizedBox(height: 16),
              _AllWeeksList(bundle: bundle),
              const DisclaimerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard({
    required this.bundle,
    required this.pregnancy,
    required this.now,
  });

  final ContentBundle bundle;
  final Pregnancy? pregnancy;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (pregnancy == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Complete setup to see your weekly content.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final ga = GestationalCalculator.gestationalAgeAt(pregnancy!.lmpDate, now);
    final weekContent = bundle.weekFor(ga.weeks);

    if (weekContent == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Content for this week arrives in the next update.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week — Week ${weekContent.week}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Size of a ${weekContent.sizeObject} (~${weekContent.sizeCm} cm)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ContentSectionHeader(title: 'Baby development'),
            ...weekContent.development.map(
              (String d) => ContentBullet(text: d),
            ),
            const SizedBox(height: 8),
            ContentSectionHeader(title: 'Your body'),
            ...weekContent.bodyChanges.map(
              (String b) => ContentBullet(text: b),
            ),
            const SizedBox(height: 8),
            ContentSectionHeader(title: 'Tips'),
            ...weekContent.tips.map((String t) => ContentBullet(text: t)),
            if (weekContent.checklist.isNotEmpty) ...[
              const SizedBox(height: 8),
              ContentSectionHeader(title: 'Checklist'),
              ...weekContent.checklist.map(
                (String c) => ContentBullet(text: c),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllWeeksList extends StatelessWidget {
  const _AllWeeksList({required this.bundle});

  final ContentBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'All Weeks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...bundle.weeks.map(
          (WeekContent w) => ListTile(
            title: Text('Week ${w.week} — size of a ${w.sizeObject}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/learn/week/${w.week}'),
          ),
        ),
      ],
    );
  }
}
