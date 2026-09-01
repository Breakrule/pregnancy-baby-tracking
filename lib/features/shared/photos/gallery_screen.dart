import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/pressable.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import 'photo_add_sheet.dart';

/// Grid gallery for one photo category. Tiles render thumbnails; the
/// full-size image only loads in the viewer.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, required this.category});

  final PhotoCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text(photoCategoryTitle(category))),
      floatingActionButton: PressableScale(
        child: FloatingActionButton(
          key: const Key('photo-add-fab'),
          onPressed: () async {
            await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => PhotoAddSheet(category: category),
            );
          },
          child: const Icon(Icons.add_a_photo),
        ),
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No photos yet.\nTap the camera button to add one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) => _PhotoTile(photo: photos[index]),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gaLabel = photo.gestationalDays != null
        ? 'Week ${photo.gestationalDays! ~/ 7}'
        : null;

    return GestureDetector(
      key: ValueKey('photo-${photo.id}'),
      onTap: () => context.go(
        '/photos/${photoCategoryPaths[photo.category]}/${photo.id}',
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<File>(
            future: ref
                .read(photoServiceProvider)
                .fileFor(photo.fileName, thumbnail: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.existsSync()) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.image_not_supported),
                );
              }
              return Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
                // Thumbnails are small; cap decode size to keep grids cheap.
                cacheWidth: 320,
              );
            },
          ),
          if (gaLabel != null)
            Positioned(
              left: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    gaLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Date subtitle helper shared with the viewer.
String formatPhotoDate(DateTime utc) => DateFormat.yMMMd().format(utc.toLocal());
