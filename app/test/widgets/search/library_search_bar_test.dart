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
      await tester.pumpWidget(buildSearchBar());
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('calls onQueryChanged when text is entered', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        buildSearchBar(onQueryChanged: (q) => lastQuery = q),
      );

      await tester.enterText(find.byType(TextField), 'tolkien');
      await tester.pump();

      expect(lastQuery, 'tolkien');
    });

    testWidgets('calls onFilterTap when filter button is tapped', (
      tester,
    ) async {
      var filterTapped = false;
      await tester.pumpWidget(
        buildSearchBar(onFilterTap: () => filterTapped = true),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump();

      expect(filterTapped, true);
    });

    testWidgets('shows filter badge when activeFilterCount > 0', (
      tester,
    ) async {
      await tester.pumpWidget(buildSearchBar(activeFilterCount: 3));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not show filter badge when activeFilterCount is 0', (
      tester,
    ) async {
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
      await tester.pumpWidget(
        buildSearchBar(
          initialQuery: 'test',
          onQueryChanged: (q) => lastQuery = q,
        ),
      );
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

    group('suggestions', () {
      testWidgets('shows field suggestions when typing a field prefix', (
        tester,
      ) async {
        await tester.pumpWidget(buildSearchBar());

        // Focus and type a field prefix
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'auth');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show 'author:' suggestion in the overlay
        expect(find.text('author:'), findsOneWidget);
      });

      testWidgets('shows status suggestions when typing status:', (
        tester,
      ) async {
        await tester.pumpWidget(buildSearchBar());

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'status:');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show status value suggestions
        expect(find.text('status:reading'), findsOneWidget);
        expect(find.text('status:finished'), findsOneWidget);
        expect(find.text('status:unread'), findsOneWidget);
      });

      testWidgets('shows format suggestions when typing format:', (
        tester,
      ) async {
        await tester.pumpWidget(buildSearchBar());

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'format:');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show format value suggestions
        expect(find.text('format:epub'), findsOneWidget);
        expect(find.text('format:pdf'), findsOneWidget);
      });

      testWidgets('applies suggestion when tapped', (tester) async {
        String? lastQuery;
        await tester.pumpWidget(
          buildSearchBar(onQueryChanged: (q) => lastQuery = q),
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'auth');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the suggestion
        await tester.tap(find.text('author:'));
        await tester.pump();

        expect(lastQuery, 'author:');
      });

      testWidgets('hides suggestions when text is cleared', (tester) async {
        await tester.pumpWidget(buildSearchBar());

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'auth');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify suggestions are showing
        expect(find.text('author:'), findsOneWidget);

        // Clear text
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Suggestions should be gone
        expect(find.text('author:'), findsNothing);
      });

      testWidgets('does not show suggestions for non-matching text', (
        tester,
      ) async {
        await tester.pumpWidget(buildSearchBar());

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'xyz');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // No field suggestions should match 'xyz'
        expect(find.text('author:'), findsNothing);
        expect(find.text('title:'), findsNothing);
      });

      testWidgets('shows multiple field suggestions for partial match', (
        tester,
      ) async {
        await tester.pumpWidget(buildSearchBar());

        await tester.tap(find.byType(TextField));
        await tester.pump();
        // 's' matches 'shelf:', 'status:'
        await tester.enterText(find.byType(TextField), 's');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('shelf:'), findsOneWidget);
        expect(find.text('status:'), findsOneWidget);
      });
    });

    group('focus behavior', () {
      testWidgets('suggestions appear only when focused', (tester) async {
        await tester.pumpWidget(buildSearchBar());

        // Initially no suggestions
        expect(find.text('author:'), findsNothing);

        // Focus and type
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'auth');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Suggestions should appear
        expect(find.text('author:'), findsOneWidget);
      });
    });

    group('didUpdateWidget', () {
      testWidgets('updates text when initialQuery changes and not focused', (
        tester,
      ) async {
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
