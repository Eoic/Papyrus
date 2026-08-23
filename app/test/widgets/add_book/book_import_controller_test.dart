import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/book_import_controller.dart';

void main() {
  test('applies dropped files with feedback', () {
    final controller = BookImportController(
      pickFiles: () async => const [],
      processor: (bytes, filename) async => _result(filename),
      deleteBookFile: (_) async {},
      committer: (result, filename) async => _book(filename),
    );
    addTearDown(controller.dispose);

    controller.applyDroppedFiles([
      SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1])),
    ], feedback: 'Some files were skipped because their format is not supported.');

    expect(controller.files.single.name, 'book.epub');
    expect(controller.pickerError, contains('skipped'));
  });

  test('reports an unsupported drop without creating a selection', () {
    final controller = BookImportController(
      pickFiles: () async => const [],
      processor: (bytes, filename) async => _result(filename),
      deleteBookFile: (_) async {},
      committer: (result, filename) async => _book(filename),
    );
    addTearDown(controller.dispose);

    controller.applyDroppedFiles(const [], feedback: 'No supported book files were dropped.');

    expect(controller.files, isEmpty);
    expect(controller.pickerError, 'No supported book files were dropped.');
  });

  test('imports selected files and reports completion once', () async {
    final completed = <List<Book>>[];
    final result = BookImportResult(
      bookId: 'book-1',
      title: 'Imported book',
      author: 'Author',
      fileSize: 3,
      fileHash: 'hash',
      fileExtension: 'epub',
    );
    final book = Book(id: 'book-1', title: 'Imported book', author: 'Author', addedAt: DateTime(2026));
    final controller = BookImportController(
      pickFiles: () async => [
        SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1, 2, 3])),
      ],
      processor: (bytes, filename) async => result,
      deleteBookFile: (_) async {},
      committer: (result, filename) async => book,
      onCompleted: completed.add,
    );
    addTearDown(controller.dispose);

    await controller.browse();
    controller.startImport();
    await pumpEventQueue();

    expect(controller.phase, BookImportPhase.summary);
    expect(controller.items.single.status, BookImportBatchStatus.added);
    expect(completed, [
      [book],
    ]);
  });

  test('retries processing failures through the full pipeline', () async {
    var attempts = 0;
    final result = BookImportResult(
      bookId: 'book-1',
      title: 'Imported book',
      author: 'Author',
      fileSize: 1,
      fileHash: 'hash',
      fileExtension: 'epub',
    );
    final book = Book(id: 'book-1', title: 'Imported book', author: 'Author', addedAt: DateTime(2026));
    final controller = BookImportController(
      pickFiles: () async => [
        SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (bytes, filename) async {
        attempts++;
        if (attempts == 1) throw Exception('Invalid book');
        return result;
      },
      deleteBookFile: (_) async {},
      committer: (result, filename) async => book,
    );
    addTearDown(controller.dispose);

    await controller.browse();
    controller.startImport();
    await pumpEventQueue();
    expect(controller.items.single.status, BookImportBatchStatus.processingFailed);

    await controller.retryItem(controller.items.single.id);
    await pumpEventQueue();

    expect(attempts, 2);
    expect(controller.items.single.status, BookImportBatchStatus.added);
  });

  test('waits for every commit before reporting completion', () async {
    final firstCommit = Completer<Book>();
    final secondCommit = Completer<Book>();
    final completed = <List<Book>>[];
    final controller = BookImportController(
      pickFiles: () async => [
        SelectedBookFile(name: 'first.epub', bytes: Uint8List.fromList([1])),
        SelectedBookFile(name: 'second.epub', bytes: Uint8List.fromList([2])),
      ],
      processor: (bytes, filename) async => _result(filename),
      deleteBookFile: (_) async {},
      committer: (result, filename) => filename == 'first.epub' ? firstCommit.future : secondCommit.future,
      onCompleted: completed.add,
    );
    addTearDown(controller.dispose);

    await controller.browse();
    controller.startImport();
    await pumpEventQueue();

    firstCommit.complete(_book('first.epub'));
    await pumpEventQueue();
    expect(controller.phase, BookImportPhase.processing);
    expect(completed, isEmpty);

    secondCommit.complete(_book('second.epub'));
    await pumpEventQueue();
    expect(controller.phase, BookImportPhase.summary);
    expect(completed.single, hasLength(2));
  });

  test('close waits for an active commit retry', () async {
    var commitAttempts = 0;
    final retryCommit = Completer<Book>();
    final deleted = <String>[];
    final controller = BookImportController(
      pickFiles: () async => [
        SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (bytes, filename) async => _result(filename),
      deleteBookFile: (bookId) async => deleted.add(bookId),
      committer: (result, filename) {
        commitAttempts++;
        if (commitAttempts == 1) throw Exception('Commit failed');
        return retryCommit.future;
      },
    );
    addTearDown(controller.dispose);

    await controller.browse();
    controller.startImport();
    await pumpEventQueue();
    expect(controller.items.single.status, BookImportBatchStatus.commitFailed);

    unawaited(controller.retryItem(controller.items.single.id));
    await pumpEventQueue();
    var closeCompleted = false;
    final close = controller.requestClose()..whenComplete(() => closeCompleted = true);
    await pumpEventQueue();

    expect(closeCompleted, isFalse);
    expect(deleted, isEmpty);

    retryCommit.complete(_book('book.epub'));
    expect(await close, BookImportCloseResult.closed);
    expect(deleted, isEmpty);
  });

  test('close succeeds after cleaning a parse result that finishes late', () async {
    final processing = Completer<BookImportResult>();
    final deleted = <String>[];
    final controller = BookImportController(
      pickFiles: () async => [
        SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (bytes, filename) => processing.future,
      deleteBookFile: (bookId) async => deleted.add(bookId),
      committer: (result, filename) async => _book(filename),
    );
    addTearDown(controller.dispose);

    await controller.browse();
    controller.startImport();
    await pumpEventQueue();
    final close = controller.requestClose();
    processing.complete(_result('book.epub'));

    expect(await close, BookImportCloseResult.closed);
    expect(deleted, ['book.epub']);
  });

  test('failed late-result cleanup remains retryable', () async {
    final processing = Completer<BookImportResult>();
    var deleteAttempts = 0;
    final controller = BookImportController(
      pickFiles: () async => [
        SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (bytes, filename) => processing.future,
      deleteBookFile: (_) async {
        deleteAttempts++;
        if (deleteAttempts == 1) throw Exception('Delete failed');
      },
      committer: (result, filename) async => _book(filename),
    );
    addTearDown(controller.dispose);

    await controller.browse();
    controller.startImport();
    await pumpEventQueue();
    final firstClose = controller.requestClose();
    processing.complete(_result('book.epub'));

    expect(await firstClose, BookImportCloseResult.processingCleanupFailed);
    expect(controller.items.single.status, BookImportBatchStatus.ready);
    expect(await controller.requestClose(), BookImportCloseResult.closed);
    expect(deleteAttempts, 2);
  });
}

BookImportResult _result(String id) =>
    BookImportResult(bookId: id, title: id, author: 'Author', fileSize: 1, fileHash: 'hash', fileExtension: 'epub');

Book _book(String id) => Book(id: id, title: id, author: 'Author', addedAt: DateTime(2026));
