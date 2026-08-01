import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/widgets/add_book/add_book_choice_sheet.dart';
import 'package:papyrus/widgets/add_book/add_physical_book_sheet.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }
}

void main() {
  Future<void> pumpLauncher(
    WidgetTester tester,
    VoidCallback Function(BuildContext) action, {
    List<NavigatorObserver> navigatorObservers = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: navigatorObservers,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(onPressed: action(context), child: const Text('Open')),
          ),
        ),
      ),
    );
  }

  testWidgets('add book opens as a bottom sheet on desktop', (tester) async {
    await pumpLauncher(
      tester,
      (context) =>
          () => AddBookChoiceSheet.show(context),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheetHandle), findsOneWidget);
    expect(find.text('EPUB, PDF, AZW3, MOBI, CBZ/CBR'), findsOneWidget);
  });

  testWidgets('does not show the online search option without a callback', (tester) async {
    await pumpLauncher(
      tester,
      (context) =>
          () => AddBookChoiceSheet.show(context),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Find books online'), findsNothing);
  });

  testWidgets('invokes online search once after the choice sheet has dismissed', (tester) async {
    var findOnlineCalls = 0;
    var sheetWasAbsentAtCallback = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (homeContext) => Scaffold(
            body: FilledButton(
              onPressed: () {
                Navigator.of(homeContext).push(
                  MaterialPageRoute<void>(
                    builder: (pageContext) => Scaffold(
                      body: Builder(
                        builder: (sheetContext) => FilledButton(
                          onPressed: () => AddBookChoiceSheet.show(
                            sheetContext,
                            onFindOnline: () {
                              findOnlineCalls++;
                              sheetWasAbsentAtCallback = find.byType(BottomSheet).evaluate().isEmpty;
                            },
                          ),
                          child: const Text('Open add book'),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open add book'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.travel_explore_outlined), findsOneWidget);
    expect(find.text('Find books online'), findsOneWidget);
    expect(find.text('Search connected book sources'), findsOneWidget);

    final onlineOption = tester.widget<InkWell>(
      find.ancestor(of: find.text('Find books online'), matching: find.byType(InkWell)),
    );

    onlineOption.onTap!();
    onlineOption.onTap!();
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(findOnlineCalls, 1);
    expect(sheetWasAbsentAtCallback, isTrue);
    expect(find.text('Open add book'), findsOneWidget);
    expect(find.text('Open page'), findsNothing);
  });

  testWidgets('digital selection and results use distinct modal routes', (tester) async {
    final observer = _CountingNavigatorObserver();
    final selected = SelectedBookFile(name: 'selected.epub', bytes: Uint8List.fromList([1]));
    await pumpLauncher(
      tester,
      (context) =>
          () => AddBookChoiceSheet.show(
            context,
            digitalFilePicker: () async => [selected],
            bookImportProcessor: (_, filename) async => BookImportResult(
              bookId: 'temporary-book',
              title: filename,
              author: 'Author',
              fileSize: 1,
              fileHash: 'hash',
              fileExtension: 'epub',
            ),
            deleteImportedBookFile: (_) async {},
          ),
      navigatorObservers: [observer],
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final initialPushCount = observer.pushCount;

    await tester.tap(find.text('Import digital books'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Browse files'), findsOneWidget);
    expect(find.text('Add book'), findsNothing);
    expect(observer.pushCount, initialPushCount + 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Import 1 book'));
    await tester.pump();

    // The results route is not pushed until the selection route has finished
    // its dismissal animation.
    expect(find.text('Import results'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Import results'), findsOneWidget);
    expect(find.text('selected.epub'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Browse files'), findsNothing);
    expect(observer.pushCount, initialPushCount + 2);
  });

  testWidgets('physical choice dismisses before opening its separate sheet', (tester) async {
    final observer = _CountingNavigatorObserver();
    await pumpLauncher(
      tester,
      (context) =>
          () => AddBookChoiceSheet.show(context),
      navigatorObservers: [observer],
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final initialPushCount = observer.pushCount;

    await tester.tap(find.text('Add physical book'));
    await tester.pumpAndSettle();

    expect(find.text('Add physical book'), findsOneWidget);
    expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
    expect(find.text('Add book'), findsNothing);
    expect(observer.pushCount, initialPushCount + 1);
  });

  testWidgets('physical import places Add in the fixed footer', (tester) async {
    await pumpLauncher(
      tester,
      (context) =>
          () => AddPhysicalBookSheet.show(context),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.widgetWithText(FilledButton, 'Add'),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.widgetWithText(FilledButton, 'Add'),
        matching: find.byKey(const Key('add-book-sheet-header')),
      ),
      findsNothing,
    );
  });

  testWidgets('physical import keeps its footer above the landscape keyboard', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 400);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(onPressed: () => AddPhysicalBookSheet.show(context), child: const Text('Open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('add-book-sheet-footer'))).bottom, lessThanOrEqualTo(150));

    final listView = find.byType(ListView);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(tester.getSize(listView).height, greaterThan(0));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    scrollable.position.jumpTo(1);
    await tester.pump();

    expect(scrollable.position.pixels, 1);
  });

  testWidgets('physical import keeps scaled compact controls above the landscape keyboard', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 400);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(onPressed: () => AddPhysicalBookSheet.show(context), child: const Text('Open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byKey(const Key('add-book-sheet-footer'))).bottom, lessThanOrEqualTo(150));

    final closeButton = find.descendant(
      of: find.byKey(const Key('add-book-sheet-header')),
      matching: find.byType(IconButton),
    );
    expect(tester.getSize(closeButton).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(closeButton).height, greaterThanOrEqualTo(44));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(tester.getSize(find.byType(ListView)).height, greaterThan(0));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });
}
