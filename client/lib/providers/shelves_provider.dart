import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/models/shelf_data.dart';

/// View mode for displaying shelves.
enum ShelvesViewMode {
  grid,
  list,
}

/// Sort options for shelves.
enum ShelfSortOption {
  name,
  bookCount,
  dateCreated,
  dateModified,
}

/// Sort options for books within a shelf.
enum BookSortOption {
  title,
  author,
  progress,
  dateAdded,
}

/// Provider for shelves page state management.
class ShelvesProvider extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  String? _error;

  // View mode
  ShelvesViewMode _viewMode = ShelvesViewMode.grid;

  // Shelves data
  List<ShelfData> _shelves = [];

  // Selected shelf for detail view
  ShelfData? _selectedShelf;

  // Sorting state for shelves
  ShelfSortOption _shelfSortOption = ShelfSortOption.name;
  bool _shelfSortAscending = true;

  // Sorting state for books within shelves
  BookSortOption _bookSortOption = BookSortOption.title;
  bool _bookSortAscending = true;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get error => _error;

  ShelvesViewMode get viewMode => _viewMode;
  bool get isGridView => _viewMode == ShelvesViewMode.grid;
  bool get isListView => _viewMode == ShelvesViewMode.list;

  List<ShelfData> get shelves => _shelves;
  bool get hasShelves => _shelves.isNotEmpty;

  /// Get default shelves (Currently Reading, Want to Read, Finished).
  List<ShelfData> get defaultShelves =>
      _shelves.where((s) => s.isDefault).toList();

  /// Get user-created shelves.
  List<ShelfData> get userShelves =>
      _shelves.where((s) => !s.isDefault).toList();

  ShelfData? get selectedShelf => _selectedShelf;

  ShelfSortOption get shelfSortOption => _shelfSortOption;
  bool get shelfSortAscending => _shelfSortAscending;

  BookSortOption get bookSortOption => _bookSortOption;
  bool get bookSortAscending => _bookSortAscending;

  /// Get total book count across all shelves.
  int get totalBookCount =>
      _shelves.fold(0, (sum, shelf) => sum + shelf.bookCount);

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads all shelves data.
  Future<void> loadShelves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Load sample data
      _shelves = ShelfData.sampleShelves;
      _shelves.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load shelves: $e';
      _isLoading = false;
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
    _applyShelvesSorting();
    notifyListeners();
  }

  /// Applies the current sorting to the shelves list.
  void _applyShelvesSorting() {
    _shelves.sort((a, b) {
      int result;
      switch (_shelfSortOption) {
        case ShelfSortOption.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ShelfSortOption.bookCount:
          result = a.bookCount.compareTo(b.bookCount);
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
  List<BookData> sortBooks(List<BookData> books) {
    final sorted = List<BookData>.from(books);
    sorted.sort((a, b) {
      int result;
      switch (_bookSortOption) {
        case BookSortOption.title:
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case BookSortOption.author:
          result = a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case BookSortOption.progress:
          result = a.progress.compareTo(b.progress);
        case BookSortOption.dateAdded:
          // For sample data, use id as a proxy for date added
          result = a.id.compareTo(b.id);
      }
      return _bookSortAscending ? result : -result;
    });
    return sorted;
  }

  /// Selects a shelf for detail view.
  void selectShelf(ShelfData? shelf) {
    _selectedShelf = shelf;
    notifyListeners();
  }

  /// Creates a new shelf.
  Future<ShelfData> createShelf({
    required String name,
    String? description,
    String? colorHex,
    IconData? icon,
  }) async {
    final now = DateTime.now();
    final newShelf = ShelfData(
      id: 'shelf-${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      colorHex: colorHex,
      icon: icon,
      bookCount: 0,
      coverPreviewUrls: [],
      sortOrder: _shelves.length,
      createdAt: now,
      updatedAt: now,
    );

    _shelves = [..._shelves, newShelf];
    notifyListeners();
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
    final index = _shelves.indexWhere((s) => s.id == shelfId);
    if (index != -1) {
      final shelf = _shelves[index];
      _shelves[index] = shelf.copyWith(
        name: name,
        description: description,
        colorHex: colorHex,
        icon: icon,
        updatedAt: DateTime.now(),
      );

      // Update selected shelf if it's the one being edited
      if (_selectedShelf?.id == shelfId) {
        _selectedShelf = _shelves[index];
      }

      notifyListeners();
    }
  }

  /// Deletes a shelf by ID.
  Future<void> deleteShelf(String shelfId) async {
    // Don't allow deleting default shelves
    final shelf = _shelves.firstWhere(
      (s) => s.id == shelfId,
      orElse: () => throw Exception('Shelf not found'),
    );

    if (shelf.isDefault) {
      throw Exception('Cannot delete default shelves');
    }

    _shelves = _shelves.where((s) => s.id != shelfId).toList();

    // Clear selected shelf if it was deleted
    if (_selectedShelf?.id == shelfId) {
      _selectedShelf = null;
    }

    notifyListeners();
  }

  /// Adds a book to a shelf.
  Future<void> addBookToShelf({
    required String shelfId,
    required BookData book,
  }) async {
    final index = _shelves.indexWhere((s) => s.id == shelfId);
    if (index != -1) {
      final shelf = _shelves[index];

      // Update cover previews (keep up to 4)
      final newCovers = [...shelf.coverPreviewUrls];
      if (book.coverURL != null &&
          book.coverURL!.isNotEmpty &&
          !newCovers.contains(book.coverURL)) {
        newCovers.insert(0, book.coverURL!);
        if (newCovers.length > 4) {
          newCovers.removeLast();
        }
      }

      _shelves[index] = shelf.copyWith(
        bookCount: shelf.bookCount + 1,
        coverPreviewUrls: newCovers,
        updatedAt: DateTime.now(),
      );

      // Update selected shelf if it's the one being modified
      if (_selectedShelf?.id == shelfId) {
        _selectedShelf = _shelves[index];
      }

      notifyListeners();
    }
  }

  /// Removes a book from a shelf.
  Future<void> removeBookFromShelf({
    required String shelfId,
    required String bookId,
  }) async {
    final index = _shelves.indexWhere((s) => s.id == shelfId);
    if (index != -1) {
      final shelf = _shelves[index];

      _shelves[index] = shelf.copyWith(
        bookCount: (shelf.bookCount - 1).clamp(0, shelf.bookCount),
        updatedAt: DateTime.now(),
      );

      // Update selected shelf if it's the one being modified
      if (_selectedShelf?.id == shelfId) {
        _selectedShelf = _shelves[index];
      }

      notifyListeners();
    }
  }

  /// Reorders shelves (drag and drop).
  void reorderShelves(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final shelf = _shelves.removeAt(oldIndex);
    _shelves.insert(newIndex, shelf);

    // Update sort orders
    for (var i = 0; i < _shelves.length; i++) {
      _shelves[i] = _shelves[i].copyWith(sortOrder: i);
    }

    notifyListeners();
  }

  /// Gets books for a specific shelf, sorted according to current settings.
  /// Note: In a real implementation, this would filter from actual book data.
  List<BookData> getBooksForShelf(String shelfId) {
    final shelf = _shelves.firstWhere(
      (s) => s.id == shelfId,
      orElse: () => throw Exception('Shelf not found'),
    );

    // For now, filter sample books that have this shelf name in their shelves list
    final books = BookData.sampleBooks
        .where((book) => book.shelves.contains(shelf.name))
        .toList();

    return sortBooks(books);
  }

  /// Refreshes shelves data.
  Future<void> refresh() async {
    await loadShelves();
  }
}
