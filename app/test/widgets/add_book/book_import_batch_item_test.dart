import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';

void main() {
  final file = SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1, 2, 3]));
  const result = BookImportResult(
    bookId: 'book-1',
    title: 'Test Book',
    author: 'Test Author',
    fileSize: 3,
    fileHash: 'hash',
    fileExtension: 'epub',
  );

  group('BookImportBatchItem', () {
    test('processing failure retries to ready while preserving identity', () {
      final failed = BookImportBatchItem.queued(
        id: 'row-1',
        file: file,
      ).startProcessing().processingFailed('Could not read the file.');

      expect(failed.status, BookImportBatchStatus.processingFailed);
      expect(failed.errorMessage, 'Could not read the file.');
      expect(failed.canRetry, isTrue);
      expect(failed.isSettled, isTrue);
      expect(failed.hasTemporaryFile, isFalse);

      final processing = failed.startProcessing();
      expect(processing.id, 'row-1');
      expect(processing.status, BookImportBatchStatus.processing);
      expect(processing.result, isNull);
      expect(processing.errorMessage, isNull);

      final ready = processing.processingSucceeded(result);
      expect(ready.id, 'row-1');
      expect(ready.status, BookImportBatchStatus.ready);
      expect(ready.result, same(result));
      expect(ready.errorMessage, isNull);
      expect(ready.canRetry, isFalse);
      expect(ready.isSettled, isTrue);
      expect(ready.hasTemporaryFile, isTrue);
    });

    test('commit failure retains result and can retry adding', () {
      final ready = BookImportBatchItem.queued(id: 'row-2', file: file).startProcessing().processingSucceeded(result);

      final failed = ready.startAdding().commitFailed('Could not add the book.');
      expect(failed.id, 'row-2');
      expect(failed.status, BookImportBatchStatus.commitFailed);
      expect(failed.result, same(result));
      expect(failed.errorMessage, 'Could not add the book.');
      expect(failed.canRetry, isTrue);
      expect(failed.isSettled, isTrue);
      expect(failed.hasTemporaryFile, isTrue);

      final adding = failed.startAdding();
      expect(adding.id, 'row-2');
      expect(adding.status, BookImportBatchStatus.adding);
      expect(adding.result, same(result));
      expect(adding.errorMessage, isNull);

      final added = adding.added();
      expect(added.id, 'row-2');
      expect(added.status, BookImportBatchStatus.added);
      expect(added.result, same(result));
      expect(added.hasTemporaryFile, isFalse);
      expect(added.isSettled, isTrue);
    });

    test('rejects invalid state transitions', () {
      final queued = BookImportBatchItem.queued(id: 'row-3', file: file);
      final processing = queued.startProcessing();
      final ready = processing.processingSucceeded(result);
      final adding = ready.startAdding();

      expect(() => queued.processingSucceeded(result), throwsStateError);
      expect(() => queued.processingFailed('Could not read the file.'), throwsStateError);
      expect(() => ready.startProcessing(), throwsStateError);
      expect(() => processing.startAdding(), throwsStateError);
      expect(() => ready.added(), throwsStateError);
      expect(() => adding.processingFailed('Could not read the file.'), throwsStateError);
    });

    test('reports settlement for every status', () {
      final queued = BookImportBatchItem.queued(id: 'row-4', file: file);
      final processing = queued.startProcessing();
      final ready = processing.processingSucceeded(result);
      final processingFailed = processing.processingFailed('Could not read the file.');
      final adding = ready.startAdding();
      final added = adding.added();
      final commitFailed = adding.commitFailed('Could not add the book.');

      expect(queued.isSettled, isFalse);
      expect(processing.isSettled, isFalse);
      expect(ready.isSettled, isTrue);
      expect(processingFailed.isSettled, isTrue);
      expect(adding.isSettled, isTrue);
      expect(added.isSettled, isTrue);
      expect(commitFailed.isSettled, isTrue);
    });
  });
}
