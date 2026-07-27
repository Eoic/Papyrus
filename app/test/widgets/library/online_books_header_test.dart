import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/library/online_books_header.dart';
import 'package:papyrus/widgets/library/selection_header.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';

void main() {
  Widget buildHeader({
    required TextEditingController controller,
    required VoidCallback onBack,
    required ValueChanged<String> onSearch,
    bool autofocus = false,
    bool isSearching = false,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OnlineBooksHeader(
              controller: controller,
              autofocus: autofocus,
              isSearching: isSearching,
              onBack: onBack,
              onSearch: onSearch,
            ),
          ),
        ),
      ),
    );
  }

  IconButton searchButton(WidgetTester tester) {
    return tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.search),
    );
  }

  testWidgets('renders back control, title, and search field', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var backCalls = 0;

    await tester.pumpWidget(
      buildHeader(
        controller: controller,
        onBack: () => backCalls++,
        onSearch: (_) {},
      ),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.text('Online results'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));

    expect(backCalls, 1);
  });

  testWidgets('matches the library search field height on desktop', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: Column(
              children: [
                OnlineBooksHeader(
                  controller: controller,
                  autofocus: false,
                  isSearching: false,
                  onBack: () {},
                  onSearch: (_) {},
                ),
                const LibrarySearchBar(),
              ],
            ),
          ),
        ),
      ),
    );

    final onlineField = find.descendant(
      of: find.byType(OnlineBooksHeader),
      matching: find.byType(TextField),
    );
    final libraryField = find.descendant(
      of: find.byType(LibrarySearchBar),
      matching: find.byType(TextField),
    );

    expect(
      tester.getSize(onlineField).height,
      tester.getSize(libraryField).height,
    );
  });

  testWidgets('matches the selection header height on desktop', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: Column(
              children: [
                OnlineBooksHeader(
                  controller: controller,
                  autofocus: false,
                  isSearching: false,
                  onBack: () {},
                  onSearch: (_) {},
                ),
                SelectionHeader(
                  selectedCount: 1,
                  totalCount: 5,
                  onClose: () {},
                  onSelectAll: () {},
                  onDeselectAll: () {},
                  actions: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(OnlineBooksHeader)).height,
      tester.getSize(find.byType(SelectionHeader)).height,
    );
  });

  testWidgets('honors autofocus for online search entered from add book', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildHeader(
        controller: controller,
        autofocus: true,
        onBack: () {},
        onSearch: (_) {},
      ),
    );
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('typing does not search and enables search for non-empty input', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submitted = <String>[];

    await tester.pumpWidget(
      buildHeader(
        controller: controller,
        onBack: () {},
        onSearch: submitted.add,
      ),
    );

    expect(searchButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Dune');
    await tester.pump();

    expect(submitted, isEmpty);
    expect(searchButton(tester).onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(searchButton(tester).onPressed, isNull);
  });

  testWidgets('keyboard submit searches the trimmed query exactly once', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submitted = <String>[];

    await tester.pumpWidget(
      buildHeader(
        controller: controller,
        onBack: () {},
        onSearch: submitted.add,
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      '  The Left Hand of Darkness  ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(submitted, ['The Left Hand of Darkness']);
  });

  testWidgets('search icon submits the trimmed query exactly once', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submitted = <String>[];

    await tester.pumpWidget(
      buildHeader(
        controller: controller,
        onBack: () {},
        onSearch: submitted.add,
      ),
    );

    await tester.enterText(find.byType(TextField), '  A Wizard of Earthsea  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Search'));

    expect(submitted, ['A Wizard of Earthsea']);
  });

  testWidgets('disables submit while searching', (tester) async {
    final controller = TextEditingController(text: 'Dune');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildHeader(
        controller: controller,
        isSearching: true,
        onBack: () {},
        onSearch: (_) {},
      ),
    );

    expect(searchButton(tester).onPressed, isNull);
  });

  testWidgets('fits compact mobile and desktop layouts with the dark theme', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in [const Size(320, 640), const Size(1280, 800)]) {
      tester.view.physicalSize = size;

      await tester.pumpWidget(
        buildHeader(controller: controller, onBack: () {}, onSearch: (_) {}),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'keeps search visible near the desktop breakpoint with large text',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 640);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: buildHeader(
            controller: controller,
            onBack: () {},
            onSearch: (_) {},
          ),
        ),
      );
      await tester.pump();

      final headerRow = find.ancestor(
        of: find.text('Online results'),
        matching: find.byType(Row),
      );

      expect(headerRow, findsOneWidget);
      expect(
        find.descendant(of: headerRow, matching: find.byType(TextField)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
