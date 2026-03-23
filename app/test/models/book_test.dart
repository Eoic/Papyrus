import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Book', () {
    group('computed properties', () {
      test('progress returns currentPosition', () {
        final book = buildTestBook(currentPosition: 0.75);
        expect(book.progress, 0.75);
      });

      test('progressPercent rounds to nearest integer', () {
        expect(buildTestBook(currentPosition: 0.333).progressPercent, 33);
        expect(buildTestBook(currentPosition: 0.999).progressPercent, 100);
        expect(buildTestBook(currentPosition: 0.0).progressPercent, 0);
        expect(buildTestBook(currentPosition: 0.505).progressPercent, 51);
      });

      test('progressLabel formats as percentage string', () {
        expect(buildTestBook(currentPosition: 0.5).progressLabel, '50%');
        expect(buildTestBook(currentPosition: 1.0).progressLabel, '100%');
        expect(buildTestBook(currentPosition: 0.0).progressLabel, '0%');
      });

      test('isReading returns true only for inProgress status', () {
        expect(
          buildTestBook(readingStatus: ReadingStatus.inProgress).isReading,
          true,
        );
        expect(
          buildTestBook(readingStatus: ReadingStatus.completed).isReading,
          false,
        );
        expect(
          buildTestBook(readingStatus: ReadingStatus.notStarted).isReading,
          false,
        );
      });

      test('isFinished returns true only for completed status', () {
        expect(
          buildTestBook(readingStatus: ReadingStatus.completed).isFinished,
          true,
        );
        expect(
          buildTestBook(readingStatus: ReadingStatus.inProgress).isFinished,
          false,
        );
      });

      test('hasProgress returns true when currentPosition > 0', () {
        expect(buildTestBook(currentPosition: 0.01).hasProgress, true);
        expect(buildTestBook(currentPosition: 0.0).hasProgress, false);
      });

      test('formatLabel returns Physical for physical books', () {
        expect(buildTestBook(isPhysical: true).formatLabel, 'Physical');
      });

      test('formatLabel returns format label for digital books', () {
        expect(buildTestBook(fileFormat: BookFormat.epub).formatLabel, 'EPUB');
        expect(buildTestBook(fileFormat: BookFormat.pdf).formatLabel, 'PDF');
      });

      test('formatLabel returns Unknown when no format set', () {
        expect(buildTestBook().formatLabel, 'Unknown');
      });

      test('allAuthors returns single author when no co-authors', () {
        expect(buildTestBook(author: 'Alice').allAuthors, 'Alice');
      });

      test('allAuthors joins author with co-authors', () {
        final book = buildTestBook(
          author: 'Alice',
          coAuthors: ['Bob', 'Charlie'],
        );
        expect(book.allAuthors, 'Alice, Bob, Charlie');
      });

      test('coverURL is backwards compat alias for coverUrl', () {
        final book = buildTestBook(coverUrl: 'http://example.com/cover.jpg');
        expect(book.coverURL, 'http://example.com/cover.jpg');
      });

      test('totalPages is backwards compat alias for pageCount', () {
        final book = buildTestBook(pageCount: 300);
        expect(book.totalPages, 300);
      });

      test('shelves returns empty list', () {
        expect(buildTestBook().shelves, isEmpty);
      });

      test('topics returns empty list', () {
        expect(buildTestBook().topics, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final book = buildTestBook(title: 'Original', isFavorite: false);
        final copy = book.copyWith(title: 'Updated', isFavorite: true);

        expect(copy.title, 'Updated');
        expect(copy.isFavorite, true);
        expect(copy.id, book.id); // unchanged
        expect(copy.author, book.author); // unchanged
      });

      test('clearCoverUrl sets coverUrl to null', () {
        final book = buildTestBook(coverUrl: 'http://example.com/cover.jpg');
        final copy = book.copyWith(clearCoverUrl: true);

        expect(copy.coverUrl, isNull);
      });

      test('clearCoverUrl false preserves existing coverUrl', () {
        final book = buildTestBook(coverUrl: 'http://example.com/cover.jpg');
        final copy = book.copyWith(clearCoverUrl: false);

        expect(copy.coverUrl, 'http://example.com/cover.jpg');
      });

      test('coverUrl parameter overrides clearCoverUrl', () {
        final book = buildTestBook(coverUrl: 'http://example.com/old.jpg');
        final copy = book.copyWith(coverUrl: 'http://example.com/new.jpg');

        expect(copy.coverUrl, 'http://example.com/new.jpg');
      });
    });

    group('toJson', () {
      test('serializes all fields with snake_case keys', () {
        final now = DateTime(2025, 6, 15, 10, 30);
        final book = Book(
          id: 'test-id',
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          author: 'Author',
          coAuthors: ['Co1', 'Co2'],
          isbn: '1234567890',
          isbn13: '1234567890123',
          publicationDate: now,
          publisher: 'Publisher',
          language: 'en',
          pageCount: 300,
          description: 'A description',
          coverUrl: 'http://cover.jpg',
          filePath: '/path/to/book.epub',
          fileFormat: BookFormat.epub,
          fileSize: 1024,
          fileHash: 'abc123',
          isPhysical: false,
          readingStatus: ReadingStatus.inProgress,
          currentPage: 150,
          currentPosition: 0.5,
          currentCfi: 'epubcfi(/6/14)',
          isFavorite: true,
          rating: 4,
          seriesId: 'series-1',
          seriesName: 'Test Series',
          seriesNumber: 2.0,
          addedAt: now,
          startedAt: now,
          completedAt: now,
          lastReadAt: now,
        );

        final json = book.toJson();

        expect(json['id'], 'test-id');
        expect(json['title'], 'Test Title');
        expect(json['subtitle'], 'Test Subtitle');
        expect(json['author'], 'Author');
        expect(json['co_authors'], ['Co1', 'Co2']);
        expect(json['isbn'], '1234567890');
        expect(json['isbn13'], '1234567890123');
        expect(json['publication_date'], now.toIso8601String());
        expect(json['publisher'], 'Publisher');
        expect(json['language'], 'en');
        expect(json['page_count'], 300);
        expect(json['description'], 'A description');
        expect(json['cover_image_url'], 'http://cover.jpg');
        expect(json['file_path'], '/path/to/book.epub');
        expect(json['file_format'], 'epub');
        expect(json['file_size'], 1024);
        expect(json['file_hash'], 'abc123');
        expect(json['is_physical'], false);
        expect(json['reading_status'], 'inProgress');
        expect(json['current_page'], 150);
        expect(json['current_position'], 0.5);
        expect(json['current_cfi'], 'epubcfi(/6/14)');
        expect(json['is_favorite'], true);
        expect(json['rating'], 4);
        expect(json['series_id'], 'series-1');
        expect(json['series_name'], 'Test Series');
        expect(json['series_number'], 2.0);
        expect(json['added_at'], now.toIso8601String());
        expect(json['started_at'], now.toIso8601String());
        expect(json['completed_at'], now.toIso8601String());
        expect(json['last_read_at'], now.toIso8601String());
      });

      test('null optional fields serialize as null', () {
        final book = buildTestBook();
        final json = book.toJson();

        expect(json['subtitle'], isNull);
        expect(json['isbn'], isNull);
        expect(json['file_path'], isNull);
        expect(json['started_at'], isNull);
        expect(json['completed_at'], isNull);
        expect(json['rating'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Title',
          'subtitle': 'Sub',
          'author': 'Author',
          'co_authors': ['Co1'],
          'isbn': '123',
          'isbn13': '1234567890123',
          'publication_date': '2025-06-15T10:30:00.000',
          'publisher': 'Pub',
          'language': 'en',
          'page_count': 300,
          'description': 'Desc',
          'cover_image_url': 'http://cover.jpg',
          'file_path': '/book.epub',
          'file_format': 'epub',
          'file_size': 1024,
          'file_hash': 'hash',
          'is_physical': true,
          'physical_location': 'Shelf A',
          'lent_to': 'Alice',
          'lent_at': '2025-06-15T10:30:00.000',
          'reading_status': 'completed',
          'current_page': 300,
          'current_position': 1.0,
          'current_cfi': 'cfi',
          'is_favorite': true,
          'rating': 5,
          'series_id': 's1',
          'series_name': 'Series',
          'series_number': 1.5,
          'added_at': '2025-06-15T10:30:00.000',
          'started_at': '2025-06-15T10:30:00.000',
          'completed_at': '2025-06-15T10:30:00.000',
          'last_read_at': '2025-06-15T10:30:00.000',
        };

        final book = Book.fromJson(json);

        expect(book.id, 'test-id');
        expect(book.title, 'Test Title');
        expect(book.subtitle, 'Sub');
        expect(book.author, 'Author');
        expect(book.coAuthors, ['Co1']);
        expect(book.isbn, '123');
        expect(book.isbn13, '1234567890123');
        expect(book.publisher, 'Pub');
        expect(book.language, 'en');
        expect(book.pageCount, 300);
        expect(book.description, 'Desc');
        expect(book.coverUrl, 'http://cover.jpg');
        expect(book.filePath, '/book.epub');
        expect(book.fileFormat, BookFormat.epub);
        expect(book.fileSize, 1024);
        expect(book.fileHash, 'hash');
        expect(book.isPhysical, true);
        expect(book.physicalLocation, 'Shelf A');
        expect(book.lentTo, 'Alice');
        expect(book.readingStatus, ReadingStatus.completed);
        expect(book.currentPage, 300);
        expect(book.currentPosition, 1.0);
        expect(book.currentCfi, 'cfi');
        expect(book.isFavorite, true);
        expect(book.rating, 5);
        expect(book.seriesId, 's1');
        expect(book.seriesName, 'Series');
        expect(book.seriesNumber, 1.5);
      });

      test('defaults for missing optional fields', () {
        final json = {
          'id': 'test',
          'title': 'Title',
          'author': 'Author',
          'added_at': '2025-01-01T00:00:00.000',
        };

        final book = Book.fromJson(json);

        expect(book.coAuthors, isEmpty);
        expect(book.isPhysical, false);
        expect(book.readingStatus, ReadingStatus.notStarted);
        expect(book.currentPosition, 0.0);
        expect(book.isFavorite, false);
        expect(book.fileFormat, isNull);
        expect(book.rating, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves all data', () {
        final original = Book(
          id: 'roundtrip-test',
          title: 'Roundtrip Book',
          author: 'Author',
          coAuthors: ['Co1', 'Co2'],
          fileFormat: BookFormat.mobi,
          readingStatus: ReadingStatus.paused,
          currentPosition: 0.42,
          currentPage: 126,
          isFavorite: true,
          rating: 3,
          pageCount: 300,
          seriesName: 'My Series',
          seriesNumber: 2.5,
          addedAt: DateTime(2025, 3, 15),
          startedAt: DateTime(2025, 4, 1),
        );

        final restored = Book.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.coAuthors, original.coAuthors);
        expect(restored.fileFormat, original.fileFormat);
        expect(restored.readingStatus, original.readingStatus);
        expect(restored.currentPosition, original.currentPosition);
        expect(restored.currentPage, original.currentPage);
        expect(restored.isFavorite, original.isFavorite);
        expect(restored.rating, original.rating);
        expect(restored.pageCount, original.pageCount);
        expect(restored.seriesName, original.seriesName);
        expect(restored.seriesNumber, original.seriesNumber);
      });
    });
  });

  group('ReadingStatus', () {
    test('label returns display text', () {
      expect(ReadingStatus.notStarted.label, 'Not started');
      expect(ReadingStatus.inProgress.label, 'Reading');
      expect(ReadingStatus.completed.label, 'Completed');
      expect(ReadingStatus.paused.label, 'Paused');
      expect(ReadingStatus.abandoned.label, 'Abandoned');
    });

    test('shortLabel returns abbreviated text', () {
      expect(ReadingStatus.notStarted.shortLabel, 'Not started');
      expect(ReadingStatus.inProgress.shortLabel, 'Reading');
      expect(ReadingStatus.completed.shortLabel, 'Finished');
      expect(ReadingStatus.paused.shortLabel, 'Paused');
      expect(ReadingStatus.abandoned.shortLabel, 'DNF');
    });
  });

  group('BookFormat', () {
    test('label returns uppercase format string', () {
      expect(BookFormat.epub.label, 'EPUB');
      expect(BookFormat.pdf.label, 'PDF');
      expect(BookFormat.mobi.label, 'MOBI');
      expect(BookFormat.azw3.label, 'AZW3');
      expect(BookFormat.txt.label, 'TXT');
      expect(BookFormat.cbr.label, 'CBR');
      expect(BookFormat.cbz.label, 'CBZ');
    });
  });
}
