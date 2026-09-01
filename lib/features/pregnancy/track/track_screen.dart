import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trackTitle)),
      body: ListView(
        children: [
          ListTile(
            key: const Key('track-weight-tile'),
            leading: const Icon(Icons.scale),
            title: Text(context.l10n.trackWeightTitle),
            subtitle: Text(context.l10n.trackWeightSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/weight'),
          ),
          ListTile(
            key: const Key('track-symptoms-tile'),
            leading: const Icon(Icons.assignment),
            title: Text(context.l10n.trackSymptomsTitle),
            subtitle: Text(context.l10n.trackSymptomsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/symptoms'),
          ),
          ListTile(
            key: const Key('track-appointments-tile'),
            leading: const Icon(Icons.event),
            title: Text(context.l10n.trackAppointmentsTitle),
            subtitle: Text(context.l10n.trackAppointmentsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/appointments'),
          ),
          ListTile(
            key: const Key('track-medications-tile'),
            leading: const Icon(Icons.medication),
            title: Text(context.l10n.trackMedicationsTitle),
            subtitle: Text(context.l10n.trackMedicationsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/medications'),
          ),
          ListTile(
            key: const Key('track-belly-photos-tile'),
            leading: const Icon(Icons.photo_camera),
            title: Text(context.l10n.homeBellyPhotos),
            subtitle: Text(context.l10n.trackBellyPhotosSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/photos/belly'),
          ),
          ListTile(
            key: const Key('track-ultrasounds-tile'),
            leading: const Icon(Icons.monitor_heart),
            title: Text(context.l10n.photosUltrasoundsTitle),
            subtitle: Text(context.l10n.trackUltrasoundsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/photos/ultrasounds'),
          ),
        ],
      ),
    );
  }
}
