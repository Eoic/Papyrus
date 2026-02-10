import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/active_filter.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';
import 'package:papyrus/widgets/filter/filter_bottom_sheet.dart';
import 'package:papyrus/widgets/filter/filter_dialog.dart';
import 'package:papyrus/widgets/library/book_grid.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/add_book/add_book_choice_sheet.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';
import 'package:provider/provider.dart';

/// Main library page with responsive layouts for all platforms.
/// - Mobile: AppBar with search, filter chips, 2-column grid, FAB
/// - Desktop: Header row, filter chips, 5-column grid or list view
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final dataStore = context.watch<DataStore>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    // Get filtered books from DataStore (single source of truth)
    final books = _getFilteredBooks(libraryProvider, dataStore);

    if (isDesktop) {
      return _buildDesktopLayout(context, books, libraryProvider);
    }

    return _buildMobileLayout(context, books, libraryProvider);
  }

  List<Book> _getFilteredBooks(LibraryProvider provider, DataStore dataStore) {
    var books = dataStore.books;

    // Apply search filter using query parser
    if (provider.searchQuery.isNotEmpty) {
      final searchQuery = SearchQueryParser.parse(provider.searchQuery);
      if (searchQuery.isNotEmpty) {
        books = books
            .where((book) => searchQuery.matches(book, dataStore: dataStore))
            .toList();
      }
    }

    // Apply category filters (quick filters from chips)
    if (!provider.isFilterActive(LibraryFilterType.all)) {
      if (provider.isFilterActive(LibraryFilterType.favorites)) {
        books = books
            .where((book) => provider.isBookFavorite(book.id, book.isFavorite))
            .toList();
      }
      if (provider.isFilterActive(LibraryFilterType.reading)) {
        books = books.where((book) => book.isReading).toList();
      }
      if (provider.isFilterActive(LibraryFilterType.finished)) {
        books = books.where((book) => book.isFinished).toList();
      }
      if (provider.isFilterActive(LibraryFilterType.unread)) {
        books = books
            .where((book) => book.readingStatus == ReadingStatus.notStarted)
            .toList();
      }
      if (provider.isFilterActive(LibraryFilterType.shelves) &&
          provider.selectedShelf != null) {
        books = books
            .where(
              (book) => dataStore
                  .getShelvesForBook(book.id)
                  .any((s) => s.name == provider.selectedShelf),
            )
            .toList();
      }
      if (provider.isFilterActive(LibraryFilterType.topics) &&
          provider.selectedTopic != null) {
        books = books
            .where(
              (book) => dataStore
                  .getTagsForBook(book.id)
                  .any((t) => t.name == provider.selectedTopic),
            )
            .toList();
      }
    }

    return provider.sortBooks(books);
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    List<Book> books,
    LibraryProvider libraryProvider,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar section with drawer button
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.md,
                left: Spacing.md,
                right: Spacing.md,
              ),
              child: Row(
                children: [
                  // Drawer hamburger button
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Library sections',
                  ),
                  const SizedBox(width: Spacing.xs),
                  // Search bar
                  Expanded(child: _buildSearchBar(libraryProvider)),
                  const SizedBox(width: Spacing.sm),
                  _buildSortButton(libraryProvider),
                ],
              ),
            ),

            // Quick filter chips
            const LibraryFilterChips(),

            // View toggle row
            Padding(
              padding: const EdgeInsets.only(
                left: Spacing.md,
                right: Spacing.md,
                bottom: Spacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _buildViewToggle(libraryProvider),
                ],
              ),
            ),

            // Book grid or list
            Expanded(
              child: books.isEmpty
                  ? _buildEmptyState()
                  : libraryProvider.isListView
                  ? _buildBookList(context, books)
                  : BookGrid(
                      books: books,
                      onBookTap: (book) =>
                          _navigateToBookDetails(context, book),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddBookChoiceSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build list of active filters for display.
  /// Uses a Set to prevent duplicate filters.
  /// Quick filters (Reading, Favorites, Finished) are excluded because they
  /// are already shown as highlighted buttons in the QuickFilterChips bar.
  List<ActiveFilter> _buildActiveFilters(LibraryProvider provider) {
    final filters = <ActiveFilter>{};

    if (provider.selectedShelf != null) {
      filters.add(
        ActiveFilter(
          type: ActiveFilterType.query,
          label: 'shelf',
          value: provider.selectedShelf!,
          queryString: 'shelf:"${provider.selectedShelf}"',
        ),
      );
    }
    if (provider.selectedTopic != null) {
      filters.add(
        ActiveFilter(
          type: ActiveFilterType.query,
          label: 'topic',
          value: provider.selectedTopic!,
          queryString: 'topic:"${provider.selectedTopic}"',
        ),
      );
    }

    // Parse search query into individual filters
    // Skip shelf/topic if already added from provider to avoid duplicates
    if (provider.searchQuery.isNotEmpty && provider.searchQuery.contains(':')) {
      final query = SearchQueryParser.parse(provider.searchQuery);
      for (final filter in query.filters) {
        if (filter.field.name != 'any') {
          // Skip if this field is already represented by provider selection
          if (filter.field.name == 'shelf' && provider.selectedShelf != null) {
            continue;
          }
          if (filter.field.name == 'topic' && provider.selectedTopic != null) {
            continue;
          }
          filters.add(
            ActiveFilter(
              type: ActiveFilterType.query,
              label: filter.field.name,
              value: filter.value,
              queryString: '${filter.field.name}:${filter.value}',
            ),
          );
        }
      }
    }

    return filters.toList();
  }

  /// Show the filter bottom sheet.
  Future<void> _showFilterBottomSheet(BuildContext context) async {
    final libraryProvider = context.read<LibraryProvider>();
    final dataStore = context.read<DataStore>();
    final filterOptions = FilterOptions.fromBooks(
      dataStore.books,
      shelfNames: dataStore.shelves.map((s) => s.name).toList(),
      topicNames: dataStore.tags.map((t) => t.name).toList(),
    );

    final result = await FilterBottomSheet.show(
      context,
      filterOptions: filterOptions,
      initialFilters: AppliedFilters.fromQueryString(
        libraryProvider.searchQuery,
        filterReading: libraryProvider.isFilterActive(
          LibraryFilterType.reading,
        ),
        filterFavorites: libraryProvider.isFilterActive(
          LibraryFilterType.favorites,
        ),
        filterFinished: libraryProvider.isFilterActive(
          LibraryFilterType.finished,
        ),
        filterUnread: libraryProvider.isFilterActive(LibraryFilterType.unread),
        shelf: libraryProvider.selectedShelf,
        topic: libraryProvider.selectedTopic,
      ),
    );

    if (result != null) {
      _applyFilterResult(result);
    }
  }

  /// Show the filter dialog (desktop).
  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await FilterDialog.show(context);
    if (result != null) {
      _applyFilterResult(result);
    }
  }

  /// Apply the filter result from either the bottom sheet or dialog.
  void _applyFilterResult(AppliedFilters result) {
    final libraryProvider = context.read<LibraryProvider>();

    // Apply quick filters
    if (result.filterReading) {
      libraryProvider.addFilter(LibraryFilterType.reading);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.reading);
    }
    if (result.filterFavorites) {
      libraryProvider.addFilter(LibraryFilterType.favorites);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.favorites);
    }
    if (result.filterFinished) {
      libraryProvider.addFilter(LibraryFilterType.finished);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.finished);
    }
    if (result.filterUnread) {
      libraryProvider.addFilter(LibraryFilterType.unread);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.unread);
    }

    // Apply shelf/topic
    libraryProvider.selectShelf(result.shelf);
    libraryProvider.selectTopic(result.topic);

    // Set or clear search query from advanced filters
    final queryString = result.toQueryString();
    if (queryString.isNotEmpty) {
      libraryProvider.setSearchQuery(queryString);
    } else {
      libraryProvider.clearSearch();
    }
  }

  Widget _buildSearchBar(LibraryProvider libraryProvider) {
    final activeFilters = _buildActiveFilters(libraryProvider);
    final isDesktop =
        MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

    return LibrarySearchBar(
      initialQuery: libraryProvider.searchQuery,
      activeFilterCount: activeFilters.length,
      onQueryChanged: (query) {
        if (query.isEmpty) {
          libraryProvider.clearSearch();
        } else {
          libraryProvider.setSearchQuery(query);
        }
      },
      onFilterTap: () => isDesktop
          ? _showFilterDialog(context)
          : _showFilterBottomSheet(context),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildViewToggle(LibraryProvider libraryProvider) {
    return ViewModeToggle(
      isGridView: libraryProvider.isGridView,
      onChanged: (isGrid) => libraryProvider.setViewMode(
        isGrid ? LibraryViewMode.grid : LibraryViewMode.list,
      ),
    );
  }

  Widget _buildAddBookButton(double height) {
    return FilledButton.icon(
      onPressed: () => AddBookChoiceSheet.show(context),
      icon: const Icon(Icons.add),
      label: const Text('Add book'),
      style: FilledButton.styleFrom(minimumSize: Size(0, height)),
    );
  }

  Widget _buildSortButton(LibraryProvider provider) {
    return PopupMenuButton<LibrarySortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort books',
      onSelected: provider.setSortOption,
      itemBuilder: (context) => [
        _buildSortMenuItem(
          LibrarySortOption.dateAddedNewest,
          'Date added (newest)',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          LibrarySortOption.dateAddedOldest,
          'Date added (oldest)',
          provider.sortOption,
        ),
        const PopupMenuDivider(),
        _buildSortMenuItem(
          LibrarySortOption.titleAZ,
          'Title (A\u2013Z)',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          LibrarySortOption.titleZA,
          'Title (Z\u2013A)',
          provider.sortOption,
        ),
        const PopupMenuDivider(),
        _buildSortMenuItem(
          LibrarySortOption.authorAZ,
          'Author (A\u2013Z)',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          LibrarySortOption.authorZA,
          'Author (Z\u2013A)',
          provider.sortOption,
        ),
        const PopupMenuDivider(),
        _buildSortMenuItem(
          LibrarySortOption.lastRead,
          'Last read',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          LibrarySortOption.rating,
          'Rating',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          LibrarySortOption.progress,
          'Progress',
          provider.sortOption,
        ),
      ],
    );
  }

  PopupMenuItem<LibrarySortOption> _buildSortMenuItem(
    LibrarySortOption option,
    String label,
    LibrarySortOption current,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == current
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<Book> books,
    LibraryProvider libraryProvider,
  ) {
    const double controlHeight = 40.0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.only(
              top: Spacing.lg,
              left: Spacing.lg,
              right: Spacing.lg,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate if we need compact layout
                // Title (~100) + search (350) + toggle (96) + button (140) + spacing/padding (~80) ≈ 766
                // Add buffer for safety
                final useCompactLayout = constraints.maxWidth < 800;

                if (useCompactLayout) {
                  // Stack layout for narrow screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // First row: title and buttons
                      Row(
                        children: [
                          Text(
                            'Library',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          _buildViewToggle(libraryProvider),
                          const SizedBox(width: Spacing.sm),
                          _buildAddBookButton(controlHeight),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      // Second row: search bar full width
                      Row(
                        children: [
                          Expanded(child: _buildSearchBar(libraryProvider)),
                          const SizedBox(width: Spacing.sm),
                          _buildSortButton(libraryProvider),
                        ],
                      ),
                    ],
                  );
                }

                // Normal row layout for wider screens
                return Row(
                  children: [
                    // Library title
                    Padding(
                      padding: const EdgeInsets.only(right: Spacing.lg),
                      child: Text(
                        'Library',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    // Search bar - fills available space
                    Expanded(child: _buildSearchBar(libraryProvider)),
                    const SizedBox(width: Spacing.md),
                    _buildSortButton(libraryProvider),
                    const SizedBox(width: Spacing.md),
                    _buildViewToggle(libraryProvider),
                    const SizedBox(width: Spacing.md),
                    _buildAddBookButton(controlHeight),
                  ],
                );
              },
            ),
          ),
          // Filter chips
          const LibraryFilterChips(),
          // Book grid or list
          Expanded(
            child: books.isEmpty
                ? _buildEmptyState()
                : libraryProvider.isListView
                ? _buildBookList(context, books)
                : BookGrid(
                    books: books,
                    onBookTap: (book) => _navigateToBookDetails(context, book),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(BuildContext context, List<Book> books) {
    final libraryProvider = context.read<LibraryProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isFavorite = libraryProvider.isBookFavorite(
          book.id,
          book.isFavorite,
        );
        return BookListItem(
          book: book,
          isFavorite: isFavorite,
          onTap: () => _navigateToBookDetails(context, book),
        );
      },
    );
  }

  void _navigateToBookDetails(BuildContext context, Book book) {
    context.go('/library/details/${book.id}');
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.library_books_outlined,
      title: 'No books found',
      subtitle: 'Try adjusting your filters or add some books',
    );
  }
}
