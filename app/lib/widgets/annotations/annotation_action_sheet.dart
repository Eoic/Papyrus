import 'dart:async';

import 'package:papyrus/widgets/shared/persistent_save.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';
import 'package:papyrus/themes/app_motion.dart';

// =============================================================================
// ANNOTATION NOTE SHEET
// =============================================================================

/// Bottom sheet for editing an annotation's attached note.
class AnnotationNoteSheet extends StatefulWidget {
  final Annotation annotation;
  final FutureOr<void> Function(String)? onSave;

  const AnnotationNoteSheet({super.key, required this.annotation, this.onSave});

  /// Show the note editing sheet. Returns the new note text, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required Annotation annotation,
    FutureOr<void> Function(String)? onSave,
  }) {
    return showModalBottomSheet<String>(
      sheetAnimationStyle: AppMotion.animationStyle(context),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (context) => AnnotationNoteSheet(annotation: annotation, onSave: onSave),
    );
  }

  @override
  State<AnnotationNoteSheet> createState() => _AnnotationNoteSheetState();
}

class _AnnotationNoteSheetState extends State<AnnotationNoteSheet> with PersistentSave<AnnotationNoteSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.annotation.note ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.md),
              BottomSheetHeader(
                title: 'Edit note',
                onCancel: () => Navigator.pop(context),
                canSave: !isSaving,
                canCancel: !isSaving,
                onSave: () async {
                  final text = _controller.text.trim();
                  final saved = await persist(() => widget.onSave?.call(text));
                  if (saved && context.mounted) Navigator.pop(context, text);
                },
              ),
              const SizedBox(height: Spacing.md),
              const Divider(height: 1),
              const SizedBox(height: Spacing.md),

              // Note field
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 500,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DELETE ANNOTATION DIALOG
// =============================================================================

/// Confirmation dialog for deleting an annotation.
class DeleteAnnotationDialog {
  /// Show the delete confirmation dialog. Returns true if confirmed.
  static Future<bool> show(BuildContext context, {required Annotation annotation, required String bookTitle}) async {
    final result = await showDialog<bool>(
      animationStyle: AppMotion.animationStyle(context),
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete annotation'),
        content: Text('Delete annotation at ${annotation.location.shortLocation} in "$bookTitle"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
