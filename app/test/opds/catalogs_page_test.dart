import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papyrus/opds/opds_catalog_store.dart';
import 'package:papyrus/opds/opds_catalogs.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/pages/catalogs_page.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_store_test.dart' show MemorySecrets;

class _WidgetCatalogStore extends OpdsCatalogStore {
  _WidgetCatalogStore(super.prefs) : super(secrets: MemorySecrets());
  String? saveFailure;
  String? removeFailure;

  @override
  Future<void> save(String scope, OpdsCatalog catalog, {OpdsCredentials? credentials, bool clearCredentials = false}) {
    if (saveFailure != null) throw OpdsException(saveFailure!);
    return super.save(scope, catalog, credentials: credentials, clearCredentials: clearCredentials);
  }

  @override
  Future<void> remove(String scope, String id) {
    if (removeFailure != null) throw OpdsException(removeFailure!);
    return super.remove(scope, id);
  }
}

class _CatalogPageHarness {
  _CatalogPageHarness(this.store, this.catalogs);
  final _WidgetCatalogStore store;
  final OpdsCatalogs catalogs;
  final requests = <Uri>[];
  int importAttempts = 0;
  late final OpdsDownloads downloads;
  late final GoRouter router;

  static Future<_CatalogPageHarness> mount(
    WidgetTester tester,
    http.Response Function(Uri uri) respond, {
    String initialLocation = '/library/catalogs/one',
  }) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = _WidgetCatalogStore(await SharedPreferences.getInstance());
    await store.save(
      'local--guest',
      OpdsCatalog(id: 'one', name: 'My catalog', uri: Uri.parse('https://books.test/feed')),
    );
    final catalogs = OpdsCatalogs(store)..setScope('local--guest');
    final harness = _CatalogPageHarness(store, catalogs);
    final gateway = OpdsHttpClient(
      clientFactory: () => MockClient((request) async {
        harness.requests.add(request.url);
        return respond(request.url);
      }),
    );
    harness.downloads = OpdsDownloads(
      httpClient: gateway,
      captureImport: () {
        harness.importAttempts++;
        throw StateError('This widget test must not start an import');
      },
    );
    Widget page(GoRouterState state) => CatalogsPage(
      catalogId: state.pathParameters['catalogId'],
      feedUri: state.uri.queryParameters['feed'] == null ? null : Uri.parse(state.uri.queryParameters['feed']!),
      query: state.uri.queryParameters['q'] ?? '',
      httpClient: gateway,
    );
    harness.router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/library/catalogs',
          builder: (_, _) => CatalogsPage(httpClient: gateway),
          routes: [GoRoute(path: ':catalogId', builder: (_, state) => page(state))],
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catalogs),
          ChangeNotifierProvider.value(value: harness.downloads),
        ],
        child: MaterialApp.router(
          theme: AppTheme.eink,
          routerConfig: harness.router,
          builder: (_, child) => AppMotionScope(reduceAnimations: true, child: Scaffold(body: child!)),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.router.dispose();
      harness.catalogs.dispose();
      harness.downloads.dispose();
    });
    await _settleNetwork(tester);
    return harness;
  }
}

Future<void> _settleNetwork(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

http.Response _feedResponse(
  String title, {
  List<Map<String, dynamic>> publications = const [],
  List<Map<String, dynamic>> links = const [],
}) => http.Response(
  jsonEncode({
    'metadata': {'title': title},
    'publications': publications,
    'links': links,
  }),
  200,
  headers: {'content-type': 'application/opds+json'},
);

Map<String, dynamic> _book() => {
  'metadata': {'identifier': 'book-one', 'title': 'A book', 'author': 'An author'},
  'links': [
    {'rel': 'download', 'href': '/book.epub', 'type': 'application/epub+zip'},
  ],
};

void main() {
  testWidgets('expanded transfers leave room for catalog search when the keyboard opens', (tester) async {
    final harness = await _CatalogPageHarness.mount(tester, (_) => _feedResponse('Books'));
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetViewInsets);
    for (var index = 0; index < 3; index++) {
      await harness.downloads.start(
        harness.catalogs.catalogs.single,
        OpdsPublication(id: 'download-$index', title: 'A failed download $index'),
        OpdsLink(uri: Uri.parse('https://books.test/book.epub'), type: 'application/epub+zip', rels: ['download']),
      );
    }
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Downloads ·'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsWidgets);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    expect(tester.getBottomLeft(find.byType(TextField)).dy, lessThan(340));
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsWidgets);
  });

  testWidgets('facet choices and collection View all links navigate to their feeds', (tester) async {
    final harness = await _CatalogPageHarness.mount(tester, (uri) {
      if (uri.path == '/filtered') return _feedResponse('Filtered books');
      if (uri.path == '/collection') return _feedResponse('Full collection');
      return http.Response(
        jsonEncode({
          'metadata': {'title': 'Browse books'},
          'facets': [
            {
              'metadata': {'title': 'Language'},
              'links': [
                {'title': 'English', 'href': '/filtered?language=en'},
              ],
            },
          ],
          'groups': [
            {
              'metadata': {'title': 'Featured'},
              'publications': [_book()],
              'links': [
                {'rel': 'collection', 'href': '/collection'},
              ],
            },
          ],
        }),
        200,
      );
    });
    expect(find.text('Language:'), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'English'));
    await _settleNetwork(tester);
    expect(find.text('Filtered books'), findsOneWidget);
    expect(harness.requests.last, Uri.parse('https://books.test/filtered?language=en'));
    await tester.tap(find.byTooltip('Catalog home'));
    await _settleNetwork(tester);
    await tester.tap(find.text('View all'));
    await _settleNetwork(tester);
    expect(find.text('Full collection'), findsOneWidget);
    expect(harness.requests.last, Uri.parse('https://books.test/collection'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('search keeps encoded feed and query through pagination, refresh and route history', (tester) async {
    const query = 'tea & coffee/ž';
    final searchUri = Uri.https('books.test', '/search', {'query': query});
    final pageTwoUri = searchUri.replace(queryParameters: {'query': query, 'page': '2'});
    final harness = await _CatalogPageHarness.mount(tester, (uri) {
      if (uri.path == '/search') {
        final pageTwo = uri.queryParameters['page'] == '2';
        return _feedResponse(
          pageTwo ? 'Search page two' : 'Search results',
          links: [
            {'rel': pageTwo ? 'previous' : 'next', 'href': (pageTwo ? searchUri : pageTwoUri).toString()},
          ],
        );
      }
      return _feedResponse(
        'Catalog home feed',
        links: [
          {'rel': 'search', 'href': 'https://books.test/search{?query}', 'templated': true},
        ],
      );
    });
    final homeRoute = harness.router.routeInformationProvider.value.uri;
    await tester.enterText(find.byType(TextField), query);
    await tester.tap(find.byTooltip('Search catalog'));
    await _settleNetwork(tester);
    expect(find.text('Search results'), findsOneWidget);
    final searchRoute = harness.router.routeInformationProvider.value.uri;
    expect(searchRoute.queryParameters['q'], query);
    final encodedFeed = Uri.parse(searchRoute.queryParameters['feed']!);
    expect(encodedFeed.queryParameters, {'query': query});
    expect(harness.requests.last.queryParameters, {'query': query});
    await tester.tap(find.text('Next'));
    await _settleNetwork(tester);
    expect(find.text('Search page two'), findsOneWidget);
    expect(harness.router.routeInformationProvider.value.uri.queryParameters['q'], query);
    await tester.tap(find.text('Previous'));
    await _settleNetwork(tester);
    expect(find.text('Search results'), findsOneWidget);
    final requestsBeforeRefresh = harness.requests.length;
    await tester.tap(find.byTooltip('Refresh catalog'));
    await _settleNetwork(tester);
    expect(harness.requests.length, requestsBeforeRefresh + 1);
    expect(harness.requests.last.queryParameters, {'query': query});
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, query);

    // The browser delivers history entries through the route information provider.
    await harness.router.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: homeRoute));
    await _settleNetwork(tester);
    expect(find.text('Catalog home feed'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    await harness.router.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: searchRoute));
    await _settleNetwork(tester);
    expect(find.text('Search results'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, query);
    expect(harness.requests.last.queryParameters, {'query': query});
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit and remove failures keep the saved catalog and allow retry', (tester) async {
    final harness = await _CatalogPageHarness.mount(
      tester,
      (_) => _feedResponse('Books'),
      initialLocation: '/library/catalogs',
    );
    harness.store.saveFailure = 'Catalog save failed.';
    await tester.tap(find.byTooltip('Catalog options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('opds-name')), 'Renamed catalog');
    await tester.tap(find.text('Save'));
    await _settleNetwork(tester);
    expect(find.text('Catalog save failed.'), findsOneWidget);
    expect(find.byKey(const Key('opds-name')), findsOneWidget);
    expect(harness.catalogs.catalogs.single.name, 'My catalog');
    harness.store.saveFailure = null;
    await tester.tap(find.text('Save'));
    await _settleNetwork(tester);
    expect(find.byKey(const Key('opds-name')), findsNothing);
    expect(find.text('Renamed catalog'), findsOneWidget);

    harness.store.removeFailure = 'Catalog removal failed.';
    await tester.tap(find.byTooltip('Catalog options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await _settleNetwork(tester);
    expect(find.text('Catalog removal failed.'), findsOneWidget);
    expect(find.text('Renamed catalog'), findsOneWidget);
    expect(harness.catalogs.catalogs, hasLength(1));
    harness.store.removeFailure = null;
    await tester.tap(find.byTooltip('Catalog options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await _settleNetwork(tester);
    expect(find.text('No catalogs yet'), findsOneWidget);
    expect(harness.catalogs.catalogs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed feed can retry to empty results and refresh to books', (tester) async {
    var attempt = 0;
    final harness = await _CatalogPageHarness.mount(tester, (_) {
      attempt++;
      if (attempt == 1) return http.Response('Unavailable', 503);
      return _feedResponse('Books', publications: attempt == 2 ? [] : [_book()]);
    });
    expect(
      find.textContaining('HTTP 503'),
      findsOneWidget,
      reason:
          'requests=${harness.requests}; texts=${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).join(' | ')}',
    );
    await tester.tap(find.text('Retry'));
    await _settleNetwork(tester);
    expect(find.textContaining('HTTP 503'), findsNothing);
    expect(find.text('No books or sections found.'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh catalog'));
    await _settleNetwork(tester);
    expect(find.text('A book'), findsOneWidget);
    expect(find.text('No books or sections found.'), findsNothing);
    expect(harness.requests, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('open publication details cannot download after catalog or account changes', (tester) async {
    final harness = await _CatalogPageHarness.mount(tester, (_) => _feedResponse('Books', publications: [_book()]));
    for (final changeAccount in [false, true]) {
      await tester.tap(find.text('A book'));
      await tester.pumpAndSettle();
      expect(find.text('Download EPUB'), findsOneWidget);
      if (changeAccount) {
        harness.catalogs.setScope('local--other');
      } else {
        await harness.catalogs.save(
          OpdsCatalog(id: 'one', name: 'Changed catalog', uri: Uri.parse('https://other-books.test/feed')),
        );
      }
      await _settleNetwork(tester);
      await tester.tap(find.text('Download EPUB'));
      await _settleNetwork(tester);
      expect(find.text('The catalog or account changed. Close these details and reopen the book.'), findsOneWidget);
      expect(harness.downloads.jobs, isEmpty);
      expect(harness.importAttempts, 0);
      expect(harness.requests.where((uri) => uri.path.endsWith('.epub')), isEmpty);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('an editor opened in another account cannot save into the active account', (tester) async {
    final harness = await _CatalogPageHarness.mount(
      tester,
      (_) => _feedResponse('Books'),
      initialLocation: '/library/catalogs',
    );
    await tester.tap(find.byTooltip('Catalog options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('opds-name')), 'Wrong account catalog');
    harness.catalogs.setScope('local--other');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await _settleNetwork(tester);
    expect(find.text('The active account changed. Close this editor and try again.'), findsOneWidget);
    expect(find.byKey(const Key('opds-name')), findsOneWidget);
    expect(harness.catalogs.catalogs, isEmpty);
    expect(harness.store.load('local--other'), isEmpty);
    expect(harness.store.load('local--guest').single.name, 'My catalog');
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1280.0]) {
    testWidgets('add and browse a catalog at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final catalogs = OpdsCatalogs(OpdsCatalogStore(await SharedPreferences.getInstance(), secrets: MemorySecrets()))
        ..setScope('local--guest');
      final downloads = OpdsDownloads(captureImport: () => throw StateError('unused'));
      final gateway = OpdsHttpClient(
        clientFactory: () => MockClient(
          (_) async => http.Response(
            '{"metadata":{"title":"Fixture books"},"publications":[{"metadata":{"title":"A book","author":"An author"},"links":[{"rel":"http://opds-spec.org/acquisition/open-access","href":"book.epub","type":"application/epub+zip"}]}]}',
            200,
          ),
        ),
      );
      final router = GoRouter(
        initialLocation: '/library/catalogs',
        routes: [
          GoRoute(
            path: '/library/catalogs',
            builder: (_, _) => CatalogsPage(httpClient: gateway),
            routes: [
              GoRoute(
                path: ':catalogId',
                builder: (_, state) => CatalogsPage(catalogId: state.pathParameters['catalogId'], httpClient: gateway),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: catalogs),
            ChangeNotifierProvider.value(value: downloads),
          ],
          child: MaterialApp.router(
            theme: AppTheme.eink,
            routerConfig: router,
            builder: (_, child) => AppMotionScope(reduceAnimations: true, child: Scaffold(body: child!)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No catalogs yet'), findsOneWidget);
      await tester.tap(find.text('Add catalog').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('opds-name')), 'My catalog');
      await tester.enterText(find.byKey(const Key('opds-url')), 'https://books.test/feed');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('My catalog'), findsOneWidget);
      await tester.tap(find.text('My catalog'));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(
        find.text('A book'),
        findsOneWidget,
        reason:
            '${tester.widgetList<Text>(find.byType(Text)).map((widget) => widget.data).join(' | ')}; progress=${find.byType(CircularProgressIndicator).evaluate().length}',
      );
      expect(find.text('An author'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      catalogs.dispose();
      downloads.dispose();
    });
  }
}
