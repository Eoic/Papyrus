import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:provider/provider.dart';

/// Bottom sheet for moving a book to one or more shelves.
class MoveToShelfSheet extends StatefulWidget {
  /// The book to move.
  final Book book;

  /// Called when shelf assignments change.
  final void Function(List<String> shelfIds)? onSave;

  const MoveToShelfSheet({super.key, required this.book, this.onSave});

  /// Shows the move to shelf sheet.
  static Future<void> show(
    BuildContext context, {
    required Book book,
    void Function(List<String> shelfIds)? onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => MoveToShelfSheet(book: book, onSave: onSave),
    );
  }

  @override
  State<MoveToShelfSheet> createState() => _MoveToShelfSheetState();
}

class _MoveToShelfSheetState extends State<MoveToShelfSheet> {
  late Set<String> _selectedShelfIds;

  @override
  void initState() {
    super.initState();
    // Initialize with current shelf assignments
    final dataStore = context.read<DataStore>();
    _selectedShelfIds = dataStore.getShelfIdsForBook(widget.book.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dataStore = context.watch<DataStore>();
    final shelves = dataStore.shelves;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.lg),

            // Header with book info
            Row(
              children: [
                // Book cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 40,
                    height: 60,
                    child: _buildCover(context),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add to shelves', style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        widget.book.title,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Shelf list
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // Shelves list
                  ...shelves.map((shelf) => _buildShelfTile(context, shelf)),
                  if (shelves.isNotEmpty) const SizedBox(height: Spacing.md),

                  // Create new shelf button
                  _buildCreateShelfButton(context),
                  const SizedBox(height: Spacing.lg),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onSave,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.book.coverURL != null && widget.book.coverURL!.isNotEmpty) {
      return Image.network(
        widget.book.coverURL!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.menu_book,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      );
    }

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget _buildShelfTile(BuildContext context, Shelf shelf) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedShelfIds.contains(shelf.id);
    final shelfColor = shelf.color ?? colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      elevation: 0,
      color: isSelected
          ? shelfColor.withValues(alpha: 0.1)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? shelfColor : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleShelf(shelf.id),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              // Shelf icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shelfColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(shelf.displayIcon, color: shelfColor, size: 20),
              ),
              const SizedBox(width: Spacing.md),
              // Shelf info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelf.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      shelf.bookCountLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleShelf(shelf.id),
                activeColor: shelfColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateShelfButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: _showCreateShelfSheet,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.add,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                'Create new shelf',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleShelf(String shelfId) {
    setState(() {
      if (_selectedShelfIds.contains(shelfId)) {
        _selectedShelfIds.remove(shelfId);
      } else {
        _selectedShelfIds.add(shelfId);
      }
    });
  }

  void _showCreateShelfSheet() {
    final dataStore = context.read<DataStore>();

    AddShelfSheet.show(
      context,
      onSave: (name, description, colorHex, icon) {
        final now = DateTime.now();
        final newShelf = Shelf(
          id: 'shelf-${now.millisecondsSinceEpoch}',
          name: name,
          description: description,
          colorHex: colorHex,
          icon: icon,
          sortOrder: dataStore.shelves.length,
          createdAt: now,
          updatedAt: now,
        );
        dataStore.addShelf(newShelf);

        // Auto-select the newly created shelf
        setState(() {
          _selectedShelfIds.add(newShelf.id);
        });
      },
    );
  }

  void _onSave() {
    widget.onSave?.call(_selectedShelfIds.toList());
    Navigator.pop(context);
  }
}
