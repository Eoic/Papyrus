import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/active_filter.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';
import 'package:papyrus/widgets/filter/active_filter_bar.dart';
import 'package:papyrus/widgets/filter/filter_bottom_sheet.dart';
import 'package:papyrus/widgets/filter/quick_filter_chips.dart';
import 'package:papyrus/widgets/library/advanced_search_bar.dart';
import 'package:papyrus/widgets/library/book_grid.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/eink_tab_filter.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/search/mobile_search_bar.dart';
import 'package:provider/provider.dart';

/// Main library page with responsive layouts for all platforms.
/// - Mobile: AppBar with search, filter chips, 2-column grid, FAB
/// - Desktop: Header row, filter chips, 5-column grid or list view
/// - E-ink: Header, tab filter, single-column list
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();
    final libraryProvider = context.watch<LibraryProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    // Get filtered books
    final books = _getFilteredBooks(libraryProvider);

    if (displayMode.isEinkMode) {
      return _buildEinkLayout(context, books, libraryProvider);
    }

    if (isDesktop) {
      return _buildDesktopLayout(context, books, libraryProvider);
    }

    return _buildMobileLayout(context, books, libraryProvider);
  }

  List<BookData> _getFilteredBooks(LibraryProvider provider) {
    var books = BookData.sampleBooks;

    // Apply search filter using query parser
    if (provider.searchQuery.isNotEmpty) {
      final searchQuery = SearchQueryParser.parse(provider.searchQuery);
      if (searchQuery.isNotEmpty) {
        books = books.where((book) => searchQuery.matches(book)).toList();
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
      if (provider.isFilterActive(LibraryFilterType.shelves) &&
          provider.selectedShelf != null) {
        books = books
            .where((book) => book.shelves.contains(provider.selectedShelf))
            .toList();
      }
      if (provider.isFilterActive(LibraryFilterType.topics) &&
          provider.selectedTopic != null) {
        books = books
            .where((book) => book.topics.contains(provider.selectedTopic))
            .toList();
      }
    }

    return books;
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    List<BookData> books,
    LibraryProvider libraryProvider,
  ) {
    final activeFilters = _buildActiveFilters(libraryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar section
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: MobileSearchBar(
                initialQuery: libraryProvider.searchQuery,
                activeFilterCount: activeFilters.length,
                onQueryChanged: (query) {
                  libraryProvider.setSearchQuery(query);
                },
                onFilterTap: () => _showFilterBottomSheet(context),
              ),
            ),

            // Active filter bar (only visible when filters are active)
            if (activeFilters.isNotEmpty)
              ActiveFilterBar(
                filters: activeFilters,
                onFilterRemoved: (filter) =>
                    _removeFilter(libraryProvider, filter),
                onClearAll: () => libraryProvider.resetFilters(),
              ),

            // Quick filter chips
            QuickFilterChips(
              selectedFilters: libraryProvider.activeFilters,
              onFilterToggled: (filter) {
                if (filter == LibraryFilterType.all) {
                  libraryProvider.resetFilters();
                } else {
                  libraryProvider.toggleFilter(filter);
                }
              },
              onMoreFilters: () => _showFilterBottomSheet(context),
            ),

            // View toggle row
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  SegmentedButton<LibraryViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: LibraryViewMode.grid,
                        icon: Icon(Icons.grid_view, size: IconSizes.small),
                      ),
                      ButtonSegment(
                        value: LibraryViewMode.list,
                        icon: Icon(Icons.view_list, size: IconSizes.small),
                      ),
                    ],
                    selected: {libraryProvider.viewMode},
                    onSelectionChanged: (selection) {
                      libraryProvider.setViewMode(selection.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            // Book grid or list
            Expanded(
              child: books.isEmpty
                  ? _buildEmptyState(context)
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
        onPressed: () {
          // TODO: Add book action
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build list of active filters for display.
  /// Uses a Set to prevent duplicate filters.
  List<ActiveFilter> _buildActiveFilters(LibraryProvider provider) {
    final filters = <ActiveFilter>{};

    // Add quick filters
    if (provider.isFilterActive(LibraryFilterType.reading)) {
      filters.add(const ActiveFilter(
        type: ActiveFilterType.quick,
        label: 'Reading',
        value: 'reading',
      ));
    }
    if (provider.isFilterActive(LibraryFilterType.favorites)) {
      filters.add(const ActiveFilter(
        type: ActiveFilterType.quick,
        label: 'Favorites',
        value: 'favorites',
      ));
    }
    if (provider.isFilterActive(LibraryFilterType.finished)) {
      filters.add(const ActiveFilter(
        type: ActiveFilterType.quick,
        label: 'Finished',
        value: 'finished',
      ));
    }
    if (provider.selectedShelf != null) {
      filters.add(ActiveFilter(
        type: ActiveFilterType.query,
        label: 'shelf',
        value: provider.selectedShelf!,
        queryString: 'shelf:"${provider.selectedShelf}"',
      ));
    }
    if (provider.selectedTopic != null) {
      filters.add(ActiveFilter(
        type: ActiveFilterType.query,
        label: 'topic',
        value: provider.selectedTopic!,
        queryString: 'topic:"${provider.selectedTopic}"',
      ));
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
          filters.add(ActiveFilter(
            type: ActiveFilterType.query,
            label: filter.field.name,
            value: filter.value,
            queryString: '${filter.field.name}:${filter.value}',
          ));
        }
      }
    }

    return filters.toList();
  }

  /// Remove a filter from the provider.
  void _removeFilter(LibraryProvider provider, ActiveFilter filter) {
    if (filter.type == ActiveFilterType.quick) {
      switch (filter.value) {
        case 'reading':
          provider.removeFilter(LibraryFilterType.reading);
        case 'favorites':
          provider.removeFilter(LibraryFilterType.favorites);
        case 'finished':
          provider.removeFilter(LibraryFilterType.finished);
      }
    } else {
      // Remove from search query
      if (filter.queryString != null) {
        final currentQuery = provider.searchQuery;
        final newQuery = currentQuery
            .replaceAll(filter.queryString!, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        provider.setSearchQuery(newQuery);
      }
      // Clear shelf/topic selection
      if (filter.label == 'shelf') {
        provider.selectShelf(null);
      } else if (filter.label == 'topic') {
        provider.selectTopic(null);
      }
    }
  }

  /// Show the filter bottom sheet.
  Future<void> _showFilterBottomSheet(BuildContext context) async {
    final libraryProvider = context.read<LibraryProvider>();
    final filterOptions = FilterOptions.fromBooks(BookData.sampleBooks);

    final result = await FilterBottomSheet.show(
      context,
      filterOptions: filterOptions,
      initialFilters: AppliedFilters(
        filterReading: libraryProvider.isFilterActive(LibraryFilterType.reading),
        filterFavorites:
            libraryProvider.isFilterActive(LibraryFilterType.favorites),
        filterFinished:
            libraryProvider.isFilterActive(LibraryFilterType.finished),
        shelf: libraryProvider.selectedShelf,
        topic: libraryProvider.selectedTopic,
      ),
    );

    if (result != null) {
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
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildViewToggle(
    BuildContext context,
    LibraryProvider libraryProvider,
    double height,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ToggleButtons(
          isSelected: [
            libraryProvider.viewMode == LibraryViewMode.grid,
            libraryProvider.viewMode == LibraryViewMode.list,
          ],
          onPressed: (index) {
            libraryProvider.setViewMode(
              index == 0 ? LibraryViewMode.grid : LibraryViewMode.list,
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          renderBorder: false,
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: height,
          ),
          children: const [
            Icon(Icons.grid_view),
            Icon(Icons.view_list),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBookButton(double height) {
    return FilledButton.icon(
      onPressed: () {
        // TODO: Add book action
      },
      icon: const Icon(Icons.add),
      label: const Text('Add book'),
      style: FilledButton.styleFrom(
        minimumSize: Size(0, height),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<BookData> books,
    LibraryProvider libraryProvider,
  ) {
    const double controlHeight = 48.0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
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
                          _buildViewToggle(context, libraryProvider, controlHeight),
                          const SizedBox(width: Spacing.sm),
                          _buildAddBookButton(controlHeight),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      // Second row: search bar full width
                      AdvancedSearchBar(
                        height: controlHeight,
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
                    Expanded(
                      child: AdvancedSearchBar(
                        height: controlHeight,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    _buildViewToggle(context, libraryProvider, controlHeight),
                    const SizedBox(width: Spacing.md),
                    _buildAddBookButton(controlHeight),
                  ],
                );
              },
            ),
          ),
          // Filter chips
          const LibraryFilterChips(),
          const SizedBox(height: Spacing.sm),
          // Book grid or list
          Expanded(
            child: books.isEmpty
                ? _buildEmptyState(context)
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
    );
  }

  Widget _buildBookList(BuildContext context, List<BookData> books) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookListItem(
          book: book,
          onTap: () => _navigateToBookDetails(context, book),
        );
      },
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkLayout(
    BuildContext context,
    List<BookData> books,
    LibraryProvider libraryProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: ComponentSizes.einkHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline,
                  width: BorderWidths.einkDefault,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Library',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${books.length} books',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          // Tab filter
          const EinkTabFilter(),
          // Book list
          Expanded(
            child: books.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return BookListItem(
                        book: book,
                        onTap: () => _navigateToBookDetails(context, book),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No books found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Try adjusting your filters or add some books',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  void _navigateToBookDetails(BuildContext context, BookData book) {
    context.go('/library/details/${book.id}');
  }
}
