import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';
import 'package:papyrus/widgets/filter/filter_bottom_sheet.dart';
import 'package:papyrus/widgets/filter/filter_dialog.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/quick_filter_chips.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';
import 'package:papyrus/widgets/shelves/shelf_card.dart';
import 'package:provider/provider.dart';

/// Page for viewing books and child shelves within a specific shelf.
class ShelfContentsPage extends StatefulWidget {
  final String? shelfId;

  const ShelfContentsPage({super.key, required this.shelfId});

  @override
  State<ShelfContentsPage> createState() => _ShelfContentsPageState();
}

class _ShelfContentsPageState extends State<ShelfContentsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ShelvesProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ShelvesProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataStore = context.read<DataStore>();
    _provider.attach(dataStore);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = context.watch<DataStore>();
    final shelf = dataStore.getShelf(widget.shelfId ?? '');

    if (shelf == null) {
      return _buildNotFound(context);
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ShelvesProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (isDesktop) {
            return _buildDesktopLayout(context, shelf, provider);
          }
          return _buildMobileLayout(context, shelf, provider);
        },
      ),
    );
  }

  // ============================================================================
  // NOT FOUND STATE
  // ============================================================================

  Widget _buildNotFound(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isDesktop ? Spacing.lg : Spacing.md),
              child: Row(children: [_buildDesktopBackButton(context)]),
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.shelves,
                title: 'Shelf not found',
                subtitle: 'This shelf may have been deleted',
                action: FilledButton.icon(
                  onPressed: () => context.go('/library/shelves'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to shelves'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    Shelf shelf,
    ShelvesProvider provider,
  ) {
    final libraryProvider = context.watch<LibraryProvider>();
    final childShelves = provider.getChildShelves(shelf.id);
    final books = provider.getFilteredBooksForShelf(
      shelf.id,
      isFavorite: (bookId) {
        final book = context.read<DataStore>().getBook(bookId);
        return libraryProvider.isBookFavorite(
          bookId,
          book?.isFavorite ?? false,
        );
      },
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shelfColor = shelf.color ?? colorScheme.primary;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/shelves'),
      body: SafeArea(
        child: Column(
          children: [
            // Row 1: Back icon + Search + Sort
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.md,
                left: Spacing.md,
                right: Spacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/library/shelves'),
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(child: _buildSearchBar(provider, isDesktop: false)),
                  const SizedBox(width: Spacing.sm),
                  _buildSortButton(provider),
                ],
              ),
            ),
            // Filter chips
            _buildFilterChips(provider),
            // Row 2: Shelf info + View toggle
            Padding(
              padding: const EdgeInsets.only(
                left: Spacing.md,
                right: Spacing.md,
                bottom: Spacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          shelf.displayIcon,
                          size: IconSizes.small,
                          color: shelfColor,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Flexible(
                          child: Text(
                            shelf.name,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          '\u00b7 ${books.length} ${books.length == 1 ? 'book' : 'books'}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  _buildViewToggle(provider),
                ],
              ),
            ),
            // Content grid/list
            Expanded(
              child: _buildContent(
                context,
                childShelves,
                books,
                provider,
                libraryProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    Shelf shelf,
    ShelvesProvider provider,
  ) {
    final libraryProvider = context.watch<LibraryProvider>();
    final childShelves = provider.getChildShelves(shelf.id);
    final books = provider.getFilteredBooksForShelf(
      shelf.id,
      isFavorite: (bookId) {
        final book = context.read<DataStore>().getBook(bookId);
        return libraryProvider.isBookFavorite(
          bookId,
          book?.isFavorite ?? false,
        );
      },
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: Spacing.lg,
              left: Spacing.lg,
              right: Spacing.lg,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useCompactLayout = constraints.maxWidth < 800;

                if (useCompactLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _buildDesktopBackButton(context),
                          const Spacer(),
                          _buildViewToggle(provider),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSearchBar(provider, isDesktop: true),
                          ),
                          const SizedBox(width: Spacing.sm),
                          _buildSortButton(provider),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    _buildDesktopBackButton(context),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: _buildSearchBar(provider, isDesktop: true)),
                    const SizedBox(width: Spacing.md),
                    _buildSortButton(provider),
                    const SizedBox(width: Spacing.md),
                    _buildViewToggle(provider),
                  ],
                );
              },
            ),
          ),
          // Filter chips
          _buildFilterChips(provider),
          // Content grid/list
          Expanded(
            child: _buildContent(
              context,
              childShelves,
              books,
              provider,
              libraryProvider,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER CONTROLS
  // ============================================================================

  Widget _buildDesktopBackButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: () => context.go('/library/shelves'),
      style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
      icon: const Icon(Icons.arrow_back, size: 20),
      label: Text('Shelves', style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildSearchBar(ShelvesProvider provider, {required bool isDesktop}) {
    final activeFilterCount = _countActiveAdvancedFilters(provider);

    return LibrarySearchBar(
      onQueryChanged: provider.setBookSearchQuery,
      initialQuery: provider.bookSearchQuery,
      activeFilterCount: activeFilterCount,
      onFilterTap: () => isDesktop
          ? _showFilterDialog(context, provider)
          : _showFilterBottomSheet(context, provider),
    );
  }

  Widget _buildSortButton(ShelvesProvider provider) {
    return PopupMenuButton<BookSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort books',
      onSelected: (option) => provider.setBookSortOption(option),
      itemBuilder: (context) => [
        _buildSortMenuItem(BookSortOption.title, 'Title', provider),
        _buildSortMenuItem(BookSortOption.author, 'Author', provider),
        _buildSortMenuItem(BookSortOption.progress, 'Progress', provider),
        _buildSortMenuItem(BookSortOption.dateAdded, 'Date added', provider),
      ],
    );
  }

  PopupMenuItem<BookSortOption> _buildSortMenuItem(
    BookSortOption option,
    String label,
    ShelvesProvider provider,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == provider.bookSortOption
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ShelvesProvider provider) {
    return ViewModeToggle(
      isGridView: provider.isGridView,
      onChanged: (isGrid) => provider.setViewMode(
        isGrid ? ShelvesViewMode.grid : ShelvesViewMode.list,
      ),
    );
  }

  // ============================================================================
  // FILTER CHIPS
  // ============================================================================

  static const _quickFilters = [
    (type: BookFilterType.all, label: 'All', icon: Icons.apps),
    (type: BookFilterType.reading, label: 'Reading', icon: Icons.auto_stories),
    (type: BookFilterType.favorites, label: 'Favorites', icon: Icons.favorite),
    (
      type: BookFilterType.finished,
      label: 'Finished',
      icon: Icons.check_circle,
    ),
    (type: BookFilterType.unread, label: 'Unread', icon: Icons.book),
  ];

  Widget _buildFilterChips(ShelvesProvider provider) {
    return QuickFilterChips(
      filters: _quickFilters
          .map(
            (f) => QuickFilterChipData(
              label: f.label,
              icon: f.icon,
              isSelected: provider.isBookFilterActive(f.type),
            ),
          )
          .toList(),
      onFilterTapped: (index) =>
          provider.toggleBookFilter(_quickFilters[index].type),
    );
  }

  // ============================================================================
  // ADVANCED FILTERS
  // ============================================================================

  int _countActiveAdvancedFilters(ShelvesProvider provider) {
    if (provider.bookSearchQuery.isEmpty ||
        !provider.bookSearchQuery.contains(':')) {
      return 0;
    }
    final query = SearchQueryParser.parse(provider.bookSearchQuery);
    return query.filters.where((f) => f.field.name != 'any').length;
  }

  Future<void> _showFilterBottomSheet(
    BuildContext context,
    ShelvesProvider provider,
  ) async {
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
        provider.bookSearchQuery,
        filterReading: provider.isBookFilterActive(BookFilterType.reading),
        filterFavorites: provider.isBookFilterActive(BookFilterType.favorites),
        filterFinished: provider.isBookFilterActive(BookFilterType.finished),
        filterUnread: provider.isBookFilterActive(BookFilterType.unread),
      ),
    );

    if (result != null) {
      _applyShelfFilterResult(result, provider);
    }
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    ShelvesProvider provider,
  ) async {
    final dataStore = context.read<DataStore>();
    final filterOptions = FilterOptions.fromBooks(
      dataStore.books,
      shelfNames: dataStore.shelves.map((s) => s.name).toList(),
      topicNames: dataStore.tags.map((t) => t.name).toList(),
    );

    final result = await FilterDialog.show(
      context,
      filterOptions: filterOptions,
      initialFilters: AppliedFilters.fromQueryString(
        provider.bookSearchQuery,
        filterReading: provider.isBookFilterActive(BookFilterType.reading),
        filterFavorites: provider.isBookFilterActive(BookFilterType.favorites),
        filterFinished: provider.isBookFilterActive(BookFilterType.finished),
        filterUnread: provider.isBookFilterActive(BookFilterType.unread),
      ),
    );

    if (result != null) {
      _applyShelfFilterResult(result, provider);
    }
  }

  void _applyShelfFilterResult(
    AppliedFilters result,
    ShelvesProvider provider,
  ) {
    // Apply quick filters
    if (result.filterReading) {
      provider.addBookFilter(BookFilterType.reading);
    } else {
      provider.removeBookFilter(BookFilterType.reading);
    }
    if (result.filterFavorites) {
      provider.addBookFilter(BookFilterType.favorites);
    } else {
      provider.removeBookFilter(BookFilterType.favorites);
    }
    if (result.filterFinished) {
      provider.addBookFilter(BookFilterType.finished);
    } else {
      provider.removeBookFilter(BookFilterType.finished);
    }
    if (result.filterUnread) {
      provider.addBookFilter(BookFilterType.unread);
    } else {
      provider.removeBookFilter(BookFilterType.unread);
    }

    // Set or clear search query from advanced filters
    final queryString = result.toQueryString();
    if (queryString.isNotEmpty) {
      provider.setBookSearchQuery(queryString);
    } else {
      provider.clearBookSearch();
    }
  }

  // ============================================================================
  // CONTENT (MIXED GRID / LIST)
  // ============================================================================

  Widget _buildContent(
    BuildContext context,
    List<Shelf> childShelves,
    List<Book> books,
    ShelvesProvider provider,
    LibraryProvider libraryProvider,
  ) {
    final totalItems = childShelves.length + books.length;

    if (totalItems == 0) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No books in this shelf',
        subtitle: 'Add books from your library to organize them here',
      );
    }

    if (provider.isListView) {
      return _buildListContent(
        context,
        childShelves,
        books,
        provider,
        libraryProvider,
      );
    }

    return _buildGridContent(
      context,
      childShelves,
      books,
      provider,
      libraryProvider,
    );
  }

  Widget _buildGridContent(
    BuildContext context,
    List<Shelf> childShelves,
    List<Book> books,
    ShelvesProvider provider,
    LibraryProvider libraryProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalItems = childShelves.length + books.length;

    int crossAxisCount;
    double spacing;
    double childAspectRatio;

    if (screenWidth >= Breakpoints.desktopLarge) {
      crossAxisCount = 6;
      spacing = Spacing.md;
      childAspectRatio = 0.55;
    } else if (screenWidth >= Breakpoints.desktopSmall) {
      crossAxisCount = 5;
      spacing = Spacing.md;
      childAspectRatio = 0.55;
    } else if (screenWidth >= Breakpoints.tablet) {
      crossAxisCount = 4;
      spacing = Spacing.sm + 4;
      childAspectRatio = 0.55;
    } else {
      crossAxisCount = 2;
      spacing = Spacing.sm;
      childAspectRatio = 0.58;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        bottom: Spacing.md,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < childShelves.length) {
          final shelf = childShelves[index];
          return ShelfCard(
            shelf: shelf,
            onTap: () => context.go('/library/shelves/${shelf.id}'),
          );
        }

        final book = books[index - childShelves.length];
        final isFavorite = libraryProvider.isBookFavorite(
          book.id,
          book.isFavorite,
        );
        return BookCard(
          book: book,
          isFavorite: isFavorite,
          onToggleFavorite: (current) =>
              libraryProvider.toggleFavorite(book.id, current),
          onTap: () => context.go('/library/details/${book.id}'),
        );
      },
    );
  }

  Widget _buildListContent(
    BuildContext context,
    List<Shelf> childShelves,
    List<Book> books,
    ShelvesProvider provider,
    LibraryProvider libraryProvider,
  ) {
    final totalItems = childShelves.length + books.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < childShelves.length) {
          final shelf = childShelves[index];
          return ShelfCard(
            shelf: shelf,
            isListItem: true,
            onTap: () => context.go('/library/shelves/${shelf.id}'),
          );
        }

        final book = books[index - childShelves.length];
        final isFavorite = libraryProvider.isBookFavorite(
          book.id,
          book.isFavorite,
        );
        return BookListItem(
          book: book,
          isFavorite: isFavorite,
          onTap: () => context.go('/library/details/${book.id}'),
        );
      },
    );
  }
}
