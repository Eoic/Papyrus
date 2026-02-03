import 'package:flutter/foundation.dart';

/// View mode for displaying books in the library.
enum LibraryViewMode { grid, list }

/// Active filter type for library content.
enum LibraryFilterType { all, shelves, topics, favorites, reading, finished }

/// Provider for managing library view state.
class LibraryProvider extends ChangeNotifier {
  LibraryViewMode _viewMode = LibraryViewMode.grid;
  final Set<LibraryFilterType> _activeFilters = {LibraryFilterType.all};
  String _searchQuery = '';
  String? _selectedShelf;
  String? _selectedTopic;

  /// Track favorite status overrides for books.
  /// Key is book ID, value is the overridden favorite status.
  final Map<String, bool> _favoriteOverrides = {};

  /// Current view mode (grid or list).
  LibraryViewMode get viewMode => _viewMode;

  /// Active filters for library content.
  Set<LibraryFilterType> get activeFilters => Set.unmodifiable(_activeFilters);

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Currently selected shelf for filtering.
  String? get selectedShelf => _selectedShelf;

  /// Currently selected topic for filtering.
  String? get selectedTopic => _selectedTopic;

  /// Whether the list view is currently active.
  bool get isListView => _viewMode == LibraryViewMode.list;

  /// Whether the grid view is currently active.
  bool get isGridView => _viewMode == LibraryViewMode.grid;

  /// Whether there are any active advanced filters (search query contains field:value syntax).
  bool get hasActiveAdvancedFilters {
    if (_searchQuery.isEmpty) return false;
    // Check if search query contains field:value pattern
    return _searchQuery.contains(':');
  }

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

  /// Clear the search query.
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
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
}
