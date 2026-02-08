import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/widgets/book_details/book_action_buttons.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BookActionButtons', () {
    Widget buildWidget({
      Book? book,
      VoidCallback? onContinueReading,
      VoidCallback? onUpdateProgress,
      VoidCallback? onToggleFavorite,
      VoidCallback? onEdit,
      bool isDesktop = false,
    }) {
      return createTestApp(
        child: BookActionButtons(
          book:
              book ??
              buildTestBook(
                fileFormat: BookFormat.epub,
                currentPosition: 0.5,
                readingStatus: ReadingStatus.inProgress,
              ),
          onContinueReading: onContinueReading,
          onUpdateProgress: onUpdateProgress,
          onToggleFavorite: onToggleFavorite,
          onEdit: onEdit,
          isDesktop: isDesktop,
        ),
      );
    }

    group('digital book', () {
      testWidgets('shows Continue button when book has progress', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(
              currentPosition: 0.5,
              fileFormat: BookFormat.epub,
            ),
          ),
        );

        expect(find.text('Continue'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('shows Read button when book has no progress (mobile)', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(
              currentPosition: 0.0,
              fileFormat: BookFormat.epub,
            ),
          ),
        );

        expect(find.text('Read'), findsOneWidget);
        expect(find.byIcon(Icons.menu_book), findsOneWidget);
      });

      testWidgets(
        'shows Start reading button when book has no progress (desktop)',
        (tester) async {
          await tester.pumpWidget(
            buildWidget(
              book: buildTestBook(
                currentPosition: 0.0,
                fileFormat: BookFormat.epub,
              ),
              isDesktop: true,
            ),
          );

          expect(find.text('Start reading'), findsOneWidget);
        },
      );

      testWidgets('calls onContinueReading when tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(
              currentPosition: 0.5,
              fileFormat: BookFormat.epub,
            ),
            onContinueReading: () => called = true,
          ),
        );

        await tester.tap(find.text('Continue'));
        expect(called, true);
      });
    });

    group('physical book', () {
      testWidgets('shows Update progress button', (tester) async {
        await tester.pumpWidget(
          buildWidget(book: buildTestBook(isPhysical: true)),
        );

        expect(find.text('Update progress'), findsOneWidget);
        expect(find.byIcon(Icons.edit_note), findsOneWidget);
      });

      testWidgets('calls onUpdateProgress when tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(isPhysical: true),
            onUpdateProgress: () => called = true,
          ),
        );

        await tester.tap(find.text('Update progress'));
        expect(called, true);
      });
    });

    group('favorite button', () {
      testWidgets('shows outlined heart when not favorite', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(isFavorite: false, fileFormat: BookFormat.epub),
          ),
        );

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      });

      testWidgets('shows filled heart when favorite', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(isFavorite: true, fileFormat: BookFormat.epub),
          ),
        );

        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('calls onToggleFavorite when tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(fileFormat: BookFormat.epub),
            onToggleFavorite: () => called = true,
          ),
        );

        // Find the favorite button (OutlinedButton with heart icon)
        final favoriteButton = find.ancestor(
          of: find.byIcon(Icons.favorite_border),
          matching: find.byType(OutlinedButton),
        );
        await tester.tap(favoriteButton);
        expect(called, true);
      });
    });

    group('edit button', () {
      testWidgets('shows edit icon', (tester) async {
        await tester.pumpWidget(
          buildWidget(book: buildTestBook(fileFormat: BookFormat.epub)),
        );

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('calls onEdit when tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(
            book: buildTestBook(fileFormat: BookFormat.epub),
            onEdit: () => called = true,
          ),
        );

        final editButton = find.ancestor(
          of: find.byIcon(Icons.edit_outlined),
          matching: find.byType(OutlinedButton),
        );
        await tester.tap(editButton);
        expect(called, true);
      });
    });
  });
}
