import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:papyrus/services/book_import_result.dart';

@immutable
class SelectedBookFile {
  const SelectedBookFile({required this.name, required this.bytes});

  final String name;
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

  BookImportBatchItem startProcessing() =>
      BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.processing);

  BookImportBatchItem processingSucceeded(BookImportResult value) =>
      BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.ready, result: value);

  BookImportBatchItem processingFailed(String message) =>
      BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.processingFailed, errorMessage: message);

  BookImportBatchItem startAdding() =>
      BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.adding, result: result);

  BookImportBatchItem added() =>
      BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.added, result: result);

  BookImportBatchItem commitFailed(String message) => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.commitFailed,
    result: result,
    errorMessage: message,
  );
}
