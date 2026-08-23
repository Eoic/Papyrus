import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';

typedef DigitalBookFilePicker = Future<List<SelectedBookFile>> Function();
typedef BookImportProcessor = Future<BookImportResult> Function(Uint8List bytes, String filename);
typedef ImportedBookFileDeleter = Future<void> Function(String bookId);
typedef ImportedBookCommitter = Future<Book> Function(BookImportResult result, String sourceFilename);

const bookImportWebExtensions = ['epub'];
const bookImportNativeExtensions = ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];

enum BookImportPhase { selecting, processing, summary }

enum BookImportCloseResult { closed, processingCleanupFailed, cleanupFailed }

enum BookImportRemoveResult { removed, ignored, cleanupFailed }

/// Owns the state and asynchronous lifecycle of a batch book import.
class BookImportController extends ChangeNotifier {
  BookImportController({
    required DigitalBookFilePicker pickFiles,
    required BookImportProcessor processor,
    required ImportedBookFileDeleter deleteBookFile,
    required ImportedBookCommitter committer,
    ValueChanged<List<Book>>? onCompleted,
  }) : _pickFiles = pickFiles,
       _processor = processor,
       _deleteBookFile = deleteBookFile,
       _committer = committer,
       _onCompleted = onCompleted;

  final DigitalBookFilePicker _pickFiles;
  final BookImportProcessor _processor;
  final ImportedBookFileDeleter _deleteBookFile;
  final ImportedBookCommitter _committer;
  final ValueChanged<List<Book>>? _onCompleted;

  BookImportPhase _phase = BookImportPhase.selecting;
  List<SelectedBookFile> _files = const [];
  List<BookImportBatchItem> _items = const [];
  bool _isPicking = false;
  String? _pickerError;
  bool _isClosing = false;
  bool _didComplete = false;
  bool _disposed = false;

  final Map<String, int> _processingTokens = {};
  final Map<String, Future<bool>> _processingFutures = {};
  final Set<String> _cleanedBookIds = {};
  final Map<String, Future<bool>> _cleanupFutures = {};
  final List<Book> _addedBooks = [];
  Future<BookImportCloseResult>? _closeFuture;

  BookImportPhase get phase => _phase;
  List<SelectedBookFile> get files => _files;
  List<BookImportBatchItem> get items => List.unmodifiable(_items);
  bool get isPicking => _isPicking;
  String? get pickerError => _pickerError;
  bool get isClosing => _isClosing;

  List<SelectedBookFile> get readableFiles => _files.where((file) => file.bytes != null).toList(growable: false);

  bool get allSettled =>
      _items.isNotEmpty &&
      _items.every(
        (item) => switch (item.status) {
          BookImportBatchStatus.added ||
          BookImportBatchStatus.processingFailed ||
          BookImportBatchStatus.commitFailed => true,
          BookImportBatchStatus.queued ||
          BookImportBatchStatus.processing ||
          BookImportBatchStatus.ready ||
          BookImportBatchStatus.adding => false,
        },
      );

  bool get anyProcessing => _items.any(
    (item) =>
        item.status == BookImportBatchStatus.queued ||
        item.status == BookImportBatchStatus.processing ||
        item.status == BookImportBatchStatus.adding,
  );

  int get successCount => _items.where((item) => item.status == BookImportBatchStatus.added).length;
  int get failureCount => _items.length - successCount;

  Future<void> browse() async {
    if (_disposed || _isPicking) return;
    _update(() {
      _isPicking = true;
      _pickerError = null;
    });
    try {
      final selectedFiles = await _pickFiles();
      if (_disposed || selectedFiles.isEmpty) return;
      _update(() => _files = List.unmodifiable(selectedFiles));
    } catch (_) {
      if (_disposed) return;
      _update(() => _pickerError = 'Could not open the selected files. Please try again.');
    } finally {
      if (!_disposed) _update(() => _isPicking = false);
    }
  }

  void removeFile(SelectedBookFile file) {
    if (_disposed) return;
    _update(() => _files = List.unmodifiable(_files.where((candidate) => !identical(candidate, file))));
  }

  void clearSelection() {
    if (_disposed) return;
    _update(() {
      _files = const [];
      _pickerError = null;
    });
  }

  void startImport() {
    final importFiles = readableFiles;
    if (_disposed || importFiles.isEmpty) return;
    _update(() {
      _phase = BookImportPhase.processing;
      _items = List.generate(
        importFiles.length,
        (index) => BookImportBatchItem.queued(id: 'import-$index', file: importFiles[index]),
        growable: true,
      );
    });
    for (final item in List<BookImportBatchItem>.of(_items)) {
      unawaited(_startProcessing(item.id));
    }
  }

  Future<void> retryItem(String id) async {
    if (_disposed || _isClosing) return;
    final index = _indexOf(id);
    if (index < 0) return;
    final item = _items[index];

    if (item.status == BookImportBatchStatus.processingFailed) {
      _update(() => _phase = BookImportPhase.processing);
      unawaited(_startProcessing(id));
      return;
    }

    if (item.status == BookImportBatchStatus.commitFailed) {
      _update(() {
        _phase = BookImportPhase.processing;
        _items[index] = item.startAdding();
      });
      unawaited(_startCommit(id));
    }
  }

  Future<BookImportRemoveResult> removeItem(String id) async {
    if (_disposed || _isClosing || (_phase == BookImportPhase.processing && anyProcessing)) {
      return BookImportRemoveResult.ignored;
    }
    final index = _indexOf(id);
    if (index < 0) return BookImportRemoveResult.ignored;
    final item = _items[index];

    final result = item.result;
    if (result != null && item.status != BookImportBatchStatus.added) {
      final deleted = await _deleteTemporary(result.bookId);
      if (!deleted) return BookImportRemoveResult.cleanupFailed;
    }
    if (_disposed) return BookImportRemoveResult.ignored;
    _update(() => _items.removeAt(index));
    return BookImportRemoveResult.removed;
  }

  Future<BookImportCloseResult> requestClose() {
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

  Future<bool> _startProcessing(String id) => _startTrackedOperation(id, () => _process(id));

  Future<bool> _startCommit(String id) => _startTrackedOperation(id, () => _commitItem(id));

  Future<bool> _startTrackedOperation(String id, Future<bool> Function() operation) {
    final inFlight = _processingFutures[id];
    if (inFlight != null) return inFlight;
    final processing = operation();
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
    if (_disposed || _isClosing) return true;
    final index = _indexOf(id);
    if (index < 0) return true;

    final token = (_processingTokens[id] ?? 0) + 1;
    _processingTokens[id] = token;
    final processingItem = _items[index].startProcessing();
    _update(() => _items[index] = processingItem);

    final bytes = processingItem.file.bytes;
    if (bytes == null) {
      if (!_isCurrentProcessing(id, token)) return true;
      _update(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingFailed('Could not read this file.');
      });
      _maybeTransitionToSummary();
      return true;
    }

    BookImportResult result;
    try {
      result = await _processor(bytes, processingItem.file.name);
    } catch (error) {
      if (!_isCurrentProcessing(id, token)) return true;
      _update(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingFailed(_safeErrorMessage(error));
      });
      _maybeTransitionToSummary();
      return true;
    }

    if (_isClosing) {
      final deleted = await _deleteTemporary(result.bookId);
      if (!deleted && !_disposed && _isMatchingProcessing(id, token)) {
        _update(() {
          final currentIndex = _indexOf(id);
          _items[currentIndex] = _items[currentIndex].processingSucceeded(result);
        });
      }
      return deleted;
    }
    if (_disposed || !_isMatchingProcessing(id, token)) {
      return _deleteTemporary(result.bookId);
    }

    _update(() {
      final currentIndex = _indexOf(id);
      _items[currentIndex] = _items[currentIndex].processingSucceeded(result);
    });
    _update(() {
      final currentIndex = _indexOf(id);
      if (currentIndex >= 0 && _items[currentIndex].status == BookImportBatchStatus.ready) {
        _items[currentIndex] = _items[currentIndex].startAdding();
      }
    });

    try {
      final book = await _committer(result, processingItem.file.name);
      if (_disposed) return true;
      final currentIndex = _indexOf(id);
      if (currentIndex < 0 || _items[currentIndex].status != BookImportBatchStatus.adding) return true;
      _update(() {
        _items[currentIndex] = _items[currentIndex].added();
        _addedBooks.add(book);
      });
    } catch (error) {
      if (_disposed) return true;
      final currentIndex = _indexOf(id);
      if (currentIndex < 0 || _items[currentIndex].status != BookImportBatchStatus.adding) return true;
      _update(() {
        _items[currentIndex] = _items[currentIndex].commitFailed(_safeErrorMessage(error));
      });
    }

    _maybeTransitionToSummary();
    return true;
  }

  Future<bool> _commitItem(String id) async {
    final index = _indexOf(id);
    if (index < 0) return true;
    final item = _items[index];
    if (item.status != BookImportBatchStatus.adding || item.result == null) return true;

    try {
      final book = await _committer(item.result!, item.file.name);
      if (_disposed) return true;
      final currentIndex = _indexOf(id);
      if (currentIndex < 0 || _items[currentIndex].status != BookImportBatchStatus.adding) return true;
      _update(() {
        _items[currentIndex] = _items[currentIndex].added();
        _addedBooks.add(book);
      });
    } catch (error) {
      if (_disposed) return true;
      final currentIndex = _indexOf(id);
      if (currentIndex < 0 || _items[currentIndex].status != BookImportBatchStatus.adding) return true;
      _update(() {
        _items[currentIndex] = _items[currentIndex].commitFailed(_safeErrorMessage(error));
      });
    }
    _maybeTransitionToSummary();
    return true;
  }

  void _maybeTransitionToSummary() {
    if (_disposed || _phase != BookImportPhase.processing || !allSettled) return;
    _update(() => _phase = BookImportPhase.summary);
    if (_didComplete) return;
    _didComplete = true;
    _onCompleted?.call(List<Book>.unmodifiable(_addedBooks));
  }

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
      await _deleteBookFile(bookId);
      _cleanedBookIds.add(bookId);
      return true;
    } catch (_) {
      debugPrint('Book import temporary-file cleanup failed.');
      return false;
    }
  }

  Future<BookImportCloseResult> _close() async {
    if (_disposed) return BookImportCloseResult.processingCleanupFailed;
    if (_isClosing) return BookImportCloseResult.processingCleanupFailed;
    _update(() => _isClosing = true);

    final processingResults = await Future.wait(List<Future<bool>>.of(_processingFutures.values));
    if (processingResults.any((completed) => !completed)) {
      if (!_disposed) _update(() => _isClosing = false);
      return BookImportCloseResult.processingCleanupFailed;
    }

    final bookIds = _items.where((item) => item.hasTemporaryFile).map((item) => item.result!.bookId).toSet();
    final cleanupResults = await Future.wait(bookIds.map(_deleteTemporary));
    if (cleanupResults.any((deleted) => !deleted)) {
      if (!_disposed) _update(() => _isClosing = false);
      return BookImportCloseResult.cleanupFailed;
    }
    return BookImportCloseResult.closed;
  }

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  bool _isCurrentProcessing(String id, int token) => !_isClosing && _isMatchingProcessing(id, token);

  bool _isMatchingProcessing(String id, int token) {
    if (_disposed || _processingTokens[id] != token) return false;
    final index = _indexOf(id);
    return index >= 0 && _items[index].status == BookImportBatchStatus.processing;
  }

  String _safeErrorMessage(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
    return message.isEmpty ? 'Could not import this file.' : message;
  }

  void _update(VoidCallback update) {
    if (_disposed) return;
    update();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
