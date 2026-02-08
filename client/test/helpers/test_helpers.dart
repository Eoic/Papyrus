import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Creates a [MaterialApp] wrapper with required providers for widget testing.
///
/// Pass [additionalProviders] to add providers beyond the default
/// [LibraryProvider] and [DataStore].
Widget createTestApp({
  required Widget child,
  LibraryProvider? libraryProvider,
  DataStore? dataStore,
  Size screenSize = const Size(400, 800),
  List<SingleChildWidget>? additionalProviders,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LibraryProvider>.value(
        value: libraryProvider ?? LibraryProvider(),
      ),
      ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
      ...?additionalProviders,
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Creates a [MaterialApp] wrapper with a custom builder for full-page tests.
///
/// Pass [additionalProviders] to add providers beyond the default
/// [LibraryProvider] and [DataStore].
Widget createTestPage({
  required Widget page,
  LibraryProvider? libraryProvider,
  DataStore? dataStore,
  Size screenSize = const Size(400, 800),
  List<SingleChildWidget>? additionalProviders,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LibraryProvider>.value(
        value: libraryProvider ?? LibraryProvider(),
      ),
      ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
      ...?additionalProviders,
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: page,
      ),
    ),
  );
}

/// Creates test books with various states for filtering tests.
List<Book> createTestBooks() {
  final now = DateTime.now();
  return [
    Book(
      id: 'book-1',
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      readingStatus: ReadingStatus.inProgress,
      currentPosition: 0.5,
      isFavorite: true,
      fileFormat: BookFormat.epub,
      addedAt: now,
    ),
    Book(
      id: 'book-2',
      title: 'Dune',
      author: 'Frank Herbert',
      readingStatus: ReadingStatus.completed,
      currentPosition: 1.0,
      isFavorite: false,
      fileFormat: BookFormat.pdf,
      addedAt: now,
    ),
    Book(
      id: 'book-3',
      title: '1984',
      author: 'George Orwell',
      readingStatus: ReadingStatus.notStarted,
      currentPosition: 0.0,
      isFavorite: false,
      fileFormat: BookFormat.mobi,
      addedAt: now,
    ),
    Book(
      id: 'book-4',
      title: 'Foundation',
      author: 'Isaac Asimov',
      readingStatus: ReadingStatus.notStarted,
      currentPosition: 0.0,
      isFavorite: true,
      isPhysical: true,
      addedAt: now,
    ),
    Book(
      id: 'book-5',
      title: 'Neuromancer',
      author: 'William Gibson',
      readingStatus: ReadingStatus.inProgress,
      currentPosition: 0.25,
      isFavorite: false,
      fileFormat: BookFormat.epub,
      addedAt: now,
    ),
  ];
}

/// Creates a [DataStore] pre-loaded with test data.
DataStore createTestDataStore({
  List<Book>? books,
  List<Shelf>? shelves,
  List<Tag>? tags,
}) {
  final now = DateTime.now();
  final store = DataStore();
  store.loadData(
    books: books ?? createTestBooks(),
    shelves:
        shelves ??
        [
          Shelf(id: 'shelf-1', name: 'Fiction', createdAt: now, updatedAt: now),
          Shelf(
            id: 'shelf-2',
            name: 'Science Fiction',
            createdAt: now,
            updatedAt: now,
          ),
        ],
    tags:
        tags ??
        [
          Tag(
            id: 'tag-1',
            name: 'Fantasy',
            colorHex: '#4CAF50',
            createdAt: now,
          ),
          Tag(
            id: 'tag-2',
            name: 'Classic',
            colorHex: '#2196F3',
            createdAt: now,
          ),
        ],
  );
  return store;
}

// ============================================================
// Test data builders
// ============================================================

int _nextId = 1;

/// Builds a [Book] with sensible defaults. Override only what you need.
Book buildTestBook({
  String? id,
  String title = 'Test Book',
  String author = 'Test Author',
  List<String> coAuthors = const [],
  ReadingStatus readingStatus = ReadingStatus.notStarted,
  double currentPosition = 0.0,
  int? currentPage,
  int? pageCount,
  bool isPhysical = false,
  bool isFavorite = false,
  BookFormat? fileFormat,
  String? coverUrl,
  String? description,
  String? seriesId,
  String? seriesName,
  double? seriesNumber,
  int? rating,
  DateTime? addedAt,
  DateTime? startedAt,
  DateTime? completedAt,
  DateTime? lastReadAt,
}) {
  return Book(
    id: id ?? 'book-${_nextId++}',
    title: title,
    author: author,
    coAuthors: coAuthors,
    readingStatus: readingStatus,
    currentPosition: currentPosition,
    currentPage: currentPage,
    pageCount: pageCount,
    isPhysical: isPhysical,
    isFavorite: isFavorite,
    fileFormat: fileFormat,
    coverUrl: coverUrl,
    description: description,
    seriesId: seriesId,
    seriesName: seriesName,
    seriesNumber: seriesNumber,
    rating: rating,
    addedAt: addedAt ?? DateTime(2025, 1, 1),
    startedAt: startedAt,
    completedAt: completedAt,
    lastReadAt: lastReadAt,
  );
}

/// Builds a [Bookmark] with sensible defaults.
Bookmark buildTestBookmark({
  String? id,
  String bookId = 'book-1',
  double position = 0.5,
  int? pageNumber,
  String? chapterTitle,
  String? note,
  String colorHex = '#FF5722',
  DateTime? createdAt,
}) {
  return Bookmark(
    id: id ?? 'bm-${_nextId++}',
    bookId: bookId,
    position: position,
    pageNumber: pageNumber,
    chapterTitle: chapterTitle,
    note: note,
    colorHex: colorHex,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
  );
}

/// Builds an [Annotation] with sensible defaults.
Annotation buildTestAnnotation({
  String? id,
  String bookId = 'book-1',
  String selectedText = 'Highlighted text',
  HighlightColor color = HighlightColor.yellow,
  BookLocation? location,
  String? note,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Annotation(
    id: id ?? 'ann-${_nextId++}',
    bookId: bookId,
    selectedText: selectedText,
    color: color,
    location: location ?? const BookLocation(pageNumber: 1),
    note: note,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    updatedAt: updatedAt,
  );
}

/// Builds a [Note] with sensible defaults.
Note buildTestNote({
  String? id,
  String bookId = 'book-1',
  String title = 'Test Note',
  String content = 'Test note content.',
  BookLocation? location,
  List<String> tags = const [],
  bool isPinned = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Note(
    id: id ?? 'note-${_nextId++}',
    bookId: bookId,
    title: title,
    content: content,
    location: location,
    tags: tags,
    isPinned: isPinned,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    updatedAt: updatedAt,
  );
}

/// Builds a [Shelf] with sensible defaults.
Shelf buildTestShelf({
  String? id,
  String name = 'Test Shelf',
  String? description,
  String? colorHex,
  int sortOrder = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = createdAt ?? DateTime(2025, 1, 1);
  return Shelf(
    id: id ?? 'shelf-${_nextId++}',
    name: name,
    description: description,
    colorHex: colorHex,
    sortOrder: sortOrder,
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

/// Builds a [Tag] with sensible defaults.
Tag buildTestTag({
  String? id,
  String name = 'Test Tag',
  String colorHex = '#4CAF50',
  String? description,
  DateTime? createdAt,
}) {
  return Tag(
    id: id ?? 'tag-${_nextId++}',
    name: name,
    colorHex: colorHex,
    description: description,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
  );
}
