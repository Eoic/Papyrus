import 'dart:async';

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
import 'package:papyrus/widgets/add_book/add_book_sheet_scaffold.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:provider/provider.dart';

typedef BookImportProcessor = Future<BookImportResult> Function(Uint8List bytes, String filename);
typedef ImportedBookFileDeleter = Future<void> Function(String bookId);
typedef ImportedBookCommitter = Future<Book> Function(BookImportResult result, String sourceFilename);

/// Processes a selected batch and keeps each file's result independently actionable.
class BookImportResultsSheet extends StatefulWidget {
  const BookImportResultsSheet({
    super.key,
    required this.files,
    required this.processor,
    required this.deleteBookFile,
    required this.onClose,
    this.committer,
    this.onCompleted,
    this.scrollController,
  });

  final List<SelectedBookFile> files;
  final BookImportProcessor processor;
  final ImportedBookFileDeleter deleteBookFile;
  final ImportedBookCommitter? committer;
  final VoidCallback onClose;
  final ValueChanged<List<Book>>? onCompleted;
  final ScrollController? scrollController;

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
    final filePath = kIsWeb
        ? 'opfs://books/${result.bookId}.$extension'
        : result.bookId; // Native resolves via BookImportService.getBookFile.
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

  /// Opens the processing step as its own root-level modal sheet.
  static Future<void> show(
    BuildContext context, {
    required List<SelectedBookFile> files,
    BookImportProcessor? processor,
    ImportedBookFileDeleter? deleteBookFile,
    ImportedBookCommitter? committer,
  }) {
    final importService = processor == null || deleteBookFile == null ? context.read<BookImportService>() : null;
    final effectiveProcessor = processor ?? importService!.importBook;
    final effectiveDeleter = deleteBookFile ?? importService!.deleteBookFile;
    final effectiveCommitter = committer ?? (result, filename) => _commitResult(context, result, filename);
    final messenger = ScaffoldMessenger.maybeOf(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => BookImportResultsSheet(
          files: files,
          processor: effectiveProcessor,
          deleteBookFile: effectiveDeleter,
          committer: effectiveCommitter,
          scrollController: scrollController,
          onClose: () => Navigator.of(sheetContext).pop(),
          onCompleted: (books) {
            final count = books.length;
            messenger?.showSnackBar(
              SnackBar(content: Text('Added $count ${count == 1 ? 'book' : 'books'} to library')),
            );
          },
        ),
      ),
    );
  }

  @override
  State<BookImportResultsSheet> createState() => _BookImportResultsSheetState();
}

class _BookImportResultsSheetState extends State<BookImportResultsSheet> {
  late List<BookImportBatchItem> _items;
  final Map<String, int> _processingTokens = {};
  final Map<String, Future<bool>> _processingFutures = {};
  final Set<String> _removingIds = {};
  final Set<String> _cleanedBookIds = {};
  final Map<String, Future<bool>> _cleanupFutures = {};
  final List<Book> _addedBooks = [];
  bool _isClosing = false;
  bool _isAdding = false;
  bool _didComplete = false;
  Future<void>? _closeFuture;

  @override
  void initState() {
    super.initState();
    _items = List.generate(
      widget.files.length,
      (index) => BookImportBatchItem.queued(id: 'import-$index', file: widget.files[index]),
      growable: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in List<BookImportBatchItem>.of(_items)) {
        unawaited(_startProcessing(item.id));
      }
    });
  }

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  Future<bool> _startProcessing(String id) {
    final inFlight = _processingFutures[id];
    if (inFlight != null) return inFlight;

    final processing = _process(id);
    _processingFutures[id] = processing;
    unawaited(
      processing.whenComplete(() {
        if (identical(_processingFutures[id], processing)) {
          _processingFutures.remove(id);
        }
      }),
    );
    return processing;
  }

  Future<bool> _process(String id) async {
    if (_isClosing || !mounted) return true;
    final index = _indexOf(id);
    if (index < 0) return true;

    final token = (_processingTokens[id] ?? 0) + 1;
    _processingTokens[id] = token;
    final processingItem = _items[index].startProcessing();
    setState(() => _items[index] = processingItem);

    final bytes = processingItem.file.bytes;
    if (bytes == null) {
      if (!_isCurrentProcessing(id, token)) return true;
      setState(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingFailed('Could not read this file.');
      });
      return true;
    }

    try {
      final result = await widget.processor(bytes, processingItem.file.name);
      if (_isClosing) {
        final deleted = await _deleteTemporary(result.bookId);
        if (!deleted && _isMatchingProcessing(id, token)) {
          setState(() {
            final currentIndex = _indexOf(id);
            _items[currentIndex] = _items[currentIndex].processingSucceeded(result);
          });
        }
        return deleted;
      }
      if (!mounted || !_isMatchingProcessing(id, token)) {
        return _deleteTemporary(result.bookId);
      }
      setState(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingSucceeded(result);
      });
      return true;
    } catch (error) {
      if (!_isCurrentProcessing(id, token)) return true;
      setState(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingFailed(_safeErrorMessage(error));
      });
      return true;
    }
  }

  bool _isCurrentProcessing(String id, int token) {
    return !_isClosing && _isMatchingProcessing(id, token);
  }

  bool _isMatchingProcessing(String id, int token) {
    if (!mounted || _processingTokens[id] != token) return false;
    final index = _indexOf(id);
    return index >= 0 && _items[index].status == BookImportBatchStatus.processing;
  }

  String _safeErrorMessage(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
    return message.isEmpty ? 'Could not import this file.' : message;
  }

  int get _readyCount => _items.where((item) => item.status == BookImportBatchStatus.ready).length;

  bool get _processingSettled => _items.every((item) => item.isSettled);

  bool get _hasCleanupAction => _isClosing || _removingIds.isNotEmpty;

  bool get _canAdd => _processingSettled && _readyCount > 0 && !_isAdding && !_hasCleanupAction;

  Future<void> _addReadyBooks() async {
    if (!_canAdd) return;
    final readyIds = _items
        .where((item) => item.status == BookImportBatchStatus.ready)
        .map((item) => item.id)
        .toList(growable: false);
    if (readyIds.isEmpty) return;

    setState(() {
      _isAdding = true;
      for (final id in readyIds) {
        final index = _indexOf(id);
        if (index >= 0 && _items[index].status == BookImportBatchStatus.ready) {
          _items[index] = _items[index].startAdding();
        }
      }
    });

    for (final id in readyIds) {
      await _commitAddingItem(id);
    }
    if (!mounted) return;
    setState(() => _isAdding = false);
    _completeIfAllAdded();
  }

  Future<void> _retryCommit(String id) async {
    if (_isAdding || _hasCleanupAction || !mounted) return;
    final index = _indexOf(id);
    if (index < 0 || _items[index].status != BookImportBatchStatus.commitFailed) return;

    setState(() {
      _isAdding = true;
      _items[index] = _items[index].startAdding();
    });
    await _commitAddingItem(id);
    if (!mounted) return;
    setState(() => _isAdding = false);
    _completeIfAllAdded();
  }

  Future<void> _commitAddingItem(String id) async {
    final index = _indexOf(id);
    if (index < 0) return;
    final item = _items[index];
    if (item.status != BookImportBatchStatus.adding || item.result == null) return;

    try {
      final book =
          await (widget.committer ??
              (result, filename) =>
                  BookImportResultsSheet._commitResult(context, result, filename))(item.result!, item.file.name);
      if (!mounted) return;
      final currentIndex = _indexOf(id);
      if (currentIndex < 0 || _items[currentIndex].status != BookImportBatchStatus.adding) return;
      setState(() {
        _items[currentIndex] = _items[currentIndex].added();
        _addedBooks.add(book);
      });
    } catch (error) {
      if (!mounted) return;
      final currentIndex = _indexOf(id);
      if (currentIndex < 0 || _items[currentIndex].status != BookImportBatchStatus.adding) return;
      setState(() {
        _items[currentIndex] = _items[currentIndex].commitFailed(_safeErrorMessage(error));
      });
    }
  }

  void _completeIfAllAdded() {
    if (_didComplete || _items.isEmpty || !_items.every((item) => item.status == BookImportBatchStatus.added)) {
      return;
    }
    _didComplete = true;
    final books = List<Book>.unmodifiable(_addedBooks);
    widget.onClose();
    widget.onCompleted?.call(books);
  }

  Future<void> _remove(String id) async {
    if (_isClosing || _isAdding || _removingIds.contains(id)) return;
    final index = _indexOf(id);
    if (index < 0) return;
    final item = _items[index];
    if (item.status != BookImportBatchStatus.processingFailed &&
        item.status != BookImportBatchStatus.ready &&
        item.status != BookImportBatchStatus.commitFailed) {
      return;
    }

    _removingIds.add(id);
    if (mounted) setState(() {});
    var deleted = true;
    final result = item.result;
    if (result != null) {
      deleted = await _deleteTemporary(result.bookId);
    }
    if (!mounted) return;
    _removingIds.remove(id);
    if (_isClosing) {
      setState(() {});
      return;
    }
    if (!deleted) {
      setState(() {});
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Could not remove the imported file. Please try again.')));
      return;
    }
    final currentIndex = _indexOf(id);
    if (currentIndex >= 0) {
      setState(() => _items.removeAt(currentIndex));
      _completeIfAllAdded();
    }
  }

  Future<bool> _deleteTemporary(String bookId) {
    if (_cleanedBookIds.contains(bookId)) return Future.value(true);
    final inFlight = _cleanupFutures[bookId];
    if (inFlight != null) return inFlight;

    final cleanup = _performDelete(bookId);
    _cleanupFutures[bookId] = cleanup;
    unawaited(
      cleanup.whenComplete(() {
        if (identical(_cleanupFutures[bookId], cleanup)) {
          _cleanupFutures.remove(bookId);
        }
      }),
    );
    return cleanup;
  }

  Future<bool> _performDelete(String bookId) async {
    try {
      await widget.deleteBookFile(bookId);
      _cleanedBookIds.add(bookId);
      return true;
    } catch (_) {
      debugPrint('Book import temporary-file cleanup failed.');
      return false;
    }
  }

  Future<void> _requestClose() {
    if (_isAdding) return Future.value();
    final inFlight = _closeFuture;
    if (inFlight != null) return inFlight;

    final close = _close();
    _closeFuture = close;
    unawaited(
      close.whenComplete(() {
        if (identical(_closeFuture, close)) {
          _closeFuture = null;
        }
      }),
    );
    return close;
  }

  Future<void> _close() async {
    if (_isClosing) return;
    if (mounted) {
      setState(() => _isClosing = true);
    } else {
      _isClosing = true;
    }

    final processingResults = await Future.wait(List<Future<bool>>.of(_processingFutures.values));
    if (processingResults.any((cleaned) => !cleaned)) {
      _restoreAfterCloseFailure();
      return;
    }

    final bookIds = _items.where((item) => item.hasTemporaryFile).map((item) => item.result!.bookId).toSet();
    final cleanupResults = await Future.wait(bookIds.map(_deleteTemporary));
    if (cleanupResults.any((deleted) => !deleted)) {
      _restoreAfterCloseFailure();
      return;
    }
    if (!mounted) return;
    widget.onClose();
  }

  void _restoreAfterCloseFailure() {
    if (!mounted) return;
    setState(() => _isClosing = false);
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Could not remove temporary files. Please try again.')));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestClose());
      },
      child: AddBookSheetScaffold(
        title: 'Import results',
        canClose: !_isClosing && !_isAdding,
        onClose: () => unawaited(_requestClose()),
        body: ListView.separated(
          key: const Key('book-import-results-list'),
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _ImportResultRow(
              key: ValueKey(item.id),
              item: item,
              isRemoving: _removingIds.contains(item.id),
              onRetry: _isClosing || _isAdding
                  ? null
                  : () => unawaited(
                      item.status == BookImportBatchStatus.commitFailed
                          ? _retryCommit(item.id)
                          : _startProcessing(item.id),
                    ),
              onRemove: _isClosing || _isAdding ? null : () => unawaited(_remove(item.id)),
            );
          },
        ),
        footer: OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: Spacing.sm,
          overflowSpacing: Spacing.sm,
          children: [
            TextButton(
              onPressed: _isClosing || _isAdding ? null : () => unawaited(_requestClose()),
              child: const Text('Close'),
            ),
            if (_items.isNotEmpty)
              FilledButton(
                onPressed: _canAdd ? () => unawaited(_addReadyBooks()) : null,
                child: Text('Add $_readyCount to library'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImportResultRow extends StatelessWidget {
  const _ImportResultRow({
    super.key,
    required this.item,
    required this.isRemoving,
    required this.onRetry,
    required this.onRemove,
  });

  final BookImportBatchItem item;
  final bool isRemoving;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final failed =
        item.status == BookImportBatchStatus.processingFailed || item.status == BookImportBatchStatus.commitFailed;
    final ready = item.status == BookImportBatchStatus.ready;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _statusIcon(colorScheme),
      title: Text(item.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _statusLabel,
        style: failed ? TextStyle(color: colorScheme.error) : null,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: failed || ready
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (failed) TextButton(onPressed: isRemoving ? null : onRetry, child: const Text('Retry')),
                if (isRemoving)
                  const Padding(
                    padding: EdgeInsets.all(Spacing.sm),
                    child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(tooltip: 'Remove ${item.file.name}', onPressed: onRemove, icon: const Icon(Icons.close)),
              ],
            )
          : null,
    );
  }

  Widget _statusIcon(ColorScheme colorScheme) {
    return switch (item.status) {
      BookImportBatchStatus.queued => const Icon(Icons.schedule_outlined),
      BookImportBatchStatus.processing => const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      BookImportBatchStatus.ready => Icon(Icons.check_circle_outline, color: colorScheme.primary),
      BookImportBatchStatus.processingFailed => Icon(Icons.error_outline, color: colorScheme.error),
      BookImportBatchStatus.adding => const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      BookImportBatchStatus.added => Icon(Icons.check_circle, color: colorScheme.primary),
      BookImportBatchStatus.commitFailed => Icon(Icons.error_outline, color: colorScheme.error),
    };
  }

  String get _statusLabel {
    return switch (item.status) {
      BookImportBatchStatus.queued => 'Queued',
      BookImportBatchStatus.processing => 'Processing',
      BookImportBatchStatus.ready => 'Ready',
      BookImportBatchStatus.processingFailed => item.errorMessage ?? 'Could not import this file.',
      BookImportBatchStatus.adding => 'Adding',
      BookImportBatchStatus.added => 'Added',
      BookImportBatchStatus.commitFailed => item.errorMessage ?? 'Could not add this book.',
    };
  }
}
