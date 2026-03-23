import 'package:flutter/foundation.dart';
import 'package:papyrus/models/book.dart';

/// View mode for displaying books in the library.
enum LibraryViewMode { grid, list }

/// Active filter type for library content.
enum LibraryFilterType {
  all,
  shelves,
  topics,
  favorites,
  reading,
  finished,
  unread,
}

/// Sort options for library books. Each value encodes its direction.
enum LibrarySortOption {
  dateAddedNewest,
  dateAddedOldest,
  titleAZ,
  titleZA,
  authorAZ,
  authorZA,
  lastRead,
  rating,
  progress,
}

/// Provider for managing library view state.
class LibraryProvider extends ChangeNotifier {
  LibraryViewMode _viewMode = LibraryViewMode.grid;
  final Set<LibraryFilterType> _activeFilters = {LibraryFilterType.all};
  LibrarySortOption _sortOption = LibrarySortOption.dateAddedNewest;
  String _searchQuery = '';
  String? _selectedShelf;
  String? _selectedTopic;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedBookIds = {};

  /// Track favorite status overrides for books.
  /// Key is book ID, value is the overridden favorite status.
  final Map<String, bool> _favoriteOverrides = {};

  /// Whether selection mode is active.
  bool get isSelectionMode => _isSelectionMode;

  /// Currently selected book IDs.
  Set<String> get selectedBookIds => Set.unmodifiable(_selectedBookIds);

  /// Number of selected books.
  int get selectedCount => _selectedBookIds.length;

  /// Current view mode (grid or list).
  LibraryViewMode get viewMode => _viewMode;

  /// Active filters for library content.
  Set<LibraryFilterType> get activeFilters => Set.unmodifiable(_activeFilters);

  /// Current sort option.
  LibrarySortOption get sortOption => _sortOption;

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Currently selected shelf for filtering.
  String? get selectedShelf => _selectedShelf;

  /// Currently selected topic for filtering.
  String? get selectedTopic => _selectedTopic;

  /// Whether the search query contains advanced field filters.
  bool get hasActiveAdvancedFilters => _searchQuery.contains(':');

  /// Whether the list view is currently active.
  bool get isListView => _viewMode == LibraryViewMode.list;

  /// Whether the grid view is currently active.
  bool get isGridView => _viewMode == LibraryViewMode.grid;

  /// Set the view mode.
  void setViewMode(LibraryViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// Toggle between grid and list view.
  void toggleViewMode() {
    _viewMode = _viewMode == LibraryViewMode.grid
        ? LibraryViewMode.list
        : LibraryViewMode.grid;
    notifyListeners();
  }

  /// Set the sort option.
  void setSortOption(LibrarySortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  /// Sort a list of books according to the current sort option.
  List<Book> sortBooks(List<Book> books) {
    final sorted = List<Book>.of(books);
    sorted.sort((a, b) {
      switch (_sortOption) {
        case LibrarySortOption.dateAddedNewest:
          return b.addedAt.compareTo(a.addedAt);
        case LibrarySortOption.dateAddedOldest:
          return a.addedAt.compareTo(b.addedAt);
        case LibrarySortOption.titleAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.titleZA:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case LibrarySortOption.authorAZ:
          return a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case LibrarySortOption.authorZA:
          return b.author.toLowerCase().compareTo(a.author.toLowerCase());
        case LibrarySortOption.lastRead:
          // Nulls sort to end
          if (a.lastReadAt == null && b.lastReadAt == null) return 0;
          if (a.lastReadAt == null) return 1;
          if (b.lastReadAt == null) return -1;
          return b.lastReadAt!.compareTo(a.lastReadAt!);
        case LibrarySortOption.rating:
          // Nulls sort to end, highest first
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;
          return b.rating!.compareTo(a.rating!);
        case LibrarySortOption.progress:
          return b.currentPosition.compareTo(a.currentPosition);
      }
    });
    return sorted;
  }

  /// Set a single filter (replaces existing filters).
  void setFilter(LibraryFilterType filter) {
    _activeFilters.clear();
    _activeFilters.add(filter);
    // Clear shelf/topic selection when switching filters
    if (filter != LibraryFilterType.shelves) {
      _selectedShelf = null;
    }
    if (filter != LibraryFilterType.topics) {
      _selectedTopic = null;
    }
    notifyListeners();
  }

  /// Add a filter to active filters.
  void addFilter(LibraryFilterType filter) {
    // Remove 'all' filter when adding specific filters
    if (filter != LibraryFilterType.all) {
      _activeFilters.remove(LibraryFilterType.all);
    }
    _activeFilters.add(filter);
    notifyListeners();
  }

  /// Remove a filter from active filters.
  void removeFilter(LibraryFilterType filter) {
    _activeFilters.remove(filter);
    // If no filters remain, default to 'all'
    if (_activeFilters.isEmpty) {
      _activeFilters.add(LibraryFilterType.all);
    }
    notifyListeners();
  }

  /// Toggle a filter on/off.
  void toggleFilter(LibraryFilterType filter) {
    if (_activeFilters.contains(filter)) {
      removeFilter(filter);
    } else {
      addFilter(filter);
    }
  }

  /// Check if a specific filter is active.
  bool isFilterActive(LibraryFilterType filter) {
    return _activeFilters.contains(filter);
  }

  /// Set the search query.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Clear the search query and associated shelf/topic filters.
  void clearSearch() {
    _searchQuery = '';
    _selectedShelf = null;
    _selectedTopic = null;
    _activeFilters.remove(LibraryFilterType.shelves);
    _activeFilters.remove(LibraryFilterType.topics);
    if (_activeFilters.isEmpty) {
      _activeFilters.add(LibraryFilterType.all);
    }
    notifyListeners();
  }

  /// Select a shelf for filtering.
  void selectShelf(String? shelf) {
    _selectedShelf = shelf;
    if (shelf != null) {
      setFilter(LibraryFilterType.shelves);
    }
    notifyListeners();
  }

  /// Select a topic for filtering.
  void selectTopic(String? topic) {
    _selectedTopic = topic;
    if (topic != null) {
      setFilter(LibraryFilterType.topics);
    }
    notifyListeners();
  }

  /// Reset all filters to default state.
  void resetFilters() {
    _activeFilters.clear();
    _activeFilters.add(LibraryFilterType.all);
    _searchQuery = '';
    _selectedShelf = null;
    _selectedTopic = null;
    notifyListeners();
  }

  /// Check if a book is favorited (considering overrides).
  bool isBookFavorite(String bookId, bool originalFavorite) {
    return _favoriteOverrides[bookId] ?? originalFavorite;
  }

  /// Toggle the favorite status of a book.
  void toggleFavorite(String bookId, bool currentFavorite) {
    _favoriteOverrides[bookId] = !currentFavorite;
    notifyListeners();
  }

  /// Get the effective favorite status for a book.
  bool? getFavoriteOverride(String bookId) {
    return _favoriteOverrides[bookId];
  }

  // ===========================================================================
  // Selection mode
  // ===========================================================================

  /// Enter selection mode, optionally pre-selecting a book.
  void enterSelectionMode([String? initialBookId]) {
    _isSelectionMode = true;
    _selectedBookIds.clear();
    if (initialBookId != null) _selectedBookIds.add(initialBookId);
    notifyListeners();
  }

  /// Exit selection mode and clear selection.
  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedBookIds.clear();
    notifyListeners();
  }

  /// Toggle selection of a single book.
  void toggleBookSelection(String bookId) {
    if (_selectedBookIds.contains(bookId)) {
      _selectedBookIds.remove(bookId);
      if (_selectedBookIds.isEmpty) exitSelectionMode();
    } else {
      _selectedBookIds.add(bookId);
    }
    notifyListeners();
  }

  /// Whether a specific book is selected.
  bool isBookSelected(String bookId) => _selectedBookIds.contains(bookId);

  /// Select all given book IDs.
  void selectAll(List<String> bookIds) {
    _selectedBookIds.addAll(bookIds);
    notifyListeners();
  }

  /// Deselect all books (stays in selection mode).
  void deselectAll() {
    _selectedBookIds.clear();
    notifyListeners();
  }
}
