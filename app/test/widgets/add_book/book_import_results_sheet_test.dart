import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/book_import_results_sheet.dart';

class _PopCountingObserver extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

BookImportResult resultFor(String filename, {String? bookId}) {
  return BookImportResult(
    bookId: bookId ?? 'book-$filename',
    title: filename,
    author: 'Author',
    fileSize: 1,
    fileHash: 'hash-$filename',
    fileExtension: filename.split('.').last,
  );
}

Book bookFor(BookImportResult result) {
  return Book(id: result.bookId, title: result.title, author: result.author, addedAt: DateTime(2026));
}

void main() {
  Future<void> pumpResults(
    WidgetTester tester, {
    required List<SelectedBookFile> files,
    required BookImportProcessor processor,
    ImportedBookFileDeleter? deleter,
    ImportedBookCommitter? committer,
    VoidCallback? onClose,
    ValueChanged<List<Book>>? onCompleted,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: BookImportResultsSheet(
              files: files,
              processor: processor,
              deleteBookFile: deleter ?? (_) async {},
              committer: committer,
              onClose: onClose ?? () {},
              onCompleted: onCompleted,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('processes batch rows independently into ready and failed states', (tester) async {
    final files = [
      SelectedBookFile(name: 'good.epub', bytes: Uint8List.fromList([1])),
      SelectedBookFile(name: 'bad.epub', bytes: Uint8List.fromList([2])),
    ];

    await pumpResults(
      tester,
      files: files,
      processor: (_, filename) async {
        if (filename == 'bad.epub') throw Exception('Broken file');
        return resultFor(filename);
      },
    );
    await tester.pump();

    expect(find.text('good.epub'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('bad.epub'), findsOneWidget);
    expect(find.text('Broken file'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('retries only the failed row', (tester) async {
    var goodCalls = 0;
    var badCalls = 0;
    final files = [
      SelectedBookFile(name: 'good.epub', bytes: Uint8List.fromList([1])),
      SelectedBookFile(name: 'bad.epub', bytes: Uint8List.fromList([2])),
    ];

    await pumpResults(
      tester,
      files: files,
      processor: (_, filename) async {
        if (filename == 'good.epub') {
          goodCalls++;
          return resultFor(filename);
        }
        badCalls++;
        if (badCalls == 1) throw Exception('Try again');
        return resultFor(filename);
      },
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pump();
    await tester.pump();

    expect(goodCalls, 1);
    expect(badCalls, 2);
    expect(find.text('Ready'), findsNWidgets(2));
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('removes failed rows and cleans ready files before removing them', (tester) async {
    final deletionGate = Completer<void>();
    final deleted = <String>[];
    final files = [
      SelectedBookFile(name: 'ready.epub', bytes: Uint8List.fromList([1])),
      SelectedBookFile(name: 'failed.epub', bytes: Uint8List.fromList([2])),
    ];

    await pumpResults(
      tester,
      files: files,
      processor: (_, filename) async {
        if (filename == 'failed.epub') throw Exception('Failed');
        return resultFor(filename, bookId: 'temporary-ready');
      },
      deleter: (bookId) async {
        deleted.add(bookId);
        await deletionGate.future;
      },
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Remove failed.epub'));
    await tester.pump();
    expect(find.text('failed.epub'), findsNothing);

    await tester.tap(find.byTooltip('Remove ready.epub'));
    await tester.pump();
    expect(deleted, ['temporary-ready']);
    expect(find.text('ready.epub'), findsOneWidget);

    deletionGate.complete();
    await tester.pump();
    expect(find.text('ready.epub'), findsNothing);
  });

  testWidgets('marks unreadable files failed without calling the processor', (tester) async {
    var processorCalls = 0;

    await pumpResults(
      tester,
      files: const [SelectedBookFile(name: 'missing.epub', bytes: null)],
      processor: (_, _) async {
        processorCalls++;
        return resultFor('unexpected.epub');
      },
    );
    await tester.pump();

    expect(processorCalls, 0);
    expect(find.text('missing.epub'), findsOneWidget);
    expect(find.text('Could not read this file.'), findsOneWidget);
  });

  testWidgets('close cleans every ready result and completes once', (tester) async {
    final deleted = <String>[];
    final observer = _PopCountingObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'one.epub', bytes: Uint8List.fromList([1])),
                  SelectedBookFile(name: 'two.epub', bytes: Uint8List.fromList([2])),
                ],
                processor: (_, filename) async => resultFor(filename),
                deleteBookFile: (bookId) async => deleted.add(bookId),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(deleted.toSet(), {'book-one.epub', 'book-two.epub'});
    expect(observer.pops, 1);
    expect(find.byType(BookImportResultsSheet), findsNothing);
  });

  testWidgets('dragging the route downward cannot dismiss and bypass cleanup', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'ready.epub', bytes: Uint8List.fromList([1])),
                ],
                processor: (_, filename) async => resultFor(filename, bookId: 'temporary-ready'),
                deleteBookFile: (bookId) async => deleted.add(bookId),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const Key('add-book-sheet-header')), const Offset(0, 700));
    await tester.pumpAndSettle();

    expect(find.byType(BookImportResultsSheet), findsOneWidget);
    expect(find.text('ready.epub'), findsOneWidget);
    expect(deleted, isEmpty);
  });

  testWidgets('cleanup failure keeps the sheet open and close can retry', (tester) async {
    var deleteAttempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'ready.epub', bytes: Uint8List.fromList([1])),
                ],
                processor: (_, filename) async => resultFor(filename, bookId: 'temporary-ready'),
                deleteBookFile: (_) async {
                  deleteAttempts++;
                  if (deleteAttempts == 1) throw Exception('private cleanup detail');
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(deleteAttempts, 1);
    expect(find.byType(BookImportResultsSheet), findsOneWidget);
    expect(find.text('Could not remove temporary files. Please try again.'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Close')).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(deleteAttempts, 2);
    expect(find.byType(BookImportResultsSheet), findsNothing);
  });

  testWidgets('close awaits and deduplicates cleanup already started by remove', (tester) async {
    final deletionGate = Completer<void>();
    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'ready.epub', bytes: Uint8List.fromList([1])),
                ],
                processor: (_, filename) async => resultFor(filename, bookId: 'temporary-ready'),
                deleteBookFile: (_) async {
                  deleteCalls++;
                  await deletionGate.future;
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove ready.epub'));
    await tester.pump();
    expect(deleteCalls, 1);

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(deleteCalls, 1);
    expect(find.byType(BookImportResultsSheet), findsOneWidget);

    deletionGate.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(deleteCalls, 1);
    expect(find.byType(BookImportResultsSheet), findsNothing);
  });

  testWidgets('close waits for a late success to be cleaned before disposing state', (tester) async {
    final processing = Completer<BookImportResult>();
    final deleted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'slow.epub', bytes: Uint8List.fromList([1])),
                ],
                processor: (_, _) => processing.future,
                deleteBookFile: (bookId) async => deleted.add(bookId),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BookImportResultsSheet), findsOneWidget);

    processing.complete(resultFor('slow.epub', bookId: 'late-book'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(deleted, ['late-book']);
    expect(find.byType(BookImportResultsSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed late-success cleanup keeps close retryable without reprocessing', (tester) async {
    final processing = Completer<BookImportResult>();
    final observer = _PopCountingObserver();
    var processorCalls = 0;
    var deleteAttempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'slow.epub', bytes: Uint8List.fromList([1])),
                ],
                processor: (_, _) {
                  processorCalls++;
                  return processing.future;
                },
                deleteBookFile: (_) async {
                  deleteAttempts++;
                  if (deleteAttempts == 1) throw Exception('private cleanup detail');
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    expect(find.byType(BookImportResultsSheet), findsOneWidget);

    processing.complete(resultFor('slow.epub', bookId: 'late-book'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(processorCalls, 1);
    expect(deleteAttempts, 1);
    expect(observer.pops, 0);
    expect(find.byType(BookImportResultsSheet), findsOneWidget);
    expect(find.text('Could not remove temporary files. Please try again.'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Close')).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(processorCalls, 1);
    expect(deleteAttempts, 2);
    expect(observer.pops, 1);
    expect(find.byType(BookImportResultsSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('places results between the fixed header and footer', (tester) async {
    await pumpResults(
      tester,
      files: const [SelectedBookFile(name: 'missing.epub', bytes: null)],
      processor: (_, _) async => resultFor('unused.epub'),
    );

    expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
    expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.widgetWithText(TextButton, 'Close'),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('book-import-results-list')),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsNothing,
    );
  });

  testWidgets('enables the counted add action only after processing settles', (tester) async {
    final processing = Completer<BookImportResult>();
    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'one.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (_, _) => processing.future,
      committer: (result, _) async => bookFor(result),
    );

    final addButton = find.widgetWithText(FilledButton, 'Add 0 to library');
    expect(addButton, findsOneWidget);
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);

    processing.complete(resultFor('one.epub'));
    await tester.pump();

    final enabledButton = find.widgetWithText(FilledButton, 'Add 1 to library');
    expect(enabledButton, findsOneWidget);
    expect(tester.widget<FilledButton>(enabledButton).onPressed, isNotNull);
  });

  testWidgets('commits every ready book and reports the completed batch', (tester) async {
    final committed = <String>[];
    List<Book>? completed;
    var closed = false;
    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'one.epub', bytes: Uint8List.fromList([1])),
        SelectedBookFile(name: 'two.epub', bytes: Uint8List.fromList([2])),
      ],
      processor: (_, filename) async => resultFor(filename),
      committer: (result, filename) async {
        committed.add(filename);
        return bookFor(result);
      },
      onClose: () => closed = true,
      onCompleted: (books) => completed = books,
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Add 2 to library'));
    await tester.pump();
    await tester.pump();

    expect(committed, ['one.epub', 'two.epub']);
    expect(completed?.map((book) => book.id), ['book-one.epub', 'book-two.epub']);
    expect(closed, isTrue);
  });

  testWidgets('partial commit retries only the failed final commit without duplicating successes', (tester) async {
    final processCalls = <String, int>{};
    final commitCalls = <String, int>{};
    List<Book>? completed;
    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'a.epub', bytes: Uint8List.fromList([1])),
        SelectedBookFile(name: 'b.epub', bytes: Uint8List.fromList([2])),
      ],
      processor: (_, filename) async {
        processCalls.update(filename, (count) => count + 1, ifAbsent: () => 1);
        return resultFor(filename);
      },
      committer: (result, filename) async {
        final attempt = commitCalls.update(filename, (count) => count + 1, ifAbsent: () => 1);
        if (filename == 'b.epub' && attempt == 1) throw Exception('Could not save');
        return bookFor(result);
      },
      onCompleted: (books) => completed = books,
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Add 2 to library'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Could not save'), findsOneWidget);
    expect(completed, isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pump();
    await tester.pump();

    expect(processCalls, {'a.epub': 1, 'b.epub': 1});
    expect(commitCalls, {'a.epub': 1, 'b.epub': 2});
    expect(completed, isNotNull);
  });

  testWidgets('removing a commit failure cleans only its temporary result', (tester) async {
    final deleted = <String>[];
    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'added.epub', bytes: Uint8List.fromList([1])),
        SelectedBookFile(name: 'failed.epub', bytes: Uint8List.fromList([2])),
      ],
      processor: (_, filename) async => resultFor(filename, bookId: 'temporary-$filename'),
      committer: (result, filename) async {
        if (filename == 'failed.epub') throw Exception('Commit failed');
        return bookFor(result);
      },
      deleter: (bookId) async => deleted.add(bookId),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Add 2 to library'));
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Remove added.epub'), findsNothing);
    await tester.tap(find.byTooltip('Remove failed.epub'));
    await tester.pump();

    expect(deleted, ['temporary-failed.epub']);
    expect(find.text('failed.epub'), findsNothing);
  });

  testWidgets('disables dismissal and mutable actions while a commit is active', (tester) async {
    final commit = Completer<Book>();
    var closed = false;
    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'slow.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (_, filename) async => resultFor(filename),
      committer: (_, _) => commit.future,
      onClose: () => closed = true,
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Add 1 to library'));
    await tester.pump();

    final closeButton = find.descendant(
      of: find.byKey(const Key('add-book-sheet-header')),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(closeButton).onPressed, isNull);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Close')).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add 0 to library')).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(closed, isFalse);

    commit.complete(bookFor(resultFor('slow.epub')));
    await tester.pump();
    await tester.pump();
  });

  testWidgets('closing after a partial commit deletes only uncommitted temporary files', (tester) async {
    final deleted = <String>[];
    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'added.epub', bytes: Uint8List.fromList([1])),
        SelectedBookFile(name: 'failed.epub', bytes: Uint8List.fromList([2])),
      ],
      processor: (_, filename) async => resultFor(filename, bookId: filename),
      committer: (result, filename) async {
        if (filename == 'failed.epub') throw Exception('Commit failed');
        return bookFor(result);
      },
      deleter: (bookId) async => deleted.add(bookId),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Add 2 to library'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
    await tester.pump();

    expect(deleted, ['failed.epub']);
  });

  testWidgets('production route closes and reports the completed book count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => BookImportResultsSheet.show(
                context,
                files: [
                  SelectedBookFile(name: 'one.epub', bytes: Uint8List.fromList([1])),
                  SelectedBookFile(name: 'two.epub', bytes: Uint8List.fromList([2])),
                ],
                processor: (_, filename) async => resultFor(filename),
                deleteBookFile: (_) async {},
                committer: (result, _) async => bookFor(result),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add 2 to library'));
    await tester.pumpAndSettle();

    expect(find.byType(BookImportResultsSheet), findsNothing);
    expect(find.text('Added 2 books to library'), findsOneWidget);
  });

  testWidgets('empty results keep a Close-only footer usable at narrow scaled width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpResults(tester, files: const [], processor: (_, filename) async => resultFor(filename));

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(TextButton, 'Close').hitTestable(), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ready results keep Close and counted Add usable at narrow scaled width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpResults(
      tester,
      files: [
        SelectedBookFile(name: 'ready.epub', bytes: Uint8List.fromList([1])),
      ],
      processor: (_, filename) async => resultFor(filename),
      committer: (result, _) async => bookFor(result),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(TextButton, 'Close').hitTestable(), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add 1 to library').hitTestable(), findsOneWidget);
  });
}
