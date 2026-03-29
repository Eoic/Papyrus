import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/services/file_metadata_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:papyrus/services/book_import_result.dart';

/// Native (non-web) implementation of [BookImportService].
///
/// Uses [FileMetadataService] for metadata extraction and stores files
/// in the application documents directory.
class BookImportService {
  final _metadataService = FileMetadataService();

  /// Incrementing counter used to guarantee unique book IDs.
  int _nextId = 0;

  /// Imports a book file: extracts metadata and stores the file locally.
  ///
  /// Supports all formats handled by [FileMetadataService]:
  /// EPUB, PDF, MOBI, AZW3, CBZ, CBR, TXT.
  Future<BookImportResult> importBook(Uint8List bytes, String filename) async {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    if (ext.isEmpty) {
      throw ArgumentError('Filename has no extension: $filename');
    }

    final bookId = 'book-${DateTime.now().millisecondsSinceEpoch}-${_nextId++}';

    // Extract metadata
    final metadata = await _metadataService.extractMetadata(bytes, filename);

    // Compute SHA-256 hash
    final fileHash = sha256.convert(bytes).toString();

    // Store the file
    final booksDir = await _getBooksDirectory();
    final file = File(p.join(booksDir.path, '$bookId.$ext'));
    await file.writeAsBytes(bytes);

    return BookImportResult(
      bookId: bookId,
      title: metadata.title ?? p.basenameWithoutExtension(filename),
      subtitle: metadata.subtitle,
      author: metadata.primaryAuthor,
      coAuthors: metadata.coAuthors,
      publisher: metadata.publisher,
      description: metadata.description,
      language: metadata.language,
      isbn: metadata.isbn,
      isbn13: metadata.isbn13,
      pageCount: metadata.pageCount,
      coverImage: metadata.coverImageBytes,
      coverMimeType: metadata.coverImageMimeType,
      fileSize: bytes.length,
      fileHash: fileHash,
      fileExtension: ext,
    );
  }

  /// Deletes the stored file for [bookId].
  Future<void> deleteBookFile(String bookId) async {
    final booksDir = await _getBooksDirectory();
    final files = booksDir.listSync();
    for (final entity in files) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == bookId) {
        await entity.delete();
        return;
      }
    }
  }

  /// Retrieves the raw file bytes for a stored book.
  ///
  /// Returns null if the file does not exist.
  Future<Uint8List?> getBookFile(String bookId) async {
    final booksDir = await _getBooksDirectory();
    final files = booksDir.listSync();
    for (final entity in files) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == bookId) {
        return entity.readAsBytes();
      }
    }
    return null;
  }

  /// No-op on native — no worker to terminate.
  void dispose() {}

  /// Returns (and creates if needed) the books storage directory.
  Future<Directory> _getBooksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(appDir.path, 'books'));
    if (!booksDir.existsSync()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }
}
