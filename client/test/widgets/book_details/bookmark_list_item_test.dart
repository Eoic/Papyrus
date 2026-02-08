import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/widgets/bookmarks/bookmark_list_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late Bookmark bookmarkWithNote;
  late Bookmark bookmarkWithoutNote;

  setUp(() {
    bookmarkWithNote = Bookmark(
      id: 'bm-1',
      bookId: 'book-1',
      position: 0.25,
      pageNumber: 42,
      chapterTitle: 'Chapter 3',
      note: 'This is an important passage to remember.',
      colorHex: '#4CAF50',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    bookmarkWithoutNote = Bookmark(
      id: 'bm-2',
      bookId: 'book-1',
      position: 0.5,
      pageNumber: 100,
      colorHex: '#FF5722',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );
  });

  Widget buildItem({
    Bookmark? bookmark,
    bool showActionMenu = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return createTestApp(
      child: BookmarkListItem(
        bookmark: bookmark ?? bookmarkWithNote,
        bookTitle: 'Test Book',
        showActionMenu: showActionMenu,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  group('BookmarkListItem', () {
    group('rendering', () {
      testWidgets('displays location text', (tester) async {
        await tester.pumpWidget(buildItem());

        expect(find.text('Chapter 3, Page 42'), findsOneWidget);
      });

      testWidgets('displays relative date', (tester) async {
        await tester.pumpWidget(buildItem());

        expect(find.text('2 hours ago'), findsOneWidget);
      });

      testWidgets('shows note text when bookmark has a note', (tester) async {
        await tester.pumpWidget(buildItem());

        expect(
          find.text('This is an important passage to remember.'),
          findsOneWidget,
        );
      });

      testWidgets('hides note section when no note', (tester) async {
        await tester.pumpWidget(buildItem(bookmark: bookmarkWithoutNote));

        expect(find.byIcon(Icons.note_outlined), findsNothing);
      });

      testWidgets('shows color dot', (tester) async {
        await tester.pumpWidget(buildItem());

        // The color dot is an 8x8 circle Container
        final dot = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              widget.constraints?.maxWidth == 8,
        );
        expect(dot, findsOneWidget);
      });

      testWidgets('shows action menu when showActionMenu is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildItem(showActionMenu: true));

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('hides action menu when showActionMenu is false', (
        tester,
      ) async {
        await tester.pumpWidget(buildItem(showActionMenu: false));

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('displays page-only location when no chapter', (
        tester,
      ) async {
        await tester.pumpWidget(buildItem(bookmark: bookmarkWithoutNote));

        expect(find.text('Page 100'), findsOneWidget);
      });
    });

    group('callbacks', () {
      testWidgets('long press calls onLongPress', (tester) async {
        var longPressed = false;
        await tester.pumpWidget(
          buildItem(onLongPress: () => longPressed = true),
        );

        await tester.longPress(find.byType(BookmarkListItem));
        await tester.pump();

        expect(longPressed, isTrue);
      });

      testWidgets('action menu button calls onLongPress', (tester) async {
        var pressed = false;
        await tester.pumpWidget(buildItem(onLongPress: () => pressed = true));

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });
  });
}
