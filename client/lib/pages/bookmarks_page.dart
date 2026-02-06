import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/providers/bookmarks_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/bookmarks/bookmark_action_sheet.dart';
import 'package:papyrus/widgets/bookmarks/bookmark_list_item.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:provider/provider.dart';

/// Color name mapping for filter chip labels.
const _colorNames = {
  '#FF5722': 'Orange',
  '#F44336': 'Red',
  '#E91E63': 'Pink',
  '#9C27B0': 'Purple',
  '#2196F3': 'Blue',
  '#4CAF50': 'Green',
  '#FFC107': 'Amber',
};

/// Bookmarks page showing all bookmarks across all books.
///
/// Features search, color filtering, sorting, and grouping by book.
class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late BookmarksProvider _provider;
  final _searchController = TextEditingController();
  bool _showMobileSearch = false;
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _provider = BookmarksProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataStore = context.read<DataStore>();
    _provider.attach(dataStore);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<BookmarksProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (isDesktop) {
            return _buildDesktopLayout(context, provider);
          }
          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, BookmarksProvider provider) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/bookmarks'),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Library sections',
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Bookmarks',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showMobileSearch ? Icons.search_off : Icons.search,
                    ),
                    onPressed: () {
                      setState(() {
                        _showMobileSearch = !_showMobileSearch;
                        if (!_showMobileSearch) {
                          _searchController.clear();
                          provider.clearSearch();
                        }
                      });
                    },
                    tooltip: 'Search bookmarks',
                  ),
                  _buildSortButton(provider),
                ],
              ),
            ),

            // Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Row(
                children: [
                  Text(
                    '${provider.totalCount} ${provider.totalCount == 1 ? 'bookmark' : 'bookmarks'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar (toggled)
            if (_showMobileSearch) ...[
              const SizedBox(height: Spacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: _buildSearchField(provider),
              ),
            ],

            // Color filter chips
            if (provider.hasBookmarks) ...[
              const SizedBox(height: Spacing.sm),
              _buildColorFilterChips(provider),
            ],

            const SizedBox(height: Spacing.sm),

            // Content
            Expanded(child: _buildContent(context, provider)),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context, BookmarksProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Text('Bookmarks', style: textTheme.headlineMedium),
                const SizedBox(width: Spacing.lg),
                Text(
                  '${provider.totalCount} ${provider.totalCount == 1 ? 'bookmark' : 'bookmarks'}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 300, child: _buildSearchField(provider)),
                const SizedBox(width: Spacing.md),
                _buildSortButton(provider),
              ],
            ),
          ),

          // Color filter chips
          if (provider.hasBookmarks) _buildColorFilterChips(provider),

          // Content
          Expanded(child: _buildContent(context, provider)),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildSearchField(BookmarksProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search bookmarks...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
      ),
    );
  }

  Widget _buildSortButton(BookmarksProvider provider) {
    return PopupMenuButton<BookmarkSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort bookmarks',
      onSelected: provider.setSortOption,
      itemBuilder: (context) => [
        _buildSortMenuItem(
          BookmarkSortOption.dateNewest,
          'Newest first',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          BookmarkSortOption.dateOldest,
          'Oldest first',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          BookmarkSortOption.bookTitle,
          'By book title',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          BookmarkSortOption.position,
          'By position',
          provider.sortOption,
        ),
      ],
    );
  }

  PopupMenuItem<BookmarkSortOption> _buildSortMenuItem(
    BookmarkSortOption option,
    String label,
    BookmarkSortOption current,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (option == current)
            Icon(
              Icons.check,
              size: IconSizes.small,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildColorFilterChips(BookmarksProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        children: [
          // Clear chip (shown when filters are active)
          if (provider.activeColors.isNotEmpty) ...[
            ActionChip(
              label: const Text('Clear'),
              onPressed: provider.clearColorFilters,
              avatar: const Icon(Icons.clear, size: 16),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          // Color chips
          ...Bookmark.availableColors.map((hex) {
            final isSelected = provider.activeColors.contains(hex);
            final color = Color(
              int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
            );
            final name = _colorNames[hex] ?? 'Unknown';

            return Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: FilterChip(
                selected: isSelected,
                label: Text(name),
                avatar: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                onSelected: (_) => provider.toggleColorFilter(hex),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookmarksProvider provider) {
    if (!provider.hasBookmarks) {
      return const EmptyState(
        icon: Icons.bookmark_outline,
        title: 'No bookmarks yet',
        subtitle: 'Bookmarks you create while reading will appear here',
      );
    }

    if (!provider.hasResults) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No bookmarks found',
        subtitle: 'Try adjusting your search or filters',
        action: TextButton(
          onPressed: () {
            _searchController.clear();
            provider.clearAllFilters();
          },
          child: const Text('Clear filters'),
        ),
      );
    }

    return _buildBookmarkList(context, provider);
  }

  Widget _buildBookmarkList(BuildContext context, BookmarksProvider provider) {
    final groups = provider.bookmarksByBook;
    final items = <Widget>[];

    for (final entry in groups.entries) {
      final isCollapsed = _collapsedGroups.contains(entry.key);
      items.add(
        _buildBookGroupHeader(
          context,
          provider,
          entry.key,
          entry.value.length,
          isCollapsed,
        ),
      );
      if (!isCollapsed) {
        for (final bookmark in entry.value) {
          items.add(
            BookmarkListItem(
              bookmark: bookmark,
              bookTitle: provider.getBookTitle(bookmark.bookId),
              onTap: () => _navigateToBook(context, bookmark.bookId),
              onEditNote: () => _showEditNoteSheet(context, provider, bookmark),
              onChangeColor: () =>
                  _showColorPicker(context, provider, bookmark),
              onDelete: () =>
                  _confirmDeleteBookmark(context, provider, bookmark),
            ),
          );
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      children: items,
    );
  }

  Widget _buildBookGroupHeader(
    BuildContext context,
    BookmarksProvider provider,
    String bookId,
    int count,
    bool isCollapsed,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bookTitle = provider.getBookTitle(bookId);
    final coverUrl = provider.getBookCoverUrl(bookId);

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () {
          setState(() {
            if (_collapsedGroups.contains(bookId)) {
              _collapsedGroups.remove(bookId);
            } else {
              _collapsedGroups.add(bookId);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Row(
            children: [
              // Small book cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 32,
                  height: 48,
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.menu_book,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.menu_book,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count ${count == 1 ? 'bookmark' : 'bookmarks'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                color: colorScheme.onSurfaceVariant,
                size: IconSizes.action,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _navigateToBook(BuildContext context, String bookId) {
    context.goNamed('BOOK_DETAILS', pathParameters: {'bookId': bookId});
  }

  void _showEditNoteSheet(
    BuildContext context,
    BookmarksProvider provider,
    Bookmark bookmark,
  ) async {
    final note = await BookmarkNoteSheet.show(context, bookmark: bookmark);
    if (!mounted) return;

    if (note != null) {
      provider.updateBookmarkNote(bookmark.id, note.isEmpty ? null : note);
    }
  }

  void _showColorPicker(
    BuildContext context,
    BookmarksProvider provider,
    Bookmark bookmark,
  ) async {
    final colorHex = await BookmarkColorSheet.show(context, bookmark: bookmark);
    if (colorHex != null && mounted) {
      provider.updateBookmarkColor(bookmark.id, colorHex);
    }
  }

  void _confirmDeleteBookmark(
    BuildContext context,
    BookmarksProvider provider,
    Bookmark bookmark,
  ) async {
    final bookTitle = provider.getBookTitle(bookmark.bookId);
    final confirmed = await DeleteBookmarkDialog.show(
      context,
      bookmark: bookmark,
      bookTitle: bookTitle,
    );
    if (confirmed && mounted) {
      provider.deleteBookmark(bookmark.id);
    }
  }
}
