import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:papyrus/data/repositories/book_repository.dart';
import 'package:papyrus/data/repositories/library_repository.dart';
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
  DataStore({BookRepository? bookRepository}) {
    final repository = bookRepository ?? InMemoryBookRepository();
    _bookRepository = repository;
    _listenRepository(repository);
  }

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
  BookRepository? _bookRepository;
  StreamSubscription<List<Book>>? _bookSubscription;
  StreamSubscription<LibrarySnapshot>? _librarySubscription;

  LibraryRepository? get libraryRepository {
    final repository = _bookRepository;
    return repository is LibraryRepository ? repository as LibraryRepository : null;
  }

  void _listenRepository(BookRepository repository) {
    if (repository is LibraryRepository) {
      _librarySubscription = (repository as LibraryRepository).watchLibrary().listen(
        _replaceLibrary,
        onError: (Object error, StackTrace stack) =>
            FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'papyrus library')),
      );
    } else {
      _bookSubscription = repository.watchAll().listen(replaceBooksFromSync);
    }
  }

  void _replaceLibrary(LibrarySnapshot snapshot) {
    _shelves
      ..clear()
      ..addEntries(snapshot.shelves.map((value) => MapEntry(value.id, value)));
    _tags
      ..clear()
      ..addEntries(snapshot.tags.map((value) => MapEntry(value.id, value)));
    _notes
      ..clear()
      ..addEntries(snapshot.notes.map((value) => MapEntry(value.id, value)));
    _annotations
      ..clear()
      ..addEntries(snapshot.annotations.map((value) => MapEntry(value.id, value)));
    _bookmarks
      ..clear()
      ..addEntries(snapshot.bookmarks.map((value) => MapEntry(value.id, value)));
    _bookShelfRelations
      ..clear()
      ..addAll(snapshot.bookShelves);
    _bookTagRelations
      ..clear()
      ..addAll(snapshot.bookTags);
    if (snapshot.books.isEmpty) {
      _series.clear();
      _readingGoals.clear();
    }
    replaceBooksFromSync(snapshot.books);
  }

  // ============================================================
  // Getters for read access
  // ============================================================

  bool get isLoaded => _isLoaded;

  /// Completes when the active book repository has emitted its first snapshot.
  ///
  /// A direct repository lookup may temporarily return null while persistent
  /// storage is still opening. Callers should wait for this before treating a
  /// missing ID as authoritative.
  Future<void> waitUntilLoaded() {
    if (_isLoaded) return Future<void>.value();

    final completer = Completer<void>();
    late VoidCallback listener;
    listener = () {
      if (!_isLoaded || completer.isCompleted) return;
      removeListener(listener);
      completer.complete();
    };

    addListener(listener);
    // Close the gap if loading completed between the initial check and listener
    // registration.
    listener();
    return completer.future;
  }

  List<Book> get books => _books.values.toList();

  /// Get all shelves with computed bookCount and coverPreviews.
  List<Shelf> get shelves => _shelves.values.map((shelf) {
    final bookCount = getBookCountForShelf(shelf.id);
    final coverPreviews = getCoverPreviewsForShelf(shelf.id);
    return shelf.copyWith(bookCount: bookCount, coverPreviews: coverPreviews);
  }).toList();

  List<Tag> get tags => _tags.values.toList();
  List<Series> get seriesList => _series.values.toList();
  List<Annotation> get annotations => _annotations.values.toList();
  List<Note> get notes => _notes.values.toList();
  List<Bookmark> get bookmarks => _bookmarks.values.toList();
  List<ReadingSession> get readingSessions => _readingSessions.values.toList();
  List<ReadingGoal> get readingGoals => _readingGoals.values.toList();
  List<BookShelfRelation> get bookShelfRelations => List.unmodifiable(_bookShelfRelations);
  List<BookTagRelation> get bookTagRelations => List.unmodifiable(_bookTagRelations);

  // ============================================================
  // Book CRUD
  // ============================================================

  Book? getBook(String id) => _books[id];

  Future<void> attachBookRepository(BookRepository repository) async {
    final wasLoaded = _isLoaded;
    _isLoaded = false;
    if (wasLoaded) notifyListeners();
    await _bookSubscription?.cancel();
    await _librarySubscription?.cancel();
    clear();
    _bookRepository = repository;
    _listenRepository(repository);
  }

  Future<void> disposeBookRepository() async {
    await _bookSubscription?.cancel();
    await _librarySubscription?.cancel();
    _bookSubscription = null;
    _bookRepository = null;
  }

  BookRepository requireBookRepository() {
    final repository = _bookRepository;
    if (repository == null) {
      throw StateError('Book repository is not initialized');
    }
    return repository is LibraryRepository ? (repository as LibraryRepository).scopedBooks : repository;
  }

  bool isBookRepositoryCurrent(BookRepository repository) =>
      repository is EditableBookRepository ? repository.isCurrent : identical(_bookRepository, repository);

  void addBook(Book book) {
    final repository = requireBookRepository();
    _books[book.id] = book;
    notifyListeners();
    _reportWrite(repository.upsert(book));
  }

  Future<void> addBookAndWait(Book book) async {
    final repository = requireBookRepository();
    await addBookToRepositoryAndWait(repository, book);
  }

  Future<void> addBookToRepositoryAndWait(BookRepository repository, Book book) async {
    await repository.upsert(book);
    if (isBookRepositoryCurrent(repository) && !identical(_books[book.id], book)) {
      _books[book.id] = book;
      notifyListeners();
    }
  }

  void updateBook(Book book) {
    final repository = requireBookRepository();
    final previous = _books[book.id];
    _books[book.id] = book;
    notifyListeners();
    _reportWrite(
      repository is EditableBookRepository && previous != null
          ? repository.update(book, previous: previous)
          : repository.upsert(book),
    );
  }

  void _reportWrite(Future<void> operation) {
    unawaited(
      operation.catchError((Object error, StackTrace stack) {
        FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'papyrus library write'));
      }),
    );
  }

  Future<void> updateBookAndWait(Book book, {Book? previous, BookRepository? repository}) async {
    final target = repository ?? requireBookRepository();
    final baseline = previous ?? _books[book.id];
    if (target is EditableBookRepository && baseline != null) {
      await target.update(book, previous: baseline);
      final saved = await target.getById(book.id);
      if (target.isCurrent && saved != null) {
        _books[book.id] = saved;
        notifyListeners();
      }
    } else {
      await addBookToRepositoryAndWait(target, book);
    }
  }

  Future<void> _saveEntity<T>(
    EntityRepository<T>? repository,
    T value,
    String id,
    T? previous,
    void Function(T) apply,
  ) {
    if (repository == null) {
      apply(value);
      notifyListeners();
      return Future.value();
    }
    final scope = requireBookRepository();
    return (() async {
      await repository.upsert(value, previous: previous);
      final saved = await repository.getById(id);
      if (isBookRepositoryCurrent(scope) && saved != null) {
        apply(saved);
        notifyListeners();
      }
    })();
  }

  Future<void> _deleteEntity<T>(EntityRepository<T>? repository, String id, void Function() apply) {
    if (repository == null) {
      apply();
      notifyListeners();
      return Future.value();
    }
    final scope = requireBookRepository();
    return (() async {
      await repository.delete(id);
      if (isBookRepositoryCurrent(scope)) {
        apply();
        notifyListeners();
      }
    })();
  }

  void deleteBook(String id) {
    final repository = requireBookRepository();
    _reportWrite(repository.delete(id));
  }

  Future<void> deleteBookAndWait(String id) async {
    final repository = requireBookRepository();
    await deleteBookFromRepositoryAndWait(repository, id);
  }

  Future<void> deleteBookFromRepositoryAndWait(BookRepository repository, String id) async {
    await repository.delete(id);
    if (isBookRepositoryCurrent(repository) && _books.remove(id) != null) {
      notifyListeners();
    }
  }

  void replaceBooksFromSync(List<Book> books) {
    final mergedBooks = books
        .map((book) {
          final localBook = _books[book.id];
          if (libraryRepository == null && book.coverMediaId == null && localBook?.coverMediaId != null) {
            // PowerSync can briefly emit the downloaded server row before its
            // pending local media-reference update is acknowledged. Keep the
            // established local reference through that transient null snapshot.
            return book.copyWith(coverMediaId: localBook!.coverMediaId);
          }
          return book;
        })
        .toList(growable: false);
    final syncedIds = mergedBooks.map((book) => book.id).toSet();
    _books
      ..clear()
      ..addEntries(mergedBooks.map((book) => MapEntry(book.id, book)));
    _bookShelfRelations.removeWhere((relation) => !syncedIds.contains(relation.bookId));
    _bookTagRelations.removeWhere((relation) => !syncedIds.contains(relation.bookId));
    _annotations.removeWhere((key, annotation) => !syncedIds.contains(annotation.bookId));
    _notes.removeWhere((key, note) => !syncedIds.contains(note.bookId));
    _bookmarks.removeWhere((key, bookmark) => !syncedIds.contains(bookmark.bookId));
    _readingSessions.removeWhere((key, session) => !syncedIds.contains(session.bookId));
    _isLoaded = true;
    notifyListeners();
  }

  // ============================================================
  // Shelf CRUD
  // ============================================================

  /// Get a shelf by ID with computed bookCount and coverPreviews.
  Shelf? getShelf(String id) {
    final shelf = _shelves[id];
    if (shelf == null) return null;
    return shelf.copyWith(bookCount: getBookCountForShelf(id), coverPreviews: getCoverPreviewsForShelf(id));
  }

  Future<void> addShelf(Shelf shelf, {Shelf? previous, EntityRepository<Shelf>? repository}) => _saveEntity(
    repository ?? libraryRepository?.shelves,
    shelf,
    shelf.id,
    previous,
    (saved) => _shelves[shelf.id] = saved,
  );

  Future<void> updateShelf(Shelf shelf, {Shelf? previous, EntityRepository<Shelf>? repository}) => _saveEntity(
    repository ?? libraryRepository?.shelves,
    shelf,
    shelf.id,
    previous ?? _shelves[shelf.id],
    (saved) => _shelves[shelf.id] = saved,
  );

  Future<void> deleteShelf(String id, {EntityRepository<Shelf>? repository}) =>
      _deleteEntity(repository ?? libraryRepository?.shelves, id, () {
        _shelves.remove(id);
        _bookShelfRelations.removeWhere((r) => r.shelfId == id);
      });

  /// Get all books in a shelf.
  List<Book> getBooksInShelf(String shelfId) {
    final bookIds = _bookShelfRelations.where((r) => r.shelfId == shelfId).map((r) => r.bookId);
    return bookIds.map((id) => _books[id]).whereType<Book>().toList();
  }

  /// Get book count for a shelf.
  int getBookCountForShelf(String shelfId) {
    return _bookShelfRelations.where((r) => r.shelfId == shelfId).length;
  }

  /// Get child shelves of a parent shelf, enriched with bookCount/coverPreviews.
  List<Shelf> getChildShelves(String parentShelfId) {
    return _shelves.values
        .where((s) => s.parentShelfId == parentShelfId)
        .map(
          (shelf) => shelf.copyWith(
            bookCount: getBookCountForShelf(shelf.id),
            coverPreviews: getCoverPreviewsForShelf(shelf.id),
          ),
        )
        .toList();
  }

  /// Get cover previews for a shelf (up to 4 books).
  List<CoverPreview> getCoverPreviewsForShelf(String shelfId, {int limit = 4}) {
    final books = getBooksInShelf(shelfId);
    return books
        .take(limit)
        .map((b) => CoverPreview(bookId: b.id, url: b.coverUrl, mediaId: b.coverMediaId, title: b.title))
        .toList();
  }

  // ============================================================
  // Tag CRUD
  // ============================================================

  Tag? getTag(String id) => _tags[id];

  Future<void> addTag(Tag tag, {Tag? previous, EntityRepository<Tag>? repository}) =>
      _saveEntity(repository ?? libraryRepository?.tags, tag, tag.id, previous, (saved) => _tags[tag.id] = saved);

  Future<void> updateTag(Tag tag, {Tag? previous, EntityRepository<Tag>? repository}) => _saveEntity(
    repository ?? libraryRepository?.tags,
    tag,
    tag.id,
    previous ?? _tags[tag.id],
    (saved) => _tags[tag.id] = saved,
  );

  Future<void> deleteTag(String id, {EntityRepository<Tag>? repository}) =>
      _deleteEntity(repository ?? libraryRepository?.tags, id, () {
        _tags.remove(id);
        _bookTagRelations.removeWhere((r) => r.tagId == id);
      });

  /// Get all books with a tag.
  List<Book> getBooksWithTag(String tagId) {
    final bookIds = _bookTagRelations.where((r) => r.tagId == tagId).map((r) => r.bookId);
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

  Future<void> addAnnotation(Annotation annotation, {Annotation? previous, EntityRepository<Annotation>? repository}) =>
      _saveEntity(
        repository ?? libraryRepository?.annotations,
        annotation,
        annotation.id,
        previous,
        (saved) => _annotations[annotation.id] = saved,
      );

  Future<void> updateAnnotation(
    Annotation annotation, {
    Annotation? previous,
    EntityRepository<Annotation>? repository,
  }) => _saveEntity(
    repository ?? libraryRepository?.annotations,
    annotation,
    annotation.id,
    previous ?? _annotations[annotation.id],
    (saved) => _annotations[annotation.id] = saved,
  );

  Future<void> deleteAnnotation(String id, {EntityRepository<Annotation>? repository}) =>
      _deleteEntity(repository ?? libraryRepository?.annotations, id, () {
        _annotations.remove(id);
      });

  // ============================================================
  // Note CRUD
  // ============================================================

  Note? getNote(String id) => _notes[id];

  List<Note> getNotesForBook(String bookId) {
    return _notes.values.where((n) => n.bookId == bookId).toList();
  }

  Future<void> addNote(Note note, {Note? previous, EntityRepository<Note>? repository}) =>
      _saveEntity(repository ?? libraryRepository?.notes, note, note.id, previous, (saved) => _notes[note.id] = saved);

  Future<void> updateNote(Note note, {Note? previous, EntityRepository<Note>? repository}) => _saveEntity(
    repository ?? libraryRepository?.notes,
    note,
    note.id,
    previous ?? _notes[note.id],
    (saved) => _notes[note.id] = saved,
  );

  Future<void> deleteNote(String id, {EntityRepository<Note>? repository}) =>
      _deleteEntity(repository ?? libraryRepository?.notes, id, () {
        _notes.remove(id);
      });

  // ============================================================
  // Bookmark CRUD
  // ============================================================

  Bookmark? getBookmark(String id) => _bookmarks[id];

  List<Bookmark> getBookmarksForBook(String bookId) {
    return _bookmarks.values.where((b) => b.bookId == bookId).toList();
  }

  Future<void> addBookmark(Bookmark bookmark, {Bookmark? previous, EntityRepository<Bookmark>? repository}) =>
      _saveEntity(
        repository ?? libraryRepository?.bookmarks,
        bookmark,
        bookmark.id,
        previous,
        (saved) => _bookmarks[bookmark.id] = saved,
      );

  Future<void> updateBookmark(Bookmark bookmark, {Bookmark? previous, EntityRepository<Bookmark>? repository}) =>
      _saveEntity(
        repository ?? libraryRepository?.bookmarks,
        bookmark,
        bookmark.id,
        previous ?? _bookmarks[bookmark.id],
        (saved) => _bookmarks[bookmark.id] = saved,
      );

  Future<void> deleteBookmark(String id, {EntityRepository<Bookmark>? repository}) =>
      _deleteEntity(repository ?? libraryRepository?.bookmarks, id, () {
        _bookmarks.remove(id);
      });

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
    return _readingGoals.values.where((g) => g.isActive && !g.isArchived).toList();
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

  Future<void> updateBookMemberships({
    required Set<String> bookIds,
    List<String>? shelfIds,
    List<String>? tagIds,
    Set<String>? previousShelfIds,
    Set<String>? previousTagIds,
    bool additive = false,
    LibraryMembershipWriter? repository,
  }) async {
    final target = repository ?? libraryRepository?.memberships;
    if (target != null) {
      await target.updateMemberships(
        bookIds: bookIds,
        shelfIds: shelfIds,
        tagIds: tagIds,
        previousShelfIds: previousShelfIds,
        previousTagIds: previousTagIds,
        additive: additive,
      );
      return;
    }
    for (final bookId in bookIds) {
      if (shelfIds != null) {
        if (!additive) {
          for (final id in (previousShelfIds ?? getShelfIdsForBook(bookId).toSet()).difference(shelfIds.toSet())) {
            await removeBookFromShelf(bookId, id);
          }
        }
        for (final id in shelfIds) {
          await addBookToShelf(bookId, id);
        }
      }
      if (tagIds != null) {
        if (!additive) {
          for (final id in (previousTagIds ?? getTagIdsForBook(bookId).toSet()).difference(tagIds.toSet())) {
            await removeTagFromBook(bookId, id);
          }
        }
        for (final id in tagIds) {
          await addTagToBook(bookId, id);
        }
      }
    }
  }

  Future<void> addBookToShelf(String bookId, String shelfId) {
    final exists = _bookShelfRelations.any((r) => r.bookId == bookId && r.shelfId == shelfId);
    if (exists) return Future.value();
    final relation = BookShelfRelation(bookId: bookId, shelfId: shelfId, addedAt: DateTime.now().toUtc());
    return _saveEntity<BookShelfRelation>(libraryRepository?.bookShelves, relation, '$bookId:$shelfId', null, (saved) {
      _bookShelfRelations.removeWhere((r) => r.bookId == bookId && r.shelfId == shelfId);
      _bookShelfRelations.add(saved);
    });
  }

  Future<void> removeBookFromShelf(String bookId, String shelfId) => _deleteEntity(
    libraryRepository?.bookShelves,
    '$bookId:$shelfId',
    () => _bookShelfRelations.removeWhere((r) => r.bookId == bookId && r.shelfId == shelfId),
  );

  List<String> getShelfIdsForBook(String bookId) {
    return _bookShelfRelations.where((r) => r.bookId == bookId).map((r) => r.shelfId).toList();
  }

  List<Shelf> getShelvesForBook(String bookId) {
    final shelfIds = getShelfIdsForBook(bookId);
    return shelfIds.map((id) => getShelf(id)).whereType<Shelf>().toList();
  }

  // ============================================================
  // Book-Tag Relations
  // ============================================================

  Future<void> addTagToBook(String bookId, String tagId) {
    final exists = _bookTagRelations.any((r) => r.bookId == bookId && r.tagId == tagId);
    if (exists) return Future.value();
    final relation = BookTagRelation(bookId: bookId, tagId: tagId, createdAt: DateTime.now().toUtc());
    return _saveEntity<BookTagRelation>(libraryRepository?.bookTags, relation, '$bookId:$tagId', null, (saved) {
      _bookTagRelations.removeWhere((r) => r.bookId == bookId && r.tagId == tagId);
      _bookTagRelations.add(saved);
    });
  }

  Future<void> removeTagFromBook(String bookId, String tagId) => _deleteEntity(
    libraryRepository?.bookTags,
    '$bookId:$tagId',
    () => _bookTagRelations.removeWhere((r) => r.bookId == bookId && r.tagId == tagId),
  );

  List<String> getTagIdsForBook(String bookId) {
    return _bookTagRelations.where((r) => r.bookId == bookId).map((r) => r.tagId).toList();
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
      final repository = _bookRepository;
      if (repository is InMemoryBookRepository) {
        repository.replaceAll(books);
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
