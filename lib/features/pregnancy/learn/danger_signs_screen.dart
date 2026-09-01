import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import 'content_widgets.dart';

class DangerSignsScreen extends ConsumerWidget {
  const DangerSignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(contentProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dangerSignsTitle)),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.commonError('$e'))),
        data: (bundle) {
          if (bundle.redFlags.isEmpty) {
            return Center(child: Text(context.l10n.dangerSignsNoneLoaded));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ContentSectionHeader(title: context.l10n.homeWhenToCallProvider),
              const SizedBox(height: 8),
              ...bundle.redFlags.map(
                (flag) => Padding(
                  key: ValueKey(flag.key),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flag.label,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(flag.message),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const DisclaimerFooter(),
            ],
          );
        },
      ),
    );
  }
}
