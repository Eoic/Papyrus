import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/bulk_book_actions.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/library/selection_header.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Center(
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
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, Shelf shelf, ShelvesProvider provider) {
    final libraryProvider = context.watch<LibraryProvider>();
    final childShelves = provider.getChildShelves(shelf.id);
    final books = provider.getFilteredBooksForShelf(
      shelf.id,
      isFavorite: (bookId) {
        final book = context.read<DataStore>().getBook(bookId);
        return libraryProvider.isBookFavorite(bookId, book?.isFavorite ?? false);
      },
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shelfColor = shelf.color ?? colorScheme.primary;
    final isSelectionMode = libraryProvider.isSelectionMode;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/shelves'),
      body: SafeArea(
        child: Column(
          children: [
            // Row 1: Selection header or Back + Search + Sort
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md, left: Spacing.md, right: Spacing.md),
              child: isSelectionMode
                  ? SelectionHeader(
                      selectedCount: libraryProvider.selectedCount,
                      totalCount: books.length,
                      onClose: libraryProvider.exitSelectionMode,
                      onSelectAll: () => libraryProvider.selectAll(books.map((b) => b.id).toList()),
                      onDeselectAll: libraryProvider.deselectAll,
                    )
                  : Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/library/shelves')),
                        const SizedBox(width: Spacing.xs),
                        Expanded(child: _buildSearchBar(provider)),
                        const SizedBox(width: Spacing.sm),
                        _buildSortButton(provider),
                      ],
                    ),
            ),
            // Filter chips
            // _buildFilterChips(provider),
            // Row 2: Shelf info + View toggle (hidden during selection)
            if (!isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.md, right: Spacing.md, bottom: Spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(shelf.displayIcon, size: IconSizes.small, color: shelfColor),
                          const SizedBox(width: Spacing.xs),
                          Flexible(
                            child: Text(
                              shelf.name,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            '\u00b7 ${books.length} ${books.length == 1 ? 'book' : 'books'}',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
            Expanded(child: _buildContent(context, childShelves, books, provider, libraryProvider)),
          ],
        ),
      ),
      bottomNavigationBar: isSelectionMode ? buildMobileBottomActionBar(context, libraryProvider) : null,
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context, Shelf shelf, ShelvesProvider provider) {
    final libraryProvider = context.watch<LibraryProvider>();
    final childShelves = provider.getChildShelves(shelf.id);
    final books = provider.getFilteredBooksForShelf(
      shelf.id,
      isFavorite: (bookId) {
        final book = context.read<DataStore>().getBook(bookId);
        return libraryProvider.isBookFavorite(bookId, book?.isFavorite ?? false);
      },
    );

    final isSelectionMode = libraryProvider.isSelectionMode;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (libraryProvider.isSelectionMode) {
            libraryProvider.exitSelectionMode();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(top: Spacing.lg, left: Spacing.lg, right: Spacing.lg),
                child: isSelectionMode
                    ? SelectionHeader(
                        selectedCount: libraryProvider.selectedCount,
                        totalCount: books.length,
                        onClose: libraryProvider.exitSelectionMode,
                        onSelectAll: () => libraryProvider.selectAll(books.map((b) => b.id).toList()),
                        onDeselectAll: libraryProvider.deselectAll,
                        actions: buildBulkActionBar(context, libraryProvider),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final useCompactLayout = constraints.maxWidth < 800;

                          if (useCompactLayout) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildSearchBar(provider)),
                                    const SizedBox(width: Spacing.sm),
                                    _buildSortButton(provider),
                                  ],
                                ),
                                const SizedBox(height: Spacing.md),
                                Row(children: [const Spacer(), _buildViewToggle(provider)]),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: _buildSearchBar(provider)),
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
              // _buildFilterChips(provider, horizontalPadding: Spacing.lg),
              // Content grid/list
              Expanded(child: _buildContent(context, childShelves, books, provider, libraryProvider)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER CONTROLS
  // ============================================================================

  Widget _buildSearchBar(ShelvesProvider provider) {
    return LibrarySearchBar(onQueryChanged: provider.setBookSearchQuery, initialQuery: provider.bookSearchQuery);
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

  PopupMenuItem<BookSortOption> _buildSortMenuItem(BookSortOption option, String label, ShelvesProvider provider) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == provider.bookSortOption ? Theme.of(context).colorScheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ShelvesProvider provider) {
    return ViewModeToggle(
      isGridView: provider.isGridView,
      onChanged: (isGrid) => provider.setViewMode(isGrid ? ShelvesViewMode.grid : ShelvesViewMode.list),
    );
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
      return _buildListContent(context, childShelves, books, provider, libraryProvider);
    }

    return _buildGridContent(context, childShelves, books, provider, libraryProvider);
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
      padding: const EdgeInsets.only(left: Spacing.md, right: Spacing.md, bottom: Spacing.md),
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
          return ShelfCard(shelf: shelf, onTap: () => context.go('/library/shelves/${shelf.id}'));
        }

        final book = books[index - childShelves.length];
        final isFavorite = libraryProvider.isBookFavorite(book.id, book.isFavorite);
        final isSelectionMode = libraryProvider.isSelectionMode;
        return BookCard(
          book: book,
          isFavorite: isFavorite,
          isSelectionMode: isSelectionMode,
          isSelected: libraryProvider.isBookSelected(book.id),
          onSelectToggle: () => libraryProvider.toggleBookSelection(book.id),
          onEnterSelectionMode: () => libraryProvider.enterSelectionMode(book.id),
          onToggleFavorite: (current) => libraryProvider.toggleFavorite(book.id, current),
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
          return ShelfCard(shelf: shelf, isListItem: true, onTap: () => context.go('/library/shelves/${shelf.id}'));
        }

        final book = books[index - childShelves.length];
        final isFavorite = libraryProvider.isBookFavorite(book.id, book.isFavorite);
        return BookListItem(
          book: book,
          isFavorite: isFavorite,
          isSelectionMode: libraryProvider.isSelectionMode,
          isSelected: libraryProvider.isBookSelected(book.id),
          onSelectToggle: () => libraryProvider.toggleBookSelection(book.id),
          onTap: () => context.go('/library/details/${book.id}'),
        );
      },
    );
  }
}
