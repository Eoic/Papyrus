import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// Result of note action sheet selection.
enum NoteAction { edit, delete }

/// Bottom sheet for note actions (edit, delete).
class NoteActionSheet extends StatelessWidget {
  final Note note;

  const NoteActionSheet({
    super.key,
    required this.note,
  });

  /// Shows the action sheet and returns the selected action.
  static Future<NoteAction?> show(
    BuildContext context, {
    required Note note,
  }) async {
    final displayMode = context.read<DisplayModeProvider>();

    if (displayMode.isEinkMode) {
      return showDialog<NoteAction>(
        context: context,
        builder: (context) => _EinkNoteActionDialog(note: note),
      );
    }

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
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Note title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                note.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(),

            // Edit action
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: colorScheme.onSurface,
              ),
              title: const Text('Edit note'),
              onTap: () => Navigator.of(context).pop(NoteAction.edit),
            ),

            // Delete action
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
              ),
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

/// E-ink specific action dialog.
class _EinkNoteActionDialog extends StatelessWidget {
  final Note note;

  const _EinkNoteActionDialog({required this.note});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(Spacing.pageMarginsEink),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              note.title.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.md),
            const Divider(thickness: 1, color: Colors.black),
            const SizedBox(height: Spacing.md),

            // Edit button
            SizedBox(
              height: TouchTargets.einkMin,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(NoteAction.edit),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'EDIT NOTE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Delete button
            SizedBox(
              height: TouchTargets.einkMin,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(NoteAction.delete),
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'DELETE NOTE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Cancel button
            SizedBox(
              height: TouchTargets.einkMin,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                ),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for deleting a note.
class DeleteNoteDialog extends StatelessWidget {
  final Note note;

  const DeleteNoteDialog({
    super.key,
    required this.note,
  });

  /// Shows the delete confirmation dialog.
  static Future<bool> show(
    BuildContext context, {
    required Note note,
  }) async {
    final displayMode = context.read<DisplayModeProvider>();

    if (displayMode.isEinkMode) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => _EinkDeleteNoteDialog(note: note),
      );
      return result ?? false;
    }

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
      title: const Text('Delete Note'),
      content: Text(
        'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/// E-ink specific delete confirmation dialog.
class _EinkDeleteNoteDialog extends StatelessWidget {
  final Note note;

  const _EinkDeleteNoteDialog({required this.note});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(Spacing.pageMarginsEink),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'DELETE NOTE',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: Spacing.md),

            // Message
            Text(
              'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Spacing.lg),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: TouchTargets.einkMin,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                          color: Colors.black,
                          width: BorderWidths.einkDefault,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: SizedBox(
                    height: TouchTargets.einkMin,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'DELETE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
