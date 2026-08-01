import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/shelf.dart';

/// View mode for displaying shelves.
enum ShelvesViewMode { smallGrid, largeGrid, list }

/// Filter options for shelf occupancy.
enum ShelfContentsFilter { all, withBooks, empty }

/// Filter options for shelf type.
enum ShelfTypeFilter { all, regular, smart }

/// Sort options for shelves.
enum ShelfSortOption { name, bookCount, dateCreated, dateModified }

/// Provider for shelves page state management.
/// Uses DataStore as the single source of truth.
class ShelvesProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Loading state
  bool _isLoading = false;
  String? _error;

  // Shelf collection controls
  ShelvesViewMode _viewMode = ShelvesViewMode.smallGrid;
  ShelfContentsFilter _contentsFilter = ShelfContentsFilter.all;
  ShelfTypeFilter _typeFilter = ShelfTypeFilter.all;

  // Selected shelf for detail view
  Shelf? _selectedShelf;

  // Sorting state for shelves
  ShelfSortOption _shelfSortOption = ShelfSortOption.name;
  bool _shelfSortAscending = true;

  // Search
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
  ShelfContentsFilter get contentsFilter => _contentsFilter;
  ShelfTypeFilter get typeFilter => _typeFilter;
  bool get isSmallGridView => _viewMode == ShelvesViewMode.smallGrid;
  bool get isLargeGridView => _viewMode == ShelvesViewMode.largeGrid;
  bool get isListView => _viewMode == ShelvesViewMode.list;

  bool get hasActiveShelfControls =>
      _contentsFilter != ShelfContentsFilter.all ||
      _typeFilter != ShelfTypeFilter.all ||
      _shelfSortOption != ShelfSortOption.name ||
      !_shelfSortAscending ||
      _viewMode != ShelvesViewMode.smallGrid;

  /// Get all shelves, filtered and sorted according to current settings.
  List<Shelf> get shelves {
    if (_dataStore == null) return [];
    var list = List<Shelf>.from(_dataStore!.shelves);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((shelf) {
        return shelf.name.toLowerCase().contains(query) || (shelf.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (_contentsFilter) {
      case ShelfContentsFilter.all:
        break;
      case ShelfContentsFilter.withBooks:
        list = list.where((shelf) => _dataStore!.getBookCountForShelf(shelf.id) > 0).toList();
      case ShelfContentsFilter.empty:
        list = list.where((shelf) => _dataStore!.getBookCountForShelf(shelf.id) == 0).toList();
    }

    switch (_typeFilter) {
      case ShelfTypeFilter.all:
        break;
      case ShelfTypeFilter.regular:
        list = list.where((shelf) => !shelf.isSmart).toList();
      case ShelfTypeFilter.smart:
        list = list.where((shelf) => shelf.isSmart).toList();
    }

    _applySorting(list);
    return list;
  }

  bool get hasShelves => shelves.isNotEmpty;
  bool get hasAnyShelves => _dataStore?.shelves.isNotEmpty ?? false;

  Shelf? get selectedShelf => _selectedShelf;

  String get searchQuery => _searchQuery;

  ShelfSortOption get shelfSortOption => _shelfSortOption;
  bool get shelfSortAscending => _shelfSortAscending;

  /// Get total book count across all shelves.
  int get totalBookCount {
    if (_dataStore == null) return 0;
    return _dataStore!.shelves.fold(0, (sum, shelf) => sum + _dataStore!.getBookCountForShelf(shelf.id));
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

  /// Sets the shelf occupancy filter.
  void setContentsFilter(ShelfContentsFilter filter) {
    if (_contentsFilter != filter) {
      _contentsFilter = filter;
      notifyListeners();
    }
  }

  /// Sets the shelf type filter.
  void setTypeFilter(ShelfTypeFilter filter) {
    if (_typeFilter != filter) {
      _typeFilter = filter;
      notifyListeners();
    }
  }

  /// Sets the shelf sort option and its explicit direction.
  void setShelfSortOption(ShelfSortOption option, {required bool ascending}) {
    if (_shelfSortOption == option && _shelfSortAscending == ascending) return;

    _shelfSortOption = option;
    _shelfSortAscending = ascending;
    notifyListeners();
  }

  /// Resets shelf collection controls without changing text search.
  void clearShelfControls() {
    _contentsFilter = ShelfContentsFilter.all;
    _typeFilter = ShelfTypeFilter.all;
    _shelfSortOption = ShelfSortOption.name;
    _shelfSortAscending = true;
    _viewMode = ShelvesViewMode.smallGrid;
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

  /// Gets child shelves of a parent shelf.
  List<Shelf> getChildShelves(String parentShelfId) {
    if (_dataStore == null) return [];
    return _dataStore!.getChildShelves(parentShelfId);
  }

  /// Selects a shelf for detail view.
  void selectShelf(Shelf? shelf) {
    _selectedShelf = shelf;
    notifyListeners();
  }

  /// Creates a new shelf.
  Future<Shelf> createShelf({required String name, String? description, String? colorHex, IconData? icon}) async {
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
    bool clearDescription = false,
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
      clearDescription: clearDescription,
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
  Future<void> addBookToShelf({required String shelfId, required String bookId}) async {
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
  Future<void> removeBookFromShelf({required String shelfId, required String bookId}) async {
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

  /// Get book count for a specific shelf.
  int getBookCountForShelf(String shelfId) {
    if (_dataStore == null) return 0;
    return _dataStore!.getBookCountForShelf(shelfId);
  }

  /// Get cover previews for a shelf.
  List<CoverPreview> getCoverPreviewsForShelf(String shelfId) {
    if (_dataStore == null) return [];
    return _dataStore!.getCoverPreviewsForShelf(shelfId);
  }

  /// Refreshes shelves data.
  Future<void> refresh() async {
    await loadShelves();
  }
}
