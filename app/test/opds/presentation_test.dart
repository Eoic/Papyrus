import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/services/book_import_session.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/opds/opds_download_panel.dart';
import 'package:papyrus/widgets/opds/opds_feed_view.dart';
import 'package:papyrus/widgets/opds/opds_publication_tile.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';
import 'package:provider/provider.dart';

final _catalog = OpdsCatalog(id: 'catalog', name: 'Public library', uri: Uri.parse('https://books.test/feed'));
final _epub = OpdsLink(
  uri: Uri.parse('https://books.test/book.epub'),
  type: 'application/epub+zip',
  title: 'EPUB with images for current e-readers',
  rels: ['download'],
);
final _pdf = OpdsLink(uri: Uri.parse('https://books.test/book.pdf'), type: 'application/pdf', rels: ['download']);
final _gateway = OpdsHttpClient(clientFactory: () => MockClient((_) async => http.Response('book', 200)));

OpdsPublication _publication({String id = 'one', String title = 'Pride and Prejudice', String? description}) =>
    OpdsPublication(
      id: id,
      title: title,
      authors: ['Jane Austen'],
      description: description,
      language: 'English',
      publisher: 'A publisher',
      links: [_epub, _pdf],
    );

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
  double width = 360,
  OpdsDownloads? downloads,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final transfers = downloads ?? OpdsDownloads(captureImport: () => throw StateError('Unused import'));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: transfers,
      child: MaterialApp(
        theme: theme,
        home: AppMotionScope(
          reduceAnimations: true,
          child: Scaffold(body: SafeArea(child: child)),
        ),
      ),
    ),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    transfers.dispose();
  });
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

BookImportSession _unusedSession() => BookImportSession(
  process: (_, _) async => throw StateError('Import must not start'),
  deleteFile: (_) async {},
  commit: (_, _) async => throw StateError('Commit must not start'),
  isCurrent: () => true,
);

class _PendingHttp extends OpdsHttpClient {
  final response = Completer<OpdsResponse>();

  @override
  Future<OpdsResponse> get(
    OpdsCatalog catalog,
    Uri uri, {
    OpdsCredentials? credentials,
    OpdsCancellation? cancellation,
    void Function(int, int?)? onProgress,
    int maxBytes = 8 * 1024 * 1024,
  }) {
    cancellation?.addListener(() {
      if (!response.isCompleted) response.completeError(const OpdsCancelled());
    });
    onProgress?.call(512, 1024);
    return response.future;
  }
}

Widget _panel(OpdsDownloads downloads, {ValueChanged<OpdsDownloadJob>? onRetry}) => AnimatedBuilder(
  animation: downloads,
  builder: (_, _) => Align(
    alignment: Alignment.bottomCenter,
    child: OpdsDownloadPanel(downloads: downloads, onRetry: onRetry ?? (_) {}),
  ),
);

void main() {
  final themes = [('light', AppTheme.light), ('dark', AppTheme.dark), ('eink', AppTheme.eink)];
  for (final (name, theme) in themes) {
    for (final width in [360.0, 1280.0]) {
      testWidgets('$name $width feed switches grid/list and keeps navigation and pagination usable', (tester) async {
        var grid = true;
        Uri? navigated;
        Uri? paged;
        final feed = OpdsFeed(
          uri: _catalog.uri,
          title: 'Popular books',
          navigation: [
            OpdsLink(
              uri: Uri.parse('https://books.test/author'),
              title: 'An author collection',
              description: 'Jane Austen · novels and stories',
              imageUri: Uri.parse('data:image/png;base64,AA=='),
            ),
          ],
          publications: [
            _publication(),
            _publication(id: 'two', title: 'Short'),
          ],
          links: [
            OpdsLink(uri: Uri.parse('https://books.test/feed?page=1'), rels: ['previous']),
            OpdsLink(uri: Uri.parse('https://books.test/feed?page=3'), rels: ['next']),
          ],
        );
        await _mount(
          tester,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatefulBuilder(
              builder: (_, setState) => OpdsFeedView(
                catalog: _catalog,
                feed: feed,
                httpClient: _gateway,
                isGridView: grid,
                onViewChanged: (value) => setState(() => grid = value),
                onNavigate: (uri) => navigated = uri,
                onPage: (uri) => paged = uri,
                onDownload: (_, _) {},
                onRefresh: () {},
              ),
            ),
          ),
          theme: theme,
          width: width,
        );
        expect(find.text('Jane Austen · novels and stories'), findsOneWidget);
        expect(find.byIcon(Icons.folder_outlined), findsNothing);
        final first = find.byKey(const ValueKey('one'));
        final second = find.byKey(const ValueKey('two'));
        expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
        expect(tester.getTopLeft(second).dx, greaterThan(tester.getTopLeft(first).dx));
        expect(
          tester.getBottomLeft(find.descendant(of: first, matching: find.byType(OpdsCover))).dy,
          tester.getBottomLeft(find.descendant(of: second, matching: find.byType(OpdsCover))).dy,
          reason: 'Grid covers align when titles occupy different numbers of lines.',
        );
        await tester.tap(find.text('An author collection'));
        expect(navigated, Uri.parse('https://books.test/author'));
        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(first).dx, tester.getTopLeft(second).dx);
        expect(tester.getTopLeft(second).dy, greaterThan(tester.getTopLeft(first).dy));
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
        await tester.scrollUntilVisible(find.text('Next'), 200, scrollable: find.byType(Scrollable).first);
        final previous = find.widgetWithText(OutlinedButton, 'Previous');
        final next = find.widgetWithText(OutlinedButton, 'Next');
        expect(tester.getSize(previous).width, lessThanOrEqualTo(width - 32));
        expect(tester.getRect(previous).overlaps(tester.getRect(next)), isFalse);
        expect(tester.getSize(next).width, lessThan(160));
        expect(tester.getRect(previous).left, greaterThanOrEqualTo(16));
        expect(tester.getRect(next).right, lessThanOrEqualTo(width - 16));
        await tester.tap(next);
        expect(paged, feed.nextLink!.uri);
        await tester.tap(previous);
        expect(paged, feed.previousLink!.uri);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$name 360 details expand a long description while download formats stay reachable', (tester) async {
      final description = List.generate(
        12,
        (index) =>
            'Paragraph ${index + 1}. This edition includes notes about the story, its characters, and the original publication.',
      ).join('\n\n');
      final selected = <OpdsLink>[];
      await _mount(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: OpdsPublicationTile(
              catalog: _catalog,
              publication: _publication(description: description),
              httpClient: _gateway,
              onNavigate: (_) {},
              onDownload: selected.add,
            ),
          ),
        ),
        theme: theme,
      );
      await tester.tap(find.text('Pride and Prejudice'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Book details'), findsOneWidget);
      await tester.ensureVisible(find.text('Download EPUB'));
      await tester.pumpAndSettle();
      expect(find.text('Download EPUB').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Download EPUB'));
      expect(selected, [_epub]);
      final text = find.byKey(const Key('opds-description'));
      expect(tester.widget<Text>(text).maxLines, 7);
      await tester.ensureVisible(find.text('Read more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).maxLines, isNull);
      expect(tester.widget<Text>(text).data, description);
      await tester.ensureVisible(find.text('Download PDF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download PDF'));
      expect(selected, [_epub, _pdf]);
      await tester.ensureVisible(find.text('Show less'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).maxLines, 7);
      expect(find.text('Close').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('360 details can expand a short description that wraps beyond seven lines', (tester) async {
    final description = List.filled(4, 'A sentence with enough words to wrap at this width.').join('\n');
    expect(description.length, lessThan(320));
    final publication = OpdsPublication(
      id: 'short-description',
      title: 'Book with notes',
      description: description,
      links: [_epub],
    );
    await _mount(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: OpdsPublicationTile(
          catalog: _catalog,
          publication: publication,
          httpClient: _gateway,
          onNavigate: (_) {},
          onDownload: (_) {},
        ),
      ),
      theme: AppTheme.light,
    );
    await tester.tap(find.text('Book with notes'));
    await tester.pumpAndSettle();
    expect(find.text('Read more'), findsOneWidget);
    await tester.ensureVisible(find.text('Read more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('opds-description'))).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 download panel stays compact and protects active transfers until cancelled', (tester) async {
    final gateway = _PendingHttp();
    final downloads = OpdsDownloads(httpClient: gateway, captureImport: _unusedSession);
    final operation = downloads.start(_catalog, _publication(), _epub);
    await _mount(tester, _panel(downloads), theme: AppTheme.eink, downloads: downloads);
    expect(find.text('Downloads · 1 in progress'), findsOneWidget);
    expect(find.text('Pride and Prejudice'), findsNothing);
    expect(tester.getSize(find.byType(OpdsDownloadPanel)).height, lessThan(80));
    downloads.dismiss(downloads.jobs.single.key);
    expect(downloads.jobs, hasLength(1));
    await tester.tap(find.text('Downloads · 1 in progress'));
    await tester.pumpAndSettle();
    expect(find.text('Downloading · 50%'), findsOneWidget);
    expect(tester.widget<AppLinearProgressIndicator>(find.byType(AppLinearProgressIndicator)).value, 0.5);
    expect(find.byTooltip('Dismiss download'), findsNothing);
    expect(find.byTooltip('Cancel download'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel download'));
    await operation;
    await _settle(tester);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.byTooltip('Cancel download'), findsNothing);
    await tester.tap(find.byTooltip('Dismiss download'));
    await tester.pumpAndSettle();
    expect(downloads.jobs, isEmpty);
    expect(find.textContaining('Downloads ·'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 collapsed download panel announces errors and exposes retry and dismiss', (tester) async {
    final gateway = _PendingHttp();
    final downloads = OpdsDownloads(httpClient: gateway, captureImport: _unusedSession);
    final operation = downloads.start(_catalog, _publication(), _epub);
    final retried = <OpdsDownloadJob>[];
    await _mount(
      tester,
      _panel(downloads, onRetry: retried.add),
      theme: AppTheme.dark,
      downloads: downloads,
    );
    gateway.response.completeError(const OpdsException('The catalog could not send this book.'));
    await operation;
    await _settle(tester);
    expect(find.text('Downloads · 1 failed'), findsOneWidget);
    expect(find.text('The catalog could not send this book.'), findsNothing);
    await tester.tap(find.text('Downloads · 1 failed'));
    await tester.pumpAndSettle();
    expect(find.text('The catalog could not send this book.'), findsOneWidget);
    expect(find.byType(AppLinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retried.single, same(downloads.jobs.single));
    await tester.tap(find.byTooltip('Dismiss download'));
    await tester.pumpAndSettle();
    expect(downloads.jobs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1280 download panel protects the commit phase then allows completed dismissal', (tester) async {
    final finish = Completer<Book>();
    final downloads = OpdsDownloads(
      httpClient: _gateway,
      captureImport: () => BookImportSession(
        process: (Uint8List _, String _) async => const BookImportResult(
          bookId: 'imported',
          title: 'Book',
          author: 'Author',
          fileSize: 4,
          fileHash: 'hash',
          fileExtension: 'epub',
        ),
        deleteFile: (_) async {},
        isCurrent: () => true,
        commit: (_, _) => finish.future,
      ),
    );
    final operation = downloads.start(_catalog, _publication(), _epub);
    await _mount(tester, _panel(downloads), theme: AppTheme.light, width: 1280, downloads: downloads);
    expect(downloads.jobs.single.status, OpdsDownloadStatus.committing);
    await tester.tap(find.text('Downloads · 1 in progress'));
    await tester.pumpAndSettle();
    expect(find.text('Adding to library…'), findsOneWidget);
    expect(find.byTooltip('Cancel download'), findsNothing);
    expect(find.byTooltip('Dismiss download'), findsNothing);
    downloads.dismiss(downloads.jobs.single.key);
    expect(downloads.jobs, hasLength(1));
    finish.complete(Book(id: 'imported', title: 'Book', author: 'Author', addedAt: DateTime(2026)));
    await operation;
    await _settle(tester);
    expect(find.text('Downloads · 1 finished'), findsOneWidget);
    expect(find.text('Open book'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss download'));
    await tester.pumpAndSettle();
    expect(downloads.jobs, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
