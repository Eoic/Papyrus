import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:provider/provider.dart';

/// Creates a [MaterialApp] wrapper with required providers for widget testing.
Widget createTestApp({
  required Widget child,
  LibraryProvider? libraryProvider,
  DataStore? dataStore,
  Size screenSize = const Size(400, 800),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LibraryProvider>.value(
        value: libraryProvider ?? LibraryProvider(),
      ),
      ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
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
Widget createTestPage({
  required Widget page,
  LibraryProvider? libraryProvider,
  DataStore? dataStore,
  Size screenSize = const Size(400, 800),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LibraryProvider>.value(
        value: libraryProvider ?? LibraryProvider(),
      ),
      ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
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
