import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/repositories/library_repository.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/services/book_delete_cleanup_service.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/bulk_action_bar.dart';
import 'package:papyrus/widgets/library/bulk_status_sheet.dart';
import 'package:papyrus/widgets/shelves/move_to_shelf_sheet.dart';
import 'package:papyrus/widgets/topics/manage_topics_sheet.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/themes/app_motion.dart';

// =============================================================================
// LOW-LEVEL BULK OPERATIONS
// =============================================================================

/// Add all selected books to the given shelves.
Future<void> bulkAddToShelves(
  DataStore dataStore,
  Set<String> bookIds,
  List<String> shelfIds, {
  LibraryMembershipWriter? repository,
}) => dataStore.updateBookMemberships(bookIds: bookIds, shelfIds: shelfIds, additive: true, repository: repository);

/// Set topics for all selected books (additive — does not remove existing).
Future<void> bulkAddTopics(
  DataStore dataStore,
  Set<String> bookIds,
  List<String> tagIds, {
  LibraryMembershipWriter? repository,
}) => dataStore.updateBookMemberships(bookIds: bookIds, tagIds: tagIds, additive: true, repository: repository);

/// Change reading status for all selected books.
void bulkChangeStatus(DataStore dataStore, Set<String> bookIds, LibraryReadingStatus status) {
  for (final bookId in bookIds) {
    final book = dataStore.getBook(bookId);
    if (book != null) {
      dataStore.updateBook(book.copyWith(readingStatus: status));
    }
  }
}

/// Toggle favorite for all selected books.
/// If any are not favorited, sets all to favorite; otherwise un-favorites all.
Future<void> bulkToggleFavorite(LibraryProvider libraryProvider, DataStore dataStore, Set<String> bookIds) async {
  final allFavorite = bookIds.every((id) {
    final book = dataStore.getBook(id);
    return book != null && libraryProvider.isBookFavorite(id, book.isFavorite);
  });

  final writes = <Future<void>>[];
  for (final bookId in bookIds) {
    final book = dataStore.getBook(bookId);
    if (book == null) continue;
    final currentFav = libraryProvider.isBookFavorite(bookId, book.isFavorite);
    if (allFavorite) {
      // Un-favorite all
      if (currentFav) writes.add(libraryProvider.toggleFavorite(bookId, true));
    } else {
      // Favorite all
      if (!currentFav) writes.add(libraryProvider.toggleFavorite(bookId, false));
    }
  }
  await Future.wait(writes);
}

/// Delete all selected books.
void bulkDelete(DataStore dataStore, Set<String> bookIds) {
  for (final bookId in bookIds) {
    dataStore.deleteBook(bookId);
  }
}

// =============================================================================
// UI HANDLERS (shared between LibraryPage and ShelfContentsPage)
// =============================================================================

/// Show the move-to-shelf sheet for selected books.
void handleBulkAddToShelf(BuildContext context, LibraryProvider libraryProvider) {
  final dataStore = context.read<DataStore>();
  final selectedIds = libraryProvider.selectedBookIds.toList();
  final repository = dataStore.libraryRepository?.memberships;

  MoveToShelfSheet.showBulk(
    context,
    bookIds: selectedIds,
    onSave: (shelfIds) async {
      await bulkAddToShelves(dataStore, selectedIds.toSet(), shelfIds, repository: repository);
      libraryProvider.exitSelectionMode();
    },
  );
}

/// Show the manage-topics sheet for selected books.
void handleBulkManageTopics(BuildContext context, LibraryProvider libraryProvider) {
  final dataStore = context.read<DataStore>();
  final selectedIds = libraryProvider.selectedBookIds.toList();
  final repository = dataStore.libraryRepository?.memberships;

  ManageTopicsSheet.showBulk(
    context,
    bookIds: selectedIds,
    onSave: (tagIds) async {
      await bulkAddTopics(dataStore, selectedIds.toSet(), tagIds, repository: repository);
      libraryProvider.exitSelectionMode();
    },
  );
}

/// Show the status change sheet for selected books.
void handleBulkChangeStatus(BuildContext context, LibraryProvider libraryProvider) {
  final dataStore = context.read<DataStore>();

  BulkStatusSheet.show(
    context,
    bookCount: libraryProvider.selectedCount,
    onStatusSelected: (status) {
      bulkChangeStatus(dataStore, libraryProvider.selectedBookIds, status);
      libraryProvider.exitSelectionMode();
    },
  );
}

/// Toggle favorite status for all selected books.
Future<void> handleBulkToggleFavorite(BuildContext context, LibraryProvider libraryProvider) async {
  final dataStore = context.read<DataStore>();
  try {
    await bulkToggleFavorite(libraryProvider, dataStore, libraryProvider.selectedBookIds);
    libraryProvider.exitSelectionMode();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Could not save favorites. Please try again.')),
      );
    }
  }
}

/// Show a confirmation dialog and delete all selected books.
void handleBulkDelete(BuildContext context, LibraryProvider libraryProvider) {
  final dataStore = context.read<DataStore>();
  final count = libraryProvider.selectedCount;

  showDialog(
    animationStyle: AppMotion.animationStyle(context),
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete books?'),
      content: Text(
        'Are you sure you want to delete $count ${count == 1 ? 'book' : 'books'}? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final selectedBookIds = libraryProvider.selectedBookIds.toSet();
            final mediaUploadQueue = context.read<MediaUploadQueue>();
            final importService = context.read<BookImportService>();
            final mediaScope = mediaUploadQueue.activeScope;
            Navigator.pop(context);
            for (final bookId in selectedBookIds) {
              final book = dataStore.getBook(bookId);
              await deleteBookWithMediaCleanup(
                dataStore: dataStore,
                mediaUploadQueue: mediaUploadQueue,
                bookId: bookId,
                coverMediaId: book?.coverMediaId,
                deleteBookFile: importService.deleteBookFile,
                deleteCoverFile: mediaScope == null
                    ? null
                    : (mediaId) => importService.deleteCoverFile(mediaScope, mediaId),
              );
            }
            libraryProvider.exitSelectionMode();
          },
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

/// Build a [BulkActionBar] wired to all bulk action handlers.
BulkActionBar buildBulkActionBar(BuildContext context, LibraryProvider libraryProvider) {
  return BulkActionBar(
    onAddToShelf: () => handleBulkAddToShelf(context, libraryProvider),
    onManageTopics: () => handleBulkManageTopics(context, libraryProvider),
    onChangeStatus: () => handleBulkChangeStatus(context, libraryProvider),
    onToggleFavorite: () => handleBulkToggleFavorite(context, libraryProvider),
    onDelete: () => handleBulkDelete(context, libraryProvider),
  );
}

/// Build the mobile bottom action bar container with bulk actions.
Widget buildMobileBottomActionBar(BuildContext context, LibraryProvider libraryProvider) {
  final colorScheme = Theme.of(context).colorScheme;

  return Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        child: buildBulkActionBar(context, libraryProvider),
      ),
    ),
  );
}
