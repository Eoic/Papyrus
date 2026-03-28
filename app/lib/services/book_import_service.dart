import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

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

/// Service that communicates with the book_worker.js Web Worker for
/// EPUB processing and OPFS file storage.
///
/// Only available on web — methods throw [UnsupportedError] on other platforms.
class BookImportService {
  web.Worker? _worker;

  /// Incrementing counter used to guarantee unique book IDs.
  int _nextId = 0;

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
          final message =
              _jsToNullableString(obj['message']) ?? 'Unknown error';
          final error = Exception(message);
          final action = _jsToNullableString(obj['action']);
          final bookId = _jsToNullableString(obj['bookId']);
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
          final bookId = _jsToNullableString(obj['bookId']);
          if (action == null || bookId == null) return;

          final key = '$action:$bookId';
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

    final bookId = 'book-${DateTime.now().millisecondsSinceEpoch}-${_nextId++}';
    final completer = Completer<JSObject>();
    final worker = _getWorker();

    _pending['process:$bookId'] = completer;

    // Transfer bytes as ArrayBuffer for zero-copy transfer.
    // Ensure we only send the actual byte range, not the whole backing buffer.
    final actualBytes = bytes.offsetInBytes == 0 &&
            bytes.lengthInBytes == bytes.buffer.lengthInBytes
        ? bytes
        : Uint8List.fromList(bytes);
    final jsBuffer = actualBytes.buffer.toJS;
    final message = JSObject();
    message['type'] = 'process'.toJS;
    message['format'] = ext.toJS;
    message['bookId'] = bookId.toJS;
    message['fileData'] = jsBuffer;

    worker.postMessage(message, [jsBuffer].toJS);

    final obj = await completer.future;
    return _parseImportResult(obj, bookId);
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

    await completer.future;
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

    final obj = await completer.future;
    final fileDataJs = obj['fileData'];
    if (fileDataJs == null || fileDataJs.isNull || fileDataJs.isUndefined) {
      return null;
    }
    return (fileDataJs as JSArrayBuffer).toDart.asUint8List();
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

  BookImportResult _parseImportResult(JSObject data, String bookId) {
    final metadataRaw = data['metadata'];
    if (metadataRaw == null ||
        metadataRaw.isNull ||
        metadataRaw.isUndefined) {
      throw StateError(
        'Worker response is missing required "metadata" field for book $bookId.',
      );
    }
    final metadataJs = metadataRaw as JSObject;

    final title =
        _jsToNullableString(metadataJs['title']) ?? bookId;
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
      throw StateError(
        'Worker response missing "fileSize" for book $bookId',
      );
    }
    final fileSize = (fileSizeRaw as JSNumber).toDartInt;

    final fileHashRaw = _jsToNullableString(data['fileHash']);
    if (fileHashRaw == null) {
      throw StateError(
        'Worker response is missing required "fileHash" field for book $bookId.',
      );
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
