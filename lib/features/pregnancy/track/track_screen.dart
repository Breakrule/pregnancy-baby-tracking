import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('track-weight-tile'),
            leading: const Icon(Icons.scale),
            title: const Text('Weight'),
            subtitle: const Text('Track weight gain with IOM guidelines'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/weight'),
          ),
          ListTile(
            key: const Key('track-symptoms-tile'),
            leading: const Icon(Icons.assignment),
            title: const Text('Symptoms'),
            subtitle: const Text('View symptom history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/symptoms'),
          ),
          ListTile(
            key: const Key('track-appointments-tile'),
            leading: const Icon(Icons.event),
            title: const Text('Appointments'),
            subtitle: const Text('Upcoming visits and checkups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/appointments'),
          ),
          ListTile(
            key: const Key('track-medications-tile'),
            leading: const Icon(Icons.medication),
            title: const Text('Medications'),
            subtitle: const Text('Medication tracking and reminders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/track/medications'),
          ),
          ListTile(
            key: const Key('track-belly-photos-tile'),
            leading: const Icon(Icons.photo_camera),
            title: const Text('Belly photos'),
            subtitle: const Text('Your bump, week by week'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/photos/belly'),
          ),
          ListTile(
            key: const Key('track-ultrasounds-tile'),
            leading: const Icon(Icons.monitor_heart),
            title: const Text('Ultrasounds'),
            subtitle: const Text('Scan photos with dates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/photos/ultrasounds'),
          ),
        ],
      ),
    );
  }
}
