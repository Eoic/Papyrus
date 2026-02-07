import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// Bottom sheet or page for viewing books in a shelf.
class ShelfDetailSheet extends StatefulWidget {
  /// The shelf to display.
  final ShelfData shelf;

  /// The books in this shelf.
  final List<BookData> books;

  /// Called when delete is tapped.
  final VoidCallback? onDelete;

  /// Called when a book is removed from the shelf.
  final void Function(BookData book)? onRemoveBook;

  const ShelfDetailSheet({
    super.key,
    required this.shelf,
    required this.books,
    this.onDelete,
    this.onRemoveBook,
  });

  @override
  State<ShelfDetailSheet> createState() => _ShelfDetailSheetState();

  /// Shows the shelf detail sheet.
  ///
  /// Returns `'edit'` if the user chose to edit the shelf.
  static Future<String?> show(
    BuildContext context, {
    required ShelfData shelf,
    required List<BookData> books,
    VoidCallback? onDelete,
    void Function(BookData book)? onRemoveBook,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ShelfDetailSheet(
          shelf: shelf,
          books: books,
          onDelete: onDelete,
          onRemoveBook: onRemoveBook,
        ),
      ),
    );
  }
}

class _ShelfDetailSheetState extends State<ShelfDetailSheet> {
  BookSortOption _sortOption = BookSortOption.title;
  bool _sortAscending = true;
  late List<BookData> _sortedBooks;

  @override
  void initState() {
    super.initState();
    _sortedBooks = List.from(widget.books);
    _applySorting();
  }

  void _applySorting() {
    _sortedBooks.sort((a, b) {
      int result;
      switch (_sortOption) {
        case BookSortOption.title:
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case BookSortOption.author:
          result = a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case BookSortOption.progress:
          result = a.progress.compareTo(b.progress);
        case BookSortOption.dateAdded:
          result = a.id.compareTo(b.id);
      }
      return _sortAscending ? result : -result;
    });
  }

  void _setSortOption(BookSortOption option) {
    setState(() {
      if (_sortOption == option) {
        _sortAscending = !_sortAscending;
      } else {
        _sortOption = option;
        _sortAscending = true;
      }
      _applySorting();
    });
  }

  String get _sortLabel {
    switch (_sortOption) {
      case BookSortOption.title:
        return 'Title';
      case BookSortOption.author:
        return 'Author';
      case BookSortOption.progress:
        return 'Progress';
      case BookSortOption.dateAdded:
        return 'Date added';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shelfColor = widget.shelf.color ?? colorScheme.primary;

    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: Spacing.md),
          child: const BottomSheetHandle(),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: shelfColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: shelfColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  widget.shelf.displayIcon,
                  size: 28,
                  color: shelfColor,
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shelf.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.shelf.description ?? widget.shelf.bookCountLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.of(context).pop('edit');
                    case 'delete':
                      _confirmDelete(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: IconSizes.small),
                        SizedBox(width: Spacing.sm),
                        Text('Edit shelf'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outlined,
                          size: IconSizes.small,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Delete shelf',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant),
        // Book count
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Text(
                '${_sortedBooks.length} ${_sortedBooks.length == 1 ? 'book' : 'books'}',
                style: textTheme.titleMedium,
              ),
              const Spacer(),
              // Sort button
              TextButton.icon(
                onPressed: () => _showSortOptions(context),
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                ),
                label: Text(_sortLabel),
              ),
            ],
          ),
        ),
        // Books list
        Expanded(
          child: _sortedBooks.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  itemCount: _sortedBooks.length,
                  itemBuilder: (context, index) =>
                      _buildBookItem(context, _sortedBooks[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No books in this shelf',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Add books from your library to organize them here',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, BookData book) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.go('/library/details/${book.id}');
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: ComponentSizes.bookCoverWidthList,
                  height: ComponentSizes.bookCoverHeightList,
                  child: book.coverURL != null
                      ? Image.network(
                          book.coverURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCoverPlaceholder(context),
                        )
                      : _buildCoverPlaceholder(context),
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.progress > 0) ...[
                      const SizedBox(height: Spacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: book.progress,
                                minHeight: 4,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                color: book.isFinished
                                    ? colorScheme.tertiary
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            book.progressLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Remove button
              if (widget.onRemoveBook != null)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: colorScheme.error,
                  ),
                  onPressed: () => _confirmRemoveBook(context, book),
                  tooltip: 'Remove from shelf',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book,
        size: 24,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Text(
                  'Sort by',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              _buildSortOption(context, BookSortOption.title, 'Title'),
              _buildSortOption(context, BookSortOption.author, 'Author'),
              _buildSortOption(context, BookSortOption.progress, 'Progress'),
              _buildSortOption(context, BookSortOption.dateAdded, 'Date added'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    BookSortOption option,
    String label,
  ) {
    final isSelected = _sortOption == option;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        isSelected
            ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
            : Icons.sort,
        color: isSelected ? colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: colorScheme.primary)
          : null,
      onTap: () {
        Navigator.of(context).pop();
        _setSortOption(option);
      },
    );
  }

  void _confirmRemoveBook(BuildContext context, BookData book) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from shelf'),
        content: Text('Remove "${book.title}" from "${widget.shelf.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Remove from local list and trigger rebuild
              setState(() {
                _sortedBooks.removeWhere((b) => b.id == book.id);
              });
              // Notify parent to persist the change
              widget.onRemoveBook?.call(book);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete shelf'),
        content: Text(
          'Delete "${widget.shelf.name}"? Books will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close sheet
              widget.onDelete?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
