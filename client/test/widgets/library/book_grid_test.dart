import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:papyrus/widgets/library/book_grid.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BookGrid', () {
    late List<Book> testBooks;

    setUp(() {
      testBooks = createTestBooks();
    });

    Widget buildGrid({
      List<Book>? books,
      void Function(Book)? onBookTap,
      Size screenSize = const Size(400, 800),
    }) {
      return createTestApp(
        dataStore: createTestDataStore(books: books ?? testBooks),
        child: BookGrid(books: books ?? testBooks, onBookTap: onBookTap),
        screenSize: screenSize,
      );
    }

    testWidgets('renders BookCards in grid', (tester) async {
      await tester.pumpWidget(buildGrid());
      await tester.pumpAndSettle();

      // GridView.builder lazily builds cards so not all may be rendered
      // at once; verify at least some cards are visible
      expect(find.byType(BookCard), findsAtLeastNWidgets(2));
    });

    testWidgets('renders empty grid when no books', (tester) async {
      await tester.pumpWidget(buildGrid(books: []));
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNothing);
    });

    testWidgets('passes onBookTap to each card', (tester) async {
      Book? tappedBook;
      await tester.pumpWidget(
        buildGrid(onBookTap: (book) => tappedBook = book),
      );
      await tester.pumpAndSettle();

      // Tap the first card
      await tester.tap(find.byType(BookCard).first);
      await tester.pump();

      expect(tappedBook, isNotNull);
      expect(tappedBook!.title, 'The Hobbit');
    });

    testWidgets('displays books in GridView', (tester) async {
      await tester.pumpWidget(buildGrid());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('renders with a single book', (tester) async {
      await tester.pumpWidget(buildGrid(books: [testBooks.first]));
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsOneWidget);
    });
  });
}
