import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_card.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:provider/provider.dart';

typedef _GridLayout = ({int crossAxisCount, double spacing, double childAspectRatio});

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final LibraryViewMode libraryViewMode;
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
    required this.libraryViewMode,
    this.onBookTap,
    this.padding,
    this.acquisitionJobsByBookId = const {},
    this.placeholderJobs = const [],
    this.selectedAcquisitionJobIds = const {},
    this.onAcquisitionTap,
    this.onAcquisitionSelectionToggle,
  });

  _GridLayout _resolveGridLayout({required double width, required LibraryViewMode viewMode}) {
    if (viewMode == LibraryViewMode.list) {
      throw ArgumentError('List mode does not use a grid layout');
    }

    final isLargeGrid = viewMode == LibraryViewMode.largeGrid;

    if (width >= Breakpoints.desktopLarge) {
      return (crossAxisCount: isLargeGrid ? 4 : 6, spacing: Spacing.md, childAspectRatio: 0.55);
    }

    if (width >= Breakpoints.desktopSmall) {
      return (crossAxisCount: isLargeGrid ? 3 : 5, spacing: Spacing.md, childAspectRatio: 0.55);
    }

    if (width >= Breakpoints.tablet) {
      return (crossAxisCount: isLargeGrid ? 3 : 4, spacing: Spacing.sm + 4, childAspectRatio: 0.55);
    }

    return (crossAxisCount: 2, spacing: Spacing.sm, childAspectRatio: 0.58);
  }

  @override
  Widget build(BuildContext context) {
    final layout = _resolveGridLayout(width: MediaQuery.sizeOf(context).width, viewMode: libraryViewMode);
    final libraryProvider = context.watch<LibraryProvider>();
    final bookIds = books.map((book) => book.id).toSet();
    final placeholderJobsByBookId = <String, AcquisitionJob>{};

    for (final job in placeholderJobs) {
      final bookId = job.bookId;

      if (bookId != null) {
        placeholderJobsByBookId.putIfAbsent(bookId, () => job);
      }
    }

    final linkedJobsByBookId = <String, AcquisitionJob>{};
    final claimedJobIds = <String>{};

    for (final book in books) {
      final job = acquisitionJobsByBookId[book.id] ?? placeholderJobsByBookId[book.id];

      if (job != null && claimedJobIds.add(job.id)) {
        linkedJobsByBookId[book.id] = job;
      }
    }

    final orphanJobs = <AcquisitionJob>[];
    final seenJobIds = <String>{...claimedJobIds};
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
        // Flutter 3.41 compatibility; replaced by scrollCacheExtent in 3.42+.
        // ignore: deprecated_member_use
        cacheExtent: 200,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.crossAxisCount,
          mainAxisSpacing: layout.spacing,
          crossAxisSpacing: layout.spacing,
          childAspectRatio: layout.childAspectRatio,
        ),
        itemCount: books.length + orphanJobs.length,
        itemBuilder: (context, index) {
          if (index >= books.length) {
            final job = orphanJobs[index - books.length];
            final canSelect = job.status != AcquisitionJobStatus.completed;

            return AcquisitionPlaceholderCard(
              job: job,
              onTap: onAcquisitionTap == null ? null : () => onAcquisitionTap!(job),
              isSelectionMode: canSelect && selectedAcquisitionJobIds.isNotEmpty,
              isSelected: selectedAcquisitionJobIds.contains(job.id),
              onSelectToggle: !canSelect || onAcquisitionSelectionToggle == null
                  ? null
                  : () => onAcquisitionSelectionToggle!(job),
              onEnterSelectionMode: !canSelect || onAcquisitionSelectionToggle == null
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
            onToggleFavorite: job == null ? (current) => libraryProvider.toggleFavorite(book.id, current) : null,
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
