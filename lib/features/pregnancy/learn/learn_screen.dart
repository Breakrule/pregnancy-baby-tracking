import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models.dart';
import '../../../content/providers.dart';
import '../../../core/l10n.dart';
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
      appBar: AppBar(title: Text(context.l10n.learnTitle)),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(context.l10n.learnFailedToLoad('$e'))),
        data: (bundle) => pregnancyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
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
            context.l10n.learnCompleteSetup,
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
            context.l10n.learnContentNextUpdate,
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
              context.l10n.learnThisWeek(weekContent.week),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.learnSizeOf(
                weekContent.sizeObject,
                '${weekContent.sizeCm}',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ContentSectionHeader(title: context.l10n.learnBabyDevelopment),
            ...weekContent.development.map(
              (String d) => ContentBullet(text: d),
            ),
            const SizedBox(height: 8),
            ContentSectionHeader(title: context.l10n.learnYourBody),
            ...weekContent.bodyChanges.map(
              (String b) => ContentBullet(text: b),
            ),
            const SizedBox(height: 8),
            ContentSectionHeader(title: context.l10n.learnTips),
            ...weekContent.tips.map((String t) => ContentBullet(text: t)),
            if (weekContent.checklist.isNotEmpty) ...[
              const SizedBox(height: 8),
              ContentSectionHeader(title: context.l10n.learnChecklist),
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
            context.l10n.learnAllWeeks,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...bundle.weeks.map(
          (WeekContent w) => ListTile(
            title: Text(context.l10n.learnWeekSize(w.week, w.sizeObject)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/learn/week/${w.week}'),
          ),
        ),
      ],
    );
  }
}
