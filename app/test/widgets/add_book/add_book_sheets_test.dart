import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/add_book/add_book_choice_sheet.dart';
import 'package:papyrus/widgets/add_book/import_book_sheet.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

void main() {
  Future<void> pumpLauncher(WidgetTester tester, VoidCallback Function(BuildContext) action) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
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

  testWidgets('shows the online search option and invokes its callback after closing', (tester) async {
    var findOnlineCalls = 0;

    await pumpLauncher(
      tester,
      (context) =>
          () => AddBookChoiceSheet.show(context, onFindOnline: () => findOnlineCalls++),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.travel_explore_outlined), findsOneWidget);
    expect(find.text('Find books online'), findsOneWidget);
    expect(find.text('Search connected book sources'), findsOneWidget);

    await tester.tap(find.text('Find books online'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(findOnlineCalls, 1);
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
}
