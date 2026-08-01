import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  Future<void> pumpResults(
    WidgetTester tester, {
    required List<SelectedBookFile> files,
    required BookImportProcessor processor,
    ImportedBookFileDeleter? deleter,
    VoidCallback? onClose,
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
              onClose: onClose ?? () {},
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

  testWidgets('a success arriving after close is deleted without updating disposed state', (tester) async {
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
    expect(find.byType(BookImportResultsSheet), findsNothing);

    processing.complete(resultFor('slow.epub', bookId: 'late-book'));
    await tester.pump();
    await tester.pump();

    expect(deleted, ['late-book']);
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
}
