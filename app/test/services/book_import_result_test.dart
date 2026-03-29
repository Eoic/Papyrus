import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/book_import_result.dart';

void main() {
  group('BookImportResult', () {
    test('constructs with required fields only', () {
      const result = BookImportResult(
        bookId: 'book-1',
        title: 'Test Book',
        author: 'Author',
        fileSize: 1024,
        fileHash: 'abc123',
        fileExtension: 'epub',
      );

      expect(result.bookId, 'book-1');
      expect(result.title, 'Test Book');
      expect(result.author, 'Author');
      expect(result.fileSize, 1024);
      expect(result.fileHash, 'abc123');
      expect(result.fileExtension, 'epub');

      // Defaults
      expect(result.subtitle, isNull);
      expect(result.coAuthors, isEmpty);
      expect(result.publisher, isNull);
      expect(result.description, isNull);
      expect(result.language, isNull);
      expect(result.isbn, isNull);
      expect(result.isbn13, isNull);
      expect(result.pageCount, isNull);
      expect(result.coverImage, isNull);
      expect(result.coverMimeType, isNull);
    });

    test('constructs with all fields populated', () {
      final cover = Uint8List.fromList([1, 2, 3]);

      final result = BookImportResult(
        bookId: 'book-2',
        title: 'Full Book',
        subtitle: 'A Subtitle',
        author: 'Primary Author',
        coAuthors: ['Co-Author 1', 'Co-Author 2'],
        publisher: 'Publisher',
        description: 'A book description.',
        language: 'en',
        isbn: '1234567890',
        isbn13: '9781234567890',
        pageCount: 300,
        coverImage: cover,
        coverMimeType: 'image/png',
        fileSize: 2048,
        fileHash: 'def456',
        fileExtension: 'pdf',
      );

      expect(result.subtitle, 'A Subtitle');
      expect(result.coAuthors, ['Co-Author 1', 'Co-Author 2']);
      expect(result.publisher, 'Publisher');
      expect(result.description, 'A book description.');
      expect(result.language, 'en');
      expect(result.isbn, '1234567890');
      expect(result.isbn13, '9781234567890');
      expect(result.pageCount, 300);
      expect(result.coverImage, cover);
      expect(result.coverMimeType, 'image/png');
      expect(result.fileExtension, 'pdf');
    });
  });
}
