import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/bookmark.dart';

/// Sort options for bookmarks.
enum BookmarkSortOption { dateNewest, dateOldest, bookTitle, position }

/// Provider for bookmarks page state management.
/// Uses DataStore as the single source of truth.
class BookmarksProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Sorting
  BookmarkSortOption _sortOption = BookmarkSortOption.dateNewest;

  // Filtering
  Set<String> _selectedColors = {};
  String _searchQuery = '';

  /// Attach to a DataStore instance.
  void attach(DataStore dataStore) {
    if (_dataStore != dataStore) {
      _dataStore?.removeListener(_onDataStoreChanged);
      _dataStore = dataStore;
      _dataStore!.addListener(_onDataStoreChanged);
      notifyListeners();
    }
  }

  void _onDataStoreChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dataStore?.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  BookmarkSortOption get sortOption => _sortOption;
  Set<String> get activeColors => _selectedColors;
  String get searchQuery => _searchQuery;

  /// Whether there are any bookmarks at all (unfiltered).
  bool get hasBookmarks =>
      _dataStore != null && _dataStore!.bookmarks.isNotEmpty;

  /// Whether current filters yield results.
  bool get hasResults => bookmarks.isNotEmpty;

  /// Whether any filter or search is active.
  bool get isFiltered => _selectedColors.isNotEmpty || _searchQuery.isNotEmpty;

  /// Total count of filtered bookmarks.
  int get totalCount => bookmarks.length;

  /// All bookmarks, filtered and sorted.
  List<Bookmark> get bookmarks {
    if (_dataStore == null) return [];
    var list = List<Bookmark>.from(_dataStore!.bookmarks);
    list = _applyFilters(list);
    _applySorting(list);
    return list;
  }

  /// Bookmarks grouped by book, preserving sort order.
  Map<String, List<Bookmark>> get bookmarksByBook {
    final filtered = bookmarks;
    final map = <String, List<Bookmark>>{};
    for (final bookmark in filtered) {
      map.putIfAbsent(bookmark.bookId, () => []).add(bookmark);
    }
    return map;
  }

  /// Resolve book title from DataStore.
  String getBookTitle(String bookId) {
    return _dataStore?.getBook(bookId)?.title ?? 'Unknown book';
  }

  /// Resolve book cover URL from DataStore.
  String? getBookCoverUrl(String bookId) {
    return _dataStore?.getBook(bookId)?.coverUrl;
  }

  // ============================================================================
  // SORTING & FILTERING
  // ============================================================================

  void setSortOption(BookmarkSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleColorFilter(String colorHex) {
    _selectedColors = Set.from(_selectedColors);
    if (_selectedColors.contains(colorHex)) {
      _selectedColors.remove(colorHex);
    } else {
      _selectedColors.add(colorHex);
    }
    notifyListeners();
  }

  void clearColorFilters() {
    _selectedColors = {};
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedColors = {};
    _searchQuery = '';
    notifyListeners();
  }

  // ============================================================================
  // CRUD (delegated to DataStore)
  // ============================================================================

  void updateBookmarkNote(String bookmarkId, String? note) {
    final bookmark = _dataStore?.getBookmark(bookmarkId);
    if (bookmark == null || _dataStore == null) return;
    _dataStore!.updateBookmark(bookmark.copyWith(note: note));
  }

  void updateBookmarkColor(String bookmarkId, String colorHex) {
    final bookmark = _dataStore?.getBookmark(bookmarkId);
    if (bookmark == null || _dataStore == null) return;
    _dataStore!.updateBookmark(bookmark.copyWith(colorHex: colorHex));
  }

  void deleteBookmark(String bookmarkId) {
    _dataStore?.deleteBookmark(bookmarkId);
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  List<Bookmark> _applyFilters(List<Bookmark> all) {
    var result = all;

    if (_selectedColors.isNotEmpty) {
      result = result
          .where((b) => _selectedColors.contains(b.colorHex))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((b) {
        final bookTitle = getBookTitle(b.bookId).toLowerCase();
        final note = b.note?.toLowerCase() ?? '';
        final chapter = b.chapterTitle?.toLowerCase() ?? '';
        return bookTitle.contains(query) ||
            note.contains(query) ||
            chapter.contains(query);
      }).toList();
    }

    return result;
  }

  void _applySorting(List<Bookmark> list) {
    list.sort((a, b) {
      switch (_sortOption) {
        case BookmarkSortOption.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case BookmarkSortOption.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case BookmarkSortOption.bookTitle:
          return getBookTitle(
            a.bookId,
          ).toLowerCase().compareTo(getBookTitle(b.bookId).toLowerCase());
        case BookmarkSortOption.position:
          return a.position.compareTo(b.position);
      }
    });
  }
}
