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
import 'package:papyrus/widgets/add_book/add_book_sheet_scaffold.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Type aliases (re-exported from the existing two sheets for compatibility)
// ---------------------------------------------------------------------------

typedef DigitalBookFilePicker = Future<List<SelectedBookFile>> Function();
typedef BookImportProcessor = Future<BookImportResult> Function(Uint8List bytes, String filename);
typedef ImportedBookFileDeleter = Future<void> Function(String bookId);
typedef ImportedBookCommitter = Future<Book> Function(BookImportResult result, String sourceFilename);

// ---------------------------------------------------------------------------
// Helper: human-readable file size
// ---------------------------------------------------------------------------

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ---------------------------------------------------------------------------
// Helper: icon per extension
// ---------------------------------------------------------------------------

IconData _iconForExtension(String name) {
  final ext = name.toLowerCase().split('.').last;
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf,
    'epub' || 'mobi' || 'azw3' => Icons.menu_book,
    'cbz' || 'cbr' => Icons.folder_zip,
    'txt' => Icons.text_snippet,
    _ => Icons.insert_drive_file,
  };
}

// ---------------------------------------------------------------------------
// Internal phases
// ---------------------------------------------------------------------------

enum _ImportPhase { selecting, processing, summary }

// ---------------------------------------------------------------------------
// BookImportSheet
// ---------------------------------------------------------------------------

/// A unified import sheet that handles the full journey:
///  1. File selection
///  2. Automatic parse + save pipeline (no manual "Add to library" step)
///  3. Inline summary showing successes and failures
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

  // -- Standard FilePicker launchers -----------------------------------------

  static const _webExtensions = ['epub'];
  static const _nativeExtensions = ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];

  static Future<List<SelectedBookFile>> defaultPickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kIsWeb ? _webExtensions : _nativeExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return const [];
    return result.files.map((file) => SelectedBookFile(name: file.name, bytes: file.bytes)).toList();
  }

  // -- Root-level modal entry -------------------------------------------------

  /// Opens the unified import sheet as a root-level modal bottom sheet.
  ///
  /// When [processor] / [deleteBookFile] / [committer] are not provided they
  /// are resolved from the widget tree via [Provider].
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
              final messenger = ScaffoldMessenger.maybeOf(context);
              final count = books.length;
              messenger?.showSnackBar(
                SnackBar(content: Text('$count ${count == 1 ? 'book' : 'books'} added to library')),
              );
            },
          ),
        );
      },
    );
  }

  /// Resolves the commit service from the widget tree (identical logic to the
  /// old [BookImportResultsSheet._commitResult]).
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
  // -- State -----------------------------------------------------------------

  _ImportPhase _phase = _ImportPhase.selecting;
  List<SelectedBookFile> _files = const [];
  List<BookImportBatchItem> _items = const [];
  bool _isPicking = false;
  String? _pickerError;
  bool _isClosing = false;
  bool _didComplete = false;

  // Processing bookkeeping
  final Map<String, int> _processingTokens = {};
  final Map<String, Future<bool>> _processingFutures = {};
  final Set<String> _cleanedBookIds = {};
  final Map<String, Future<bool>> _cleanupFutures = {};
  final List<Book> _addedBooks = [];
  Future<void>? _closeFuture;

  // -- Convenience getters ---------------------------------------------------

  List<SelectedBookFile> get _readableFiles => _files.where((file) => file.bytes != null).toList(growable: false);

  bool get _allSettled => _items.isNotEmpty && _items.every((item) => item.isSettled);

  bool get _anyProcessing => _items.any(
    (item) =>
        item.status == BookImportBatchStatus.queued ||
        item.status == BookImportBatchStatus.processing ||
        item.status == BookImportBatchStatus.adding,
  );

  int get _successCount => _items.where((item) => item.status == BookImportBatchStatus.added).length;

  int get _failureCount => _items.length - _successCount;

  // -- File picking ----------------------------------------------------------

  Future<void> _browse() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _pickerError = null;
    });
    try {
      final files = await widget.pickFiles();
      if (!mounted || files.isEmpty) return;
      setState(() => _files = List.unmodifiable(files));
    } catch (_) {
      if (!mounted) return;
      setState(() => _pickerError = 'Could not open the selected files. Please try again.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeFile(SelectedBookFile file) {
    setState(() => _files = List.unmodifiable(_files.where((f) => !identical(f, file))));
  }

  /// Discards the current selection and returns the sheet to the browse view.
  void _clearSelection() {
    setState(() {
      _files = const [];
      _pickerError = null;
    });
  }

  // -- Start processing ------------------------------------------------------

  Future<void> _startImport() async {
    if (_readableFiles.isEmpty) return;
    setState(() {
      _phase = _ImportPhase.processing;
      _items = List.generate(
        _readableFiles.length,
        (i) => BookImportBatchItem.queued(id: 'import-$i', file: _readableFiles[i]),
        growable: true,
      );
    });
    // Kick off all files concurrently
    for (final item in List<BookImportBatchItem>.of(_items)) {
      unawaited(_startProcessing(item.id));
    }
  }

  // -- Processing pipeline (parse → commit for each file) --------------------

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
        final i = _indexOf(id);
        _items[i] = _items[i].processingFailed('Could not read this file.');
      });
      _maybeTransitionToSummary();
      return true;
    }

    // Phase A: parse
    BookImportResult result;
    try {
      result = await widget.processor(bytes, processingItem.file.name);
    } catch (error) {
      if (!_isCurrentProcessing(id, token)) return true;
      setState(() {
        final i = _indexOf(id);
        _items[i] = _items[i].processingFailed(_safeErrorMessage(error));
      });
      _maybeTransitionToSummary();
      return true;
    }

    if (_isClosing) {
      await _deleteTemporary(result.bookId);
      return false;
    }
    if (!mounted || !_isMatchingProcessing(id, token)) {
      return _deleteTemporary(result.bookId);
    }

    setState(() {
      final i = _indexOf(id);
      _items[i] = _items[i].processingSucceeded(result);
    });

    // Phase B: commit (automatic, no user intervention)
    setState(() {
      final i = _indexOf(id);
      if (i >= 0 && _items[i].status == BookImportBatchStatus.ready) {
        _items[i] = _items[i].startAdding();
      }
    });

    try {
      final book = await widget.committer(result, processingItem.file.name);
      if (!mounted) return true;
      final i = _indexOf(id);
      if (i < 0 || _items[i].status != BookImportBatchStatus.adding) return true;

      setState(() {
        _items[i] = _items[i].added();
        _addedBooks.add(book);
      });
    } catch (error) {
      if (!mounted) return true;
      final i = _indexOf(id);
      if (i < 0 || _items[i].status != BookImportBatchStatus.adding) return true;
      setState(() {
        _items[i] = _items[i].commitFailed(_safeErrorMessage(error));
      });
    }

    _maybeTransitionToSummary();
    return true;
  }

  void _maybeTransitionToSummary() {
    if (_phase != _ImportPhase.processing || !_allSettled) return;
    setState(() => _phase = _ImportPhase.summary);
    if (_didComplete) return;
    _didComplete = true;
    final books = List<Book>.unmodifiable(_addedBooks);
    widget.onCompleted?.call(books);
  }

  // -- Retry a failed item ---------------------------------------------------

  Future<void> _retryItem(String id) async {
    if (_isClosing || !mounted) {
      return;
    }
    final index = _indexOf(id);
    if (index < 0) {
      return;
    }
    final item = _items[index];

    // Processing failures: re-run the full parse → commit pipeline.
    if (item.status == BookImportBatchStatus.processingFailed) {
      setState(() {
        _phase = _ImportPhase.processing;
        _items[index] = item.startProcessing();
      });
      unawaited(_startProcessing(id));
      return;
    }

    // Commit failures: only re-run the commit step.
    if (item.status == BookImportBatchStatus.commitFailed) {
      setState(() {
        _phase = _ImportPhase.processing;
        _items[index] = item.startAdding();
      });
      unawaited(_commitItem(id));
      return;
    }
  }

  Future<void> _commitItem(String id) async {
    final index = _indexOf(id);
    if (index < 0) return;
    final item = _items[index];
    if (item.status != BookImportBatchStatus.adding || item.result == null) return;

    try {
      final book = await widget.committer(item.result!, item.file.name);
      if (!mounted) return;
      final i = _indexOf(id);
      if (i < 0 || _items[i].status != BookImportBatchStatus.adding) return;

      setState(() {
        _items[i] = _items[i].added();
        _addedBooks.add(book);
      });
    } catch (error) {
      if (!mounted) return;
      final i = _indexOf(id);
      if (i < 0 || _items[i].status != BookImportBatchStatus.adding) return;
      setState(() {
        _items[i] = _items[i].commitFailed(_safeErrorMessage(error));
      });
    }
    _maybeTransitionToSummary();
  }

  // -- Remove an item --------------------------------------------------------

  Future<void> _removeItem(String id) async {
    if (_isClosing || (_phase == _ImportPhase.processing && _anyProcessing)) {
      return;
    }
    final index = _indexOf(id);
    if (index < 0) return;
    final item = _items[index];

    final result = item.result;
    if (result != null && item.status != BookImportBatchStatus.added) {
      final deleted = await _deleteTemporary(result.bookId);
      if (!deleted && mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('Could not remove the imported file.')));
        return;
      }
    }
    if (!mounted) return;
    setState(() => _items.removeAt(index));
  }

  // -- Cleanup helpers -------------------------------------------------------

  Future<bool> _deleteTemporary(String bookId) {
    if (_cleanedBookIds.contains(bookId)) return Future.value(true);
    final inFlight = _cleanupFutures[bookId];
    if (inFlight != null) return inFlight;
    final cleanup = _performDelete(bookId);
    _cleanupFutures[bookId] = cleanup;
    unawaited(
      cleanup.whenComplete(() {
        if (identical(_cleanupFutures[bookId], cleanup)) _cleanupFutures.remove(bookId);
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

  // -- Close flow ------------------------------------------------------------

  Future<void> _requestClose() {
    final inFlight = _closeFuture;
    if (inFlight != null) return inFlight;
    final close = _close();
    _closeFuture = close;
    unawaited(
      close.whenComplete(() {
        if (identical(_closeFuture, close)) _closeFuture = null;
      }),
    );
    return close;
  }

  Future<void> _close() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    // Wait for in-flight processing
    final results = await Future.wait(List<Future<bool>>.of(_processingFutures.values));
    if (results.any((ok) => !ok)) {
      if (mounted) setState(() => _isClosing = false);
      return;
    }
    // Clean up temporary files for items that haven't been added
    final bookIds = _items.where((item) => item.hasTemporaryFile).map((item) => item.result!.bookId).toSet();
    final cleanupResults = await Future.wait(bookIds.map(_deleteTemporary));
    if (cleanupResults.any((deleted) => !deleted)) {
      if (mounted) {
        setState(() => _isClosing = false);
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('Could not remove temporary files. Please try again.')));
      }
      return;
    }
    if (!mounted) return;
    widget.onClose();
  }

  // -- Helpers ---------------------------------------------------------------

  bool _isCurrentProcessing(String id, int token) => !_isClosing && _isMatchingProcessing(id, token);

  bool _isMatchingProcessing(String id, int token) {
    if (!mounted || _processingTokens[id] != token) return false;
    final index = _indexOf(id);
    return index >= 0 && _items[index].status == BookImportBatchStatus.processing;
  }

  String _safeErrorMessage(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
    return message.isEmpty ? 'Could not import this file.' : message;
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestClose());
      },
      child: switch (_phase) {
        _ImportPhase.selecting => _buildSelectingPhase(),
        _ImportPhase.processing => _buildProcessingPhase(),
        _ImportPhase.summary => _buildSummaryPhase(),
      },
    );
  }

  // ==========================================================================
  // Phase 1: File Selection
  // ==========================================================================

  Widget _buildSelectingPhase() {
    final hasFiles = _files.isNotEmpty;
    final hasReadable = _readableFiles.isNotEmpty;
    return AddBookSheetScaffold(
      title: 'Import books',
      canClose: true,
      onClose: widget.onClose,
      body: hasFiles ? _buildFileList() : _buildBrowseOnly(),
      footer: Row(
        children: [
          if (hasFiles) FilledButton(onPressed: _isPicking ? null : _clearSelection, child: const Text('Reset')),
          const Spacer(),
          TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
          const SizedBox(width: Spacing.sm),
          FilledButton(
            onPressed: hasReadable ? _startImport : null,
            child: Text('Import ${_readableFiles.length} ${_readableFiles.length == 1 ? 'book' : 'books'}'),
          ),
        ],
      ),
    );
  }

  /// Large, welcoming file-picker area when no files have been selected yet.
  /// Supported formats appear only inside [_BrowseArea] — not duplicated here.
  Widget _buildBrowseOnly() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _BrowseArea(isPicking: _isPicking, onTap: _browse),
          if (_pickerError case final message?) ...[
            const SizedBox(height: Spacing.sm),
            Text(message, style: TextStyle(color: colorScheme.error, fontSize: 13)),
          ],
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  /// File list — the "Reset" action lives in the footer so it is always visible.
  Widget _buildFileList() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      children: [
        if (_pickerError case final message?) ...[
          Text(message, style: TextStyle(color: colorScheme.error, fontSize: 13)),
          const SizedBox(height: Spacing.sm),
        ],
        Text(
          '${_files.length} ${_files.length == 1 ? 'file' : 'files'} selected',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Spacing.sm),
        ..._files.map((file) => _FileSelectCard(file: file, onRemove: () => _removeFile(file))),
      ],
    );
  }

  // ==========================================================================
  // Phase 2: Processing
  // ==========================================================================

  Widget _buildProcessingPhase() {
    return AddBookSheetScaffold(
      title: 'Importing books',
      canClose: !_isClosing,
      onClose: () => unawaited(_requestClose()),
      body: ListView.separated(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.xs),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _ImportProgressCard(
            key: ValueKey(item.id),
            item: item,
            onRetry: _isClosing ? null : () => unawaited(_retryItem(item.id)),
            onRemove: _isClosing ? null : () => unawaited(_removeItem(item.id)),
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
            onPressed: _isClosing || _anyProcessing ? null : () => unawaited(_requestClose()),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Phase 3: Summary
  // ==========================================================================

  Widget _buildSummaryPhase() {
    final hasFailures = _failureCount > 0;

    return AddBookSheetScaffold(
      title: 'Import complete',
      canClose: true,
      onClose: widget.onClose,
      body: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        children: _items
            .map(
              (item) => _ImportResultCard(
                key: ValueKey(item.id),
                item: item,
                onRetry: hasFailures && !_isClosing
                    ? () {
                        setState(() => _phase = _ImportPhase.processing);
                        unawaited(_retryItem(item.id));
                      }
                    : null,
              ),
            )
            .toList(),
      ),
      footer: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: Spacing.sm,
        overflowSpacing: Spacing.sm,
        children: [
          FilledButton(onPressed: widget.onClose, child: const Text('Done')),
          if (hasFailures)
            OutlinedButton(
              onPressed: () {
                setState(() => _phase = _ImportPhase.processing);
                for (final item in List<BookImportBatchItem>.of(_items)) {
                  if (item.status == BookImportBatchStatus.processingFailed ||
                      item.status == BookImportBatchStatus.commitFailed) {
                    unawaited(_retryItem(item.id));
                  }
                }
              },
              child: Text('Retry $_failureCount failed'),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Browse area widget
// ============================================================================

/// A large, inviting tappable area that triggers the platform file picker.
/// Supported formats are listed from the [BookImportSheet] extension constants
/// so they stay in one place.
class _BrowseArea extends StatelessWidget {
  const _BrowseArea({required this.isPicking, required this.onTap});

  final bool isPicking;
  final VoidCallback onTap;

  static const _allExtensions = BookImportSheet._nativeExtensions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formats = _allExtensions.map((e) => e.toUpperCase()).join(', ');

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.symmetric(vertical: Spacing.xxl, horizontal: Spacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPicking)
                const SizedBox.square(dimension: 48, child: CircularProgressIndicator(strokeWidth: 3))
              else
                Icon(Icons.cloud_upload_outlined, size: 48, color: colorScheme.primary),
              const SizedBox(height: Spacing.md),
              Text('Browse files', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: Spacing.sm),
              Text(
                'Tap to select $formats',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// File selection card (Phase 1)
// ============================================================================

class _FileSelectCard extends StatelessWidget {
  const _FileSelectCard({required this.file, required this.onRemove});

  final SelectedBookFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readable = file.bytes != null;
    final sizeText = file.bytes != null ? _formatSize(file.bytes!.length) : 'Unknown size';

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: readable ? colorScheme.primaryContainer : colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              readable ? _iconForExtension(file.name) : Icons.error_outline,
              size: 20,
              color: readable ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(file.name, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  readable ? sizeText : 'Unreadable',
                  style: textTheme.bodySmall?.copyWith(
                    color: readable ? colorScheme.onSurfaceVariant : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${file.name}',
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Import progress card (Phase 2)
// ============================================================================

class _ImportProgressCard extends StatelessWidget {
  const _ImportProgressCard({super.key, required this.item, required this.onRetry, required this.onRemove});

  final BookImportBatchItem item;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final failed =
        item.status == BookImportBatchStatus.processingFailed || item.status == BookImportBatchStatus.commitFailed;
    final added = item.status == BookImportBatchStatus.added;

    final displayTitle = _displayTitle;
    final displaySubtitle = _displaySubtitle;

    return AnimatedContainer(
      key: ValueKey('${item.id}-${item.status}'),
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      decoration: BoxDecoration(
        color: added
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : failed
            ? colorScheme.errorContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: added
              ? colorScheme.primary.withValues(alpha: 0.3)
              : failed
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          // Leading icon
          AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _statusWidget(colorScheme)),
          const SizedBox(width: Spacing.md),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayTitle, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  displaySubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: failed ? colorScheme.error : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Trailing actions
          if (failed && onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            )
          else if (onRemove != null && (failed || item.status == BookImportBatchStatus.ready))
            IconButton(
              tooltip: 'Remove ${item.file.name}',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _statusWidget(ColorScheme colorScheme) {
    return switch (item.status) {
      BookImportBatchStatus.queued => SizedBox(
        key: const ValueKey('queued-icon'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSurfaceVariant),
      ),
      BookImportBatchStatus.processing => SizedBox(
        key: const ValueKey('processing-icon'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      BookImportBatchStatus.adding => SizedBox(
        key: const ValueKey('adding-icon'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      BookImportBatchStatus.ready => Icon(
        Icons.check_circle_outline,
        key: const ValueKey('ready-icon'),
        color: colorScheme.primary,
        size: 24,
      ),
      BookImportBatchStatus.added => Icon(
        Icons.check_circle,
        key: const ValueKey('added-icon'),
        color: colorScheme.primary,
        size: 24,
      ),
      BookImportBatchStatus.processingFailed => Icon(
        Icons.error_outline,
        key: const ValueKey('parse-failed-icon'),
        color: colorScheme.error,
        size: 24,
      ),
      BookImportBatchStatus.commitFailed => Icon(
        Icons.error_outline,
        key: const ValueKey('commit-failed-icon'),
        color: colorScheme.error,
        size: 24,
      ),
    };
  }

  String get _displayTitle {
    final result = item.result;
    if (result != null) {
      return result.title.isNotEmpty ? result.title : item.file.name;
    }
    return item.file.name;
  }

  String get _displaySubtitle {
    return switch (item.status) {
      BookImportBatchStatus.queued => 'Preparing…',
      BookImportBatchStatus.processing => 'Extracting metadata…',
      BookImportBatchStatus.adding => 'Saving to library…',
      BookImportBatchStatus.ready => 'Ready',
      BookImportBatchStatus.added => item.result?.author.isNotEmpty == true ? 'by ${item.result!.author}' : 'Added',
      BookImportBatchStatus.processingFailed => item.errorMessage ?? 'Could not read this file.',
      BookImportBatchStatus.commitFailed => item.errorMessage ?? 'Could not save to library.',
    };
  }
}

// ============================================================================
// Summary banner (Phase 3)
// ============================================================================
// Import result card (Phase 3: summary individual rows)
// ============================================================================

class _ImportResultCard extends StatelessWidget {
  const _ImportResultCard({super.key, required this.item, this.onRetry});

  final BookImportBatchItem item;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final added = item.status == BookImportBatchStatus.added;
    final failed =
        item.status == BookImportBatchStatus.processingFailed || item.status == BookImportBatchStatus.commitFailed;
    final result = item.result;
    final hasCover = result?.coverImage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: added
              ? colorScheme.primary.withValues(alpha: 0.2)
              : failed
              ? colorScheme.error.withValues(alpha: 0.2)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover or icon
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: hasCover
                ? Image.memory(
                    result!.coverImage!,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackIcon(colorScheme, added, failed),
                  )
                : _fallbackIcon(colorScheme, added, failed),
          ),
          const SizedBox(width: Spacing.md),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result?.title.isNotEmpty == true ? result!.title : item.file.name,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result?.author.isNotEmpty == true)
                  Text(
                    result!.author,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      added ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: added ? colorScheme.primary : colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        added ? 'Imported' : (item.errorMessage ?? 'Failed'),
                        style: textTheme.labelSmall?.copyWith(color: added ? colorScheme.primary : colorScheme.error),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (failed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(ColorScheme colorScheme, bool added, bool failed) {
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: added
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : failed
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        added ? Icons.menu_book : Icons.insert_drive_file,
        size: 20,
        color: added ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
