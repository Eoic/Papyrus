import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Section displaying recently added books in a horizontal scroll.
class RecentlyAddedSection extends StatelessWidget {
  /// List of recently added books.
  final List<Book> books;

  /// Called when a book is tapped.
  final void Function(Book book)? onBookTap;

  /// Called when "View all" is tapped.
  final VoidCallback? onSeeAll;

  /// Whether to use desktop styling (larger covers).
  final bool isDesktop;

  const RecentlyAddedSection({
    super.key,
    required this.books,
    this.onBookTap,
    this.onSeeAll,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return _buildEmptyState(context);
    return _buildSection(context);
  }

  // ============================================================================
  // STANDARD LAYOUT
  // ============================================================================

  /// Builds the section with header and horizontal book scroll.
  Widget _buildSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coverWidth = isDesktop ? 100.0 : 80.0;
    final coverHeight = isDesktop ? 150.0 : 120.0;
    final horizontalPadding = isDesktop ? 0.0 : Spacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recently added', style: textTheme.titleMedium),
              _buildViewAllButton(
                onPressed: onSeeAll ?? () => context.go('/library'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          height: coverHeight + 8,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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

  /// Builds a single book cover with tap handling and hover cursor.
  Widget _buildBookCover(
    BuildContext context, {
    required Book book,
    required double width,
    required double height,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
      ),
    );
  }

  /// Builds a placeholder with icon and title when no cover image is available.
  Widget _buildCoverPlaceholder(BuildContext context, Book book) {
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

  /// Builds the "View all" text button with forward arrow.
  Widget _buildViewAllButton({required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Text('View all'),
      label: const Icon(Icons.arrow_forward, size: 16),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  /// Builds the empty state when no books have been added recently.
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

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _onBookTap(BuildContext context, Book book) {
    if (onBookTap != null) {
      onBookTap!(book);
    } else {
      context.push('/library/details/${book.id}');
    }
  }
}
