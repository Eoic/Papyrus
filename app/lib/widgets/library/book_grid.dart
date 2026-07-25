import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_card.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:provider/provider.dart';

/// Responsive grid for displaying books.
/// - Mobile: 2 columns with 8px gap
/// - Tablet: 3-4 columns with 12px gap
/// - Desktop: 5 columns with 16px gap
class BookGrid extends StatelessWidget {
  final List<Book> books;
  final void Function(Book book)? onBookTap;
  final EdgeInsets? padding;
  final Map<String, AcquisitionJob> acquisitionJobsByBookId;
  final List<AcquisitionJob> placeholderJobs;
  final Set<String> selectedAcquisitionJobIds;
  final ValueChanged<AcquisitionJob>? onAcquisitionTap;
  final ValueChanged<AcquisitionJob>? onAcquisitionSelectionToggle;

  const BookGrid({
    super.key,
    required this.books,
    this.onBookTap,
    this.padding,
    this.acquisitionJobsByBookId = const {},
    this.placeholderJobs = const [],
    this.selectedAcquisitionJobIds = const {},
    this.onAcquisitionTap,
    this.onAcquisitionSelectionToggle,
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
    final bookIds = books.map((book) => book.id).toSet();
    final linkedJobsByBookId = <String, AcquisitionJob>{
      for (final entry in acquisitionJobsByBookId.entries)
        if (bookIds.contains(entry.key)) entry.key: entry.value,
    };

    for (final job in placeholderJobs) {
      final bookId = job.bookId;

      if (bookId != null && bookIds.contains(bookId)) {
        linkedJobsByBookId.putIfAbsent(bookId, () => job);
      }
    }

    final linkedJobIds = linkedJobsByBookId.values.map((job) => job.id).toSet();
    final orphanJobs = <AcquisitionJob>[];
    final seenJobIds = <String>{...linkedJobIds};
    final seenPendingBookIds = <String>{};

    for (final job in placeholderJobs) {
      if (!seenJobIds.add(job.id)) {
        continue;
      }

      final bookId = job.bookId;

      if (bookId != null && (bookIds.contains(bookId) || !seenPendingBookIds.add(bookId))) {
        continue;
      }

      orphanJobs.add(job);
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: GridView.builder(
        padding: padding ?? const EdgeInsets.only(left: Spacing.md, right: Spacing.md, bottom: Spacing.md),
        cacheExtent: 200,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: books.length + orphanJobs.length,
        itemBuilder: (context, index) {
          if (index >= books.length) {
            final job = orphanJobs[index - books.length];

            return AcquisitionPlaceholderCard(
              job: job,
              onTap: onAcquisitionTap == null ? null : () => onAcquisitionTap!(job),
              isSelectionMode: selectedAcquisitionJobIds.isNotEmpty,
              isSelected: selectedAcquisitionJobIds.contains(job.id),
              onSelectToggle: onAcquisitionSelectionToggle == null ? null : () => onAcquisitionSelectionToggle!(job),
              onEnterSelectionMode: onAcquisitionSelectionToggle == null
                  ? null
                  : () => onAcquisitionSelectionToggle!(job),
            );
          }

          final book = books[index];
          final job = linkedJobsByBookId[book.id];
          final isFavorite = libraryProvider.isBookFavorite(book.id, book.isFavorite);

          return BookCard(
            book: book,
            isFavorite: isFavorite,
            onToggleFavorite: (current) => libraryProvider.toggleFavorite(book.id, current),
            onTap: job != null
                ? onAcquisitionTap == null
                      ? null
                      : () => onAcquisitionTap!(job)
                : onBookTap == null
                ? null
                : () => onBookTap!(book),
            isSelectionMode: job != null ? selectedAcquisitionJobIds.isNotEmpty : libraryProvider.isSelectionMode,
            isSelected: job != null
                ? selectedAcquisitionJobIds.contains(job.id)
                : libraryProvider.isBookSelected(book.id),
            onSelectToggle: job != null
                ? onAcquisitionSelectionToggle == null
                      ? null
                      : () => onAcquisitionSelectionToggle!(job)
                : () => libraryProvider.toggleBookSelection(book.id),
            onEnterSelectionMode: job != null
                ? onAcquisitionSelectionToggle == null
                      ? null
                      : () => onAcquisitionSelectionToggle!(job)
                : () => libraryProvider.enterSelectionMode(book.id),
            acquisitionJob: job,
          );
        },
      ),
    );
  }
}
