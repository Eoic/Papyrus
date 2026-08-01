import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/digital_book_import_sheet.dart';

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required DigitalBookFilePicker pickFiles,
    required ValueChanged<List<SelectedBookFile>> onConfirm,
    VoidCallback? onCancel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: DigitalBookImportSheet(pickFiles: pickFiles, onConfirm: onConfirm, onCancel: onCancel ?? () {}),
          ),
        ),
      ),
    );
  }

  testWidgets('confirms the readable files left after removing a selection', (tester) async {
    List<SelectedBookFile>? confirmedFiles;
    final first = SelectedBookFile(name: 'first.epub', bytes: Uint8List.fromList([1]));
    final second = SelectedBookFile(name: 'second.pdf', bytes: Uint8List.fromList([2]));

    await pumpSheet(tester, pickFiles: () async => [first, second], onConfirm: (files) => confirmedFiles = files);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();

    expect(find.text('first.epub'), findsOneWidget);
    expect(find.text('second.pdf'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Import 2 books'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove first.epub'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Import 1 book'));

    expect(confirmedFiles, [same(second)]);
  });

  testWidgets('places selection content between the fixed header and footer', (tester) async {
    await pumpSheet(tester, pickFiles: () async => [], onConfirm: (_) {});

    expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
    expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.widgetWithText(FilledButton, 'Import 0 books'),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.widgetWithText(OutlinedButton, 'Browse files'),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsNothing,
    );
  });

  testWidgets('a fresh non-empty pick replaces the previous selection', (tester) async {
    var pickCount = 0;
    final oldFile = SelectedBookFile(name: 'old.epub', bytes: Uint8List.fromList([1]));
    final newFile = SelectedBookFile(name: 'new.pdf', bytes: Uint8List.fromList([2]));

    await pumpSheet(
      tester,
      pickFiles: () async {
        pickCount++;
        return pickCount == 1 ? [oldFile] : [newFile];
      },
      onConfirm: (_) {},
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();
    expect(find.text('old.epub'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();

    expect(find.text('old.epub'), findsNothing);
    expect(find.text('new.pdf'), findsOneWidget);
  });

  testWidgets('marks unreadable files and disables confirmation when none are readable', (tester) async {
    await pumpSheet(
      tester,
      pickFiles: () async => const [SelectedBookFile(name: 'broken.epub', bytes: null)],
      onConfirm: (_) => fail('Unreadable files must not be confirmed'),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();

    expect(find.text('broken.epub'), findsOneWidget);
    expect(find.text('Unreadable'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Import 1 book')).onPressed, isNull);
  });

  testWidgets('confirms readable and unreadable retained files as one batch', (tester) async {
    List<SelectedBookFile>? confirmedFiles;
    final readable = SelectedBookFile(name: 'readable.epub', bytes: Uint8List.fromList([1]));
    const unreadable = SelectedBookFile(name: 'unreadable.pdf', bytes: null);

    await pumpSheet(
      tester,
      pickFiles: () async => [readable, unreadable],
      onConfirm: (files) => confirmedFiles = files,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Import 2 books'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Import 2 books'));

    expect(confirmedFiles, [same(readable), same(unreadable)]);
  });

  testWidgets('preserves the selection and shows safe feedback when picking fails', (tester) async {
    var pickCount = 0;
    final selected = SelectedBookFile(name: 'selected.epub', bytes: Uint8List.fromList([1]));

    await pumpSheet(
      tester,
      pickFiles: () async {
        pickCount++;
        if (pickCount == 1) return [selected];
        throw Exception('private platform path');
      },
      onConfirm: (_) {},
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse files'));
    await tester.pump();

    expect(find.text('selected.epub'), findsOneWidget);
    expect(find.text('Could not open the selected files. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps footer actions usable at narrow width with scaled text', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 1200);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpSheet(tester, pickFiles: () async => [], onConfirm: (_) {});

    expect(tester.takeException(), isNull);
    expect(
      find.ancestor(
        of: find.widgetWithText(TextButton, 'Cancel'),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.widgetWithText(FilledButton, 'Import 0 books'),
        matching: find.byKey(const Key('add-book-sheet-footer')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('show pushes the draggable sheet on the root navigator', (tester) async {
    final rootObserver = _CountingNavigatorObserver();
    final nestedObserver = _CountingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [rootObserver],
        home: Navigator(
          observers: [nestedObserver],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (nestedContext) => Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => DigitalBookImportSheet.show(context, pickFiles: () async => []),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rootPushes = rootObserver.pushes;
    final nestedPushes = nestedObserver.pushes;

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(rootObserver.pushes, rootPushes + 1);
    expect(nestedObserver.pushes, nestedPushes);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is ModalBarrier && widget.color != null), findsOneWidget);
  });
}
