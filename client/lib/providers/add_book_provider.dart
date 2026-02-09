import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/file_metadata_service.dart';
import 'package:papyrus/services/sha256_hash.dart';
import 'package:path/path.dart' as p;

/// Wait until the next frame is painted and the browser has composited.
///
/// After the post-frame callback fires, a short [Future.delayed] exits the
/// requestAnimationFrame callback so the browser can actually composite pixels
/// to screen before execution continues. Without this, the next synchronous
/// work starts before any visual update is displayed.
Future<void> _ensureFramePainted() async {
  final completer = Completer<void>();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    completer.complete();
  });
  SchedulerBinding.instance.scheduleFrame();
  await completer.future;
  // Exit rAF so browser can composite. 16ms ≈ one frame at 60fps.
  await Future.delayed(const Duration(milliseconds: 16));
}

/// Combined result of hashing and metadata extraction from an isolate.
class _FileProcessResult {
  final String fileHash;
  final FileMetadataResult metadata;
  const _FileProcessResult({required this.fileHash, required this.metadata});
}

/// Top-level entry point for compute(). Runs SHA-256 hashing and metadata
/// extraction in a single call — off the main thread on native platforms.
Future<_FileProcessResult> _processFileInIsolate(
  (Uint8List, String) args,
) async {
  final (bytes, filename) = args;
  final hash = sha256.convert(bytes).toString();
  final metadata = await FileMetadataService().extractMetadata(bytes, filename);
  return _FileProcessResult(fileHash: hash, metadata: metadata);
}

/// Status of a single file import.
enum FileImportStatus { pending, extracting, success, duplicate, error }

/// A single file being imported.
class FileImportItem {
  final String fileName;
  final int fileSize;
  final Uint8List bytes;
  final BookFormat format;
  FileImportStatus status;
  String? errorMessage;
  FileMetadataResult? metadata;
  Uint8List? coverImageBytes;
  String? coverImageMimeType;
  String? fileHash;

  // Editable fields (pre-filled from metadata)
  String title;
  String author;
  String? subtitle;
  String? publisher;
  String? language;
  String? isbn;
  String? isbn13;
  String? description;
  int? pageCount;
  List<String> coAuthors;
  String? publicationDate;
  String? seriesName;
  double? seriesNumber;
  int? rating;
  String? coverUrl;

  FileImportItem({
    required this.fileName,
    required this.fileSize,
    required this.bytes,
    required this.format,
    this.status = FileImportStatus.pending,
    this.errorMessage,
    this.metadata,
    this.coverImageBytes,
    this.coverImageMimeType,
    this.fileHash,
    this.title = '',
    this.author = '',
    this.subtitle,
    this.publisher,
    this.language,
    this.isbn,
    this.isbn13,
    this.description,
    this.pageCount,
    this.coAuthors = const [],
    this.publicationDate,
    this.seriesName,
    this.seriesNumber,
    this.rating,
    this.coverUrl,
  });
}

/// Provider for managing the digital book import pipeline.
class AddBookProvider extends ChangeNotifier {
  List<FileImportItem> _items = [];
  bool _isProcessing = false;
  bool _isPicking = false;
  bool _isAddingToLibrary = false;
  bool _cancelled = false;
  int _processedCount = 0;

  List<FileImportItem> get items => _items;
  bool get isProcessing => _isProcessing;
  bool get isPicking => _isPicking;
  bool get isAddingToLibrary => _isAddingToLibrary;
  int get processedCount => _processedCount;
  int get totalCount => _items.length;

  /// Sets internal state for widget tests. Not for production use.
  @visibleForTesting
  void setTestState({
    List<FileImportItem>? items,
    bool? isPicking,
    bool? isProcessing,
    bool? isAddingToLibrary,
    int? processedCount,
  }) {
    if (items != null) _items = items;
    if (isPicking != null) _isPicking = isPicking;
    if (isProcessing != null) _isProcessing = isProcessing;
    if (isAddingToLibrary != null) _isAddingToLibrary = isAddingToLibrary;
    if (processedCount != null) _processedCount = processedCount;
    notifyListeners();
  }

  int get successCount =>
      _items.where((i) => i.status == FileImportStatus.success).length;

  bool get hasSuccessfulItems => successCount > 0;

  /// Pick files using the system file picker.
  /// Returns true if files were selected.
  Future<bool> pickFiles() async {
    _isPicking = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'],
        withData: true,
      );

      _isPicking = false;

      if (result == null || result.files.isEmpty) {
        notifyListeners();
        return false;
      }

      _items = result.files.where((f) => f.bytes != null).map((f) {
        final ext = p.extension(f.name).toLowerCase();
        return FileImportItem(
          fileName: f.name,
          fileSize: f.size,
          bytes: f.bytes!,
          format: _formatFromExtension(ext),
          title: p.basenameWithoutExtension(f.name),
        );
      }).toList();

      notifyListeners();
      return _items.isNotEmpty;
    } catch (_) {
      _isPicking = false;
      notifyListeners();
      return false;
    }
  }

  /// Process all files: extract metadata and compute hashes.
  ///
  /// SHA-256 hashing and metadata extraction run together in a single
  /// [compute] call — off the main thread on native platforms.
  /// On web, [compute] runs on the main thread (no isolate/web worker
  /// support), so we use [_ensureFramePainted] to guarantee the browser
  /// displays progress before the blocking work begins.
  Future<void> processFiles(DataStore dataStore) async {
    _isProcessing = true;
    _cancelled = false;
    _processedCount = 0;
    notifyListeners();

    // Let Flutter build/paint the processing UI before blocking work starts.
    await _ensureFramePainted();

    for (var i = 0; i < _items.length; i++) {
      if (_cancelled) break;

      final item = _items[i];
      item.status = FileImportStatus.extracting;
      notifyListeners();

      // Ensure the extracting status is visible before heavy work.
      await _ensureFramePainted();
      if (_cancelled) break;

      try {
        final _FileProcessResult result;
        if (kIsWeb) {
          // Web: compute() runs on the main thread (no isolate support).
          // Hash via Web Crypto API (async, non-blocking).
          final hash = await computeSha256(item.bytes);
          await _ensureFramePainted();
          if (_cancelled) break;
          // Metadata extraction blocks the main thread (unavoidable without
          // replacing parsing libraries), but is bounded per file.
          final metadata = await FileMetadataService().extractMetadata(
            item.bytes,
            item.fileName,
          );
          result = _FileProcessResult(fileHash: hash, metadata: metadata);
        } else {
          // Native: real isolate, no UI impact.
          result = await compute(_processFileInIsolate, (
            item.bytes,
            item.fileName,
          ));
        }

        item.fileHash = result.fileHash;

        // Check for duplicates
        final isDuplicate = dataStore.books.any(
          (b) => b.fileHash == result.fileHash,
        );
        if (isDuplicate) {
          item.status = FileImportStatus.duplicate;
          _processedCount++;
          notifyListeners();
          continue;
        }

        final metadata = result.metadata;
        item.metadata = metadata;
        item.coverImageBytes = metadata.coverImageBytes;
        item.coverImageMimeType = metadata.coverImageMimeType;

        // Pre-fill editable fields from metadata
        if (metadata.title != null && metadata.title!.isNotEmpty) {
          item.title = metadata.title!;
        }
        if (metadata.primaryAuthor.isNotEmpty) {
          item.author = metadata.primaryAuthor;
        }
        item.subtitle = metadata.subtitle;
        item.publisher = metadata.publisher;
        item.language = metadata.language;
        item.isbn = metadata.isbn;
        item.isbn13 = metadata.isbn13;
        item.description = metadata.description;
        item.pageCount = metadata.pageCount;
        item.coAuthors = metadata.coAuthors;
        item.publicationDate = metadata.publishedDate;

        item.status = FileImportStatus.success;
      } catch (e) {
        item.status = FileImportStatus.error;
        item.errorMessage = 'Failed to process: $e';
      }

      _processedCount++;
      notifyListeners();
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// Cancel the current processing loop.
  void cancelProcessing() {
    _cancelled = true;
  }

  /// Remove an item from the list.
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  /// Update editable fields on an item.
  void updateItem(
    int index, {
    String? title,
    String? author,
    String? subtitle,
    String? publisher,
    String? language,
    String? isbn,
    String? isbn13,
    String? description,
    int? pageCount,
    List<String>? coAuthors,
    String? publicationDate,
    String? seriesName,
    double? seriesNumber,
    int? rating,
    Uint8List? coverImageBytes,
    String? coverUrl,
    bool clearCoverImage = false,
    bool clearCoverUrl = false,
  }) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    if (title != null) item.title = title;
    if (author != null) item.author = author;
    if (subtitle != null) item.subtitle = subtitle;
    if (publisher != null) item.publisher = publisher;
    if (language != null) item.language = language;
    if (isbn != null) item.isbn = isbn;
    if (isbn13 != null) item.isbn13 = isbn13;
    if (description != null) item.description = description;
    if (pageCount != null) item.pageCount = pageCount;
    if (coAuthors != null) item.coAuthors = coAuthors;
    if (publicationDate != null) item.publicationDate = publicationDate;
    if (seriesName != null) item.seriesName = seriesName;
    if (seriesNumber != null) item.seriesNumber = seriesNumber;
    if (rating != null) item.rating = rating;

    if (coverImageBytes != null) {
      item.coverImageBytes = coverImageBytes;
      item.coverUrl = null;
    } else if (clearCoverImage) {
      item.coverImageBytes = null;
    }

    if (coverUrl != null) {
      item.coverUrl = coverUrl;
      item.coverImageBytes = null;
    } else if (clearCoverUrl) {
      item.coverUrl = null;
    }

    notifyListeners();
  }

  /// Clear the rating on an item.
  void clearItemRating(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].rating = null;
    notifyListeners();
  }

  /// Add all successful items to the library.
  Future<int> addToLibrary(DataStore dataStore) async {
    _isAddingToLibrary = true;
    notifyListeners();

    var addedCount = 0;
    final now = DateTime.now();

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.status != FileImportStatus.success) continue;
      if (item.title.trim().isEmpty || item.author.trim().isEmpty) continue;

      String? coverUrl;
      if (item.coverImageBytes != null) {
        coverUrl = _bytesToDataUri(
          item.coverImageBytes!,
          item.coverImageMimeType,
        );
      } else if (item.coverUrl != null && item.coverUrl!.isNotEmpty) {
        coverUrl = item.coverUrl;
      }

      final book = Book(
        id: 'book-${now.millisecondsSinceEpoch}-$i',
        title: item.title.trim(),
        subtitle: item.subtitle,
        author: item.author.trim(),
        coAuthors: item.coAuthors,
        isbn: item.isbn,
        isbn13: item.isbn13,
        publisher: item.publisher,
        language: item.language,
        pageCount: item.pageCount,
        description: item.description,
        coverUrl: coverUrl,
        fileFormat: item.format,
        fileSize: item.fileSize,
        fileHash: item.fileHash,
        publicationDate: _tryParseDate(item.publicationDate),
        rating: item.rating,
        seriesName: item.seriesName,
        seriesNumber: item.seriesNumber,
        addedAt: now,
      );

      dataStore.addBook(book);
      addedCount++;
    }

    _isAddingToLibrary = false;
    notifyListeners();
    return addedCount;
  }

  /// Convert image bytes to a data URI string.
  String _bytesToDataUri(Uint8List bytes, String? mimeType) {
    String mime = mimeType ?? 'image/jpeg';
    if (mime.isEmpty) {
      // Detect from magic bytes
      if (bytes.length >= 8) {
        if (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47) {
          mime = 'image/png';
        } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
          mime = 'image/gif';
        } else if (bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46) {
          mime = 'image/webp';
        }
      }
    }
    final base64Data = base64Encode(bytes);
    return 'data:$mime;base64,$base64Data';
  }

  /// Try to parse a date string in various formats.
  DateTime? _tryParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final fullDate = DateTime.tryParse(dateStr);
    if (fullDate != null) return fullDate;
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(dateStr)) {
      return DateTime.tryParse('$dateStr-01');
    }
    final year = int.tryParse(dateStr);
    if (year != null && year > 0 && year < 10000) {
      return DateTime(year);
    }
    return null;
  }

  /// Map file extension to BookFormat.
  BookFormat _formatFromExtension(String ext) {
    switch (ext) {
      case '.epub':
        return BookFormat.epub;
      case '.pdf':
        return BookFormat.pdf;
      case '.mobi':
        return BookFormat.mobi;
      case '.azw3' || '.azw':
        return BookFormat.azw3;
      case '.txt':
        return BookFormat.txt;
      case '.cbr':
        return BookFormat.cbr;
      case '.cbz':
        return BookFormat.cbz;
      default:
        return BookFormat.epub;
    }
  }
}
