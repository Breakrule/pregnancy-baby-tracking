import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/db/tables.dart';
import '../../../data/providers.dart';
import '../../../domain/gestational/gestational_calculator.dart';
import 'photo_service.dart';

/// Route segment names for each photo category.
const photoCategoryPaths = <PhotoCategory, String>{
  PhotoCategory.belly: 'belly',
  PhotoCategory.ultrasound: 'ultrasounds',
  PhotoCategory.baby: 'baby',
};

PhotoCategory? photoCategoryFromPath(String path) {
  for (final entry in photoCategoryPaths.entries) {
    if (entry.value == path) return entry.key;
  }
  return null;
}

String photoCategoryTitle(PhotoCategory category) => switch (category) {
  PhotoCategory.belly => 'Belly photos',
  PhotoCategory.ultrasound => 'Ultrasounds',
  PhotoCategory.baby => 'Baby photos',
};

/// Two-step add flow: pick a source (camera/gallery), then confirm date and
/// notes before saving. A captured-but-not-saved photo is deleted again.
class PhotoAddSheet extends ConsumerStatefulWidget {
  const PhotoAddSheet({super.key, required this.category});

  final PhotoCategory category;

  @override
  ConsumerState<PhotoAddSheet> createState() => _PhotoAddSheetState();
}

class _PhotoAddSheetState extends ConsumerState<PhotoAddSheet> {
  CapturedPhoto? _captured;
  late DateTime _takenAt = DateTime.now();
  final _notesController = TextEditingController();
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _notesController.dispose();
    // User captured a photo but backed out — don't leave orphan files.
    if (_captured != null && !_saved) {
      ref.read(photoServiceProvider).deleteFiles(_captured!.fileName);
    }
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    final captured = await ref
        .read(photoServiceProvider)
        .capture(source: source);
    if (!mounted || captured == null) return;
    setState(() => _captured = captured);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _takenAt = _takenAt.isAfter(picked)
            ? picked.add(_takenAt.difference(DateTime(picked.year, picked.month, picked.day)))
            : picked;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _captured == null) return;
    setState(() => _saving = true);

    int? gestationalDays;
    if (widget.category != PhotoCategory.baby) {
      final pregnancy = await ref.read(activePregnancyProvider.future);
      if (pregnancy != null) {
        gestationalDays = GestationalCalculator
            .gestationalAgeAt(pregnancy.lmpDate, _takenAt)
            .totalDays;
      }
    }

    await ref.read(photoRepositoryProvider).add(
      category: widget.category,
      takenAt: _takenAt.toUtc(),
      fileName: _captured!.fileName,
      gestationalDays: gestationalDays,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    _saved = true;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final captured = _captured;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: captured == null ? _buildSourcePicker() : _buildDetails(captured),
      ),
    );
  }

  Widget _buildSourcePicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: const Key('photo-source-camera'),
          leading: const Icon(Icons.photo_camera),
          title: const Text('Take photo'),
          onTap: () => _capture(ImageSource.camera),
        ),
        ListTile(
          key: const Key('photo-source-gallery'),
          leading: const Icon(Icons.photo_library),
          title: const Text('Choose from gallery'),
          onTap: () => _capture(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildDetails(CapturedPhoto captured) {
    final dateLabel = DateFormat.yMMMd().format(_takenAt);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<File>(
          future: ref.read(photoServiceProvider).fileFor(captured.fileName),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 160);
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                snapshot.data!,
                height: 180,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          key: const Key('photo-date-tile'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: Text(dateLabel),
          onTap: _pickDate,
        ),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('photo-save-button'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
