import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:papyrus/media/cover_storage_bucket.dart';
import 'package:papyrus/media/local_cover_image_provider.dart';
import 'package:papyrus/media/media_storage_scope.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

export 'package:papyrus/services/book_import_result.dart';

/// Service that communicates with the book_worker.js Web Worker for
/// EPUB processing and OPFS file storage.
///
/// Only available on web — methods throw [UnsupportedError] on other platforms.
class BookImportService {
  web.Worker? _worker;

  /// Timeout for worker operations before they are considered failed.
  static const _timeout = Duration(seconds: 30);

  /// Pending requests keyed by '$action:$bookId'.
  final Map<String, Completer<JSObject>> _pending = {};

  /// Returns the cached worker, creating it lazily on first access.
  /// The single `onmessage` handler is registered here so concurrent calls
  /// do not overwrite each other's handler.
  web.Worker _getWorker() {
    if (_worker != null) return _worker!;

    final worker = web.Worker('book_worker.js'.toJS);

    // Use web.Event (not web.MessageEvent) as the callback parameter type.
    // dart2wasm may silently drop callbacks when the parameter type is a
    // specific Event subclass that the runtime cannot match to the JS object.
    worker.addEventListener(
      'error',
      ((web.Event _) {
        final error = Exception('Worker error');
        for (final c in _pending.values) {
          if (!c.isCompleted) c.completeError(error);
        }
        _pending.clear();
      }).toJS,
    );

    worker.addEventListener(
      'message',
      ((web.Event e) {
        final event = e as web.MessageEvent;
        final data = event.data;
        if (data == null || data.isNull || data.isUndefined) {
          final error = Exception('Worker returned null data');
          for (final c in _pending.values) {
            if (!c.isCompleted) c.completeError(error);
          }
          _pending.clear();
          return;
        }

        final obj = data as JSObject;
        final type = _jsToNullableString(obj['type']);

        if (type == 'error') {
          final message = _jsToNullableString(obj['message']) ?? 'Unknown error';
          final error = Exception(message);
          final action = _jsToNullableString(obj['action']);
          final requestId = _jsToNullableString(obj['requestId']);
          final bookId = _jsToNullableString(obj['bookId']);
          if (requestId != null) {
            final c = _pending.remove(requestId);
            if (c != null && !c.isCompleted) {
              c.completeError(error);
              return;
            }
          }
          if (action != null && bookId != null) {
            final key = '$action:$bookId';
            final c = _pending.remove(key);
            if (c != null && !c.isCompleted) {
              c.completeError(error);
              return;
            }
          }
          for (final c in _pending.values) {
            if (!c.isCompleted) c.completeError(error);
          }
          _pending.clear();
          return;
        }

        if (type == 'success') {
          final action = _jsToNullableString(obj['action']);
          final requestId = _jsToNullableString(obj['requestId']);
          final bookId = _jsToNullableString(obj['bookId']);
          final key = requestId ?? (action != null && bookId != null ? '$action:$bookId' : null);
          if (key == null) {
            debugPrint(
              'BookImportService: success message with null '
              'action=$action bookId=$bookId requestId=$requestId — ignoring',
            );
            return;
          }

          final c = _pending.remove(key);
          if (c != null && !c.isCompleted) {
            c.complete(obj);
          }
        }
      }).toJS,
    );

    _worker = worker;
    return worker;
  }

  /// Processes a book file and stores it in OPFS via the web worker.
  ///
  /// Only 'epub' format is currently supported.
  /// Throws [UnsupportedError] when called on non-web platforms.
  /// Throws [ArgumentError] for unsupported file formats.
  Future<BookImportResult> importBook(Uint8List bytes, String filename) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only supported on web.');
    }

    final ext = filename.toLowerCase().split('.').last;
    if (ext != 'epub') {
      throw ArgumentError('Unsupported format: $ext. Only epub is supported.');
    }

    final bookId = const Uuid().v4();
    final completer = Completer<JSObject>();
    final worker = _getWorker();

    _pending['process:$bookId'] = completer;

    // Transfer bytes as ArrayBuffer for zero-copy transfer.
    // Ensure we only send the actual byte range, not the whole backing buffer.
    final actualBytes = bytes.offsetInBytes == 0 && bytes.lengthInBytes == bytes.buffer.lengthInBytes
        ? bytes
        : Uint8List.fromList(bytes);
    final jsBuffer = actualBytes.buffer.toJS;
    final message = JSObject();
    message['type'] = 'process'.toJS;
    message['format'] = ext.toJS;
    message['bookId'] = bookId.toJS;
    message['fileData'] = jsBuffer;

    worker.postMessage(message, [jsBuffer].toJS);

    final obj = await completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove('process:$bookId');
        throw TimeoutException('Book import timed out after ${_timeout.inSeconds}s', _timeout);
      },
    );
    return _parseImportResult(obj, bookId, ext);
  }

  /// Deletes a stored book file from OPFS by [bookId].
  ///
  /// Throws [UnsupportedError] when called on non-web platforms.
  Future<void> deleteBookFile(String bookId) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only supported on web.');
    }

    final completer = Completer<JSObject>();
    final worker = _getWorker();

    _pending['delete:$bookId'] = completer;

    final message = JSObject();
    message['type'] = 'delete'.toJS;
    message['bookId'] = bookId.toJS;

    worker.postMessage(message);

    await completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove('delete:$bookId');
        throw TimeoutException('Delete timed out after ${_timeout.inSeconds}s', _timeout);
      },
    );
  }

  /// Retrieves the raw file bytes for a stored book from OPFS.
  ///
  /// Returns null if the file does not exist.
  /// Throws [UnsupportedError] when called on non-web platforms.
  Future<Uint8List?> getBookFile(String bookId) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only supported on web.');
    }

    final completer = Completer<JSObject>();
    final worker = _getWorker();

    _pending['getFile:$bookId'] = completer;

    final message = JSObject();
    message['type'] = 'getFile'.toJS;
    message['bookId'] = bookId.toJS;

    worker.postMessage(message);

    final obj = await completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove('getFile:$bookId');
        throw TimeoutException('Get file timed out after ${_timeout.inSeconds}s', _timeout);
      },
    );
    final fileDataJs = obj['fileData'];
    if (fileDataJs == null || fileDataJs.isNull || fileDataJs.isUndefined) {
      return null;
    }
    return (fileDataJs as JSArrayBuffer).toDart.asUint8List();
  }

  /// Checks whether a stored book exists without transferring its contents
  /// out of OPFS.
  Future<bool> hasBookFile(String bookId) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only supported on web.');
    }

    final completer = Completer<JSObject>();
    final worker = _getWorker();
    _pending['hasFile:$bookId'] = completer;

    final message = JSObject();
    message['type'] = 'hasFile'.toJS;
    message['bookId'] = bookId.toJS;
    worker.postMessage(message);

    final obj = await completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove('hasFile:$bookId');
        throw TimeoutException('File check timed out after ${_timeout.inSeconds}s', _timeout);
      },
    );
    return (obj['exists'] as JSBoolean).toDart;
  }

  /// Stores raw book bytes in OPFS for [bookId].
  ///
  /// Throws [UnsupportedError] when called on non-web platforms.
  Future<void> storeBookFile(String bookId, String extension, Uint8List bytes) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only supported on web.');
    }

    final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
    if (normalizedExtension.isEmpty) {
      throw ArgumentError('Book file extension cannot be empty.');
    }

    final completer = Completer<JSObject>();
    final worker = _getWorker();

    _pending['storeFile:$bookId'] = completer;

    final actualBytes = bytes.offsetInBytes == 0 && bytes.lengthInBytes == bytes.buffer.lengthInBytes
        ? bytes
        : Uint8List.fromList(bytes);
    final jsBuffer = actualBytes.buffer.toJS;
    final message = JSObject();
    message['type'] = 'storeFile'.toJS;
    message['format'] = normalizedExtension.toJS;
    message['bookId'] = bookId.toJS;
    message['fileData'] = jsBuffer;

    worker.postMessage(message, [jsBuffer].toJS);

    await completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove('storeFile:$bookId');
        throw TimeoutException('Store file timed out after ${_timeout.inSeconds}s', _timeout);
      },
    );
  }

  Future<Uint8List?> getCoverFile(MediaStorageScope scope, String mediaId) async {
    return _getCoverFile(scope, CoverStorageBucket.cached, mediaId);
  }

  Future<void> storeCoverFile(MediaStorageScope scope, String mediaId, Uint8List bytes) async {
    await _storeCoverFile(scope, CoverStorageBucket.cached, mediaId, bytes);
  }

  Future<void> deleteCoverFile(MediaStorageScope scope, String mediaId) async {
    await _deleteCoverFile(scope, CoverStorageBucket.cached, mediaId);
  }

  Future<Uint8List?> getPendingCoverFile(MediaStorageScope scope, String bookId) async {
    return _getCoverFile(scope, CoverStorageBucket.pending, bookId);
  }

  Future<void> storePendingCoverFile(MediaStorageScope scope, String bookId, Uint8List bytes) async {
    await _storeCoverFile(scope, CoverStorageBucket.pending, bookId, bytes);
  }

  Future<void> deletePendingCoverFile(MediaStorageScope scope, String bookId) async {
    await _deleteCoverFile(scope, CoverStorageBucket.pending, bookId);
  }

  Future<Uint8List?> getGuestCoverFile(String bookId) async {
    return _getCoverFile(MediaStorageScope.localGuest, CoverStorageBucket.guestBooks, bookId);
  }

  Future<void> storeGuestCoverFile(String bookId, Uint8List bytes) async {
    await _storeCoverFile(MediaStorageScope.localGuest, CoverStorageBucket.guestBooks, bookId, bytes);
  }

  Future<void> deleteGuestCoverFile(String bookId) async {
    await _deleteCoverFile(MediaStorageScope.localGuest, CoverStorageBucket.guestBooks, bookId);
  }

  Future<void> promotePendingCoverFile(
    MediaStorageScope scope, {
    required String bookId,
    required String mediaId,
  }) async {
    await _sendCoverRequest(
      type: 'promoteCover',
      scope: scope,
      bucket: CoverStorageBucket.pending,
      mediaId: bookId,
      targetMediaId: mediaId,
    );
  }

  Future<Uint8List?> _getCoverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id) async {
    final obj = await _sendCoverRequest(type: 'getCover', scope: scope, bucket: bucket, mediaId: id);
    final fileDataJs = obj['fileData'];
    if (fileDataJs == null || fileDataJs.isNull || fileDataJs.isUndefined) {
      return null;
    }
    return (fileDataJs as JSArrayBuffer).toDart.asUint8List();
  }

  Future<void> _storeCoverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id, Uint8List bytes) async {
    await _sendCoverRequest(type: 'storeCover', scope: scope, bucket: bucket, mediaId: id, bytes: bytes);
  }

  Future<void> _deleteCoverFile(MediaStorageScope scope, CoverStorageBucket bucket, String id) async {
    await _sendCoverRequest(type: 'deleteCover', scope: scope, bucket: bucket, mediaId: id);
    LocalCoverImageProvider.evictKey(scopeKey: scope.persistenceKey, bucket: bucket, fileId: id);
  }

  Future<void> clearCoverFiles(MediaStorageScope scope) async {
    await _sendCoverRequest(type: 'clearCovers', scope: scope, bucket: CoverStorageBucket.cached);
  }

  /// Terminates the Web Worker and releases resources.
  void dispose() {
    _worker?.terminate();
    _worker = null;
    final error = StateError('BookImportService was disposed');
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<JSObject> _sendCoverRequest({
    required String type,
    required MediaStorageScope scope,
    required CoverStorageBucket bucket,
    String? mediaId,
    String? targetMediaId,
    Uint8List? bytes,
  }) async {
    final requestId = const Uuid().v4();
    final completer = Completer<JSObject>();
    final worker = _getWorker();
    _pending[requestId] = completer;

    final message = JSObject();
    message['type'] = type.toJS;
    message['requestId'] = requestId.toJS;
    message['scopeKey'] = scope.persistenceKey.toJS;
    message['bucket'] = bucket.pathComponent.toJS;
    if (mediaId != null) message['mediaId'] = mediaId.toJS;
    if (targetMediaId != null) message['targetMediaId'] = targetMediaId.toJS;

    if (bytes == null) {
      worker.postMessage(message);
    } else {
      // Cover bytes are also returned to Image.memory on a cache miss. Transfer
      // a copy so postMessage does not detach the caller's backing buffer.
      final actualBytes = Uint8List.fromList(bytes);
      final jsBuffer = actualBytes.buffer.toJS;
      message['fileData'] = jsBuffer;
      worker.postMessage(message, [jsBuffer].toJS);
    }

    return completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove(requestId);
        throw TimeoutException('$type timed out after ${_timeout.inSeconds}s', _timeout);
      },
    );
  }

  BookImportResult _parseImportResult(JSObject data, String bookId, String fileExtension) {
    final metadataRaw = data['metadata'];
    if (metadataRaw == null || metadataRaw.isNull || metadataRaw.isUndefined) {
      throw StateError('Worker response is missing required "metadata" field for book $bookId.');
    }
    final metadataJs = metadataRaw as JSObject;

    final title = _jsToNullableString(metadataJs['title']) ?? bookId;
    final subtitle = _jsToNullableString(metadataJs['subtitle']);
    final author = _jsToNullableString(metadataJs['author']) ?? '';
    final publisher = _jsToNullableString(metadataJs['publisher']);
    final description = _jsToNullableString(metadataJs['description']);
    final language = _jsToNullableString(metadataJs['language']);
    final isbn = _jsToNullableString(metadataJs['isbn']);
    final pageCount = _jsToNullableInt(metadataJs['pageCount']);

    // co-authors array
    final coAuthorsJs = metadataJs['coAuthors'];
    final coAuthors = <String>[];
    if (coAuthorsJs != null && !coAuthorsJs.isNull && !coAuthorsJs.isUndefined) {
      final arr = coAuthorsJs as JSArray<JSString>;
      for (var i = 0; i < arr.length; i++) {
        final item = _jsToNullableString(arr[i]);
        if (item != null) coAuthors.add(item);
      }
    }

    // Cover image
    Uint8List? coverImage;
    final coverDataJs = data['coverData'];
    if (coverDataJs != null && !coverDataJs.isNull && !coverDataJs.isUndefined) {
      coverImage = (coverDataJs as JSArrayBuffer).toDart.asUint8List();
    }
    final coverMimeType = _jsToNullableString(data['coverMimeType']);

    final fileSizeRaw = data['fileSize'];
    if (fileSizeRaw == null || fileSizeRaw.isNull || fileSizeRaw.isUndefined) {
      throw StateError('Worker response missing "fileSize" for book $bookId');
    }
    final fileSize = (fileSizeRaw as JSNumber).toDartInt;

    final fileHashRaw = _jsToNullableString(data['fileHash']);
    if (fileHashRaw == null) {
      throw StateError('Worker response is missing required "fileHash" field for book $bookId.');
    }
    final fileHash = fileHashRaw;

    return BookImportResult(
      bookId: bookId,
      title: title,
      subtitle: subtitle,
      author: author,
      coAuthors: coAuthors,
      publisher: publisher,
      description: description,
      language: language,
      isbn: isbn,
      pageCount: pageCount,
      coverImage: coverImage,
      coverMimeType: coverMimeType,
      fileSize: fileSize,
      fileHash: fileHash,
      fileExtension: fileExtension,
    );
  }

  static String? _jsToNullableString(JSAny? value) {
    if (value == null || value.isNull || value.isUndefined) return null;
    return (value as JSString).toDart;
  }

  static int? _jsToNullableInt(JSAny? value) {
    if (value == null || value.isNull || value.isUndefined) return null;
    return (value as JSNumber).toDartInt;
  }
}
