import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';

void main() {
  group('LibrarySearchBar', () {
    Widget buildSearchBar({
      ValueChanged<String>? onQueryChanged,
      VoidCallback? onFilterTap,
      int activeFilterCount = 0,
      String initialQuery = '',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LibrarySearchBar(
              onQueryChanged: onQueryChanged,
              onFilterTap: onFilterTap,
              activeFilterCount: activeFilterCount,
              initialQuery: initialQuery,
            ),
          ),
        ),
      );
    }

    testWidgets('displays search hint text', (tester) async {
      await tester.pumpWidget(buildSearchBar());
      expect(find.text('Search books...'), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(buildSearchBar());
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays filter button', (tester) async {
      await tester.pumpWidget(buildSearchBar(onFilterTap: () {}));
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('calls onQueryChanged when text is entered', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildSearchBar(onQueryChanged: (q) => lastQuery = q));

      await tester.enterText(find.byType(TextField), 'tolkien');
      await tester.pump();

      expect(lastQuery, 'tolkien');
    });

    testWidgets('calls onFilterTap when filter button is tapped', (tester) async {
      var filterTapped = false;
      await tester.pumpWidget(buildSearchBar(onFilterTap: () => filterTapped = true));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();

      expect(filterTapped, true);
    });

    testWidgets('shows filter badge when activeFilterCount > 0', (tester) async {
      await tester.pumpWidget(buildSearchBar(activeFilterCount: 3, onFilterTap: () {}));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not show filter badge when activeFilterCount is 0', (tester) async {
      await tester.pumpWidget(buildSearchBar(activeFilterCount: 0));

      // Badge number should not be present
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(buildSearchBar(initialQuery: 'test'));
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text when clear button is tapped', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildSearchBar(initialQuery: 'test', onQueryChanged: (q) => lastQuery = q));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(lastQuery, '');
    });

    testWidgets('initializes with initial query', (tester) async {
      await tester.pumpWidget(buildSearchBar(initialQuery: 'my search'));
      await tester.pump();

      expect(find.text('my search'), findsOneWidget);
    });

    testWidgets('contains a TextField', (tester) async {
      await tester.pumpWidget(buildSearchBar());
      expect(find.byType(TextField), findsOneWidget);
    });

    group('didUpdateWidget', () {
      testWidgets('updates text when initialQuery changes and not focused', (tester) async {
        // Start with empty query
        await tester.pumpWidget(buildSearchBar(initialQuery: ''));

        // Rebuild with new initialQuery
        await tester.pumpWidget(buildSearchBar(initialQuery: 'new query'));
        await tester.pump();

        expect(find.text('new query'), findsOneWidget);
      });
    });
  });
}
