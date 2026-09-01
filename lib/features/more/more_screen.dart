import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/widgets/disclaimer_footer.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.moreTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(context.l10n.settingsTitle),
            onTap: () => context.push('/more/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.moreAboutTitle),
            subtitle: Text(context.l10n.moreAboutVersion),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Nurture',
                applicationVersion: '0.1.0',
                children: const [DisclaimerFooter()],
              );
            },
          ),
        ],
      ),
    );
  }
}
