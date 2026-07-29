import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/enums/library_sort_option.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/utils/book_language.dart';

class LibraryProvider extends ChangeNotifier {
  String _searchQuery = '';
  String? _selectedAuthor;
  String? _selectedLanguage;
  String? _selectedFormat;
  String? _selectedShelfId;
  String? _selectedTopicId;
  bool _isFavoritesSelected = false;
  LibraryReadingStatus? _selectedStatus;
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

  /// Currently selected author for filtering.
  String? get selectedAuthor => _selectedAuthor;

  /// Currently selected normalized language for filtering.
  String? get selectedLanguage => _selectedLanguage;

  /// Currently selected normalized format for filtering.
  String? get selectedFormat => _selectedFormat;

  /// ID of the currently selected shelf for filtering.
  String? get selectedShelfId => _selectedShelfId;

  /// ID of the currently selected topic for filtering.
  String? get selectedTopicId => _selectedTopicId;

  /// Currently selected reading status for filtering.
  LibraryReadingStatus? get selectedStatus => _selectedStatus;

  /// Whether the favorites filter is active.
  bool get isFavoritesSelected => _isFavoritesSelected;

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

  void setStatusFilter(LibraryReadingStatus? status) {
    if (_selectedStatus == status) {
      return;
    }

    _selectedStatus = status;
    notifyListeners();
  }

  void setIsFavoritesSelected(bool isSelected) {
    if (_isFavoritesSelected == isSelected) {
      return;
    }

    _isFavoritesSelected = isSelected;
    notifyListeners();
  }

  void setAuthorFilter(String? author) {
    final normalized = _normalizeFilterValue(author);
    if (_selectedAuthor == normalized) {
      return;
    }

    _selectedAuthor = normalized;
    notifyListeners();
  }

  void setLanguageFilter(String? language) {
    final normalized = normalizeBookLanguage(language);
    if (_selectedLanguage == normalized) {
      return;
    }

    _selectedLanguage = normalized;
    notifyListeners();
  }

  void setFormatFilter(String? format) {
    final normalized = _normalizeFilterValue(format);
    if (_selectedFormat == normalized) {
      return;
    }

    _selectedFormat = normalized;
    notifyListeners();
  }

  void setShelfFilter(String? shelfId) {
    if (_selectedShelfId == shelfId) {
      return;
    }

    _selectedShelfId = shelfId;
    notifyListeners();
  }

  void setTopicFilter(String? topicId) {
    if (_selectedTopicId == topicId) {
      return;
    }

    _selectedTopicId = topicId;
    notifyListeners();
  }

  void resetQuickFilters() {
    final hasChanges =
        _selectedStatus != null ||
        _sortOption != LibrarySortOption.dateAddedNewest ||
        _viewMode != LibraryViewMode.smallGrid ||
        _isFavoritesSelected ||
        _selectedAuthor != null ||
        _selectedLanguage != null ||
        _selectedFormat != null ||
        _selectedShelfId != null ||
        _selectedTopicId != null;

    if (!hasChanges) {
      return;
    }

    _selectedStatus = null;
    _sortOption = LibrarySortOption.dateAddedNewest;
    _isFavoritesSelected = false;
    _viewMode = LibraryViewMode.smallGrid;
    _selectedAuthor = null;
    _selectedLanguage = null;
    _selectedFormat = null;
    _selectedShelfId = null;
    _selectedTopicId = null;
    notifyListeners();
  }

  List<Book> filterBooks(List<Book> books, {required DataStore dataStore}) {
    final searchQuery = _searchQuery.trim().toLowerCase();

    return books.where((book) {
      if (searchQuery.isNotEmpty &&
          !book.title.toLowerCase().contains(searchQuery) &&
          !book.allAuthors.toLowerCase().contains(searchQuery)) {
        return false;
      }

      if (_selectedStatus != null && book.readingStatus != _selectedStatus) {
        return false;
      }

      if (_isFavoritesSelected && !isBookFavorite(book.id, book.isFavorite)) {
        return false;
      }

      if (_selectedAuthor != null &&
          ![book.author, ...book.coAuthors].any((author) => _normalizeFilterValue(author) == _selectedAuthor)) {
        return false;
      }

      if (_selectedLanguage != null && normalizeBookLanguage(book.language) != _selectedLanguage) {
        return false;
      }

      if (_selectedFormat != null && _normalizeFilterValue(book.formatLabel) != _selectedFormat) {
        return false;
      }

      if (_selectedShelfId != null && !dataStore.getShelfIdsForBook(book.id).contains(_selectedShelfId)) {
        return false;
      }

      if (_selectedTopicId != null && !dataStore.getTagIdsForBook(book.id).contains(_selectedTopicId)) {
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
}
