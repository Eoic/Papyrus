import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:provider/provider.dart';

/// Responsive grid for displaying books.
/// - Mobile: 2 columns with 8px gap
/// - Tablet: 3-4 columns with 12px gap
/// - Desktop: 5 columns with 16px gap
class BookGrid extends StatelessWidget {
  final List<BookData> books;
  final void Function(BookData book)? onBookTap;
  final EdgeInsets? padding;

  const BookGrid({
    super.key,
    required this.books,
    this.onBookTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate columns and spacing based on screen width
    int crossAxisCount;
    double spacing;
    double childAspectRatio;

    if (screenWidth >= Breakpoints.desktopLarge) {
      crossAxisCount = 6;
      spacing = Spacing.md;
      childAspectRatio = 0.55;
    } else if (screenWidth >= Breakpoints.desktopSmall) {
      crossAxisCount = 5;
      spacing = Spacing.md;
      childAspectRatio = 0.55;
    } else if (screenWidth >= Breakpoints.tablet) {
      crossAxisCount = 4;
      spacing = Spacing.sm + 4;
      childAspectRatio = 0.55;
    } else {
      crossAxisCount = 2;
      spacing = Spacing.sm;
      childAspectRatio = 0.58;
    }

    final libraryProvider = context.watch<LibraryProvider>();

    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      cacheExtent: 200,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isFavorite = libraryProvider.isBookFavorite(
          book.id,
          book.isFavorite,
        );
        return BookCard(
          book: book,
          isFavorite: isFavorite,
          onToggleFavorite: (current) =>
              libraryProvider.toggleFavorite(book.id, current),
          onTap: onBookTap != null ? () => onBookTap!(book) : null,
        );
      },
    );
  }
}
