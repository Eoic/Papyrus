import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:papyrus/media/cover_storage_bucket.dart';
import 'package:papyrus/media/local_cover_image_provider.dart';
import 'package:papyrus/media/media_storage_scope.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/services/file_metadata_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

export 'package:papyrus/services/book_import_result.dart';

/// Native (non-web) implementation of [BookImportService].
///
/// Uses [FileMetadataService] for metadata extraction and stores files
/// in the application documents directory.
class BookImportService {
  static final RegExp _safeFilePart = RegExp(r'^[a-zA-Z0-9_.-]+$');

  final _metadataService = FileMetadataService();
  static final Map<String, Future<void>> _coverOperations = {};

  /// Imports a book file: extracts metadata and stores the file locally.
  ///
  /// Supports all formats handled by [FileMetadataService]:
  /// EPUB, PDF, MOBI, AZW3, CBZ, CBR, TXT.
  Future<BookImportResult> importBook(Uint8List bytes, String filename) async {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    if (ext.isEmpty) {
      throw ArgumentError('Filename has no extension: $filename');
    }

    final bookId = const Uuid().v4();

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

  /// Checks whether a stored book exists without reading its contents.
  Future<bool> hasBookFile(String bookId) async {
    final booksDir = await _getBooksDirectory();
    await for (final entity in booksDir.list()) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == bookId) {
        return true;
      }
    }
    return false;
  }

  /// Stores raw book bytes under the app-local book cache for [bookId].
  ///
  /// Used when a signed-in device lazily downloads a book file from the
  /// selected server.
  Future<void> storeBookFile(String bookId, String extension, Uint8List bytes) async {
    final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
    if (normalizedExtension.isEmpty) {
      throw ArgumentError('Book file extension cannot be empty.');
    }
    await deleteBookFile(bookId);
    final booksDir = await _getBooksDirectory();
    final file = File(p.join(booksDir.path, '$bookId.$normalizedExtension'));
    await file.writeAsBytes(bytes);
  }

  /// Returns a persistently cached private cover for [scope], when present.
  Future<Uint8List?> getCoverFile(MediaStorageScope scope, String mediaId) async {
    return _withCoverLock(
      scope,
      CoverStorageBucket.cached,
      mediaId,
      () => _readCoverFile(scope, CoverStorageBucket.cached, mediaId),
    );
  }

  /// Atomically stores private cover bytes in the selected account scope.
  Future<void> storeCoverFile(MediaStorageScope scope, String mediaId, Uint8List bytes) async {
    await _withCoverLock(
      scope,
      CoverStorageBucket.cached,
      mediaId,
      () => _writeCoverFile(scope, CoverStorageBucket.cached, mediaId, bytes),
    );
  }

  /// Deletes one cached private cover without affecting other scopes.
  Future<void> deleteCoverFile(MediaStorageScope scope, String mediaId) async {
    await _withCoverLock(
      scope,
      CoverStorageBucket.cached,
      mediaId,
      () => _removeCoverFile(scope, CoverStorageBucket.cached, mediaId),
    );
  }

  Future<Uint8List?> getPendingCoverFile(MediaStorageScope scope, String bookId) async {
    return _withCoverLock(
      scope,
      CoverStorageBucket.pending,
      bookId,
      () => _readCoverFile(scope, CoverStorageBucket.pending, bookId),
    );
  }

  Future<void> storePendingCoverFile(MediaStorageScope scope, String bookId, Uint8List bytes) async {
    await _withCoverLock(
      scope,
      CoverStorageBucket.pending,
      bookId,
      () => _writeCoverFile(scope, CoverStorageBucket.pending, bookId, bytes),
    );
  }

  Future<void> deletePendingCoverFile(MediaStorageScope scope, String bookId) async {
    await _withCoverLock(
      scope,
      CoverStorageBucket.pending,
      bookId,
      () => _removeCoverFile(scope, CoverStorageBucket.pending, bookId),
    );
  }

  Future<Uint8List?> getGuestCoverFile(String bookId) async {
    return _withCoverLock(
      MediaStorageScope.localGuest,
      CoverStorageBucket.guestBooks,
      bookId,
      () => _readCoverFile(MediaStorageScope.localGuest, CoverStorageBucket.guestBooks, bookId),
    );
  }

  Future<void> storeGuestCoverFile(String bookId, Uint8List bytes) async {
    await _withCoverLock(
      MediaStorageScope.localGuest,
      CoverStorageBucket.guestBooks,
      bookId,
      () => _writeCoverFile(MediaStorageScope.localGuest, CoverStorageBucket.guestBooks, bookId, bytes),
    );
  }

  Future<void> deleteGuestCoverFile(String bookId) async {
    await _withCoverLock(
      MediaStorageScope.localGuest,
      CoverStorageBucket.guestBooks,
      bookId,
      () => _removeCoverFile(MediaStorageScope.localGuest, CoverStorageBucket.guestBooks, bookId),
    );
  }

  Future<void> promotePendingCoverFile(
    MediaStorageScope scope, {
    required String bookId,
    required String mediaId,
  }) async {
    await _withCoverLock(scope, CoverStorageBucket.pending, bookId, () async {
      final bytes = await _readCoverFile(scope, CoverStorageBucket.pending, bookId);
      if (bytes == null) return;
      await _withCoverLock(
        scope,
        CoverStorageBucket.cached,
        mediaId,
        () => _writeCoverFile(scope, CoverStorageBucket.cached, mediaId, bytes),
      );
      final pendingFile = await _coverFile(scope, CoverStorageBucket.pending, bookId);
      if (await pendingFile.exists()) {
        await pendingFile.delete();
      }
    });
  }

  /// Deletes all cached private covers for one server/account scope.
  Future<void> clearCoverFiles(MediaStorageScope scope) async {
    final directory = await _coverDirectory(scope, create: false);
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
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

  Future<T> _withCoverLock<T>(
    MediaStorageScope scope,
    CoverStorageBucket bucket,
    String id,
    Future<T> Function() operation,
  ) {
    final key = '${scope.persistenceKey}|${bucket.pathComponent}|$id';
    final previous = _coverOperations[key] ?? Future<void>.value();
    final completer = Completer<T>();
    late final Future<void> current;
    current = previous.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _coverOperations[key] = current;
    unawaited(
      current.whenComplete(() {
        if (identical(_coverOperations[key], current)) {
          _coverOperations.remove(key);
        }
      }),
    );
    return completer.future;
  }

  Future<Uint8List?> _readCoverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id) async {
    final file = await _coverFile(scope, bucket, id);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> _writeCoverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id, Uint8List bytes) async {
    final file = await _coverFile(scope, bucket, id);
    final operationId = const Uuid().v4();
    final tempFile = File('${file.path}.$operationId.tmp');
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(file.path);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _removeCoverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id) async {
    final file = await _coverFile(scope, bucket, id);
    if (await file.exists()) {
      await file.delete();
    }
    LocalCoverImageProvider.evictKey(scopeKey: scope.persistenceKey, bucket: bucket, fileId: id);
  }

  Future<File> _coverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id) async {
    _validateFilePart(scope.persistenceKey, 'scope');
    _validateFilePart(bucket.pathComponent, 'bucket');
    _validateFilePart(id, 'id');
    final directory = await _coverBucketDirectory(scope, bucket, create: true);
    return File(p.join(directory!.path, '$id.bin'));
  }

  void _validateFilePart(String value, String name) {
    if (!_safeFilePart.hasMatch(value)) {
      throw ArgumentError.value(value, name, '$name contains unsafe characters');
    }
  }

  Future<Directory?> _coverBucketDirectory(
    MediaStorageScope scope,
    CoverStorageBucket bucket, {
    required bool create,
  }) async {
    final scopeDirectory = await _coverDirectory(scope, create: create);
    if (scopeDirectory == null) return null;
    final directory = Directory(p.join(scopeDirectory.path, bucket.pathComponent));
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory?> _coverDirectory(MediaStorageScope scope, {required bool create}) async {
    _validateFilePart(scope.persistenceKey, 'scope');
    final appDir = await getApplicationSupportDirectory();
    final directory = Directory(p.join(appDir.path, 'media-covers', scope.persistenceKey));
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
