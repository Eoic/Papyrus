import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/media/media_cache_service.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/services/book_delete_cleanup_service.dart';
import 'package:papyrus/services/book_download_service.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/widgets/context_menu/book_context_menu.dart';
import 'package:papyrus/widgets/shelves/move_to_shelf_sheet.dart';
import 'package:papyrus/widgets/topics/manage_topics_sheet.dart';
import 'package:provider/provider.dart';

/// Show the book context menu with standard actions.
///
/// This helper centralizes the context menu logic used by book cards and list items.
/// The [position] parameter determines where the menu appears; if null, it will
/// be positioned at the center of the screen.
void showBookContextMenu({required BuildContext context, required Book book, Offset? position}) {
  final libraryProvider = context.read<LibraryProvider>();
  final isFavorite = libraryProvider.isBookFavorite(book.id, book.isFavorite);

  BookContextMenu.show(
    context: context,
    book: book,
    isFavorite: isFavorite,
    tapPosition: position,
    onSelect: () {
      libraryProvider.enterSelectionMode(book.id);
    },
    onFavoriteToggle: () {
      libraryProvider.toggleFavorite(book.id, isFavorite);
    },
    onEdit: () {
      context.goNamed('BOOK_EDIT', pathParameters: {'bookId': book.id});
    },
    onMoveToShelf: () {
      _showMoveToShelfSheet(context, book);
    },
    onManageTopics: () {
      _showManageTopicsSheet(context, book);
    },
    onStatusChange: (status) {
      final dataStore = context.read<DataStore>();
      final currentBook = dataStore.getBook(book.id);
      if (currentBook == null) return;
      dataStore.updateBook(currentBook.copyWith(readingStatus: status));
    },
    onDownload: () {
      unawaited(_downloadBookFile(context, book));
    },
    onDelete: () {
      final mediaUploadQueue = context.read<MediaUploadQueue>();
      final importService = context.read<BookImportService>();
      final mediaScope = mediaUploadQueue.activeScope;
      unawaited(
        deleteBookWithMediaCleanup(
          dataStore: context.read<DataStore>(),
          mediaUploadQueue: mediaUploadQueue,
          bookId: book.id,
          coverMediaId: book.coverMediaId,
          deleteBookFile: importService.deleteBookFile,
          deleteCoverFile: mediaScope == null ? null : (mediaId) => importService.deleteCoverFile(mediaScope, mediaId),
        ),
      );
    },
  );
}

Future<void> _downloadBookFile(BuildContext context, Book book) async {
  final messenger = ScaffoldMessenger.of(context);
  final importService = context.read<BookImportService>();
  final mediaCacheService = context.read<MediaCacheService>();
  final downloadService = context.read<BookDownloadService>();

  messenger.showSnackBar(const SnackBar(content: Text('Preparing download...')));

  try {
    final cached = await mediaCacheService.getValidCachedBookFile(book, readLocalBookFile: importService.getBookFile);
    if (!context.mounted) return;

    final bytes =
        cached ??
        await mediaCacheService.ensureBookFileCached(
          book,
          readLocalBookFile: importService.getBookFile,
          writeLocalBookFile: importService.storeBookFile,
          downloadMedia: context.read<AuthProvider>().downloadMedia,
        );
    final result = await downloadService.saveBookFile(book: book, bytes: bytes);

    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (result.saved) {
      messenger.showSnackBar(SnackBar(content: Text('Downloaded "${book.title}"')));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Download canceled')));
    }
  } catch (_) {
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Could not download this book file.')));
  }
}

/// Shows the manage topics sheet and handles topic assignments.
void _showManageTopicsSheet(BuildContext context, Book book) {
  final dataStore = context.read<DataStore>();
  final currentTagIds = dataStore.getTagIdsForBook(book.id).toSet();
  final repository = dataStore.libraryRepository?.memberships;
  final bookId = book.id;

  ManageTopicsSheet.show(
    context,
    book: book,
    onSave: (newTagIds) => dataStore.updateBookMemberships(
      bookIds: {bookId},
      tagIds: newTagIds,
      previousTagIds: currentTagIds,
      repository: repository,
    ),
  );
}

/// Shows the move to shelf sheet and handles shelf assignments.
void _showMoveToShelfSheet(BuildContext context, Book book) {
  final dataStore = context.read<DataStore>();
  final currentShelfIds = dataStore.getShelfIdsForBook(book.id).toSet();
  final repository = dataStore.libraryRepository?.memberships;
  final bookId = book.id;

  MoveToShelfSheet.show(
    context,
    book: book,
    onSave: (newShelfIds) => dataStore.updateBookMemberships(
      bookIds: {bookId},
      shelfIds: newShelfIds,
      previousShelfIds: currentShelfIds,
      repository: repository,
    ),
  );
}
