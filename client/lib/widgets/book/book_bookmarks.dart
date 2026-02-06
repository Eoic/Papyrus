import 'package:flutter/material.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/bookmarks/bookmark_list_item.dart';
import 'package:papyrus/widgets/input/search_field.dart';

/// Sort options for bookmarks within a single book.
enum _BookmarkSort { dateNewest, dateOldest, position }

/// Bookmarks tab content for the book details page.
///
/// Displays a searchable, sortable list of bookmarks associated with a book.
/// Supports desktop and mobile layouts with optimized interactions.
class BookBookmarks extends StatefulWidget {
  final List<Bookmark> bookmarks;
  final String bookTitle;
  final Function(Bookmark)? onEditNote;
  final Function(Bookmark)? onChangeColor;
  final Function(Bookmark)? onDelete;

  const BookBookmarks({
    super.key,
    required this.bookmarks,
    required this.bookTitle,
    this.onEditNote,
    this.onChangeColor,
    this.onDelete,
  });

  @override
  State<BookBookmarks> createState() => _BookBookmarksState();
}

class _BookBookmarksState extends State<BookBookmarks> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _BookmarkSort _sortOption = _BookmarkSort.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bookmark> get _filteredAndSortedBookmarks {
    var result = widget.bookmarks.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((bookmark) {
        return bookmark.displayLocation.toLowerCase().contains(query) ||
            (bookmark.note?.toLowerCase().contains(query) ?? false) ||
            (bookmark.chapterTitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    result.sort((a, b) {
      switch (_sortOption) {
        case _BookmarkSort.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case _BookmarkSort.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case _BookmarkSort.position:
          return a.position.compareTo(b.position);
      }
    });

    return result;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (widget.bookmarks.isEmpty) {
      return const SingleChildScrollView(child: _EmptyBookmarksState());
    }

    if (isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAndSortedBookmarks;

    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildBookmarksList(
                  filtered,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  separatorHeight: Spacing.md,
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      // +4 accounts for Card's default margin to align with card borders
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg + 4,
        Spacing.lg,
        Spacing.lg + 4,
        Spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Search bookmarks...',
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAndSortedBookmarks;

    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildBookmarksList(
                  filtered,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.md,
                  ),
                  separatorHeight: Spacing.sm,
                ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      // +4 accounts for Card's default margin to align with card borders
      padding: const EdgeInsets.fromLTRB(
        Spacing.md + 4,
        Spacing.md,
        Spacing.md + 4,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Search bookmarks...',
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_BookmarkSort>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort bookmarks',
      onSelected: (option) => setState(() => _sortOption = option),
      itemBuilder: (context) => [
        _buildSortMenuItem(_BookmarkSort.dateNewest, 'Newest first'),
        _buildSortMenuItem(_BookmarkSort.dateOldest, 'Oldest first'),
        _buildSortMenuItem(_BookmarkSort.position, 'By position'),
      ],
    );
  }

  PopupMenuItem<_BookmarkSort> _buildSortMenuItem(
    _BookmarkSort option,
    String label,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (option == _sortOption)
            Icon(
              Icons.check,
              size: IconSizes.small,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(
    List<Bookmark> bookmarks, {
    required EdgeInsets padding,
    required double separatorHeight,
  }) {
    return ListView.separated(
      padding: padding,
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return BookmarkListItem(
          bookmark: bookmark,
          bookTitle: widget.bookTitle,
          onEditNote: () => widget.onEditNote?.call(bookmark),
          onChangeColor: () => widget.onChangeColor?.call(bookmark),
          onDelete: () => widget.onDelete?.call(bookmark),
        );
      },
    );
  }

  Widget _buildNoResultsState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No bookmarks found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookmarksState extends StatelessWidget {
  const _EmptyBookmarksState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No bookmarks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Bookmarks you create while reading will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
