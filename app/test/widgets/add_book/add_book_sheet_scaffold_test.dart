import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/add_book/add_book_sheet_scaffold.dart';

void main() {
  testWidgets('keeps its header and footer fixed while the body scrolls', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddBookSheetScaffold(
            title: 'Add book',
            onClose: () {},
            body: ListView.builder(
              key: const Key('scrolling-body'),
              controller: scrollController,
              itemCount: 30,
              itemBuilder: (_, index) => SizedBox(height: 64, child: Text('Item $index')),
            ),
            footer: const Text('Actions'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
    expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);

    final headerTopBeforeScroll = tester.getTopLeft(find.byKey(const Key('add-book-sheet-header'))).dy;
    final footerTopBeforeScroll = tester.getTopLeft(find.byKey(const Key('add-book-sheet-footer'))).dy;

    await tester.drag(find.byKey(const Key('scrolling-body')), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(0));
    expect(tester.getTopLeft(find.byKey(const Key('add-book-sheet-header'))).dy, headerTopBeforeScroll);
    expect(tester.getTopLeft(find.byKey(const Key('add-book-sheet-footer'))).dy, footerTopBeforeScroll);
  });

  testWidgets('constrains a large title beside the close button on narrow screens', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: AddBookSheetScaffold(
              title: 'A very long physical book title that must remain readable',
              onClose: () {},
              body: const SizedBox(),
              footer: const SizedBox(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
