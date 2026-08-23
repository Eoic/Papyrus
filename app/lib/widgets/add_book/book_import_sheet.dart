import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/services/book_import_commit_service.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/book_import_controller.dart';
import 'package:papyrus/widgets/add_book/book_import_sheet_sections.dart';
import 'package:provider/provider.dart';

export 'package:papyrus/widgets/add_book/book_import_controller.dart'
    show BookImportProcessor, DigitalBookFilePicker, ImportedBookCommitter, ImportedBookFileDeleter;

/// A unified sheet for selecting, processing, and summarizing book imports.
class BookImportSheet extends StatefulWidget {
  const BookImportSheet({
    super.key,
    required this.pickFiles,
    required this.processor,
    required this.deleteBookFile,
    required this.committer,
    required this.onClose,
    this.onCompleted,
    this.scrollController,
  });

  final DigitalBookFilePicker pickFiles;
  final BookImportProcessor processor;
  final ImportedBookFileDeleter deleteBookFile;
  final ImportedBookCommitter committer;
  final VoidCallback onClose;
  final ValueChanged<List<Book>>? onCompleted;
  final ScrollController? scrollController;

  static Future<List<SelectedBookFile>> defaultPickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kIsWeb ? bookImportWebExtensions : bookImportNativeExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return const [];
    return result.files.map((file) => SelectedBookFile(name: file.name, bytes: file.bytes)).toList();
  }

  /// Opens the import flow as a root-level modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    DigitalBookFilePicker? pickFiles,
    BookImportProcessor? processor,
    ImportedBookFileDeleter? deleteBookFile,
    ImportedBookCommitter? committer,
  }) {
    final importService = processor == null || deleteBookFile == null ? context.read<BookImportService>() : null;
    final effectiveProcessor = processor ?? importService!.importBook;
    final effectiveDeleter = deleteBookFile ?? importService!.deleteBookFile;
    final effectiveCommitter =
        committer ?? (BookImportResult result, String filename) => _commitResult(context, result, filename);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) {
        final effectivePickFiles = pickFiles ?? defaultPickFiles;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => BookImportSheet(
            pickFiles: effectivePickFiles,
            processor: effectiveProcessor,
            deleteBookFile: effectiveDeleter,
            committer: effectiveCommitter,
            scrollController: scrollController,
            onClose: () => Navigator.of(sheetContext).pop(),
            onCompleted: (books) {
              final count = books.length;
              ScaffoldMessenger.maybeOf(
                context,
              )?.showSnackBar(SnackBar(content: Text('$count ${count == 1 ? 'book' : 'books'} added to library')));
            },
          ),
        );
      },
    );
  }

  static Future<Book> _commitResult(BuildContext context, BookImportResult result, String sourceFilename) async {
    final dataStore = context.read<DataStore>();
    final bookRepository = dataStore.requireBookRepository();
    final queue = context.read<MediaUploadQueue>();
    final importService = context.read<BookImportService>();
    final authProvider = context.read<AuthProvider>();
    final powerSyncService = context.read<PapyrusPowerSyncService>();
    final isOnlineAccount = authProvider.isSignedIn && powerSyncService.mode == LibraryDatabaseMode.authenticated;
    final accountScope = isOnlineAccount ? queue.activeScope : null;
    if (isOnlineAccount && accountScope == null) {
      throw StateError('Cannot import account media without an active media storage scope');
    }

    final extension = result.fileExtension;
    final filePath = kIsWeb ? 'opfs://books/${result.bookId}.$extension' : result.bookId;
    final commitService = BookImportCommitService(
      storePendingCover: importService.storePendingCoverFile,
      storeGuestCover: importService.storeGuestCoverFile,
      deletePendingCover: importService.deletePendingCoverFile,
      deleteGuestCover: importService.deleteGuestCoverFile,
      addBook: (book) => dataStore.addBookToRepositoryAndWait(bookRepository, book),
      deleteBook: (bookId) => dataStore.deleteBookFromRepositoryAndWait(bookRepository, bookId),
      enqueueImportedBookMedia: queue.enqueueImportedBookMedia,
      isLibraryContextCurrent: () {
        final currentIsOnlineAccount =
            authProvider.isSignedIn && powerSyncService.mode == LibraryDatabaseMode.authenticated;
        return dataStore.isBookRepositoryCurrent(bookRepository) &&
            currentIsOnlineAccount == isOnlineAccount &&
            queue.activeScope == accountScope;
      },
    );
    return commitService.commit(
      result: result,
      sourceFilename: sourceFilename,
      addedAt: DateTime.now(),
      localFilePath: filePath,
      accountScope: accountScope,
    );
  }

  @override
  State<BookImportSheet> createState() => _BookImportSheetState();
}

class _BookImportSheetState extends State<BookImportSheet> {
  late final BookImportController _controller;
  Future<void>? _closeFuture;

  @override
  void initState() {
    super.initState();
    _controller = BookImportController(
      pickFiles: () => widget.pickFiles(),
      processor: (bytes, filename) => widget.processor(bytes, filename),
      deleteBookFile: (bookId) => widget.deleteBookFile(bookId),
      committer: (result, filename) => widget.committer(result, filename),
      onCompleted: (books) => widget.onCompleted?.call(books),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestClose());
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.phase) {
          BookImportPhase.selecting => BookImportSelectingSection(
            files: _controller.files,
            readableFiles: _controller.readableFiles,
            isPicking: _controller.isPicking,
            pickerError: _controller.pickerError,
            scrollController: widget.scrollController,
            onBrowse: () => unawaited(_controller.browse()),
            onDroppedFiles: _controller.applyDroppedFiles,
            onRemoveFile: _controller.removeFile,
            onClearSelection: _controller.clearSelection,
            onStartImport: _controller.startImport,
            onClose: widget.onClose,
          ),
          BookImportPhase.processing => BookImportProcessingSection(
            items: _controller.items,
            isClosing: _controller.isClosing,
            anyProcessing: _controller.anyProcessing,
            scrollController: widget.scrollController,
            onRetry: (id) => unawaited(_controller.retryItem(id)),
            onRemove: (id) => unawaited(_removeItem(id)),
            onClose: () => unawaited(_requestClose()),
          ),
          BookImportPhase.summary => BookImportSummarySection(
            items: _controller.items,
            failureCount: _controller.failureCount,
            isClosing: _controller.isClosing,
            scrollController: widget.scrollController,
            onRetry: (id) => unawaited(_controller.retryItem(id)),
            onRetryFailed: _retryFailedItems,
            onDone: () => unawaited(_requestClose()),
          ),
        },
      ),
    );
  }

  void _retryFailedItems() {
    for (final item in List<BookImportBatchItem>.of(_controller.items)) {
      if (item.canRetry) unawaited(_controller.retryItem(item.id));
    }
  }

  Future<void> _removeItem(String id) async {
    final result = await _controller.removeItem(id);
    if (!mounted || result != BookImportRemoveResult.cleanupFailed) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Could not remove the imported file.')));
  }

  Future<void> _requestClose() {
    final inFlight = _closeFuture;
    if (inFlight != null) return inFlight;
    final close = _performClose();
    _closeFuture = close;
    unawaited(
      close.whenComplete(() {
        if (identical(_closeFuture, close)) _closeFuture = null;
      }),
    );
    return close;
  }

  Future<void> _performClose() async {
    final result = await _controller.requestClose();
    if (!mounted) return;
    switch (result) {
      case BookImportCloseResult.closed:
        widget.onClose();
      case BookImportCloseResult.cleanupFailed:
      case BookImportCloseResult.processingCleanupFailed:
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('Could not remove temporary files. Please try again.')));
    }
  }
}
