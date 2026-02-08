import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/widgets/book/book_bookmarks.dart';
import 'package:papyrus/widgets/bookmarks/bookmark_list_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late List<Bookmark> testBookmarks;

  setUp(() {
    final now = DateTime.now();
    testBookmarks = [
      Bookmark(
        id: 'bm-1',
        bookId: 'book-1',
        position: 0.3,
        pageNumber: 50,
        chapterTitle: 'The Beginning',
        note: 'Great opening chapter',
        colorHex: '#4CAF50',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Bookmark(
        id: 'bm-2',
        bookId: 'book-1',
        position: 0.6,
        pageNumber: 120,
        chapterTitle: 'The Middle',
        colorHex: '#FF5722',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Bookmark(
        id: 'bm-3',
        bookId: 'book-1',
        position: 0.1,
        pageNumber: 15,
        note: 'Interesting point about philosophy',
        colorHex: '#2196F3',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  });

  Widget buildBookmarks({
    List<Bookmark>? bookmarks,
    Function(Bookmark)? onBookmarkActions,
    Size screenSize = const Size(400, 800),
  }) {
    return createTestApp(
      screenSize: screenSize,
      child: BookBookmarks(
        bookmarks: bookmarks ?? testBookmarks,
        bookTitle: 'Test Book',
        onBookmarkActions: onBookmarkActions,
      ),
    );
  }

  group('BookBookmarks', () {
    group('rendering', () {
      testWidgets('displays search field with hint text', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        expect(find.text('Search bookmarks...'), findsOneWidget);
      });

      testWidgets('displays sort button', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        expect(find.byIcon(Icons.sort), findsOneWidget);
      });

      testWidgets('renders BookmarkListItem for each bookmark', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        expect(find.byType(BookmarkListItem), findsNWidgets(3));
      });

      testWidgets('shows empty state when bookmarks list is empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildBookmarks(bookmarks: []));

        expect(find.text('No bookmarks yet'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      });
    });

    group('search', () {
      testWidgets('filters bookmarks by location text', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        await tester.enterText(find.byType(TextField), 'Beginning');
        await tester.pump();

        expect(find.byType(BookmarkListItem), findsOneWidget);
        expect(find.text('The Beginning, Page 50'), findsOneWidget);
      });

      testWidgets('filters bookmarks by note text', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        await tester.enterText(find.byType(TextField), 'philosophy');
        await tester.pump();

        expect(find.byType(BookmarkListItem), findsOneWidget);
      });

      testWidgets('shows no results when search has no matches', (
        tester,
      ) async {
        await tester.pumpWidget(buildBookmarks());

        await tester.enterText(find.byType(TextField), 'zzzznonexistent');
        await tester.pump();

        expect(find.text('No bookmarks found'), findsOneWidget);
      });

      testWidgets('clearing search restores all bookmarks', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        // Search to filter
        await tester.enterText(find.byType(TextField), 'Beginning');
        await tester.pump();
        expect(find.byType(BookmarkListItem), findsOneWidget);

        // Clear search
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        expect(find.byType(BookmarkListItem), findsNWidgets(3));
      });
    });

    group('sorting', () {
      testWidgets('tapping sort button opens popup menu with 3 options', (
        tester,
      ) async {
        await tester.pumpWidget(buildBookmarks());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        expect(find.text('Newest first'), findsOneWidget);
        expect(find.text('Oldest first'), findsOneWidget);
        expect(find.text('By position'), findsOneWidget);
      });

      testWidgets('newest first is selected by default', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        // The check icon next to "Newest first" should be visible (primary color)
        // while others should be transparent
        final newestItem = find.ancestor(
          of: find.text('Newest first'),
          matching: find.byType(Row),
        );
        expect(newestItem, findsOneWidget);
      });

      testWidgets('selecting oldest first reorders list', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        // Default: newest first — bm-3 (5h ago), bm-1 (1d ago), bm-2 (3d ago)
        var items = tester.widgetList<BookmarkListItem>(
          find.byType(BookmarkListItem),
        );
        expect(items.first.bookmark.id, 'bm-3');

        // Select "Oldest first"
        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Oldest first'));
        await tester.pumpAndSettle();

        // Now: bm-2 (3d ago), bm-1 (1d ago), bm-3 (5h ago)
        items = tester.widgetList<BookmarkListItem>(
          find.byType(BookmarkListItem),
        );
        expect(items.first.bookmark.id, 'bm-2');
      });

      testWidgets('selecting by position reorders list', (tester) async {
        await tester.pumpWidget(buildBookmarks());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();
        await tester.tap(find.text('By position'));
        await tester.pumpAndSettle();

        // By position: bm-3 (0.1), bm-1 (0.3), bm-2 (0.6)
        final items = tester.widgetList<BookmarkListItem>(
          find.byType(BookmarkListItem),
        );
        expect(items.first.bookmark.id, 'bm-3');
        expect(items.last.bookmark.id, 'bm-2');
      });
    });

    group('callbacks', () {
      testWidgets('long press on bookmark calls onBookmarkActions', (
        tester,
      ) async {
        Bookmark? actionBookmark;
        await tester.pumpWidget(
          buildBookmarks(onBookmarkActions: (b) => actionBookmark = b),
        );

        await tester.longPress(find.byType(BookmarkListItem).first);
        await tester.pump();

        expect(actionBookmark, isNotNull);
        expect(actionBookmark!.id, 'bm-3'); // newest first by default
      });
    });

    group('responsive', () {
      testWidgets('desktop layout shows action menu on items', (tester) async {
        await tester.pumpWidget(
          buildBookmarks(screenSize: const Size(1200, 800)),
        );

        expect(find.byIcon(Icons.more_vert), findsNWidgets(3));
      });

      testWidgets('mobile layout hides action menu on items', (tester) async {
        await tester.pumpWidget(
          buildBookmarks(screenSize: const Size(400, 800)),
        );

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });
    });
  });
}
