import 'package:flutter/foundation.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/models/note.dart';

/// Tab indices for book details page.
enum BookDetailsTab { details, annotations, notes }

/// Provider for managing book details page state.
class BookDetailsProvider extends ChangeNotifier {
  BookData? _book;
  List<Annotation> _annotations = [];
  List<Note> _notes = [];
  BookDetailsTab _selectedTab = BookDetailsTab.details;
  bool _isLoading = false;
  String? _error;
  bool _isDescriptionExpanded = false;

  // Getters
  BookData? get book => _book;
  List<Annotation> get annotations => _annotations;
  List<Note> get notes => _notes;
  BookDetailsTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDescriptionExpanded => _isDescriptionExpanded;

  int get annotationCount => _annotations.length;
  int get noteCount => _notes.length;

  /// Whether the book has been loaded successfully.
  bool get hasBook => _book != null;

  /// Whether the book has any annotations.
  bool get hasAnnotations => _annotations.isNotEmpty;

  /// Whether the book has any notes.
  bool get hasNotes => _notes.isNotEmpty;

  /// Load book details by ID.
  Future<void> loadBook(String bookId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay for realistic behavior
      await Future.delayed(const Duration(milliseconds: 300));

      // Find book from sample data (replace with API call later)
      final foundBook = BookData.sampleBooks.cast<BookData?>().firstWhere(
            (b) => b?.id == bookId,
            orElse: () => null,
          );

      if (foundBook == null) {
        throw Exception('Book not found');
      }

      _book = foundBook;
      _annotations = Annotation.getSampleAnnotations(bookId);
      _notes = Note.getSampleNotes(bookId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _book = null;
      _annotations = [];
      _notes = [];
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

  /// Add a new note.
  void addNote(Note note) {
    _notes = [note, ..._notes];
    notifyListeners();
  }

  /// Update an existing note.
  void updateNote(String noteId, Note updatedNote) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes = List.from(_notes)..[index] = updatedNote;
      notifyListeners();
    }
  }

  /// Delete a note.
  void deleteNote(String noteId) {
    _notes = _notes.where((n) => n.id != noteId).toList();
    notifyListeners();
  }

  /// Add a new annotation.
  void addAnnotation(Annotation annotation) {
    _annotations = [annotation, ..._annotations];
    notifyListeners();
  }

  /// Update an existing annotation.
  void updateAnnotation(String annotationId, Annotation updatedAnnotation) {
    final index = _annotations.indexWhere((a) => a.id == annotationId);
    if (index != -1) {
      _annotations = List.from(_annotations)..[index] = updatedAnnotation;
      notifyListeners();
    }
  }

  /// Delete an annotation.
  void deleteAnnotation(String annotationId) {
    _annotations = _annotations.where((a) => a.id != annotationId).toList();
    notifyListeners();
  }

  /// Toggle favorite status.
  void toggleFavorite() {
    if (_book != null) {
      _book = _book!.copyWith(isFavorite: !_book!.isFavorite);
      notifyListeners();
    }
  }

  /// Update reading progress.
  void updateProgress(double progress) {
    if (_book != null) {
      _book = _book!.copyWith(progress: progress.clamp(0.0, 1.0));
      notifyListeners();
    }
  }

  /// Clear the current book state.
  void clear() {
    _book = null;
    _annotations = [];
    _notes = [];
    _selectedTab = BookDetailsTab.details;
    _isLoading = false;
    _error = null;
    _isDescriptionExpanded = false;
    notifyListeners();
  }
}
