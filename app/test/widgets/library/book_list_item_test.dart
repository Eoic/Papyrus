import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BookListItem', () {
    late Book testBook;

    setUp(() {
      testBook = Book(
        id: 'book-1',
        title: 'The Hobbit',
        author: 'J.R.R. Tolkien',
        readingStatus: ReadingStatus.inProgress,
        currentPosition: 0.5,
        isFavorite: false,
        fileFormat: BookFormat.epub,
        addedAt: DateTime.now(),
      );
    });

    Widget buildListItem({
      Book? book,
      bool isFavorite = false,
      VoidCallback? onTap,
      bool showProgress = true,
    }) {
      return createTestApp(
        child: BookListItem(
          book: book ?? testBook,
          isFavorite: isFavorite,
          onTap: onTap,
          showProgress: showProgress,
        ),
      );
    }

    testWidgets('displays book title', (tester) async {
      await tester.pumpWidget(buildListItem());
      expect(find.text('The Hobbit'), findsOneWidget);
    });

    testWidgets('displays book author', (tester) async {
      await tester.pumpWidget(buildListItem());
      expect(find.text('J.R.R. Tolkien'), findsOneWidget);
    });

    testWidgets('displays format badge', (tester) async {
      await tester.pumpWidget(buildListItem());
      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('shows progress bar and label when progress > 0', (
      tester,
    ) async {
      await tester.pumpWidget(buildListItem());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('hides progress when showProgress is false', (tester) async {
      await tester.pumpWidget(buildListItem(showProgress: false));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('hides progress bar when progress is 0', (tester) async {
      final noProgressBook = testBook.copyWith(currentPosition: 0.0);
      await tester.pumpWidget(buildListItem(book: noProgressBook));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows filled heart icon when favorite', (tester) async {
      await tester.pumpWidget(buildListItem(isFavorite: true));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows empty heart icon when not favorite', (tester) async {
      await tester.pumpWidget(buildListItem(isFavorite: false));
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildListItem(onTap: () => tapped = true));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(buildListItem());
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('displays physical format label', (tester) async {
      final physicalBook = testBook.copyWith(isPhysical: true);
      await tester.pumpWidget(buildListItem(book: physicalBook));
      expect(find.text('Physical'), findsOneWidget);
    });

    testWidgets('displays 100% progress for finished book', (tester) async {
      final finishedBook = testBook.copyWith(
        readingStatus: ReadingStatus.completed,
        currentPosition: 1.0,
      );
      await tester.pumpWidget(buildListItem(book: finishedBook));
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
