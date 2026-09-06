import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/services/book_import_session.dart';
import 'package:papyrus/services/book_import_result.dart';

void main() {
  final catalog = OpdsCatalog(id: 'c', name: 'Books', uri: Uri.parse('https://books.test/feed'));
  final link = OpdsLink(
    uri: Uri.parse('https://books.test/book.epub'),
    type: 'application/epub+zip',
    rels: ['http://opds-spec.org/acquisition/open-access'],
  );
  final publication = OpdsPublication(id: 'p', title: 'Catalog title', authors: ['Catalog author'], links: [link]);
  BookImportResult result() => const BookImportResult(
    bookId: 'imported',
    title: 'book',
    author: 'Unknown',
    fileSize: 4,
    fileHash: 'hash',
    fileExtension: 'epub',
  );

  test('rejects a disguised login page before importing a text download', () async {
    var processed = false;
    final textLink = OpdsLink(
      uri: Uri.parse('https://books.test/book.txt'),
      type: 'text/plain',
      rels: ['http://opds-spec.org/acquisition'],
    );
    final downloads = OpdsDownloads(
      httpClient: OpdsHttpClient(
        clientFactory: () =>
            MockClient((_) async => http.Response('<!DOCTYPE html><html><body>Sign in</body></html>', 200)),
      ),
      captureImport: () => BookImportSession(
        process: (_, _) async {
          processed = true;
          return result();
        },
        deleteFile: (_) async {},
        isCurrent: () => true,
        commit: (_, _) async => throw StateError('unused'),
      ),
    );
    await downloads.start(catalog, publication, textLink);
    expect(processed, isFalse);
    expect(downloads.jobs.single.status, OpdsDownloadStatus.failed);
    downloads.dispose();
  });

  test('commits a downloaded book and fills missing embedded metadata', () async {
    BookImportResult? imported;
    final downloads = OpdsDownloads(
      httpClient: OpdsHttpClient(clientFactory: () => MockClient((_) async => http.Response('book', 200))),
      captureImport: () => BookImportSession(
        process: (_, _) async => result(),
        deleteFile: (_) async {},
        isCurrent: () => true,
        commit: (value, _) async {
          imported = value;
          return Book(id: value.bookId, title: value.title, author: value.author, addedAt: DateTime.now());
        },
      ),
    );
    await downloads.start(catalog, publication, link);
    expect(imported?.title, 'Catalog title');
    expect(imported?.author, 'Catalog author');
    expect(downloads.jobs.single.status, OpdsDownloadStatus.complete);
    downloads.dispose();
  });

  test('the final commit phase does not offer cancellation', () async {
    final committing = Completer<void>();
    final finish = Completer<Book>();
    final downloads = OpdsDownloads(
      httpClient: OpdsHttpClient(clientFactory: () => MockClient((_) async => http.Response('book', 200))),
      captureImport: () => BookImportSession(
        process: (_, _) async => result(),
        deleteFile: (_) async {},
        isCurrent: () => true,
        commit: (_, _) {
          committing.complete();
          return finish.future;
        },
      ),
    );
    final operation = downloads.start(catalog, publication, link);
    await committing.future;
    expect(downloads.jobs.single.isCancellable, isFalse);
    downloads.cancel(downloads.jobs.single.key);
    finish.complete(Book(id: 'imported', title: 'Title', author: 'Author', addedAt: DateTime.now()));
    await operation;
    expect(downloads.jobs.single.status, OpdsDownloadStatus.complete);
    downloads.dispose();
  });

  test('account change while processing cleans up without committing', () async {
    final processing = Completer<BookImportResult>();
    final started = Completer<void>();
    final deleted = <String>[];
    var commits = 0;
    final downloads = OpdsDownloads(
      httpClient: OpdsHttpClient(clientFactory: () => MockClient((_) async => http.Response('book', 200))),
      captureImport: () => BookImportSession(
        process: (Uint8List _, String _) {
          started.complete();
          return processing.future;
        },
        deleteFile: (id) async => deleted.add(id),
        isCurrent: () => true,
        commit: (_, _) async {
          commits++;
          throw StateError('must not commit');
        },
      ),
    );
    final operation = downloads.start(catalog, publication, link);
    await started.future;
    downloads.reset();
    processing.complete(result());
    await operation;
    expect(deleted, ['imported']);
    expect(commits, 0);
    expect(downloads.jobs, isEmpty);
    downloads.dispose();
  });

  test('duplicate in-flight requests share one job and failed imports clean up', () async {
    final processing = Completer<BookImportResult>();
    var requests = 0;
    final deleted = <String>[];
    final downloads = OpdsDownloads(
      httpClient: OpdsHttpClient(
        clientFactory: () => MockClient((_) async {
          requests++;
          return http.Response('book', 200);
        }),
      ),
      captureImport: () => BookImportSession(
        process: (_, _) => processing.future,
        deleteFile: (id) async => deleted.add(id),
        isCurrent: () => true,
        commit: (_, _) async => throw StateError('commit failed'),
      ),
    );
    final first = downloads.start(catalog, publication, link);
    final second = downloads.start(catalog, publication, link);
    processing.complete(result());
    await Future.wait([first, second]);
    expect(requests, 1);
    expect(deleted, ['imported']);
    expect(downloads.jobs.single.status, OpdsDownloadStatus.failed);
    downloads.dispose();
  });
}
