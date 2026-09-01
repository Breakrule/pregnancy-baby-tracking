import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import 'gallery_screen.dart';
import 'photo_add_sheet.dart';

/// Full-screen viewer for one photo: pinch-zoom on the full-size image,
/// metadata in the app bar, delete with confirmation.
class PhotoViewerScreen extends ConsumerWidget {
  const PhotoViewerScreen({
    super.key,
    required this.category,
    required this.photoId,
  });

  final PhotoCategory category;
  final int photoId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Photo photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.photosDeleteQuestion),
        content: Text(context.l10n.photosDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('photo-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Files first, then the row: a photo row without files renders a
    // placeholder, but files without a row are invisible orphans.
    await ref.read(photoServiceProvider).deleteFiles(photo.fileName);
    await ref.read(photoRepositoryProvider).delete(photo.id);
    if (context.mounted) {
      context.go('/photos/${photoCategoryPaths[category]}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Photo?>(
      future: ref.read(photoRepositoryProvider).byId(photoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final photo = snapshot.data;
        if (photo == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.photosNotFound)),
          );
        }

        final subtitle = [
          formatPhotoDate(photo.takenAt),
          if (photo.gestationalDays != null)
            context.l10n.photosWeekPlus(
              photo.gestationalDays! ~/ 7,
              photo.gestationalDays! % 7,
            ),
        ].join(' · ');

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: const TextStyle(fontSize: 15)),
                if (photo.notes != null && photo.notes!.isNotEmpty)
                  Text(
                    photo.notes!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('photo-delete-button'),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref, photo),
              ),
            ],
          ),
          body: FutureBuilder<File>(
            future: ref.read(photoServiceProvider).fileFor(photo.fileName),
            builder: (context, fileSnapshot) {
              if (!fileSnapshot.hasData || !fileSnapshot.data!.existsSync()) {
                return const Center(child: Icon(Icons.image_not_supported));
              }
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(fileSnapshot.data!, fit: BoxFit.contain),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
