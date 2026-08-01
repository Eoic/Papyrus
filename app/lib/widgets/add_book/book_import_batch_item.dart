import 'package:flutter/foundation.dart';
import 'package:papyrus/services/book_import_result.dart';

@immutable
class SelectedBookFile {
  const SelectedBookFile({required this.name, required this.bytes});

  final String name;

  /// The import workflow takes ownership of these bytes; callers must not
  /// mutate them after creating this file selection.
  final Uint8List? bytes;
}

enum BookImportBatchStatus { queued, processing, ready, processingFailed, adding, added, commitFailed }

@immutable
class BookImportBatchItem {
  const BookImportBatchItem._({
    required this.id,
    required this.file,
    required this.status,
    this.result,
    this.errorMessage,
  });

  factory BookImportBatchItem.queued({required String id, required SelectedBookFile file}) {
    return BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.queued);
  }

  final String id;
  final SelectedBookFile file;
  final BookImportBatchStatus status;
  final BookImportResult? result;
  final String? errorMessage;

  bool get canRetry => status == BookImportBatchStatus.processingFailed || status == BookImportBatchStatus.commitFailed;

  bool get isSettled => status != BookImportBatchStatus.queued && status != BookImportBatchStatus.processing;

  bool get hasTemporaryFile => result != null && status != BookImportBatchStatus.added;

  BookImportBatchItem startProcessing() {
    if (status != BookImportBatchStatus.queued && status != BookImportBatchStatus.processingFailed) {
      throw StateError('Cannot start processing an item with status $status.');
    }

    return BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.processing);
  }

  BookImportBatchItem processingSucceeded(BookImportResult value) {
    if (status != BookImportBatchStatus.processing) {
      throw StateError('Cannot complete processing for an item with status $status.');
    }

    return BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.ready, result: value);
  }

  BookImportBatchItem processingFailed(String message) {
    if (status != BookImportBatchStatus.processing) {
      throw StateError('Cannot fail processing for an item with status $status.');
    }

    return BookImportBatchItem._(
      id: id,
      file: file,
      status: BookImportBatchStatus.processingFailed,
      errorMessage: message,
    );
  }

  BookImportBatchItem startAdding() {
    if (status != BookImportBatchStatus.ready && status != BookImportBatchStatus.commitFailed) {
      throw StateError('Cannot start adding an item with status $status.');
    }
    final value = result;
    if (value == null) {
      throw StateError('Cannot add an item without a processed result.');
    }

    return BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.adding, result: value);
  }

  BookImportBatchItem added() {
    if (status != BookImportBatchStatus.adding) {
      throw StateError('Cannot finish adding an item with status $status.');
    }
    final value = result;
    if (value == null) {
      throw StateError('Cannot finish adding an item without a processed result.');
    }

    return BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.added, result: value);
  }

  BookImportBatchItem commitFailed(String message) {
    if (status != BookImportBatchStatus.adding) {
      throw StateError('Cannot fail adding an item with status $status.');
    }
    final value = result;
    if (value == null) {
      throw StateError('Cannot fail adding an item without a processed result.');
    }

    return BookImportBatchItem._(
      id: id,
      file: file,
      status: BookImportBatchStatus.commitFailed,
      result: value,
      errorMessage: message,
    );
  }
}
