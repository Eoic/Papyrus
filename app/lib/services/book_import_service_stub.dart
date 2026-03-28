import 'dart:typed_data';

/// Result of importing a book file via the web worker.
class BookImportResult {
  final String bookId;
  final String title;
  final String? subtitle;
  final String author;
  final List<String> coAuthors;
  final String? publisher;
  final String? description;
  final String? language;
  final String? isbn;
  final int? pageCount;
  final Uint8List? coverImage;
  final String? coverMimeType;
  final int fileSize;
  final String fileHash;

  const BookImportResult({
    required this.bookId,
    required this.title,
    this.subtitle,
    required this.author,
    this.coAuthors = const [],
    this.publisher,
    this.description,
    this.language,
    this.isbn,
    this.pageCount,
    this.coverImage,
    this.coverMimeType,
    required this.fileSize,
    required this.fileHash,
  });
}

/// Stub [BookImportService] for non-web platforms.
///
/// All methods throw [UnsupportedError] since book import currently
/// requires a Web Worker.
class BookImportService {
  Future<BookImportResult> importBook(Uint8List bytes, String filename) {
    throw UnsupportedError('BookImportService is only supported on web.');
  }

  Future<void> deleteBookFile(String bookId) {
    throw UnsupportedError('BookImportService is only supported on web.');
  }

  Future<Uint8List?> getBookFile(String bookId) {
    throw UnsupportedError('BookImportService is only supported on web.');
  }

  void dispose() {}
}
