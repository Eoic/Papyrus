import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/models/note.dart';

/// Tab indices for book details page.
enum BookDetailsTab { details, bookmarks, annotations, notes }

/// Provider for managing book details page state.
///
/// This provider works with DataStore to persist notes and annotations.
/// Call [setDataStore] before using this provider.
class BookDetailsProvider extends ChangeNotifier {
  DataStore? _dataStore;
  String? _currentBookId;
  BookData? _book;
  BookDetailsTab _selectedTab = BookDetailsTab.details;
  bool _isLoading = false;
  String? _error;
  bool _isDescriptionExpanded = false;

  /// Set the DataStore reference. Call this from the widget tree.
  void setDataStore(DataStore dataStore) {
    if (_dataStore != dataStore) {
      _dataStore?.removeListener(_onDataStoreChanged);
      _dataStore = dataStore;
      _dataStore!.addListener(_onDataStoreChanged);
    }
  }

  /// Called when DataStore changes - refresh current book if it was updated.
  void _onDataStoreChanged() {
    if (_currentBookId != null && _dataStore != null) {
      final updatedBook = _dataStore!.getBook(_currentBookId!);
      if (updatedBook != null && updatedBook != _book) {
        _book = updatedBook;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _dataStore?.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  // Getters
  BookData? get book => _book;

  /// Get bookmarks for the current book from DataStore.
  List<Bookmark> get bookmarks {
    if (_dataStore == null || _currentBookId == null) return [];
    return _dataStore!.getBookmarksForBook(_currentBookId!);
  }

  /// Get annotations for the current book from DataStore.
  List<Annotation> get annotations {
    if (_dataStore == null || _currentBookId == null) return [];
    return _dataStore!.getAnnotationsForBook(_currentBookId!);
  }

  /// Get notes for the current book from DataStore.
  List<Note> get notes {
    if (_dataStore == null || _currentBookId == null) return [];
    return _dataStore!.getNotesForBook(_currentBookId!);
  }

  BookDetailsTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDescriptionExpanded => _isDescriptionExpanded;

  int get bookmarkCount => bookmarks.length;
  int get annotationCount => annotations.length;
  int get noteCount => notes.length;

  /// Whether the book has been loaded successfully.
  bool get hasBook => _book != null;

  /// Whether the book has any bookmarks.
  bool get hasBookmarks => bookmarks.isNotEmpty;

  /// Whether the book has any annotations.
  bool get hasAnnotations => annotations.isNotEmpty;

  /// Whether the book has any notes.
  bool get hasNotes => notes.isNotEmpty;

  /// Load book details by ID.
  Future<void> loadBook(String bookId) async {
    // Skip reload if already loading the same book
    if (_currentBookId == bookId && _book != null && !_isLoading) {
      // Just refresh from DataStore in case data changed
      if (_dataStore != null) {
        final updatedBook = _dataStore!.getBook(bookId);
        if (updatedBook != null && updatedBook != _book) {
          _book = updatedBook;
          notifyListeners();
        }
      }
      return;
    }

    _isLoading = true;
    _error = null;
    _currentBookId = bookId;
    notifyListeners();

    try {
      // Find book from DataStore (or sample data as fallback)
      BookData? foundBook;
      if (_dataStore != null) {
        foundBook = _dataStore!.getBook(bookId);
      }

      // Fallback to sample data if not found in DataStore
      foundBook ??= BookData.sampleBooks.cast<BookData?>().firstWhere(
        (b) => b?.id == bookId,
        orElse: () => null,
      );

      if (foundBook == null) {
        throw Exception('Book not found');
      }

      _book = foundBook;
      // Notes and annotations are now fetched dynamically from DataStore
      // via the getters, so no need to load them here
      _error = null;
    } catch (e) {
      _error = e.toString();
      _book = null;
      _currentBookId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the selected tab.
  void setTab(BookDetailsTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  /// Set tab by index (for TabController).
  void setTabIndex(int index) {
    if (index >= 0 && index < BookDetailsTab.values.length) {
      setTab(BookDetailsTab.values[index]);
    }
  }

  /// Toggle description expanded state.
  void toggleDescriptionExpanded() {
    _isDescriptionExpanded = !_isDescriptionExpanded;
    notifyListeners();
  }

  /// Add a new note. Persists to DataStore.
  void addNote(Note note) {
    if (_dataStore != null) {
      _dataStore!.addNote(note);
    }
    notifyListeners();
  }

  /// Update an existing note. Persists to DataStore.
  void updateNote(String noteId, Note updatedNote) {
    if (_dataStore != null) {
      _dataStore!.updateNote(updatedNote);
    }
    notifyListeners();
  }

  /// Delete a note. Persists to DataStore.
  void deleteNote(String noteId) {
    if (_dataStore != null) {
      _dataStore!.deleteNote(noteId);
    }
    notifyListeners();
  }

  /// Update a bookmark's note. Persists to DataStore.
  void updateBookmarkNote(String bookmarkId, String? note) {
    final bookmark = _dataStore?.getBookmark(bookmarkId);
    if (bookmark == null || _dataStore == null) return;
    _dataStore!.updateBookmark(bookmark.copyWith(note: note));
    notifyListeners();
  }

  /// Update a bookmark's color. Persists to DataStore.
  void updateBookmarkColor(String bookmarkId, String colorHex) {
    final bookmark = _dataStore?.getBookmark(bookmarkId);
    if (bookmark == null || _dataStore == null) return;
    _dataStore!.updateBookmark(bookmark.copyWith(colorHex: colorHex));
    notifyListeners();
  }

  /// Delete a bookmark. Persists to DataStore.
  void deleteBookmark(String bookmarkId) {
    _dataStore?.deleteBookmark(bookmarkId);
    notifyListeners();
  }

  /// Add a new annotation. Persists to DataStore.
  void addAnnotation(Annotation annotation) {
    if (_dataStore != null) {
      _dataStore!.addAnnotation(annotation);
    }
    notifyListeners();
  }

  /// Update an existing annotation. Persists to DataStore.
  void updateAnnotation(String annotationId, Annotation updatedAnnotation) {
    if (_dataStore != null) {
      _dataStore!.updateAnnotation(updatedAnnotation);
    }
    notifyListeners();
  }

  /// Delete an annotation. Persists to DataStore.
  void deleteAnnotation(String annotationId) {
    if (_dataStore != null) {
      _dataStore!.deleteAnnotation(annotationId);
    }
    notifyListeners();
  }

  /// Toggle favorite status. Persists to DataStore.
  void toggleFavorite() {
    if (_book != null) {
      _book = _book!.copyWith(isFavorite: !_book!.isFavorite);
      if (_dataStore != null) {
        _dataStore!.updateBook(_book!);
      }
      notifyListeners();
    }
  }

  /// Update reading progress. Persists to DataStore.
  void updateProgress(double progress) {
    if (_book != null) {
      _book = _book!.copyWith(currentPosition: progress.clamp(0.0, 1.0));
      if (_dataStore != null) {
        _dataStore!.updateBook(_book!);
      }
      notifyListeners();
    }
  }

  /// Clear the current book state.
  void clear() {
    _book = null;
    _currentBookId = null;
    _selectedTab = BookDetailsTab.details;
    _isLoading = false;
    _error = null;
    _isDescriptionExpanded = false;
    notifyListeners();
  }
}
