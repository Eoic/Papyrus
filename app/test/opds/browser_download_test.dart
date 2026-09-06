import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/widgets/opds/opds_browser_download.dart';

void main() {
  OpdsDownloadJob job({String rel = 'download'}) => OpdsDownloadJob(
    key: 'test',
    catalog: OpdsCatalog(id: 'one', name: 'Catalog', uri: Uri.parse('https://books.test/feed')),
    publication: OpdsPublication(id: 'book', title: 'A book'),
    link: OpdsLink(uri: Uri.parse('https://books.test/book.epub'), type: 'application/epub+zip', rels: [rel]),
  )..status = OpdsDownloadStatus.failed;

  testWidgets('web connection failure offers a manual download without marking it imported', (tester) async {
    final failed = job()..networkFailure = true;
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpdsBrowserDownload(job: failed, onOpen: (uri) => opened = uri),
        ),
      ),
    );
    if (kIsWeb) {
      expect(find.textContaining('Library → Add book'), findsOneWidget);
      await tester.tap(find.text('Download in browser'));
      expect(opened, failed.link.uri);
      expect(opened!.userInfo, isEmpty);
      expect(failed.status, OpdsDownloadStatus.failed);
      expect(failed.bookId, isNull);
    } else {
      expect(find.text('Download in browser'), findsNothing);
    }
  });

  testWidgets('manual download is absent for HTTP failures, cancelled jobs, and purchases', (tester) async {
    for (final failed in [
      job(),
      job()
        ..networkFailure = true
        ..status = OpdsDownloadStatus.cancelled,
      job(rel: 'http://opds-spec.org/acquisition/buy')..networkFailure = true,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OpdsBrowserDownload(job: failed)),
        ),
      );
      expect(find.text('Download in browser'), findsNothing);
    }
  });
}
