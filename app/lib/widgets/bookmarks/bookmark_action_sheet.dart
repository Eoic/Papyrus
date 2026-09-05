import 'dart:async';

import 'package:flutter/material.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';
import 'package:papyrus/widgets/shared/persistent_save.dart';

// =============================================================================
// BOOKMARK ACTION SHEET (action chooser)
// =============================================================================

/// Result of bookmark action sheet selection.
enum BookmarkAction { editNote, changeColor, delete }

/// Bottom sheet for bookmark actions (edit note, change color, delete).
class BookmarkActionSheet extends StatelessWidget {
  final Bookmark bookmark;

  const BookmarkActionSheet({super.key, required this.bookmark});

  /// Shows the action sheet and returns the selected action.
  static Future<BookmarkAction?> show(BuildContext context, {required Bookmark bookmark}) async {
    return showModalBottomSheet<BookmarkAction>(
      context: context,
      builder: (context) => BookmarkActionSheet(bookmark: bookmark),
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

            // Bookmark location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                bookmark.displayLocation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(),

            // Edit note action
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
              title: const Text('Edit note'),
              onTap: () => Navigator.of(context).pop(BookmarkAction.editNote),
            ),

            // Change color action
            ListTile(
              leading: Icon(Icons.palette_outlined, color: colorScheme.onSurface),
              title: const Text('Change color'),
              onTap: () => Navigator.of(context).pop(BookmarkAction.changeColor),
            ),

            // Delete action
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text('Delete bookmark', style: TextStyle(color: colorScheme.error)),
              onTap: () => Navigator.of(context).pop(BookmarkAction.delete),
            ),

            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COLOR NAMES
// =============================================================================

/// Color name mapping for display.
const _colorNames = {
  '#FF5722': 'Orange',
  '#F44336': 'Red',
  '#E91E63': 'Pink',
  '#9C27B0': 'Purple',
  '#2196F3': 'Blue',
  '#4CAF50': 'Green',
  '#FFC107': 'Amber',
};

// =============================================================================
// BOOKMARK NOTE SHEET
// =============================================================================

/// Bottom sheet for editing a bookmark's note.
class BookmarkNoteSheet extends StatefulWidget {
  final Bookmark bookmark;
  final FutureOr<void> Function(String)? onSave;

  const BookmarkNoteSheet({super.key, required this.bookmark, this.onSave});

  /// Show the note editing sheet. Returns the new note text, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required Bookmark bookmark,
    FutureOr<void> Function(String)? onSave,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (context) => BookmarkNoteSheet(bookmark: bookmark, onSave: onSave),
    );
  }

  @override
  State<BookmarkNoteSheet> createState() => _BookmarkNoteSheetState();
}

class _BookmarkNoteSheetState extends State<BookmarkNoteSheet> with PersistentSave<BookmarkNoteSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.bookmark.note ?? '');
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
// BOOKMARK COLOR SHEET
// =============================================================================

/// Bottom sheet for selecting a bookmark color.
class BookmarkColorSheet extends StatefulWidget {
  final Bookmark bookmark;
  final FutureOr<void> Function(String)? onSave;

  const BookmarkColorSheet({super.key, required this.bookmark, this.onSave});

  /// Show the color picker sheet. Returns the selected color hex, or null.
  static Future<String?> show(
    BuildContext context, {
    required Bookmark bookmark,
    FutureOr<void> Function(String)? onSave,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (context) => BookmarkColorSheet(bookmark: bookmark, onSave: onSave),
    );
  }

  @override
  State<BookmarkColorSheet> createState() => _BookmarkColorSheetState();
}

class _BookmarkColorSheetState extends State<BookmarkColorSheet> with PersistentSave<BookmarkColorSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.md),

            // Title
            Text('Change color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.lg),

            // Color grid
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: Bookmark.availableColors.map((hex) {
                final isSelected = hex == widget.bookmark.colorHex;
                final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

                return GestureDetector(
                  onTap: isSaving
                      ? null
                      : () async {
                          final saved = await persist(() => widget.onSave?.call(hex));
                          if (saved && context.mounted) Navigator.pop(context, hex);
                        },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: colorScheme.onSurface, width: 2) : null,
                    ),
                    child: isSelected ? Icon(Icons.check, color: colorScheme.surface, size: IconSizes.action) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.lg),

            // Color names legend
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.xs,
              children: Bookmark.availableColors.map((hex) {
                final name = _colorNames[hex] ?? 'Unknown';
                final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DELETE BOOKMARK DIALOG
// =============================================================================

/// Confirmation dialog for deleting a bookmark.
class DeleteBookmarkDialog {
  /// Show the delete confirmation dialog. Returns true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required Bookmark bookmark,
    required String bookTitle,
    FutureOr<void> Function()? onDelete,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteBookmarkConfirmation(bookmark: bookmark, bookTitle: bookTitle, onDelete: onDelete),
    );
    return result ?? false;
  }
}

class _DeleteBookmarkConfirmation extends StatefulWidget {
  final Bookmark bookmark;
  final String bookTitle;
  final FutureOr<void> Function()? onDelete;

  const _DeleteBookmarkConfirmation({required this.bookmark, required this.bookTitle, this.onDelete});

  @override
  State<_DeleteBookmarkConfirmation> createState() => _DeleteBookmarkConfirmationState();
}

class _DeleteBookmarkConfirmationState extends State<_DeleteBookmarkConfirmation>
    with PersistentSave<_DeleteBookmarkConfirmation> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete bookmark'),
      content: Text('Delete bookmark at ${widget.bookmark.displayLocation} in "${widget.bookTitle}"?'),
      actions: [
        TextButton(onPressed: isSaving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving
              ? null
              : () async {
                  final saved = await persist(() => widget.onDelete?.call());
                  if (saved && context.mounted) Navigator.pop(context, true);
                },
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
