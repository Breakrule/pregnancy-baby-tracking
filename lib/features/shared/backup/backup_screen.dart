import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n.dart';
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
                  labelText: context.l10n.backupPassphraseLabel,
                  errorText: error,
                ),
              ),
              if (confirm)
                TextField(
                  key: const Key('passphrase-confirm-field'),
                  controller: second,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.backupRepeatPassphraseLabel,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final passphrase = first.text;
                if (passphrase.length < 8) {
                  setDialogState(
                    () => error = context.l10n.backupPassphraseTooShort,
                  );
                  return;
                }
                if (confirm && passphrase != second.text) {
                  setDialogState(
                    () => error = context.l10n.backupPassphrasesMismatch,
                  );
                  return;
                }
                Navigator.pop(ctx, passphrase);
              },
              child: Text(context.l10n.commonOk),
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
      title: context.l10n.backupChoosePassphraseTitle,
      confirm: true,
    );
    if (passphrase == null || !mounted) return;

    // Capture before the awaits below (context use across async gaps).
    final saveDialogTitle = context.l10n.backupSaveDialogTitle;

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
        dialogTitle: saveDialogTitle,
        fileName: 'nurture-backup-$stamp.nbk',
      );
      if (path == null) return; // user cancelled

      await File(path).writeAsBytes(bytes);
      if (mounted) _snack(context.l10n.backupSaved(p.basename(path)));
    } on Object catch (e) {
      if (mounted) _snack(context.l10n.backupExportFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.backupRestore),
        content: Text(ctx.l10n.backupRestoreConfirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.backupReplaceAllData),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final picked = await FilePicker.platform.pickFiles();
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    final passphrase = await _passphraseDialog(
      title: context.l10n.backupEnterPassphraseTitle,
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

      if (mounted) _snack(context.l10n.backupRestored);
    } on BackupException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } on Object catch (e) {
      if (mounted) _snack(context.l10n.backupRestoreFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.backupScreenTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.backupIntro),
          ),
          ListTile(
            key: const Key('export-backup-tile'),
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(context.l10n.backupExport),
            subtitle: Text(context.l10n.backupExportSubtitle),
            enabled: !_busy,
            onTap: _export,
          ),
          ListTile(
            key: const Key('restore-backup-tile'),
            leading: const Icon(Icons.file_download_outlined),
            title: Text(context.l10n.backupRestore),
            subtitle: Text(context.l10n.backupRestoreSubtitle),
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
