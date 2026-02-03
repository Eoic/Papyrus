import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Section displaying recently added books in a horizontal scroll.
class RecentlyAddedSection extends StatelessWidget {
  /// List of recently added books.
  final List<BookData> books;

  /// Called when a book is tapped.
  final void Function(BookData book)? onBookTap;

  /// Called when "See all" is tapped.
  final VoidCallback? onSeeAll;

  /// Whether to use desktop styling (larger covers).
  final bool isDesktop;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const RecentlyAddedSection({
    super.key,
    required this.books,
    this.onBookTap,
    this.onSeeAll,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return isEinkMode
          ? _buildEinkEmptyState(context)
          : _buildEmptyState(context);
    }

    if (isEinkMode) return _buildEinkSection(context);
    return _buildStandardSection(context);
  }

  // ============================================================================
  // STANDARD LAYOUT
  // ============================================================================

  Widget _buildStandardSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coverWidth = isDesktop ? 100.0 : 80.0;
    final coverHeight = isDesktop ? 150.0 : 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recently added', style: textTheme.titleMedium),
              TextButton(
                onPressed: onSeeAll ?? () => context.go('/library'),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        // Horizontal scroll
        SizedBox(
          height: coverHeight + 8, // Extra space for shadows
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            itemCount: books.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: Spacing.sm + Spacing.xs),
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildBookCover(
                context,
                book: book,
                width: coverWidth,
                height: coverHeight,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCover(
    BuildContext context, {
    required BookData book,
    required double width,
    required double height,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _onBookTap(context, book),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: book.coverURL != null && book.coverURL!.isNotEmpty
            ? Image.network(
                book.coverURL!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildCoverPlaceholder(context, book),
              )
            : _buildCoverPlaceholder(context, book),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context, BookData book) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(Spacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 24,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            book.title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkDefault,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENTLY ADDED',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: onSeeAll ?? () => context.go('/library'),
                  child: Text(
                    'SEE ALL >',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Book list
          ...books.take(3).map((book) => _buildEinkBookRow(context, book)),
        ],
      ),
    );
  }

  Widget _buildEinkBookRow(BuildContext context, BookData book) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _onBookTap(context, book),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: TouchTargets.einkMin),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black26)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title.toUpperCase(),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book.author,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Text(
              '>',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // EMPTY STATES
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'No books added recently',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          const Icon(Icons.library_books_outlined, size: 40),
          const SizedBox(height: Spacing.sm),
          Text(
            'NO BOOKS ADDED RECENTLY',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _onBookTap(BuildContext context, BookData book) {
    if (onBookTap != null) {
      onBookTap!(book);
    } else {
      context.push('/library/details/${book.id}');
    }
  }
}
