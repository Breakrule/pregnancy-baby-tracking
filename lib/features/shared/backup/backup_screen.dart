import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../data/backup/backup_service.dart';
import '../../../data/providers.dart';
import '../app_lock/app_lock_notifier.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _snack(String message, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
      ),
    );
  }

  Future<String?> _passphraseDialog({
    required String title,
    required bool confirm,
  }) {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('passphrase-field'),
                controller: first,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Passphrase',
                  errorText: error,
                ),
              ),
              if (confirm)
                TextField(
                  key: const Key('passphrase-confirm-field'),
                  controller: second,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Repeat passphrase',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final passphrase = first.text;
                if (passphrase.length < 8) {
                  setDialogState(() => error = 'Use at least 8 characters');
                  return;
                }
                if (confirm && passphrase != second.text) {
                  setDialogState(() => error = 'Passphrases do not match');
                  return;
                }
                Navigator.pop(ctx, passphrase);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      first.dispose();
      second.dispose();
    });
  }

  Future<void> _export() async {
    if (_busy) return;
    final passphrase = await _passphraseDialog(
      title: 'Choose a backup passphrase',
      confirm: true,
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final bytes = await ref
          .read(backupServiceProvider)
          .export(db, passphrase: passphrase);

      final now = DateTime.now();
      final stamp =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup',
        fileName: 'nurture-backup-$stamp.nbk',
      );
      if (path == null) return; // user cancelled

      await File(path).writeAsBytes(bytes);
      if (mounted) _snack('Backup saved: ${p.basename(path)}');
    } on Object catch (e) {
      if (mounted) _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup'),
        content: const Text(
          'This replaces ALL current data with the contents of the '
          'backup file. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace all data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final picked = await FilePicker.platform.pickFiles();
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    final passphrase = await _passphraseDialog(
      title: 'Enter backup passphrase',
      confirm: false,
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await File(path).readAsBytes();
      final db = ref.read(appDatabaseProvider);
      await ref
          .read(backupServiceProvider)
          .import(db, bytes, passphrase: passphrase);

      // The backup may carry different security settings.
      ref.invalidate(settingsProvider);
      await ref.read(appLockNotifierProvider.notifier).syncFromSettings();

      if (mounted) _snack('Backup restored');
    } on BackupException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } on Object catch (e) {
      if (mounted) _snack('Restore failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Backups are encrypted with your passphrase and saved to a '
              'file you choose. Nothing ever leaves your device '
              'automatically.',
            ),
          ),
          ListTile(
            key: const Key('export-backup-tile'),
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export backup'),
            subtitle: const Text('Save an encrypted copy of all data'),
            enabled: !_busy,
            onTap: _export,
          ),
          ListTile(
            key: const Key('restore-backup-tile'),
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Restore from backup'),
            subtitle: const Text('Replace all data from a backup file'),
            enabled: !_busy,
            onTap: _restore,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
