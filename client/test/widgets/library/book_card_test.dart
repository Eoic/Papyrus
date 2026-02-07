import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/widgets/library/book_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BookCard', () {
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

    Widget buildCard({
      Book? book,
      bool isFavorite = false,
      void Function(bool)? onToggleFavorite,
      VoidCallback? onTap,
      bool showProgress = true,
    }) {
      return createTestApp(
        child: SizedBox(
          width: 200,
          height: 300,
          child: BookCard(
            book: book ?? testBook,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            onTap: onTap,
            showProgress: showProgress,
          ),
        ),
      );
    }

    testWidgets('displays book title', (tester) async {
      await tester.pumpWidget(buildCard());
      // Title appears in both the bottom text and the placeholder cover
      expect(find.text('The Hobbit'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays book author', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('J.R.R. Tolkien'), findsOneWidget);
    });

    testWidgets('displays format badge', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('displays physical format label', (tester) async {
      final physicalBook = testBook.copyWith(isPhysical: true);
      await tester.pumpWidget(buildCard(book: physicalBook));
      expect(find.text('Physical'), findsOneWidget);
    });

    testWidgets('shows progress bar when progress > 0', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress bar when showProgress is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard(showProgress: false));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('hides progress bar when progress is 0', (tester) async {
      final noProgressBook = testBook.copyWith(currentPosition: 0.0);
      await tester.pumpWidget(buildCard(book: noProgressBook));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows unfilled heart when not favorite', (tester) async {
      await tester.pumpWidget(buildCard(isFavorite: false));
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('shows filled heart when favorite', (tester) async {
      await tester.pumpWidget(buildCard(isFavorite: true));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('calls onToggleFavorite when favorite button tapped', (
      tester,
    ) async {
      bool? tappedValue;
      await tester.pumpWidget(
        buildCard(
          isFavorite: false,
          onToggleFavorite: (current) => tappedValue = current,
        ),
      );

      // Find and tap the favorite button (InkWell wrapping the heart icon)
      final favoriteIcon = find.byIcon(Icons.favorite_border);
      expect(favoriteIcon, findsOneWidget);
      await tester.tap(favoriteIcon);
      await tester.pump();

      expect(tappedValue, false);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
