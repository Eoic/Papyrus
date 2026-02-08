import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// Result of note action sheet selection.
enum NoteAction { edit, delete }

/// Bottom sheet for note actions (edit, delete).
class NoteActionSheet extends StatelessWidget {
  final Note note;

  const NoteActionSheet({super.key, required this.note});

  /// Shows the action sheet and returns the selected action.
  static Future<NoteAction?> show(
    BuildContext context, {
    required Note note,
  }) async {
    return showModalBottomSheet<NoteAction>(
      context: context,
      builder: (context) => NoteActionSheet(note: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.md),

            // Note title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                note.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(),

            // Edit action
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
              title: const Text('Edit note'),
              onTap: () => Navigator.of(context).pop(NoteAction.edit),
            ),

            // Delete action
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Delete note',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () => Navigator.of(context).pop(NoteAction.delete),
            ),

            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for deleting a note.
class DeleteNoteDialog extends StatelessWidget {
  final Note note;

  const DeleteNoteDialog({super.key, required this.note});

  /// Shows the delete confirmation dialog.
  static Future<bool> show(BuildContext context, {required Note note}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteNoteDialog(note: note),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delete note'),
      content: Text(
        'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
