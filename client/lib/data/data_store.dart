import 'package:flutter/foundation.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/book_shelf_relation.dart';
import 'package:papyrus/models/book_tag_relation.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/models/reading_session.dart';
import 'package:papyrus/models/series.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';

/// Central in-memory data store - the single source of truth.
/// All repositories read from and write to this store.
class DataStore extends ChangeNotifier {
  // Primary data collections (keyed by ID)
  final Map<String, Book> _books = {};
  final Map<String, Shelf> _shelves = {};
  final Map<String, Tag> _tags = {};
  final Map<String, Series> _series = {};
  final Map<String, Annotation> _annotations = {};
  final Map<String, Note> _notes = {};
  final Map<String, Bookmark> _bookmarks = {};
  final Map<String, ReadingSession> _readingSessions = {};
  final Map<String, ReadingGoal> _readingGoals = {};

  // Junction table data
  final List<BookShelfRelation> _bookShelfRelations = [];
  final List<BookTagRelation> _bookTagRelations = [];

  bool _isLoaded = false;

  // ============================================================
  // Getters for read access
  // ============================================================

  bool get isLoaded => _isLoaded;

  List<Book> get books => _books.values.toList();

  /// Get all shelves with computed bookCount and coverPreviewUrls.
  List<Shelf> get shelves => _shelves.values.map((shelf) {
    final bookCount = getBookCountForShelf(shelf.id);
    final coverPreviews = getCoverPreviewsForShelf(shelf.id);
    return shelf.copyWith(
      bookCount: bookCount,
      coverPreviewUrls: coverPreviews,
    );
  }).toList();

  List<Tag> get tags => _tags.values.toList();
  List<Series> get seriesList => _series.values.toList();
  List<Annotation> get annotations => _annotations.values.toList();
  List<Note> get notes => _notes.values.toList();
  List<Bookmark> get bookmarks => _bookmarks.values.toList();
  List<ReadingSession> get readingSessions => _readingSessions.values.toList();
  List<ReadingGoal> get readingGoals => _readingGoals.values.toList();
  List<BookShelfRelation> get bookShelfRelations =>
      List.unmodifiable(_bookShelfRelations);
  List<BookTagRelation> get bookTagRelations =>
      List.unmodifiable(_bookTagRelations);

  // ============================================================
  // Book CRUD
  // ============================================================

  Book? getBook(String id) => _books[id];

  void addBook(Book book) {
    _books[book.id] = book;
    notifyListeners();
  }

  void updateBook(Book book) {
    _books[book.id] = book;
    notifyListeners();
  }

  void deleteBook(String id) {
    _books.remove(id);
    // Also remove related data
    _bookShelfRelations.removeWhere((r) => r.bookId == id);
    _bookTagRelations.removeWhere((r) => r.bookId == id);
    _annotations.removeWhere((key, a) => a.bookId == id);
    _notes.removeWhere((key, n) => n.bookId == id);
    _bookmarks.removeWhere((key, b) => b.bookId == id);
    _readingSessions.removeWhere((key, s) => s.bookId == id);
    notifyListeners();
  }

  // ============================================================
  // Shelf CRUD
  // ============================================================

  /// Get a shelf by ID with computed bookCount and coverPreviewUrls.
  Shelf? getShelf(String id) {
    final shelf = _shelves[id];
    if (shelf == null) return null;
    return shelf.copyWith(
      bookCount: getBookCountForShelf(id),
      coverPreviewUrls: getCoverPreviewsForShelf(id),
    );
  }

  void addShelf(Shelf shelf) {
    _shelves[shelf.id] = shelf;
    notifyListeners();
  }

  void updateShelf(Shelf shelf) {
    _shelves[shelf.id] = shelf;
    notifyListeners();
  }

  void deleteShelf(String id) {
    _shelves.remove(id);
    _bookShelfRelations.removeWhere((r) => r.shelfId == id);
    notifyListeners();
  }

  /// Get all books in a shelf.
  List<Book> getBooksInShelf(String shelfId) {
    final bookIds = _bookShelfRelations
        .where((r) => r.shelfId == shelfId)
        .map((r) => r.bookId);
    return bookIds.map((id) => _books[id]).whereType<Book>().toList();
  }

  /// Get book count for a shelf.
  int getBookCountForShelf(String shelfId) {
    return _bookShelfRelations.where((r) => r.shelfId == shelfId).length;
  }

  /// Get child shelves of a parent shelf, enriched with bookCount/coverPreviewUrls.
  List<Shelf> getChildShelves(String parentShelfId) {
    return _shelves.values
        .where((s) => s.parentShelfId == parentShelfId)
        .map(
          (shelf) => shelf.copyWith(
            bookCount: getBookCountForShelf(shelf.id),
            coverPreviewUrls: getCoverPreviewsForShelf(shelf.id),
          ),
        )
        .toList();
  }

  /// Get cover preview URLs for a shelf (up to 4 books).
  List<String> getCoverPreviewsForShelf(String shelfId, {int limit = 4}) {
    final books = getBooksInShelf(shelfId);
    return books
        .where((b) => b.coverUrl != null)
        .take(limit)
        .map((b) => b.coverUrl!)
        .toList();
  }

  // ============================================================
  // Tag CRUD
  // ============================================================

  Tag? getTag(String id) => _tags[id];

  void addTag(Tag tag) {
    _tags[tag.id] = tag;
    notifyListeners();
  }

  void updateTag(Tag tag) {
    _tags[tag.id] = tag;
    notifyListeners();
  }

  void deleteTag(String id) {
    _tags.remove(id);
    _bookTagRelations.removeWhere((r) => r.tagId == id);
    notifyListeners();
  }

  /// Get all books with a tag.
  List<Book> getBooksWithTag(String tagId) {
    final bookIds = _bookTagRelations
        .where((r) => r.tagId == tagId)
        .map((r) => r.bookId);
    return bookIds.map((id) => _books[id]).whereType<Book>().toList();
  }

  /// Get book count for a tag.
  int getBookCountForTag(String tagId) {
    return _bookTagRelations.where((r) => r.tagId == tagId).length;
  }

  // ============================================================
  // Series CRUD
  // ============================================================

  Series? getSeries(String id) => _series[id];

  void addSeries(Series series) {
    _series[series.id] = series;
    notifyListeners();
  }

  void updateSeries(Series series) {
    _series[series.id] = series;
    notifyListeners();
  }

  void deleteSeries(String id) {
    _series.remove(id);
    // Set seriesId to null for books in this series
    for (final book in _books.values.where((b) => b.seriesId == id)) {
      _books[book.id] = book.copyWith(seriesId: null, seriesNumber: null);
    }
    notifyListeners();
  }

  /// Get all books in a series.
  List<Book> getBooksInSeries(String seriesId) {
    return _books.values.where((b) => b.seriesId == seriesId).toList()
      ..sort((a, b) => (a.seriesNumber ?? 0).compareTo(b.seriesNumber ?? 0));
  }

  // ============================================================
  // Annotation CRUD
  // ============================================================

  Annotation? getAnnotation(String id) => _annotations[id];

  List<Annotation> getAnnotationsForBook(String bookId) {
    return _annotations.values.where((a) => a.bookId == bookId).toList();
  }

  void addAnnotation(Annotation annotation) {
    _annotations[annotation.id] = annotation;
    notifyListeners();
  }

  void updateAnnotation(Annotation annotation) {
    _annotations[annotation.id] = annotation;
    notifyListeners();
  }

  void deleteAnnotation(String id) {
    _annotations.remove(id);
    notifyListeners();
  }

  // ============================================================
  // Note CRUD
  // ============================================================

  Note? getNote(String id) => _notes[id];

  List<Note> getNotesForBook(String bookId) {
    return _notes.values.where((n) => n.bookId == bookId).toList();
  }

  void addNote(Note note) {
    _notes[note.id] = note;
    notifyListeners();
  }

  void updateNote(Note note) {
    _notes[note.id] = note;
    notifyListeners();
  }

  void deleteNote(String id) {
    _notes.remove(id);
    notifyListeners();
  }

  // ============================================================
  // Bookmark CRUD
  // ============================================================

  Bookmark? getBookmark(String id) => _bookmarks[id];

  List<Bookmark> getBookmarksForBook(String bookId) {
    return _bookmarks.values.where((b) => b.bookId == bookId).toList();
  }

  void addBookmark(Bookmark bookmark) {
    _bookmarks[bookmark.id] = bookmark;
    notifyListeners();
  }

  void updateBookmark(Bookmark bookmark) {
    _bookmarks[bookmark.id] = bookmark;
    notifyListeners();
  }

  void deleteBookmark(String id) {
    _bookmarks.remove(id);
    notifyListeners();
  }

  // ============================================================
  // Reading Session CRUD
  // ============================================================

  ReadingSession? getReadingSession(String id) => _readingSessions[id];

  List<ReadingSession> getReadingSessionsForBook(String bookId) {
    return _readingSessions.values.where((s) => s.bookId == bookId).toList();
  }

  List<ReadingSession> getReadingSessionsInRange(DateTime start, DateTime end) {
    return _readingSessions.values
        .where(
          (s) =>
              s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
              s.startTime.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  void addReadingSession(ReadingSession session) {
    _readingSessions[session.id] = session;
    notifyListeners();
  }

  void updateReadingSession(ReadingSession session) {
    _readingSessions[session.id] = session;
    notifyListeners();
  }

  void deleteReadingSession(String id) {
    _readingSessions.remove(id);
    notifyListeners();
  }

  // ============================================================
  // Reading Goal CRUD
  // ============================================================

  ReadingGoal? getReadingGoal(String id) => _readingGoals[id];

  List<ReadingGoal> get activeGoals {
    return _readingGoals.values
        .where((g) => g.isActive && !g.isArchived)
        .toList();
  }

  List<ReadingGoal> get completedGoals {
    return _readingGoals.values.where((g) => g.isArchived).toList();
  }

  void addReadingGoal(ReadingGoal goal) {
    _readingGoals[goal.id] = goal;
    notifyListeners();
  }

  void updateReadingGoal(ReadingGoal goal) {
    _readingGoals[goal.id] = goal;
    notifyListeners();
  }

  void deleteReadingGoal(String id) {
    _readingGoals.remove(id);
    notifyListeners();
  }

  // ============================================================
  // Book-Shelf Relations
  // ============================================================

  void addBookToShelf(String bookId, String shelfId) {
    final exists = _bookShelfRelations.any(
      (r) => r.bookId == bookId && r.shelfId == shelfId,
    );
    if (!exists) {
      _bookShelfRelations.add(
        BookShelfRelation(
          bookId: bookId,
          shelfId: shelfId,
          addedAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void removeBookFromShelf(String bookId, String shelfId) {
    _bookShelfRelations.removeWhere(
      (r) => r.bookId == bookId && r.shelfId == shelfId,
    );
    notifyListeners();
  }

  List<String> getShelfIdsForBook(String bookId) {
    return _bookShelfRelations
        .where((r) => r.bookId == bookId)
        .map((r) => r.shelfId)
        .toList();
  }

  List<Shelf> getShelvesForBook(String bookId) {
    final shelfIds = getShelfIdsForBook(bookId);
    return shelfIds.map((id) => getShelf(id)).whereType<Shelf>().toList();
  }

  // ============================================================
  // Book-Tag Relations
  // ============================================================

  void addTagToBook(String bookId, String tagId) {
    final exists = _bookTagRelations.any(
      (r) => r.bookId == bookId && r.tagId == tagId,
    );
    if (!exists) {
      _bookTagRelations.add(
        BookTagRelation(
          bookId: bookId,
          tagId: tagId,
          createdAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void removeTagFromBook(String bookId, String tagId) {
    _bookTagRelations.removeWhere(
      (r) => r.bookId == bookId && r.tagId == tagId,
    );
    notifyListeners();
  }

  List<String> getTagIdsForBook(String bookId) {
    return _bookTagRelations
        .where((r) => r.bookId == bookId)
        .map((r) => r.tagId)
        .toList();
  }

  List<Tag> getTagsForBook(String bookId) {
    final tagIds = getTagIdsForBook(bookId);
    return tagIds.map((id) => _tags[id]).whereType<Tag>().toList();
  }

  // ============================================================
  // Batch loading for initialization
  // ============================================================

  void loadData({
    List<Book>? books,
    List<Shelf>? shelves,
    List<Tag>? tags,
    List<Series>? series,
    List<Annotation>? annotations,
    List<Note>? notes,
    List<Bookmark>? bookmarks,
    List<ReadingSession>? readingSessions,
    List<ReadingGoal>? readingGoals,
    List<BookShelfRelation>? bookShelfRelations,
    List<BookTagRelation>? bookTagRelations,
  }) {
    if (books != null) {
      _books.clear();
      for (final book in books) {
        _books[book.id] = book;
      }
    }
    if (shelves != null) {
      _shelves.clear();
      for (final shelf in shelves) {
        _shelves[shelf.id] = shelf;
      }
    }
    if (tags != null) {
      _tags.clear();
      for (final tag in tags) {
        _tags[tag.id] = tag;
      }
    }
    if (series != null) {
      _series.clear();
      for (final s in series) {
        _series[s.id] = s;
      }
    }
    if (annotations != null) {
      _annotations.clear();
      for (final annotation in annotations) {
        _annotations[annotation.id] = annotation;
      }
    }
    if (notes != null) {
      _notes.clear();
      for (final note in notes) {
        _notes[note.id] = note;
      }
    }
    if (bookmarks != null) {
      _bookmarks.clear();
      for (final bookmark in bookmarks) {
        _bookmarks[bookmark.id] = bookmark;
      }
    }
    if (readingSessions != null) {
      _readingSessions.clear();
      for (final session in readingSessions) {
        _readingSessions[session.id] = session;
      }
    }
    if (readingGoals != null) {
      _readingGoals.clear();
      for (final goal in readingGoals) {
        _readingGoals[goal.id] = goal;
      }
    }
    if (bookShelfRelations != null) {
      _bookShelfRelations.clear();
      _bookShelfRelations.addAll(bookShelfRelations);
    }
    if (bookTagRelations != null) {
      _bookTagRelations.clear();
      _bookTagRelations.addAll(bookTagRelations);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Clear all data.
  void clear() {
    _books.clear();
    _shelves.clear();
    _tags.clear();
    _series.clear();
    _annotations.clear();
    _notes.clear();
    _bookmarks.clear();
    _readingSessions.clear();
    _readingGoals.clear();
    _bookShelfRelations.clear();
    _bookTagRelations.clear();
    _isLoaded = false;
    notifyListeners();
  }
}
