import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/services/book_import_session.dart';
import 'package:papyrus/widgets/add_book/book_import_controller.dart';

enum OpdsDownloadStatus { downloading, importing, committing, complete, failed, cancelled }

class OpdsDownloadJob {
  OpdsDownloadJob({required this.key, required this.catalog, required this.publication, required this.link});
  final String key;
  final OpdsCatalog catalog;
  final OpdsPublication publication;
  final OpdsLink link;
  final cancellation = OpdsCancellation();
  OpdsDownloadStatus status = OpdsDownloadStatus.downloading;
  int received = 0;
  int? total;
  String? error;
  String? bookId;
  bool get isCancellable => status == OpdsDownloadStatus.downloading || status == OpdsDownloadStatus.importing;
  bool get isActive => isCancellable || status == OpdsDownloadStatus.committing;
  double? get progress => total != null && total! > 0 ? received / total! : null;
}

class OpdsDownloads extends ChangeNotifier {
  OpdsDownloads({required this.captureImport, OpdsHttpClient? httpClient})
    : httpClient = httpClient ?? OpdsHttpClient();
  final BookImportSession Function() captureImport;
  final OpdsHttpClient httpClient;
  final Map<String, OpdsDownloadJob> _jobs = {};
  final Map<String, Future<void>> _operations = {};
  bool _disposed = false;
  List<OpdsDownloadJob> get jobs => List.unmodifiable(_jobs.values);

  static bool supports(OpdsLink link) =>
      (kIsWeb ? bookImportWebExtensions : bookImportNativeExtensions).contains(link.supportedExtension);
  static String jobKey(OpdsCatalog catalog, OpdsPublication publication, OpdsLink link) =>
      '${catalog.id}\n${publication.id}\n${link.uri}';

  Future<void> start(OpdsCatalog catalog, OpdsPublication publication, OpdsLink link, {OpdsCredentials? credentials}) {
    final key = jobKey(catalog, publication, link);
    if (_operations.containsKey(key)) return _operations[key]!;
    if (_disposed) return Future.value();
    final job = OpdsDownloadJob(key: key, catalog: catalog, publication: publication, link: link);
    _jobs[key] = job;
    final operation = _run(job, credentials);
    _operations[key] = operation;
    operation.whenComplete(() {
      if (identical(_operations[key], operation)) _operations.remove(key);
    });
    return operation;
  }

  Future<void> _run(OpdsDownloadJob job, OpdsCredentials? credentials) async {
    BookImportSession? session;
    BookImportResult? imported;
    var committed = false;
    void check() {
      job.cancellation.check();
      if (_disposed || !identical(_jobs[job.key], job) || (session != null && !session.isCurrent())) {
        throw const OpdsCancelled();
      }
    }

    try {
      if (!supports(job.link)) {
        throw const OpdsException('This format or acquisition method is not supported on this device.');
      }
      session = captureImport();
      check();
      _notify();
      final response = await httpClient.get(
        job.catalog,
        job.link.uri,
        credentials: credentials,
        cancellation: job.cancellation,
        maxBytes: 256 * 1024 * 1024,
        onProgress: (received, total) {
          job.received = received;
          job.total = total;
          _notify();
        },
      );
      check();
      final contentType = response.headers['content-type']?.split(';').first.trim().toLowerCase();
      final prefix = utf8
          .decode(response.bytes.take(1024).toList(), allowMalformed: true)
          .replaceFirst('\uFEFF', '')
          .trimLeft();
      final isHtml = RegExp(
        r'^(?:<\?xml[^>]*>\s*)?(?:<!doctype\s+html\b|<html\b|<head\b|<body\b)',
        caseSensitive: false,
      ).hasMatch(prefix);
      if (isHtml ||
          contentType == 'text/html' ||
          contentType == 'application/xhtml+xml' ||
          contentType == 'application/json') {
        throw const OpdsException('The catalog returned a page instead of a book file. Check access and retry.');
      }
      final extension = job.link.supportedExtension!;
      final filename = 'book.$extension';
      job.status = OpdsDownloadStatus.importing;
      _notify();
      imported = await session.process(response.bytes, filename);
      check();
      Uint8List? cover;
      String? coverMime;
      if (imported.coverImage == null && job.publication.images.isNotEmpty) {
        try {
          final response = await httpClient.get(
            job.catalog,
            job.publication.images.first.uri,
            credentials: credentials,
            cancellation: job.cancellation,
          );
          coverMime = response.headers['content-type']?.split(';').first.trim().toLowerCase();
          if (['image/jpeg', 'image/png', 'image/webp', 'image/gif'].contains(coverMime)) cover = response.bytes;
        } on OpdsCancelled {
          rethrow;
        } catch (_) {
          /* Missing artwork must not block a book import. */
        }
      }
      check();
      final result = mergeOpdsMetadata(imported, job.publication, cover: cover, coverMime: coverMime);
      job.status = OpdsDownloadStatus.committing;
      _notify();
      final book = await session.commit(result, filename);
      committed = true;
      job.bookId = book.id;
      job.status = OpdsDownloadStatus.complete;
    } on OpdsCancelled {
      job.status = OpdsDownloadStatus.cancelled;
    } catch (error) {
      job.status = OpdsDownloadStatus.failed;
      job.error = error is OpdsException ? error.message : 'Could not import this book. Please retry.';
    } finally {
      if (!committed && imported != null && session != null) {
        try {
          await session.deleteFile(imported.bookId);
        } catch (_) {
          job.error = 'Could not remove the temporary book file. Retry cleanup before downloading again.';
          job.status = OpdsDownloadStatus.failed;
        }
      }
      _notify();
    }
  }

  void cancel(String key) {
    final job = _jobs[key];
    if (job != null && job.isCancellable) job.cancellation.cancel();
    _notify();
  }

  void reset() {
    for (final job in _jobs.values) {
      job.cancellation.cancel();
    }
    _jobs.clear();
    _operations.clear();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    reset();
    super.dispose();
  }
}

BookImportResult mergeOpdsMetadata(
  BookImportResult result,
  OpdsPublication publication, {
  Uint8List? cover,
  String? coverMime,
}) {
  bool missing(String? value) =>
      value == null || value.trim().isEmpty || ['unknown', 'unknown author'].contains(value.trim().toLowerCase());
  final missingAuthor = missing(result.author);
  return BookImportResult(
    bookId: result.bookId,
    title: missing(result.title) || result.title == 'book' ? publication.title : result.title,
    subtitle: result.subtitle,
    author: missingAuthor && publication.authors.isNotEmpty ? publication.authors.first : result.author,
    coAuthors: missingAuthor && publication.authors.isNotEmpty
        ? publication.authors.skip(1).toList()
        : result.coAuthors,
    publisher: missing(result.publisher) ? publication.publisher : result.publisher,
    description: missing(result.description) ? publication.description : result.description,
    language: missing(result.language) ? publication.language : result.language,
    isbn: missing(result.isbn) ? publication.isbn : result.isbn,
    isbn13: result.isbn13,
    pageCount: result.pageCount,
    coverImage: result.coverImage ?? cover,
    coverMimeType: result.coverImage == null ? coverMime : result.coverMimeType,
    fileSize: result.fileSize,
    fileHash: result.fileHash,
    fileExtension: result.fileExtension,
  );
}
