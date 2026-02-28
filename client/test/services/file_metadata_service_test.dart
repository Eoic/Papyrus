import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/file_metadata_service.dart';

void main() {
  late FileMetadataService service;

  setUp(() {
    service = FileMetadataService();
  });

  Uint8List? loadTestFile(String name) {
    final file = File('test/data/files/$name');
    if (!file.existsSync()) {
      markTestSkipped('Test book file $name not available');
      return null;
    }
    return file.readAsBytesSync();
  }

  group('FileMetadataService', () {
    group('MOBI extraction', () {
      test('parses 1.mobi metadata (KF8, title, author, language)', () async {
        final bytes = loadTestFile('1.mobi');
        if (bytes == null) return;
        final result = await service.extractMetadata(bytes, '1.mobi');

        expect(result.title, 'Im Kampf um Ideale');
        expect(result.authors, contains('Georg Bonne'));
        expect(result.language, 'de');
      });

      test(
        'parses 2.mobi without crash (MOBI v6, limited EXTH support)',
        () async {
          final bytes = loadTestFile('2.mobi');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '2.mobi');

          // MOBI v6 has limited EXTH support in dart_mobi — metadata
          // fields may be null, but extraction should not crash.
          expect(result.warnings, isNotEmpty);
        },
      );
    });

    group('EPUB extraction', () {
      test(
        'parses 3.epub metadata (EPUB 2, title, author, cover, date)',
        () async {
          final bytes = loadTestFile('3.epub');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '3.epub');

          expect(result.title, 'Im Kampf um Ideale');
          expect(result.authors, contains('Georg Bonne'));
          expect(result.language, 'de');
          expect(result.coverImageBytes, isNotNull);
          expect(result.coverImageMimeType, 'image/png');
          expect(result.publishedDate, isNotNull);
        },
      );

      test(
        'parses 4.epub metadata (EPUB 3, title, author, cover, date)',
        () async {
          final bytes = loadTestFile('4.epub');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '4.epub');

          expect(result.title, 'Im Kampf um Ideale');
          expect(result.authors, contains('Georg Bonne'));
          expect(result.language, 'de');
          expect(result.coverImageBytes, isNotNull);
          expect(result.coverImageMimeType, 'image/png');
          expect(result.publishedDate, isNotNull);
        },
      );

      test(
        'parses 5.epub metadata (EPUB 2, title, author, cover, date)',
        () async {
          final bytes = loadTestFile('5.epub');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '5.epub');

          expect(result.title, 'Im Kampf um Ideale');
          expect(result.authors, contains('Georg Bonne'));
          expect(result.language, 'de');
          expect(result.coverImageBytes, isNotNull);
          expect(result.coverImageMimeType, 'image/png');
          expect(result.publishedDate, isNotNull);
        },
      );
    });

    group('AZW3 extraction', () {
      test(
        'parses 6.azw3 metadata (title, author, publisher, description, language)',
        () async {
          final bytes = loadTestFile('6.azw3');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '6.azw3');

          expect(result.title, 'Dracula');
          expect(result.authors, contains('Bram Stoker'));
          expect(result.publisher, 'Standard Ebooks');
          expect(result.description, contains('undead'));
          expect(result.language, 'en');
        },
      );
    });

    group('CBZ extraction', () {
      test(
        'parses 7.cbz (no ComicInfo.xml, cover from first image, warning)',
        () async {
          final bytes = loadTestFile('7.cbz');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '7.cbz');

          expect(result.coverImageBytes, isNotNull);
          expect(
            result.warnings,
            contains('No ComicInfo.xml found in CBZ archive'),
          );
        },
      );
    });

    group('CBR extraction', () {
      test(
        'handles 8.cbr RAR v4 gracefully (returns warning, no crash)',
        () async {
          final bytes = loadTestFile('8.cbr');
          if (bytes == null) return;
          final result = await service.extractMetadata(bytes, '8.cbr');

          expect(result.warnings, isNotEmpty);
        },
      );
    });

    group('TXT extraction', () {
      test('parses "Author - Title" filename pattern', () async {
        final bytes = Uint8List.fromList(utf8.encode('Some book content.'));
        final result = await service.extractMetadata(
          bytes,
          'Author Name - Book Title.txt',
        );

        expect(result.title, 'Book Title');
        expect(result.authors, ['Author Name']);
      });

      test('preserves multiple hyphens in title', () async {
        final bytes = Uint8List.fromList(utf8.encode('content'));
        final result = await service.extractMetadata(
          bytes,
          'Author - Part 1 - The Beginning.txt',
        );

        expect(result.title, 'Part 1 - The Beginning');
        expect(result.authors, ['Author']);
      });

      test('uses filename as title when no separator found', () async {
        final bytes = Uint8List.fromList(utf8.encode('Some book content.'));
        final result = await service.extractMetadata(bytes, 'JustATitle.txt');

        expect(result.title, 'JustATitle');
        expect(
          result.warnings,
          contains('Could not detect author from filename'),
        );
      });

      test('estimates page count from content length', () async {
        // 3000 bytes should yield 2 pages at ~1500 chars/page
        final bytes = Uint8List(3000);
        final result = await service.extractMetadata(bytes, 'book.txt');

        expect(result.pageCount, 2);
      });
    });

    group('FileMetadataResult getters', () {
      test('primaryAuthor returns first author', () {
        const result = FileMetadataResult(authors: ['Alice', 'Bob']);
        expect(result.primaryAuthor, 'Alice');
      });

      test('primaryAuthor returns empty string when no authors', () {
        const result = FileMetadataResult();
        expect(result.primaryAuthor, '');
      });

      test('coAuthors returns all authors except first', () {
        const result = FileMetadataResult(authors: ['Alice', 'Bob', 'Carol']);
        expect(result.coAuthors, ['Bob', 'Carol']);
      });

      test('coAuthors returns empty list for single author', () {
        const result = FileMetadataResult(authors: ['Alice']);
        expect(result.coAuthors, isEmpty);
      });
    });

    group('format dispatch', () {
      test('returns warning for unsupported file extension', () async {
        final bytes = Uint8List(0);
        final result = await service.extractMetadata(bytes, 'file.xyz');

        expect(result.warnings, contains('Unsupported file format: .xyz'));
      });
    });

    group('error handling', () {
      test('never throws on corrupted data', () async {
        final corruptedBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        // Should not throw for any supported format
        for (final filename in [
          'bad.epub',
          'bad.mobi',
          'bad.azw3',
          'bad.cbz',
          'bad.cbr',
          'bad.pdf',
        ]) {
          final result = await service.extractMetadata(
            corruptedBytes,
            filename,
          );
          expect(
            result.warnings,
            isNotEmpty,
            reason: 'Expected warnings for $filename',
          );
        }
      });
    });
  });
}
