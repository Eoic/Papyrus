import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/services/book_import_commit_service.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:provider/provider.dart';

/// Captures the destination before asynchronous work starts. A session must never
/// silently move an import into the account selected while it was downloading.
class BookImportSession {
  const BookImportSession({
    required this.process,
    required this.deleteFile,
    required this.commit,
    required this.isCurrent,
  });
  final Future<BookImportResult> Function(Uint8List bytes, String filename) process;
  final Future<void> Function(String bookId) deleteFile;
  final Future<Book> Function(BookImportResult result, String filename) commit;
  final bool Function() isCurrent;

  factory BookImportSession.fromContext(BuildContext context) => BookImportSession.capture(
    dataStore: context.read<DataStore>(),
    queue: context.read<MediaUploadQueue>(),
    importService: context.read<BookImportService>(),
    authProvider: context.read<AuthProvider>(),
    powerSyncService: context.read<PapyrusPowerSyncService>(),
  );

  factory BookImportSession.capture({
    required DataStore dataStore,
    required MediaUploadQueue queue,
    required BookImportService importService,
    required AuthProvider authProvider,
    required PapyrusPowerSyncService powerSyncService,
  }) {
    final repository = dataStore.requireBookRepository();
    final authenticated = authProvider.isSignedIn && powerSyncService.mode == LibraryDatabaseMode.authenticated;
    final scope = authenticated ? queue.activeScope : null;
    final userId = authProvider.user?.userId;
    if (authenticated && scope == null) {
      throw StateError('Cannot import account media without an active media storage scope');
    }
    if ((authProvider.isSignedIn && (!authenticated || scope?.userId != userId)) ||
        (authProvider.isOfflineMode && powerSyncService.mode != LibraryDatabaseMode.guest)) {
      throw StateError('Wait for the selected library to finish loading before importing.');
    }
    bool isCurrent() =>
        dataStore.isBookRepositoryCurrent(repository) &&
        authProvider.user?.userId == userId &&
        (authProvider.isSignedIn && powerSyncService.mode == LibraryDatabaseMode.authenticated) == authenticated &&
        queue.activeScope == scope;
    final service = BookImportCommitService(
      storePendingCover: importService.storePendingCoverFile,
      storeGuestCover: importService.storeGuestCoverFile,
      deletePendingCover: importService.deletePendingCoverFile,
      deleteGuestCover: importService.deleteGuestCoverFile,
      addBook: (book) => dataStore.addBookToRepositoryAndWait(repository, book),
      deleteBook: (id) => dataStore.deleteBookFromRepositoryAndWait(repository, id),
      enqueueImportedBookMedia: queue.enqueueImportedBookMedia,
      isLibraryContextCurrent: isCurrent,
    );
    return BookImportSession(
      process: importService.importBook,
      deleteFile: importService.deleteBookFile,
      isCurrent: isCurrent,
      commit: (result, filename) => service.commit(
        result: result,
        sourceFilename: filename,
        addedAt: DateTime.now(),
        localFilePath: kIsWeb ? 'opfs://books/${result.bookId}.${result.fileExtension}' : result.bookId,
        accountScope: scope,
      ),
    );
  }
}
