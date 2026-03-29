import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/book_import_service_stub.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake path_provider that returns a temporary directory for testing.
class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;

  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  late BookImportService service;
  late Directory tempDir;

  Uint8List? loadTestFile(String name) {
    final file = File('test/data/$name');
    if (!file.existsSync()) {
      markTestSkipped('Test book file $name not available');
      return null;
    }
    return file.readAsBytesSync();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('papyrus_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
    service = BookImportService();
  });

  tearDown(() async {
    service.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BookImportService (native)', () {
    group('importBook', () {
      test('imports book1.epub with metadata', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book1.epub');

        expect(result.bookId, startsWith('book-'));
        expect(result.title, isNotEmpty);
        expect(result.fileSize, bytes.length);
        expect(result.fileHash, isNotEmpty);
        expect(result.fileHash.length, 64); // SHA-256 hex string
        expect(result.fileExtension, 'epub');
      });

      test('imports book2.epub with metadata', () async {
        final bytes = loadTestFile('book2.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book2.epub');

        expect(result.bookId, startsWith('book-'));
        expect(result.title, isNotEmpty);
        expect(result.fileSize, bytes.length);
        expect(result.fileHash, isNotEmpty);
        expect(result.fileExtension, 'epub');
      });

      test('imports book3.epub with metadata', () async {
        final bytes = loadTestFile('book3.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book3.epub');

        expect(result.bookId, startsWith('book-'));
        expect(result.title, isNotEmpty);
        expect(result.fileSize, bytes.length);
        expect(result.fileHash, isNotEmpty);
        expect(result.fileExtension, 'epub');
      });

      test('generates unique book IDs', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result1 = await service.importBook(bytes, 'book1.epub');
        final result2 = await service.importBook(bytes, 'book1.epub');

        expect(result1.bookId, isNot(result2.bookId));
      });

      test('same file produces same hash', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result1 = await service.importBook(bytes, 'book1.epub');
        final result2 = await service.importBook(bytes, 'book1.epub');

        expect(result1.fileHash, result2.fileHash);
      });

      test('different files produce different hashes', () async {
        final bytes1 = loadTestFile('book1.epub');
        final bytes2 = loadTestFile('book2.epub');
        if (bytes1 == null || bytes2 == null) return;

        final result1 = await service.importBook(bytes1, 'book1.epub');
        final result2 = await service.importBook(bytes2, 'book2.epub');

        expect(result1.fileHash, isNot(result2.fileHash));
      });

      test('stores file to disk', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book1.epub');

        final storedFile = File(
          p.join(tempDir.path, 'books', '${result.bookId}.epub'),
        );
        expect(storedFile.existsSync(), isTrue);
        expect(storedFile.lengthSync(), bytes.length);
      });

      test('throws ArgumentError for files without extension', () async {
        final bytes = Uint8List(10);

        expect(() => service.importBook(bytes, 'noext'), throwsArgumentError);
      });

      test('handles corrupted epub gracefully', () async {
        final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        final result = await service.importBook(bytes, 'bad.epub');

        // Should still return a result (FileMetadataService never throws)
        expect(result.bookId, startsWith('book-'));
        expect(result.fileSize, 6);
        expect(result.fileHash, isNotEmpty);
        expect(result.fileExtension, 'epub');
      });

      test('imports txt file with author-title pattern', () async {
        final bytes = Uint8List.fromList(
          'Hello, this is a test book with some content.'.codeUnits,
        );

        final result = await service.importBook(
          bytes,
          'Jane Austen - Pride and Prejudice.txt',
        );

        expect(result.title, 'Pride and Prejudice');
        expect(result.author, 'Jane Austen');
        expect(result.fileExtension, 'txt');
      });
    });

    group('getBookFile', () {
      test('retrieves stored file bytes', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book1.epub');
        final retrieved = await service.getBookFile(result.bookId);

        expect(retrieved, isNotNull);
        expect(retrieved!.length, bytes.length);
      });

      test('returns null for non-existent book', () async {
        final result = await service.getBookFile('non-existent-id');

        expect(result, isNull);
      });
    });

    group('deleteBookFile', () {
      test('removes stored file', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book1.epub');

        // Verify file exists
        final retrieved = await service.getBookFile(result.bookId);
        expect(retrieved, isNotNull);

        // Delete
        await service.deleteBookFile(result.bookId);

        // Verify file is gone
        final afterDelete = await service.getBookFile(result.bookId);
        expect(afterDelete, isNull);
      });

      test('no-ops for non-existent book', () async {
        // Should not throw
        await service.deleteBookFile('non-existent-id');
      });
    });

    group('round-trip', () {
      test('import → get → delete → get returns null', () async {
        final bytes = loadTestFile('book1.epub');
        if (bytes == null) return;

        final result = await service.importBook(bytes, 'book1.epub');

        // Get
        final retrieved = await service.getBookFile(result.bookId);
        expect(retrieved, isNotNull);
        expect(retrieved!.length, bytes.length);

        // Delete
        await service.deleteBookFile(result.bookId);

        // Get again
        final afterDelete = await service.getBookFile(result.bookId);
        expect(afterDelete, isNull);
      });
    });
  });
}
