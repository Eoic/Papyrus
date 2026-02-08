import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/book_details/empty_bookmarks_state.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('EmptyBookmarksState', () {
    Widget buildWidget({bool isPhysical = false, VoidCallback? onAddBookmark}) {
      return createTestApp(
        child: EmptyBookmarksState(
          isPhysical: isPhysical,
          onAddBookmark: onAddBookmark,
        ),
      );
    }

    group('rendering', () {
      testWidgets('displays bookmark icon', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      });

      testWidgets('displays title text', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('No bookmarks yet'), findsOneWidget);
      });
    });

    group('digital book', () {
      testWidgets('shows digital book description', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(
          find.text('Bookmarks you create while reading will appear here.'),
          findsOneWidget,
        );
      });

      testWidgets('does not show add bookmark button', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Add bookmark'), findsNothing);
      });
    });

    group('physical book', () {
      testWidgets('shows physical book description', (tester) async {
        await tester.pumpWidget(buildWidget(isPhysical: true));

        expect(
          find.text('Save pages you want to return to later.'),
          findsOneWidget,
        );
      });

      testWidgets('shows add bookmark button', (tester) async {
        await tester.pumpWidget(buildWidget(isPhysical: true));

        expect(find.text('Add bookmark'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('add button calls onAddBookmark', (tester) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(isPhysical: true, onAddBookmark: () => called = true),
        );

        await tester.tap(find.text('Add bookmark'));
        expect(called, true);
      });
    });
  });
}
