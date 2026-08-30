import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/disclaimer_footer.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => context.push('/more/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Nurture 0.1.0'),
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
