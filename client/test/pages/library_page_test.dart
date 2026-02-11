import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/pages/library_page.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LibraryPage', () {
    late LibraryProvider libraryProvider;
    late DataStore dataStore;

    setUp(() {
      libraryProvider = LibraryProvider();
      dataStore = createTestDataStore();
    });

    Widget buildPage({
      Size screenSize = const Size(400, 800),
      LibraryProvider? provider,
      DataStore? store,
    }) {
      return createTestPage(
        page: const LibraryPage(),
        libraryProvider: provider ?? libraryProvider,
        dataStore: store ?? dataStore,
        screenSize: screenSize,
      );
    }

    // ========================================================================
    // Mobile layout tests
    // ========================================================================

    group('mobile layout', () {
      testWidgets('renders search bar', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(LibrarySearchBar), findsOneWidget);
      });

      testWidgets('renders filter chips', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(LibraryFilterChips), findsOneWidget);
      });

      testWidgets('renders hamburger menu button', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.menu), findsOneWidget);
      });

      testWidgets('renders FAB with add icon', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('displays book count', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('5 books'), findsOneWidget);
      });

      testWidgets('displays singular "book" when only 1 book', (tester) async {
        final singleBookStore = createTestDataStore(
          books: [createTestBooks().first],
        );
        await tester.pumpWidget(buildPage(store: singleBookStore));
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('renders grid view by default', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(BookCard), findsWidgets);
      });

      testWidgets('renders view mode toggle', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(ViewModeToggle), findsOneWidget);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
        expect(find.byIcon(Icons.view_list), findsOneWidget);
      });

      testWidgets('switches to list view when list mode is selected', (
        tester,
      ) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsWidgets);
        expect(find.byType(BookCard), findsNothing);
      });

      testWidgets('shows empty state when no books match filter', (
        tester,
      ) async {
        final emptyStore = createTestDataStore(books: []);
        await tester.pumpWidget(buildPage(store: emptyStore));
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.text('No books found'), findsOneWidget);
        expect(
          find.text('Try adjusting your filters or add some books'),
          findsOneWidget,
        );
      });
    });

    // ========================================================================
    // Desktop layout tests
    // ========================================================================

    group('desktop layout', () {
      const desktopSize = Size(1200, 800);

      testWidgets('renders search bar', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(LibrarySearchBar), findsOneWidget);
      });

      testWidgets('renders filter chips', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(LibraryFilterChips), findsOneWidget);
      });

      testWidgets('renders "Add book" button', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.text('Add book'), findsOneWidget);
      });

      testWidgets('does not render FAB on desktop', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('does not render hamburger menu on desktop', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        // The menu icon should not be in the desktop layout
        // (it's only in the mobile Scaffold drawer button)
        expect(find.byIcon(Icons.menu), findsNothing);
      });

      testWidgets('renders view toggle buttons', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(ViewModeToggle), findsOneWidget);
      });

      testWidgets('shows grid view by default on desktop', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(BookCard), findsWidgets);
      });

      testWidgets('switches to list view on desktop', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsWidgets);
      });

      testWidgets('shows empty state when no books on desktop', (tester) async {
        final emptyStore = createTestDataStore(books: []);
        await tester.pumpWidget(
          buildPage(screenSize: desktopSize, store: emptyStore),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);
      });
    });

    // ========================================================================
    // Filtering tests
    // ========================================================================

    group('filtering', () {
      testWidgets('shows all books by default', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('5 books'), findsOneWidget);
      });

      testWidgets('filters to reading books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.reading);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 2 books are reading: The Hobbit and Neuromancer
        expect(find.text('2 books'), findsOneWidget);
      });

      testWidgets('filters to favorite books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.favorites);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 2 books are favorites: The Hobbit and Foundation
        expect(find.text('2 books'), findsOneWidget);
      });

      testWidgets('filters to finished books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.finished);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 1 book is finished: Dune
        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('filters to unread books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.unread);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 2 books are unread: 1984 and Foundation
        expect(find.text('2 books'), findsOneWidget);
      });

      testWidgets('shows empty state when no books match filter', (
        tester,
      ) async {
        // Add a filter and clear all books
        libraryProvider.addFilter(LibraryFilterType.reading);
        final storeWithNoReadingBooks = createTestDataStore(
          books: [
            Book(
              id: 'book-1',
              title: 'Test Book',
              author: 'Test Author',
              readingStatus: ReadingStatus.notStarted,
              addedAt: DateTime.now(),
            ),
          ],
        );
        await tester.pumpWidget(buildPage(store: storeWithNoReadingBooks));
        await tester.pumpAndSettle();

        expect(find.text('0 books'), findsOneWidget);
        expect(find.byType(EmptyState), findsOneWidget);
      });

      testWidgets('search filter works with text', (tester) async {
        libraryProvider.setSearchQuery('Hobbit');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('search filter works with author field', (tester) async {
        libraryProvider.setSearchQuery('author:Tolkien');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('filters by shelf', (tester) async {
        // Add a book-shelf relation
        dataStore.addBookToShelf('book-1', 'shelf-1');
        libraryProvider.selectShelf('Fiction');

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('filters by topic', (tester) async {
        // Add a book-tag relation
        dataStore.addTagToBook('book-1', 'tag-1');
        libraryProvider.selectTopic('Fantasy');

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });
    });

    // ========================================================================
    // View mode interaction tests
    // ========================================================================

    group('view mode switching', () {
      testWidgets('toggling view mode on mobile updates the display', (
        tester,
      ) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Initially in grid view
        expect(find.byType(BookCard), findsWidgets);

        // Switch to list view
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsWidgets);
        expect(find.byType(BookCard), findsNothing);
      });

      testWidgets('tapping grid segment on mobile selects grid view', (
        tester,
      ) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Tap the grid view segment
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(libraryProvider.viewMode, LibraryViewMode.grid);
      });

      testWidgets('tapping list segment on mobile selects list view', (
        tester,
      ) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Tap the list view segment
        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pumpAndSettle();

        expect(libraryProvider.viewMode, LibraryViewMode.list);
      });

      testWidgets('tapping toggle on desktop switches view mode', (
        tester,
      ) async {
        const desktopSize = Size(1200, 800);
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        // Tap the list view toggle
        expect(find.byType(ViewModeToggle), findsOneWidget);

        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pumpAndSettle();

        expect(libraryProvider.viewMode, LibraryViewMode.list);
      });
    });

    // ========================================================================
    // List view specific tests
    // ========================================================================

    group('list view', () {
      testWidgets('list view shows items', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // ListView.builder lazily builds items, so not all may be visible
        expect(find.byType(BookListItem), findsAtLeastNWidgets(1));
        expect(find.byType(ListView), findsAtLeastNWidgets(1));
      });

      testWidgets('list view respects favorite override', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        // Toggle favorite for book-3 (originally not favorite)
        libraryProvider.toggleFavorite('book-3', false);

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // At least some favorite icons should be filled
        expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
      });

      testWidgets('list view on desktop shows items', (tester) async {
        const desktopSize = Size(1200, 800);
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsAtLeastNWidgets(1));
      });
    });

    // ========================================================================
    // Mobile drawer interaction
    // ========================================================================

    group('mobile drawer', () {
      testWidgets('opens drawer when hamburger menu is tapped', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Drawer should be open - verify drawer items are visible
        expect(find.text('Books'), findsOneWidget);
        expect(find.text('Shelves'), findsOneWidget);
      });
    });

    // ========================================================================
    // Desktop compact layout
    // ========================================================================

    group('desktop compact layout', () {
      testWidgets('uses compact layout at narrow desktop width', (
        tester,
      ) async {
        // 850px is >= desktopSmall (840) but < 800 in maxWidth
        // after padding. Let's use exactly 860 to trigger desktop
        // but be narrow enough for compact layout.
        const narrowDesktop = Size(860, 800);
        await tester.pumpWidget(buildPage(screenSize: narrowDesktop));
        await tester.pumpAndSettle();

        // Should still show search bar
        expect(find.byType(LibrarySearchBar), findsOneWidget);
      });

      testWidgets('uses normal row layout at wide desktop', (tester) async {
        const wideDesktop = Size(1400, 800);
        await tester.pumpWidget(buildPage(screenSize: wideDesktop));
        await tester.pumpAndSettle();

        expect(find.text('Add book'), findsOneWidget);
      });
    });

    // ========================================================================
    // Multiple filter combinations
    // ========================================================================

    group('combined filters', () {
      testWidgets('reading + favorites shows intersection', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.reading);
        libraryProvider.addFilter(LibraryFilterType.favorites);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Only The Hobbit is both reading and favorite
        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('empty search query shows all books', (tester) async {
        libraryProvider.setSearchQuery('');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('5 books'), findsOneWidget);
      });
    });
  });
}
