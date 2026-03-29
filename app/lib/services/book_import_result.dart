import 'dart:typed_data';

/// Result of importing a book file.
///
/// Shared between web (Web Worker) and native (FileMetadataService)
/// implementations of [BookImportService].
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
  final String? isbn13;
  final int? pageCount;
  final Uint8List? coverImage;
  final String? coverMimeType;
  final int fileSize;
  final String fileHash;
  final String fileExtension;

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
    this.isbn13,
    this.pageCount,
    this.coverImage,
    this.coverMimeType,
    required this.fileSize,
    required this.fileHash,
    required this.fileExtension,
  });
}
