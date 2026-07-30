import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/library_filters.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/enums/library_sort_option.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/utils/book_language.dart';

class LibraryProvider extends ChangeNotifier {
  String _searchQuery = '';
  LibraryFilters _filters = LibraryFilters();
  LibraryViewMode _viewMode = LibraryViewMode.smallGrid;
  LibrarySortOption _sortOption = LibrarySortOption.dateAddedNewest;

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

  /// Current sort option.
  LibrarySortOption get sortOption => _sortOption;

  /// Current search query.
  String get searchQuery => _searchQuery;

  LibraryFilters get filters => _filters;

  int get activeFilterCount => _filters.activeCategoryCount;

  Set<String> get selectedAuthors => _filters.authors;

  Set<String> get selectedLanguages => _filters.languages;

  Set<String> get selectedFormats => _filters.formats;

  Set<String> get selectedShelfIds => _filters.shelfIds;

  Set<String> get selectedTopicIds => _filters.topicIds;

  Set<LibraryReadingStatus> get selectedStatuses => _filters.statuses;

  FavoriteFilter get favoriteFilter => _filters.favoriteFilter;

  void setViewMode(LibraryViewMode mode) {
    if (_viewMode == mode) {
      return;
    }

    switch (mode) {
      case LibraryViewMode.smallGrid:
        _viewMode = LibraryViewMode.smallGrid;
        break;
      case LibraryViewMode.largeGrid:
        _viewMode = LibraryViewMode.largeGrid;
        break;
      case LibraryViewMode.list:
        _viewMode = LibraryViewMode.list;
        break;
    }

    notifyListeners();
  }

  void setSortOption(LibrarySortOption option) {
    if (_sortOption == option) {
      return;
    }

    _sortOption = option;
    notifyListeners();
  }

  void setStatusFilters(Set<LibraryReadingStatus> statuses) {
    applyFilters(_filters.copyWith(statuses: statuses));
  }

  void setFavoriteFilter(FavoriteFilter favoriteFilter) {
    applyFilters(_filters.copyWith(favoriteFilter: favoriteFilter));
  }

  void setAuthorFilters(Set<String> authors) {
    applyFilters(_filters.copyWith(authors: _normalizeFilterValues(authors)));
  }

  void setLanguageFilters(Set<String> languages) {
    applyFilters(_filters.copyWith(languages: languages.map(normalizeBookLanguage).whereType<String>().toSet()));
  }

  void setFormatFilters(Set<String> formats) {
    applyFilters(_filters.copyWith(formats: _normalizeFilterValues(formats)));
  }

  void setShelfFilters(Set<String> shelfIds) {
    applyFilters(_filters.copyWith(shelfIds: shelfIds));
  }

  void setTopicFilters(Set<String> topicIds) {
    applyFilters(_filters.copyWith(topicIds: topicIds));
  }

  void applyFilters(LibraryFilters filters) {
    if (_filters == filters) {
      return;
    }

    _filters = filters;
    notifyListeners();
  }

  void clearFilters() {
    applyFilters(LibraryFilters());
  }

  void resetQuickFilters() {
    final hasChanges =
        !_filters.isEmpty || _sortOption != LibrarySortOption.dateAddedNewest || _viewMode != LibraryViewMode.smallGrid;

    if (!hasChanges) {
      return;
    }

    _filters = LibraryFilters();
    _sortOption = LibrarySortOption.dateAddedNewest;
    _viewMode = LibraryViewMode.smallGrid;
    notifyListeners();
  }

  List<Book> filterBooks(List<Book> books, {required DataStore dataStore, LibraryFilters? filters}) {
    final searchQuery = _searchQuery.trim().toLowerCase();
    final appliedFilters = filters ?? _filters;

    return books.where((book) {
      if (searchQuery.isNotEmpty &&
          !book.title.toLowerCase().contains(searchQuery) &&
          !book.allAuthors.toLowerCase().contains(searchQuery)) {
        return false;
      }

      if (appliedFilters.statuses.isNotEmpty && !appliedFilters.statuses.contains(book.readingStatus)) {
        return false;
      }

      final isFavorite = isBookFavorite(book.id, book.isFavorite);
      if (appliedFilters.favoriteFilter == FavoriteFilter.favorites && !isFavorite) {
        return false;
      }

      if (appliedFilters.favoriteFilter == FavoriteFilter.notFavorites && isFavorite) {
        return false;
      }

      if (appliedFilters.authors.isNotEmpty &&
          ![
            book.author,
            ...book.coAuthors,
          ].any((author) => appliedFilters.authors.contains(_normalizeFilterValue(author)))) {
        return false;
      }

      if (appliedFilters.languages.isNotEmpty &&
          !appliedFilters.languages.contains(normalizeBookLanguage(book.language))) {
        return false;
      }

      if (appliedFilters.formats.isNotEmpty &&
          !appliedFilters.formats.contains(_normalizeFilterValue(book.formatLabel))) {
        return false;
      }

      if (appliedFilters.shelfIds.isNotEmpty &&
          !dataStore.getShelfIdsForBook(book.id).any(appliedFilters.shelfIds.contains)) {
        return false;
      }

      if (appliedFilters.topicIds.isNotEmpty &&
          !dataStore.getTagIdsForBook(book.id).any(appliedFilters.topicIds.contains)) {
        return false;
      }

      if (appliedFilters.publishers.isNotEmpty &&
          !appliedFilters.publishers.contains(_normalizeFilterValue(book.publisher))) {
        return false;
      }

      if (appliedFilters.seriesNames.isNotEmpty &&
          !appliedFilters.seriesNames.contains(_normalizeFilterValue(book.seriesName))) {
        return false;
      }

      if (appliedFilters.progressRange case final range? when !range.contains(book.currentPosition)) {
        return false;
      }

      if (appliedFilters.ratings.isNotEmpty || appliedFilters.includeUnrated) {
        final rating = book.rating;
        if (rating == null ? !appliedFilters.includeUnrated : !appliedFilters.ratings.contains(rating)) {
          return false;
        }
      }

      if (appliedFilters.publicationDateRange case final range? when !range.contains(book.publicationDate)) {
        return false;
      }

      if (appliedFilters.dateAddedRange case final range? when !range.contains(book.addedAt)) {
        return false;
      }

      if (appliedFilters.lastReadDateRange case final range? when !range.contains(book.lastReadAt)) {
        return false;
      }

      return true;
    }).toList();
  }

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
          if (a.lastReadAt == null && b.lastReadAt == null) return 0;
          if (a.lastReadAt == null) return 1;
          if (b.lastReadAt == null) return -1;
          return b.lastReadAt!.compareTo(a.lastReadAt!);
        case LibrarySortOption.ratingAsc:
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;
          return a.rating!.compareTo(b.rating!);
        case LibrarySortOption.ratingDesc:
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;
          return b.rating!.compareTo(a.rating!);
        case LibrarySortOption.progressAsc:
          return a.currentPosition.compareTo(b.currentPosition);
        case LibrarySortOption.progressDesc:
          return b.currentPosition.compareTo(a.currentPosition);
      }
    });

    return sorted;
  }

  /// Set the search query.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Clear only the text search query.
  void clearSearch() {
    if (_searchQuery.isEmpty) {
      return;
    }

    _searchQuery = '';
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

  static String? _normalizeFilterValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Set<String> _normalizeFilterValues(Set<String> values) {
    return values.map(_normalizeFilterValue).whereType<String>().toSet();
  }
}
