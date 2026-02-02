import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/metadata_service.dart';

/// State for metadata fetch operations.
enum MetadataFetchState {
  idle,
  loading,
  success,
  error,
}

/// Provider for book edit page state management.
class BookEditProvider extends ChangeNotifier {
  DataStore? _dataStore;
  final MetadataService _metadataService;

  // Book state
  Book? _originalBook;
  Book? _editedBook;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Metadata fetch state
  MetadataFetchState _fetchState = MetadataFetchState.idle;
  List<BookMetadataResult> _fetchedResults = [];
  String? _fetchError;
  MetadataSource _selectedSource = MetadataSource.openLibrary;

  // Cover image state (for uploaded files)
  Uint8List? _coverImageBytes;

  BookEditProvider({MetadataService? metadataService})
      : _metadataService = metadataService ?? MetadataService();

  // ============================================================================
  // GETTERS
  // ============================================================================

  Book? get originalBook => _originalBook;
  Book? get editedBook => _editedBook;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get hasBook => _editedBook != null;

  MetadataFetchState get fetchState => _fetchState;
  List<BookMetadataResult> get fetchedResults => _fetchedResults;
  String? get fetchError => _fetchError;
  MetadataSource get selectedSource => _selectedSource;
  bool get isFetching => _fetchState == MetadataFetchState.loading;
  Uint8List? get coverImageBytes => _coverImageBytes;
  bool get hasLocalCoverImage => _coverImageBytes != null;

  /// Whether there are unsaved changes.
  bool get hasUnsavedChanges {
    if (_originalBook == null || _editedBook == null) return false;
    // Check for local cover image as well
    if (_coverImageBytes != null) return true;
    return _originalBook != _editedBook;
  }

  /// Whether the form can be saved.
  bool get canSave => hasUnsavedChanges && !_isSaving;

  // ============================================================================
  // DATA STORE
  // ============================================================================

  /// Set the data store reference.
  void setDataStore(DataStore dataStore) {
    _dataStore = dataStore;
  }

  /// Load a book for editing.
  Future<void> loadBook(String bookId) async {
    if (_dataStore == null) {
      _error = 'Data store not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final book = _dataStore!.getBook(bookId);
      if (book == null) {
        _error = 'Book not found';
      } else {
        _originalBook = book;
        _editedBook = book;
      }
    } catch (e) {
      _error = 'Failed to load book: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save the edited book to the data store.
  Future<bool> save() async {
    if (_dataStore == null || _editedBook == null) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // If we have local cover image bytes, convert to data URI
      var bookToSave = _editedBook!;
      if (_coverImageBytes != null) {
        final dataUri = _bytesToDataUri(_coverImageBytes!);
        bookToSave = bookToSave.copyWith(coverUrl: dataUri);
        _editedBook = bookToSave;
      }

      _dataStore!.updateBook(bookToSave);
      _originalBook = bookToSave;
      _coverImageBytes = null; // Clear bytes since they're now in the URL
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save book: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Convert image bytes to a data URI string.
  String _bytesToDataUri(Uint8List bytes) {
    // Detect image type from magic bytes
    String mimeType = 'image/jpeg'; // default
    if (bytes.length >= 8) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        mimeType = 'image/png';
      } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        mimeType = 'image/gif';
      } else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
        mimeType = 'image/webp';
      }
    }

    final base64Data = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Data';
  }

  /// Revert all changes to the original book.
  void revertChanges() {
    if (_originalBook != null) {
      _editedBook = _originalBook;
      notifyListeners();
    }
  }

  // ============================================================================
  // FIELD UPDATES
  // ============================================================================

  void updateTitle(String value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(title: value);
    notifyListeners();
  }

  void updateSubtitle(String? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(subtitle: value?.isEmpty == true ? null : value);
    notifyListeners();
  }

  void updateAuthor(String value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(author: value);
    notifyListeners();
  }

  void updateCoAuthors(List<String> value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(coAuthors: value);
    notifyListeners();
  }

  void updatePublisher(String? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(publisher: value?.isEmpty == true ? null : value);
    notifyListeners();
  }

  void updateLanguage(String? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(language: value?.isEmpty == true ? null : value);
    notifyListeners();
  }

  void updatePageCount(int? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(pageCount: value);
    notifyListeners();
  }

  void updateIsbn(String? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(isbn: value?.isEmpty == true ? null : value);
    notifyListeners();
  }

  void updateIsbn13(String? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(isbn13: value?.isEmpty == true ? null : value);
    notifyListeners();
  }

  void updateDescription(String? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(description: value?.isEmpty == true ? null : value);
    notifyListeners();
  }

  void updateCoverUrl(String? value) {
    if (_editedBook == null) return;
    final shouldClear = value == null || value.isEmpty;
    _editedBook = _editedBook!.copyWith(
      coverUrl: shouldClear ? null : value,
      clearCoverUrl: shouldClear,
    );
    // Clear local bytes when URL is set
    if (value != null && value.isNotEmpty) {
      _coverImageBytes = null;
    }
    notifyListeners();
  }

  /// Update cover from uploaded file bytes.
  void updateCoverFromFile(Uint8List? bytes) {
    _coverImageBytes = bytes;
    // Clear URL when file is uploaded
    if (bytes != null && _editedBook != null) {
      _editedBook = _editedBook!.copyWith(clearCoverUrl: true);
    }
    notifyListeners();
  }

  void updatePublicationDate(DateTime? value) {
    if (_editedBook == null) return;
    _editedBook = _editedBook!.copyWith(publicationDate: value);
    notifyListeners();
  }

  // ============================================================================
  // METADATA FETCH
  // ============================================================================

  /// Set the metadata source for searches.
  void setMetadataSource(MetadataSource source) {
    _selectedSource = source;
    notifyListeners();
  }

  /// Search for book metadata by query.
  Future<void> searchMetadata(String query) async {
    if (query.trim().isEmpty) return;

    _fetchState = MetadataFetchState.loading;
    _fetchError = null;
    _fetchedResults = [];
    notifyListeners();

    try {
      final results = await _metadataService.search(query, _selectedSource);
      _fetchedResults = results;
      _fetchState =
          results.isEmpty ? MetadataFetchState.error : MetadataFetchState.success;
      if (results.isEmpty) {
        _fetchError = 'No results found';
      }
    } catch (e) {
      _fetchState = MetadataFetchState.error;
      _fetchError = 'Search failed: $e';
    }

    notifyListeners();
  }

  /// Search for book metadata by ISBN.
  Future<void> searchMetadataByIsbn(String isbn) async {
    if (isbn.trim().isEmpty) return;

    _fetchState = MetadataFetchState.loading;
    _fetchError = null;
    _fetchedResults = [];
    notifyListeners();

    try {
      final results = await _metadataService.searchByIsbn(isbn, _selectedSource);
      _fetchedResults = results;
      _fetchState =
          results.isEmpty ? MetadataFetchState.error : MetadataFetchState.success;
      if (results.isEmpty) {
        _fetchError = 'No results found for ISBN';
      }
    } catch (e) {
      _fetchState = MetadataFetchState.error;
      _fetchError = 'Search failed: $e';
    }

    notifyListeners();
  }

  /// Apply fetched metadata to the edited book.
  void applyMetadata(BookMetadataResult result) {
    if (_editedBook == null) return;

    _editedBook = _editedBook!.copyWith(
      title: result.title ?? _editedBook!.title,
      subtitle: result.subtitle ?? _editedBook!.subtitle,
      author: result.primaryAuthor.isNotEmpty
          ? result.primaryAuthor
          : _editedBook!.author,
      coAuthors: result.coAuthors.isNotEmpty
          ? result.coAuthors
          : _editedBook!.coAuthors,
      publisher: result.publisher ?? _editedBook!.publisher,
      language: result.language ?? _editedBook!.language,
      pageCount: result.pageCount ?? _editedBook!.pageCount,
      isbn: result.isbn ?? _editedBook!.isbn,
      isbn13: result.isbn13 ?? _editedBook!.isbn13,
      description: result.description ?? _editedBook!.description,
      coverUrl: result.coverUrl ?? _editedBook!.coverUrl,
    );

    // Clear fetch results after applying
    clearFetchedResults();
    notifyListeners();
  }

  /// Clear fetched metadata results.
  void clearFetchedResults() {
    _fetchState = MetadataFetchState.idle;
    _fetchedResults = [];
    _fetchError = null;
    notifyListeners();
  }
}
