import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/add_book/add_book_choice_sheet.dart';
import 'package:papyrus/widgets/add_book/add_physical_book_sheet.dart';
import 'package:papyrus/widgets/add_book/import_book_sheet.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }
}

const importedBook = BookImportResult(
  bookId: 'book-1',
  title: 'Frankenstein',
  author: 'Mary Wollstonecraft Shelley',
  pageCount: 239,
  fileSize: 1024,
  fileHash: 'hash',
  fileExtension: 'epub',
);

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

  testWidgets('import book opens as a format-neutral bottom sheet on desktop', (tester) async {
    await pumpLauncher(
      tester,
      (context) =>
          () => ImportBookSheet.show(context),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheetHandle), findsOneWidget);
    expect(find.byType(BottomSheetHeader), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('Select a digital book file'), findsOneWidget);
    expect(find.text('EPUB, PDF, AZW3, MOBI, CBZ/CBR'), findsOneWidget);
    expect(find.text('Select an EPUB file'), findsNothing);
    expect(find.text('The file will be stored offline on this device'), findsNothing);
    expect(find.byKey(const Key('import-pending-content')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('import-pending-content'))).height, 232);
    expect(
      find.ancestor(
        of: find.text('Select a digital book file'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).border != null,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('digital import transition preserves the modal backdrop', (tester) async {
    final observer = _CountingNavigatorObserver();
    await pumpLauncher(
      tester,
      (context) =>
          () => AddBookChoiceSheet.show(context),
      navigatorObservers: [observer],
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dimmingBarrier = find.byWidgetPredicate((widget) => widget is ModalBarrier && widget.color != null);
    final initialPushCount = observer.pushCount;
    final initialBarrier = tester.element(dimmingBarrier);

    await tester.tap(find.text('Import digital books'));
    await tester.pumpAndSettle();

    expect(find.text('Import book'), findsOneWidget);
    expect(dimmingBarrier, findsOneWidget);
    expect(tester.element(dimmingBarrier), same(initialBarrier));
    expect(observer.pushCount, initialPushCount);
  });

  testWidgets('successful import actions can be rendered for widget verification', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ImportBookSheet.withInitialResult(importedBook))));

    expect(find.text('Pick different file'), findsOneWidget);
    expect(find.text('Add to library'), findsOneWidget);

    final pickButton = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Pick different file'));
    final addButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add to library'));

    expect(pickButton.style?.shape?.resolve({}), isA<StadiumBorder>());
    expect(addButton.style?.shape?.resolve({}), isA<StadiumBorder>());
  });

  testWidgets('committing import actions stay visually stable and show progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: ImportBookSheet.withInitialResult(importedBook, initialCommitting: true)),
      ),
    );

    final pickButton = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Pick different file'));
    final addButton = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(pickButton.onPressed, isNull);
    expect(addButton.onPressed, isNull);
    expect(find.text('Adding...'), findsOneWidget);
    expect(find.text('Add to library'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final colorScheme = Theme.of(tester.element(find.text('Adding...'))).colorScheme;
    const disabled = <WidgetState>{WidgetState.disabled};

    expect(pickButton.style?.foregroundColor?.resolve(disabled), colorScheme.primary);
    expect(pickButton.style?.side?.resolve(disabled)?.color, colorScheme.outline);
    expect(addButton.style?.backgroundColor?.resolve(disabled), colorScheme.primary);
    expect(addButton.style?.foregroundColor?.resolve(disabled), colorScheme.onPrimary);
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
}
