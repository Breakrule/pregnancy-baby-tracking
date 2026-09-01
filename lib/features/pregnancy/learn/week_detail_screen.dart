import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import 'content_widgets.dart';

class WeekDetailScreen extends ConsumerWidget {
  const WeekDetailScreen({super.key, required this.week});

  final int week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.learnWeekTitle(week))),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(context.l10n.learnFailedToLoad('$e'))),
        data: (bundle) {
          final wc = bundle.weekFor(week);
          if (wc == null) {
            return Center(child: Text(context.l10n.learnWeekNotAvailable));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                context.l10n.learnSizeOf(wc.sizeObject, '${wc.sizeCm}'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ContentSectionHeader(title: context.l10n.learnBabyDevelopment),
              ...wc.development.map((d) => ContentBullet(text: d)),
              const SizedBox(height: 12),
              ContentSectionHeader(title: context.l10n.learnYourBody),
              ...wc.bodyChanges.map((b) => ContentBullet(text: b)),
              const SizedBox(height: 12),
              ContentSectionHeader(title: context.l10n.learnTips),
              ...wc.tips.map((t) => ContentBullet(text: t)),
              if (wc.checklist.isNotEmpty) ...[
                const SizedBox(height: 12),
                ContentSectionHeader(title: context.l10n.learnChecklist),
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
