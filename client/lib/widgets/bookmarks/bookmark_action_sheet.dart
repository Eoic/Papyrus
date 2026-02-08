import 'package:flutter/material.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/themes/design_tokens.dart';

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
  static Future<BookmarkAction?> show(
    BuildContext context, {
    required Bookmark bookmark,
  }) async {
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

            // Bookmark location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                bookmark.displayLocation,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
              leading: Icon(
                Icons.palette_outlined,
                color: colorScheme.onSurface,
              ),
              title: const Text('Change color'),
              onTap: () =>
                  Navigator.of(context).pop(BookmarkAction.changeColor),
            ),

            // Delete action
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Delete bookmark',
                style: TextStyle(color: colorScheme.error),
              ),
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

  const BookmarkNoteSheet({super.key, required this.bookmark});

  /// Show the note editing sheet. Returns the new note text, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required Bookmark bookmark,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => BookmarkNoteSheet(bookmark: bookmark),
    );
  }

  @override
  State<BookmarkNoteSheet> createState() => _BookmarkNoteSheetState();
}

class _BookmarkNoteSheetState extends State<BookmarkNoteSheet> {
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
    final colorScheme = Theme.of(context).colorScheme;
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
              // Drag handle
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Header
              Row(
                children: [
                  Text(
                    'Edit note',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilledButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      Navigator.pop(context, text.isEmpty ? '' : text);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Note field
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 500,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(),
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
class BookmarkColorSheet extends StatelessWidget {
  final Bookmark bookmark;

  const BookmarkColorSheet({super.key, required this.bookmark});

  /// Show the color picker sheet. Returns the selected color hex, or null.
  static Future<String?> show(
    BuildContext context, {
    required Bookmark bookmark,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => BookmarkColorSheet(bookmark: bookmark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Title
            Text(
              'Change color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.lg),

            // Color grid
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: Bookmark.availableColors.map((hex) {
                final isSelected = hex == bookmark.colorHex;
                final color = Color(
                  int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                );

                return GestureDetector(
                  onTap: () => Navigator.pop(context, hex),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: colorScheme.surface,
                            size: IconSizes.action,
                          )
                        : null,
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
                final color = Color(
                  int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                );

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bookmark'),
        content: Text(
          'Delete bookmark at ${bookmark.displayLocation} in "$bookTitle"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
