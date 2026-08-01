import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
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
    this.scrollController,
  });

  final List<SelectedBookFile> files;
  final BookImportProcessor processor;
  final ImportedBookFileDeleter deleteBookFile;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  /// Opens the processing step as its own root-level modal sheet.
  static Future<void> show(
    BuildContext context, {
    required List<SelectedBookFile> files,
    BookImportProcessor? processor,
    ImportedBookFileDeleter? deleteBookFile,
  }) {
    final importService = processor == null || deleteBookFile == null ? context.read<BookImportService>() : null;
    final effectiveProcessor = processor ?? importService!.importBook;
    final effectiveDeleter = deleteBookFile ?? importService!.deleteBookFile;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
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
          scrollController: scrollController,
          onClose: () => Navigator.of(sheetContext).pop(),
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
  final Set<String> _removingIds = {};
  final Set<String> _cleanedBookIds = {};
  bool _isClosing = false;
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
        unawaited(_process(item.id));
      }
    });
  }

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  Future<void> _process(String id) async {
    if (_isClosing || !mounted) return;
    final index = _indexOf(id);
    if (index < 0) return;

    final token = (_processingTokens[id] ?? 0) + 1;
    _processingTokens[id] = token;
    final processingItem = _items[index].startProcessing();
    setState(() => _items[index] = processingItem);

    final bytes = processingItem.file.bytes;
    if (bytes == null) {
      if (!_isCurrentProcessing(id, token)) return;
      setState(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingFailed('Could not read this file.');
      });
      return;
    }

    try {
      final result = await widget.processor(bytes, processingItem.file.name);
      if (_isClosing || !mounted || !_isCurrentProcessing(id, token)) {
        await _deleteTemporary(result.bookId);
        return;
      }
      setState(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingSucceeded(result);
      });
    } catch (error) {
      if (!_isCurrentProcessing(id, token)) return;
      setState(() {
        final currentIndex = _indexOf(id);
        _items[currentIndex] = _items[currentIndex].processingFailed(_safeErrorMessage(error));
      });
    }
  }

  bool _isCurrentProcessing(String id, int token) {
    if (_isClosing || !mounted || _processingTokens[id] != token) return false;
    final index = _indexOf(id);
    return index >= 0 && _items[index].status == BookImportBatchStatus.processing;
  }

  String _safeErrorMessage(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
    return message.isEmpty ? 'Could not import this file.' : message;
  }

  Future<void> _remove(String id) async {
    if (_isClosing || _removingIds.contains(id)) return;
    final index = _indexOf(id);
    if (index < 0) return;
    final item = _items[index];
    if (item.status != BookImportBatchStatus.processingFailed && item.status != BookImportBatchStatus.ready) return;

    _removingIds.add(id);
    if (mounted) setState(() {});
    var deleted = true;
    final result = item.result;
    if (result != null) {
      deleted = await _deleteTemporary(result.bookId);
    }
    if (!mounted || _isClosing) return;
    _removingIds.remove(id);
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
    }
  }

  Future<bool> _deleteTemporary(String bookId) async {
    if (!_cleanedBookIds.add(bookId)) return true;
    try {
      await widget.deleteBookFile(bookId);
      return true;
    } catch (error, stackTrace) {
      _cleanedBookIds.remove(bookId);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'book import results cleanup',
          context: ErrorDescription('while deleting a temporary imported book file'),
        ),
      );
      return false;
    }
  }

  Future<void> _requestClose() => _closeFuture ??= _close();

  Future<void> _close() async {
    if (_isClosing) return;
    if (mounted) {
      setState(() => _isClosing = true);
    } else {
      _isClosing = true;
    }

    final bookIds = _items.where((item) => item.hasTemporaryFile).map((item) => item.result!.bookId).toSet();
    await Future.wait(bookIds.map(_deleteTemporary));
    widget.onClose();
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
        canClose: !_isClosing,
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
              onRetry: _isClosing ? null : () => unawaited(_process(item.id)),
              onRemove: _isClosing ? null : () => unawaited(_remove(item.id)),
            );
          },
        ),
        footer: Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isClosing ? null : () => unawaited(_requestClose()),
            child: const Text('Close'),
          ),
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
    final failed = item.status == BookImportBatchStatus.processingFailed;
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
