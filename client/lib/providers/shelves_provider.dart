import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/shelf.dart';

/// View mode for displaying shelves.
enum ShelvesViewMode { grid, list }

/// Sort options for shelves.
enum ShelfSortOption { name, bookCount, dateCreated, dateModified }

/// Sort options for books within a shelf.
enum BookSortOption { title, author, progress, dateAdded }

/// Provider for shelves page state management.
/// Uses DataStore as the single source of truth.
class ShelvesProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Loading state
  bool _isLoading = false;
  String? _error;

  // View mode
  ShelvesViewMode _viewMode = ShelvesViewMode.grid;

  // Selected shelf for detail view
  Shelf? _selectedShelf;

  // Sorting state for shelves
  ShelfSortOption _shelfSortOption = ShelfSortOption.name;
  bool _shelfSortAscending = true;

  // Search
  String _searchQuery = '';

  // Sorting state for books within shelves
  BookSortOption _bookSortOption = BookSortOption.title;
  bool _bookSortAscending = true;

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
    // Update selected shelf if it was modified
    if (_selectedShelf != null) {
      _selectedShelf = _dataStore?.getShelf(_selectedShelf!.id);
    }
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

  bool get isLoading => _isLoading;
  String? get error => _error;

  ShelvesViewMode get viewMode => _viewMode;
  bool get isGridView => _viewMode == ShelvesViewMode.grid;
  bool get isListView => _viewMode == ShelvesViewMode.list;

  /// Get all shelves, filtered and sorted according to current settings.
  List<Shelf> get shelves {
    if (_dataStore == null) return [];
    var list = List<Shelf>.from(_dataStore!.shelves);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((shelf) {
        return shelf.name.toLowerCase().contains(query) ||
            (shelf.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    _applySorting(list);
    return list;
  }

  bool get hasShelves => shelves.isNotEmpty;

  Shelf? get selectedShelf => _selectedShelf;

  String get searchQuery => _searchQuery;

  ShelfSortOption get shelfSortOption => _shelfSortOption;
  bool get shelfSortAscending => _shelfSortAscending;

  BookSortOption get bookSortOption => _bookSortOption;
  bool get bookSortAscending => _bookSortAscending;

  /// Get total book count across all shelves.
  int get totalBookCount {
    if (_dataStore == null) return 0;
    return _dataStore!.shelves.fold(
      0,
      (sum, shelf) => sum + _dataStore!.getBookCountForShelf(shelf.id),
    );
  }

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads all shelves data. With DataStore, this is instant since data is already loaded.
  Future<void> loadShelves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay for realistic UX
      await Future.delayed(const Duration(milliseconds: 100));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load shelves: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the search query and filters shelves.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Clears the search query.
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  /// Sets the view mode.
  void setViewMode(ShelvesViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// Toggles between grid and list view.
  void toggleViewMode() {
    _viewMode = _viewMode == ShelvesViewMode.grid
        ? ShelvesViewMode.list
        : ShelvesViewMode.grid;
    notifyListeners();
  }

  /// Sets the shelf sort option. If the same option is selected, toggles direction.
  void setShelfSortOption(ShelfSortOption option, {bool? ascending}) {
    if (_shelfSortOption == option && ascending == null) {
      _shelfSortAscending = !_shelfSortAscending;
    } else {
      _shelfSortOption = option;
      if (ascending != null) _shelfSortAscending = ascending;
    }
    notifyListeners();
  }

  /// Applies the current sorting to a shelves list.
  void _applySorting(List<Shelf> list) {
    list.sort((a, b) {
      int result;
      switch (_shelfSortOption) {
        case ShelfSortOption.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ShelfSortOption.bookCount:
          final aCount = _dataStore?.getBookCountForShelf(a.id) ?? 0;
          final bCount = _dataStore?.getBookCountForShelf(b.id) ?? 0;
          result = aCount.compareTo(bCount);
        case ShelfSortOption.dateCreated:
          result = a.createdAt.compareTo(b.createdAt);
        case ShelfSortOption.dateModified:
          result = a.updatedAt.compareTo(b.updatedAt);
      }
      return _shelfSortAscending ? result : -result;
    });
  }

  /// Sets the book sort option for shelf detail view.
  void setBookSortOption(BookSortOption option, {bool? ascending}) {
    if (_bookSortOption == option && ascending == null) {
      _bookSortAscending = !_bookSortAscending;
    } else {
      _bookSortOption = option;
      if (ascending != null) _bookSortAscending = ascending;
    }
    notifyListeners();
  }

  /// Sorts a list of books according to current book sort settings.
  List<Book> sortBooks(List<Book> books) {
    final sorted = List<Book>.from(books);
    sorted.sort((a, b) {
      int result;
      switch (_bookSortOption) {
        case BookSortOption.title:
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case BookSortOption.author:
          result = a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case BookSortOption.progress:
          result = a.currentPosition.compareTo(b.currentPosition);
        case BookSortOption.dateAdded:
          result = a.addedAt.compareTo(b.addedAt);
      }
      return _bookSortAscending ? result : -result;
    });
    return sorted;
  }

  /// Selects a shelf for detail view.
  void selectShelf(Shelf? shelf) {
    _selectedShelf = shelf;
    notifyListeners();
  }

  /// Creates a new shelf.
  Future<Shelf> createShelf({
    required String name,
    String? description,
    String? colorHex,
    IconData? icon,
  }) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    final now = DateTime.now();
    final newShelf = Shelf(
      id: 'shelf-${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      colorHex: colorHex,
      icon: icon,
      sortOrder: _dataStore!.shelves.length,
      createdAt: now,
      updatedAt: now,
    );

    _dataStore!.addShelf(newShelf);
    return newShelf;
  }

  /// Updates an existing shelf.
  Future<void> updateShelf({
    required String shelfId,
    String? name,
    String? description,
    String? colorHex,
    IconData? icon,
  }) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    final shelf = _dataStore!.getShelf(shelfId);
    if (shelf == null) {
      throw Exception('Shelf not found');
    }

    final updatedShelf = shelf.copyWith(
      name: name,
      description: description,
      colorHex: colorHex,
      icon: icon,
      updatedAt: DateTime.now(),
    );

    _dataStore!.updateShelf(updatedShelf);

    // Update selected shelf if it's the one being edited
    if (_selectedShelf?.id == shelfId) {
      _selectedShelf = updatedShelf;
    }
  }

  /// Deletes a shelf by ID.
  Future<void> deleteShelf(String shelfId) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    final shelf = _dataStore!.getShelf(shelfId);
    if (shelf == null) {
      throw Exception('Shelf not found');
    }

    _dataStore!.deleteShelf(shelfId);

    // Clear selected shelf if it was deleted
    if (_selectedShelf?.id == shelfId) {
      _selectedShelf = null;
    }
  }

  /// Adds a book to a shelf.
  Future<void> addBookToShelf({
    required String shelfId,
    required String bookId,
  }) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    _dataStore!.addBookToShelf(bookId, shelfId);

    // Update the shelf's updatedAt timestamp
    final shelf = _dataStore!.getShelf(shelfId);
    if (shelf != null) {
      _dataStore!.updateShelf(shelf.copyWith(updatedAt: DateTime.now()));
    }
  }

  /// Removes a book from a shelf.
  Future<void> removeBookFromShelf({
    required String shelfId,
    required String bookId,
  }) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    _dataStore!.removeBookFromShelf(bookId, shelfId);

    // Update the shelf's updatedAt timestamp
    final shelf = _dataStore!.getShelf(shelfId);
    if (shelf != null) {
      _dataStore!.updateShelf(shelf.copyWith(updatedAt: DateTime.now()));
    }
  }

  /// Reorders shelves (drag and drop).
  void reorderShelves(int oldIndex, int newIndex) {
    if (_dataStore == null) return;

    final shelfList = List<Shelf>.from(_dataStore!.shelves);
    shelfList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final shelf = shelfList.removeAt(oldIndex);
    shelfList.insert(newIndex, shelf);

    // Update sort orders in DataStore
    for (var i = 0; i < shelfList.length; i++) {
      _dataStore!.updateShelf(shelfList[i].copyWith(sortOrder: i));
    }
  }

  /// Gets books for a specific shelf, sorted according to current settings.
  List<Book> getBooksForShelf(String shelfId) {
    if (_dataStore == null) return [];

    final books = _dataStore!.getBooksInShelf(shelfId);
    return sortBooks(books);
  }

  /// Get book count for a specific shelf.
  int getBookCountForShelf(String shelfId) {
    if (_dataStore == null) return 0;
    return _dataStore!.getBookCountForShelf(shelfId);
  }

  /// Get cover preview URLs for a shelf.
  List<String> getCoverPreviewsForShelf(String shelfId) {
    if (_dataStore == null) return [];
    return _dataStore!.getCoverPreviewsForShelf(shelfId);
  }

  /// Refreshes shelves data.
  Future<void> refresh() async {
    await loadShelves();
  }
}
