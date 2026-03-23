import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';

void main() {
  group('LibraryDrawer', () {
    Widget buildDrawer({String currentPath = '/library'}) {
      return MaterialApp(
        home: Scaffold(
          drawer: LibraryDrawer(currentPath: currentPath),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Open Drawer'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays library header', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('displays all navigation items', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Shelves'), findsOneWidget);
      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('Annotations'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('displays correct icons', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byIcon(Icons.shelves), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.format_quote), findsOneWidget);
      expect(find.byIcon(Icons.note), findsOneWidget);
    });

    testWidgets('highlights Books when on /library path', (tester) async {
      await tester.pumpWidget(buildDrawer(currentPath: '/library'));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Books item should be selected (ListTile with selected: true)
      final booksItem = tester.widget<ListTile>(
        find.ancestor(of: find.text('Books'), matching: find.byType(ListTile)),
      );
      expect(booksItem.selected, true);
    });

    testWidgets('highlights Books when on /library/books path', (tester) async {
      await tester.pumpWidget(buildDrawer(currentPath: '/library/books'));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      final booksItem = tester.widget<ListTile>(
        find.ancestor(of: find.text('Books'), matching: find.byType(ListTile)),
      );
      expect(booksItem.selected, true);
    });

    testWidgets('highlights Shelves when on /library/shelves path', (
      tester,
    ) async {
      await tester.pumpWidget(buildDrawer(currentPath: '/library/shelves'));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      final shelvesItem = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Shelves'),
          matching: find.byType(ListTile),
        ),
      );
      expect(shelvesItem.selected, true);
    });

    testWidgets('non-selected items are not highlighted', (tester) async {
      await tester.pumpWidget(buildDrawer(currentPath: '/library'));
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      final shelvesItem = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Shelves'),
          matching: find.byType(ListTile),
        ),
      );
      expect(shelvesItem.selected, false);

      final notesItem = tester.widget<ListTile>(
        find.ancestor(of: find.text('Notes'), matching: find.byType(ListTile)),
      );
      expect(notesItem.selected, false);
    });

    testWidgets('is rendered inside a Drawer widget', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });
  });
}
