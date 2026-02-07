import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/book_shelf_relation.dart';
import 'package:papyrus/models/book_tag_relation.dart';
import 'package:papyrus/models/search_filter.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';

void main() {
  final now = DateTime.now();

  Book makeBook({
    String id = 'book-1',
    String title = 'The Hobbit',
    String author = 'J.R.R. Tolkien',
    bool isPhysical = false,
    BookFormat? fileFormat = BookFormat.epub,
    ReadingStatus readingStatus = ReadingStatus.notStarted,
    double currentPosition = 0.0,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      isPhysical: isPhysical,
      fileFormat: fileFormat,
      readingStatus: readingStatus,
      currentPosition: currentPosition,
      addedAt: now,
    );
  }

  DataStore buildDataStore({
    required List<Book> books,
    List<Shelf>? shelves,
    List<Tag>? tags,
    List<BookShelfRelation>? bookShelfRelations,
    List<BookTagRelation>? bookTagRelations,
  }) {
    final store = DataStore();
    store.loadData(
      books: books,
      shelves: shelves ?? [],
      tags: tags ?? [],
      bookShelfRelations: bookShelfRelations ?? [],
      bookTagRelations: bookTagRelations ?? [],
    );
    return store;
  }

  group('SearchFilter', () {
    group('SearchField.title', () {
      test('contains matches substring', () {
        final filter = SearchFilter(
          field: SearchField.title,
          operator: SearchOperator.contains,
          value: 'Hobbit',
        );
        expect(filter.matches(makeBook()), true);
        expect(filter.matches(makeBook(title: 'Dune')), false);
      });

      test('equals matches exact value (case-insensitive)', () {
        final filter = SearchFilter(
          field: SearchField.title,
          operator: SearchOperator.equals,
          value: 'the hobbit',
        );
        expect(filter.matches(makeBook()), true);
        expect(filter.matches(makeBook(title: 'The Hobbit Part 2')), false);
      });

      test('notEquals excludes matching value', () {
        final filter = SearchFilter(
          field: SearchField.title,
          operator: SearchOperator.notEquals,
          value: 'The Hobbit',
        );
        expect(filter.matches(makeBook()), false);
        expect(filter.matches(makeBook(title: 'Dune')), true);
      });
    });

    group('SearchField.author', () {
      test('contains matches author name', () {
        final filter = SearchFilter(
          field: SearchField.author,
          operator: SearchOperator.contains,
          value: 'Tolkien',
        );
        expect(filter.matches(makeBook()), true);
        expect(filter.matches(makeBook(author: 'Frank Herbert')), false);
      });
    });

    group('SearchField.format', () {
      test('equals matches format label', () {
        final filter = SearchFilter(
          field: SearchField.format,
          operator: SearchOperator.equals,
          value: 'epub',
        );
        expect(filter.matches(makeBook(fileFormat: BookFormat.epub)), true);
        expect(filter.matches(makeBook(fileFormat: BookFormat.pdf)), false);
      });

      test('matches physical books', () {
        final filter = SearchFilter(
          field: SearchField.format,
          operator: SearchOperator.equals,
          value: 'physical',
        );
        expect(filter.matches(makeBook(isPhysical: true)), true);
        expect(filter.matches(makeBook(isPhysical: false)), false);
      });
    });

    group('SearchField.status', () {
      test('matches reading status', () {
        final filter = SearchFilter(
          field: SearchField.status,
          operator: SearchOperator.equals,
          value: 'reading',
        );
        expect(
          filter.matches(makeBook(readingStatus: ReadingStatus.inProgress)),
          true,
        );
        expect(
          filter.matches(makeBook(readingStatus: ReadingStatus.notStarted)),
          false,
        );
      });

      test('matches finished status', () {
        final filter = SearchFilter(
          field: SearchField.status,
          operator: SearchOperator.equals,
          value: 'finished',
        );
        expect(
          filter.matches(makeBook(readingStatus: ReadingStatus.completed)),
          true,
        );
      });

      test('matches unread status', () {
        final filter = SearchFilter(
          field: SearchField.status,
          operator: SearchOperator.equals,
          value: 'unread',
        );
        expect(
          filter.matches(
            makeBook(
              readingStatus: ReadingStatus.notStarted,
              currentPosition: 0.0,
            ),
          ),
          true,
        );
      });
    });

    group('SearchField.progress', () {
      test('greaterThan compares numerically', () {
        final filter = SearchFilter(
          field: SearchField.progress,
          operator: SearchOperator.greaterThan,
          value: '50',
        );
        expect(filter.matches(makeBook(currentPosition: 0.75)), true);
        expect(filter.matches(makeBook(currentPosition: 0.25)), false);
      });

      test('lessThan compares numerically', () {
        final filter = SearchFilter(
          field: SearchField.progress,
          operator: SearchOperator.lessThan,
          value: '50',
        );
        expect(filter.matches(makeBook(currentPosition: 0.25)), true);
        expect(filter.matches(makeBook(currentPosition: 0.75)), false);
      });

      test('greaterThan returns false for non-numeric value', () {
        final filter = SearchFilter(
          field: SearchField.progress,
          operator: SearchOperator.greaterThan,
          value: 'abc',
        );
        expect(filter.matches(makeBook(currentPosition: 0.5)), false);
      });
    });

    group('SearchField.any', () {
      test('matches title or author', () {
        final filter = SearchFilter(
          field: SearchField.any,
          operator: SearchOperator.contains,
          value: 'Tolkien',
        );
        expect(filter.matches(makeBook()), true);
      });

      test('matches title in combined field', () {
        final filter = SearchFilter(
          field: SearchField.any,
          operator: SearchOperator.contains,
          value: 'Hobbit',
        );
        expect(filter.matches(makeBook()), true);
      });
    });

    group('SearchField.shelf with DataStore', () {
      test('matches book on shelf via junction table', () {
        final book = makeBook(id: 'b1');
        final shelf = Shelf(
          id: 's1',
          name: 'Fiction',
          createdAt: now,
          updatedAt: now,
        );
        final dataStore = buildDataStore(
          books: [book],
          shelves: [shelf],
          bookShelfRelations: [
            BookShelfRelation(bookId: 'b1', shelfId: 's1', addedAt: now),
          ],
        );

        final filter = SearchFilter(
          field: SearchField.shelf,
          operator: SearchOperator.contains,
          value: 'Fiction',
        );
        expect(filter.matches(book, dataStore: dataStore), true);
      });

      test('does not match book not on shelf', () {
        final book = makeBook(id: 'b1');
        final shelf = Shelf(
          id: 's1',
          name: 'Fiction',
          createdAt: now,
          updatedAt: now,
        );
        final dataStore = buildDataStore(
          books: [book],
          shelves: [shelf],
          // No relation
        );

        final filter = SearchFilter(
          field: SearchField.shelf,
          operator: SearchOperator.contains,
          value: 'Fiction',
        );
        expect(filter.matches(book, dataStore: dataStore), false);
      });

      test('matches book on multiple shelves', () {
        final book = makeBook(id: 'b1');
        final shelves = [
          Shelf(id: 's1', name: 'Fiction', createdAt: now, updatedAt: now),
          Shelf(id: 's2', name: 'Favorites', createdAt: now, updatedAt: now),
        ];
        final dataStore = buildDataStore(
          books: [book],
          shelves: shelves,
          bookShelfRelations: [
            BookShelfRelation(bookId: 'b1', shelfId: 's1', addedAt: now),
            BookShelfRelation(bookId: 'b1', shelfId: 's2', addedAt: now),
          ],
        );

        final fictionFilter = SearchFilter(
          field: SearchField.shelf,
          operator: SearchOperator.contains,
          value: 'Fiction',
        );
        final favFilter = SearchFilter(
          field: SearchField.shelf,
          operator: SearchOperator.contains,
          value: 'Favorites',
        );
        expect(fictionFilter.matches(book, dataStore: dataStore), true);
        expect(favFilter.matches(book, dataStore: dataStore), true);
      });
    });

    group('SearchField.shelf without DataStore (fallback)', () {
      test('falls back to book.shelves (empty list)', () {
        final book = makeBook();
        final filter = SearchFilter(
          field: SearchField.shelf,
          operator: SearchOperator.contains,
          value: 'Fiction',
        );
        // book.shelves returns const [], so no match
        expect(filter.matches(book), false);
      });
    });

    group('SearchField.topic with DataStore', () {
      test('matches book with tag via junction table', () {
        final book = makeBook(id: 'b1');
        final tag = Tag(
          id: 't1',
          name: 'Science',
          colorHex: '#FF0000',
          createdAt: now,
        );
        final dataStore = buildDataStore(
          books: [book],
          tags: [tag],
          bookTagRelations: [
            BookTagRelation(bookId: 'b1', tagId: 't1', createdAt: now),
          ],
        );

        final filter = SearchFilter(
          field: SearchField.topic,
          operator: SearchOperator.contains,
          value: 'Science',
        );
        expect(filter.matches(book, dataStore: dataStore), true);
      });

      test('does not match book without tag', () {
        final book = makeBook(id: 'b1');
        final tag = Tag(
          id: 't1',
          name: 'Science',
          colorHex: '#FF0000',
          createdAt: now,
        );
        final dataStore = buildDataStore(
          books: [book],
          tags: [tag],
          // No relation
        );

        final filter = SearchFilter(
          field: SearchField.topic,
          operator: SearchOperator.contains,
          value: 'Science',
        );
        expect(filter.matches(book, dataStore: dataStore), false);
      });
    });

    group('SearchField.topic without DataStore (fallback)', () {
      test('falls back to book.topics (empty list)', () {
        final book = makeBook();
        final filter = SearchFilter(
          field: SearchField.topic,
          operator: SearchOperator.contains,
          value: 'Science',
        );
        expect(filter.matches(book), false);
      });
    });
  });

  group('SearchQuery', () {
    group('AND logic', () {
      test('matches when all filters pass', () {
        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.title,
              operator: SearchOperator.contains,
              value: 'Hobbit',
            ),
            SearchFilter(
              field: SearchField.author,
              operator: SearchOperator.contains,
              value: 'Tolkien',
            ),
          ],
          operators: [LogicalOperator.and],
        );
        expect(query.matches(makeBook()), true);
      });

      test('fails when one filter does not match', () {
        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.title,
              operator: SearchOperator.contains,
              value: 'Hobbit',
            ),
            SearchFilter(
              field: SearchField.author,
              operator: SearchOperator.contains,
              value: 'Herbert',
            ),
          ],
          operators: [LogicalOperator.and],
        );
        expect(query.matches(makeBook()), false);
      });
    });

    group('OR logic', () {
      test('matches when at least one filter passes', () {
        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.title,
              operator: SearchOperator.contains,
              value: 'Dune',
            ),
            SearchFilter(
              field: SearchField.author,
              operator: SearchOperator.contains,
              value: 'Tolkien',
            ),
          ],
          operators: [LogicalOperator.or],
        );
        expect(query.matches(makeBook()), true);
      });

      test('fails when no filter matches', () {
        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.title,
              operator: SearchOperator.contains,
              value: 'Dune',
            ),
            SearchFilter(
              field: SearchField.author,
              operator: SearchOperator.contains,
              value: 'Herbert',
            ),
          ],
          operators: [LogicalOperator.or],
        );
        expect(query.matches(makeBook()), false);
      });
    });

    group('NOT filters', () {
      test('excludes book when NOT filter matches', () {
        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.any,
              operator: SearchOperator.contains,
              value: 'Hobbit',
            ),
          ],
          notFilters: [
            SearchFilter(
              field: SearchField.author,
              operator: SearchOperator.contains,
              value: 'Tolkien',
            ),
          ],
        );
        expect(query.matches(makeBook()), false);
      });

      test('includes book when NOT filter does not match', () {
        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.any,
              operator: SearchOperator.contains,
              value: 'Hobbit',
            ),
          ],
          notFilters: [
            SearchFilter(
              field: SearchField.author,
              operator: SearchOperator.contains,
              value: 'Herbert',
            ),
          ],
        );
        expect(query.matches(makeBook()), true);
      });
    });

    group('DataStore passthrough', () {
      test('passes dataStore to shelf filter in query', () {
        final book = makeBook(id: 'b1');
        final shelf = Shelf(
          id: 's1',
          name: 'Fiction',
          createdAt: now,
          updatedAt: now,
        );
        final dataStore = buildDataStore(
          books: [book],
          shelves: [shelf],
          bookShelfRelations: [
            BookShelfRelation(bookId: 'b1', shelfId: 's1', addedAt: now),
          ],
        );

        final query = SearchQuery(
          filters: [
            SearchFilter(
              field: SearchField.shelf,
              operator: SearchOperator.contains,
              value: 'Fiction',
            ),
          ],
        );
        expect(query.matches(book, dataStore: dataStore), true);
      });

      test('passes dataStore to NOT filter', () {
        final book = makeBook(id: 'b1');
        final shelf = Shelf(
          id: 's1',
          name: 'Fiction',
          createdAt: now,
          updatedAt: now,
        );
        final dataStore = buildDataStore(
          books: [book],
          shelves: [shelf],
          bookShelfRelations: [
            BookShelfRelation(bookId: 'b1', shelfId: 's1', addedAt: now),
          ],
        );

        final query = SearchQuery(
          filters: [],
          notFilters: [
            SearchFilter(
              field: SearchField.shelf,
              operator: SearchOperator.contains,
              value: 'Fiction',
            ),
          ],
        );
        // Book IS on Fiction shelf, so NOT filter excludes it
        expect(query.matches(book, dataStore: dataStore), false);
      });
    });

    group('empty query', () {
      test('empty query matches any book', () {
        const query = SearchQuery();
        expect(query.matches(makeBook()), true);
        expect(query.isEmpty, true);
      });
    });
  });
}
