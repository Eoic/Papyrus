import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:papyrus/acquisition/acquisition_api_client.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_models.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/auth/token_store.dart';
import 'package:papyrus/pages/acquisition_page.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/settings/settings_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRefreshTokenStorage implements RefreshTokenStorage {
  @override
  Future<void> delete() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String refreshToken) async {}
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: AuthApiClient(config: _config),
        tokenStore: TokenStore(_MemoryRefreshTokenStorage()),
      );

  @override
  Future<AuthTokens?> bootstrap() async => _tokens();

  @override
  Future<T> withFreshAccessToken<T>(Future<T> Function(String accessToken) action) {
    return action('access-token');
  }
}

class _FakeAcquisitionApiClient extends AcquisitionApiClient {
  _FakeAcquisitionApiClient() : super(config: _config, httpClient: MockClient((_) async => throw UnimplementedError()));

  AcquisitionCapabilities capabilitiesResult = const AcquisitionCapabilities(
    enabled: true,
    endpointKinds: [
      AcquisitionEndpointKind.prowlarr,
      AcquisitionEndpointKind.qbittorrent,
      AcquisitionEndpointKind.deluge,
      AcquisitionEndpointKind.readarr,
    ],
    indexerKinds: [AcquisitionEndpointKind.prowlarr],
    downloadClientKinds: [AcquisitionEndpointKind.qbittorrent, AcquisitionEndpointKind.deluge],
    arrKinds: [AcquisitionEndpointKind.readarr],
    arrCommands: {
      AcquisitionEndpointKind.readarr: ['BookSearch'],
    },
  );
  Completer<void>? connectionTestCompleter;
  int connectionTestCalls = 0;
  int listEndpointCalls = 0;
  int createEndpointCalls = 0;
  int updateEndpointCalls = 0;
  String? lastCreatedName;
  String? lastUpdatedEndpointId;
  String? lastUpdatedApiKey;
  String? lastUpdatedUsername;
  String? lastUpdatedPassword;
  List<AcquisitionEndpoint> endpointsResult = [];
  List<TorrentRelease> releasesResult = [];
  Completer<List<TorrentRelease>>? searchCompleter;
  final searchEndpointIds = <List<String>?>[];
  final submissionCompleters = <String, Completer<AcquisitionJob>>{};
  Completer<AcquisitionJob>? arrCommandCompleter;
  final arrEndpointIds = <String>[];
  final arrCommands = <String>[];
  final arrIds = <List<int>>[];

  @override
  Future<AcquisitionCapabilities> capabilities(String accessToken) async {
    return capabilitiesResult;
  }

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints(String accessToken) async {
    listEndpointCalls += 1;
    return endpointsResult;
  }

  @override
  Future<AcquisitionEndpoint> createEndpoint({
    required String accessToken,
    required String name,
    required AcquisitionEndpointKind kind,
    required Uri baseUrl,
    String? apiKey,
    String? username,
    String? password,
  }) async {
    createEndpointCalls += 1;
    lastCreatedName = name;

    return AcquisitionEndpoint(id: 'created', name: name, kind: kind, baseUrl: baseUrl, enabled: true);
  }

  @override
  Future<AcquisitionEndpoint> updateEndpoint({
    required String accessToken,
    required String endpointId,
    String? name,
    Uri? baseUrl,
    String? apiKey,
    String? username,
    String? password,
    bool? enabled,
  }) async {
    updateEndpointCalls += 1;
    lastUpdatedEndpointId = endpointId;
    lastUpdatedApiKey = apiKey;
    lastUpdatedUsername = username;
    lastUpdatedPassword = password;

    return endpointsResult.singleWhere((endpoint) => endpoint.id == endpointId);
  }

  @override
  Future<void> testEndpoint({
    required String accessToken,
    String? endpointId,
    AcquisitionEndpointKind? kind,
    Uri? baseUrl,
    String? apiKey,
    String? username,
    String? password,
  }) {
    connectionTestCalls += 1;
    return connectionTestCompleter?.future ?? Future<void>.value();
  }

  @override
  Future<List<TorrentRelease>> search({
    required String accessToken,
    required String query,
    List<String>? endpointIds,
  }) async {
    searchEndpointIds.add(endpointIds);
    return searchCompleter?.future ?? releasesResult;
  }

  @override
  Future<AcquisitionJob> submitRelease({
    required String accessToken,
    required String endpointId,
    required TorrentRelease release,
    String? category,
    String? savePath,
  }) {
    final key = _fakeSubmissionKey(release, endpointId);
    return submissionCompleters.putIfAbsent(key, Completer<AcquisitionJob>.new).future;
  }

  @override
  Future<AcquisitionJob> runArrCommand({
    required String accessToken,
    required String endpointId,
    required String command,
    required List<int> ids,
  }) {
    arrEndpointIds.add(endpointId);
    arrCommands.add(command);
    arrIds.add(ids);
    return arrCommandCompleter?.future ?? Future.value(_job(status: 'submitted'));
  }
}

final _config = PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test'));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'acquisition_enabled': true});
  });

  testWidgets('integration dialog shows credentials required by type', (tester) async {
    final apiClient = _FakeAcquisitionApiClient();
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    await _tapSectionAdd(tester, 'acquisition-sources-section');

    expect(find.byKey(const Key('acquisition-api-key')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-username')), findsNothing);
    expect(find.byKey(const Key('acquisition-password')), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await _tapSectionAdd(tester, 'acquisition-clients-section');

    expect(find.byKey(const Key('acquisition-api-key')), findsNothing);
    expect(find.byKey(const Key('acquisition-username')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<AcquisitionEndpointKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deluge').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-api-key')), findsNothing);
    expect(find.byKey(const Key('acquisition-username')), findsNothing);
    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);
  });

  testWidgets('integration dialog locks actions and renders test errors', (tester) async {
    final apiClient = _FakeAcquisitionApiClient();
    final completer = Completer<void>();
    apiClient.connectionTestCompleter = completer;
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    await _tapSectionAdd(tester, 'acquisition-sources-section');
    await tester.enterText(find.byKey(const Key('acquisition-name')), 'Prowlarr');
    await tester.enterText(find.byKey(const Key('acquisition-url')), 'http://prowlarr.local:9696');
    await tester.scrollUntilVisible(
      find.byKey(const Key('acquisition-test-connection')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('acquisition-test-connection')));
    await tester.pump();

    expect(apiClient.connectionTestCalls, 1);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('acquisition-test-connection'))).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('acquisition-save'))).onPressed, isNull);

    await tester.tap(find.byKey(const Key('acquisition-test-connection')), warnIfMissed: false);
    await tester.pump();
    expect(apiClient.connectionTestCalls, 1);

    completer.completeError(const AuthApiException(statusCode: 502, message: 'Prowlarr connection test failed'));
    await tester.pumpAndSettle();

    expect(find.text('Prowlarr connection test failed'), findsOneWidget);
  });

  testWidgets('integration editor creates and reloads through the authenticated page API', (tester) async {
    final apiClient = _FakeAcquisitionApiClient();
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    await _tapSectionAdd(tester, 'acquisition-sources-section');
    await tester.enterText(find.byKey(const Key('acquisition-name')), 'Home Prowlarr');
    await tester.enterText(find.byKey(const Key('acquisition-url')), 'https://prowlarr.local');
    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pumpAndSettle();

    expect(apiClient.createEndpointCalls, 1);
    expect(apiClient.lastCreatedName, 'Home Prowlarr');
    expect(apiClient.listEndpointCalls, 2);
  });

  testWidgets('integration editor updates without replacing blank credentials', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne];
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('acquisition-endpoint-indexer-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pumpAndSettle();

    expect(apiClient.updateEndpointCalls, 1);
    expect(apiClient.lastUpdatedEndpointId, _indexerOne.id);
    expect(apiClient.lastUpdatedApiKey, isNull);
    expect(apiClient.lastUpdatedUsername, isNull);
    expect(apiClient.lastUpdatedPassword, isNull);
    expect(apiClient.listEndpointCalls, 2);
  });

  testWidgets('search and submission requires selected indexer and client', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne, _indexerTwo, _clientOne];
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilterChip, 'Indexer One'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Indexer Two'));
    await tester.pump();

    expect(tester.widget<TextField>(_searchField).enabled, isFalse);

    await tester.tap(find.widgetWithText(FilterChip, 'Indexer One'));
    await tester.pump();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(apiClient.searchEndpointIds, [
      ['indexer-1'],
    ]);
  });

  testWidgets('search action exposes an accessible label', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne, _clientOne];
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Search releases'), findsOneWidget);
    expect(find.bySemanticsLabel('Search releases'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('search and submission requires an enabled download client', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne];
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(_searchField).enabled, isFalse);
  });

  testWidgets('results stay hidden before an explicit search', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne, _clientOne];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-results-section')), findsNothing);
    expect(find.text('No releases found.'), findsNothing);
  });

  testWidgets('typing a query and rebuilding search controls does not show results', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne, _clientOne];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.widgetWithText(FilterChip, 'Indexer One'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Indexer One'));
    await tester.pump();

    expect(find.byKey(const Key('acquisition-results-section')), findsNothing);
    expect(find.text('No releases found.'), findsNothing);
  });

  testWidgets('an explicit empty search shows the quiet results state', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne, _clientOne];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'missing book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final resultsSection = find.byKey(const Key('acquisition-results-section'));
    expect(resultsSection, findsOneWidget);
    expect(find.descendant(of: resultsSection, matching: find.text('No releases found.')), findsOneWidget);
  });

  testWidgets('release results use quiet rows without nested cards', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()
      ..endpointsResult = [_indexerOne, _clientOne]
      ..releasesResult = [_releaseOne];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final resultsSection = find.byKey(const Key('acquisition-results-section'));
    expect(find.descendant(of: resultsSection, matching: find.byType(Card)), findsNothing);
    expect(find.descendant(of: resultsSection, matching: find.byType(ListTile)), findsOneWidget);
    expect(find.descendant(of: resultsSection, matching: find.text('Release One')), findsOneWidget);
  });

  testWidgets('duplicate download URLs retain independent row and submission identities', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()
      ..endpointsResult = [_indexerOne, _indexerTwo, _clientOne]
      ..releasesResult = [_releaseOne, _releaseMirror];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final resultsSection = find.byKey(const Key('acquisition-results-section'));
    final releaseRows = tester.widgetList<ListTile>(
      find.descendant(of: resultsSection, matching: find.byType(ListTile)),
    );

    expect(releaseRows.map((row) => row.key).toSet(), hasLength(2));

    _submissionMenu(tester, _releaseOne).onSelected?.call(_clientOne);
    await tester.pump();

    expect(_submissionItem(tester, _releaseOne, _clientOne).enabled, isFalse);
    expect(_submissionItem(tester, _releaseMirror, _clientOne).enabled, isTrue);
    expect(_submissionMenu(tester, _releaseMirror).enabled, isTrue);

    apiClient.submissionCompleters[_fakeSubmissionKey(_releaseOne, _clientOne.id)]!.complete(_job(status: 'submitted'));
    await tester.pumpAndSettle();
  });

  testWidgets('refresh invalidates results from a pending search', (tester) async {
    final searchCompleter = Completer<List<TorrentRelease>>();
    final apiClient = _FakeAcquisitionApiClient()
      ..endpointsResult = [_indexerOne, _clientOne]
      ..searchCompleter = searchCompleter;

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await tester.pump();

    searchCompleter.complete([_releaseOne]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-results-section')), findsNothing);
    expect(find.text('Release One'), findsNothing);
  });

  testWidgets('refresh prevents a stale search error from replacing current state', (tester) async {
    final searchCompleter = Completer<List<TorrentRelease>>();
    final apiClient = _FakeAcquisitionApiClient()
      ..endpointsResult = [_indexerOne, _clientOne]
      ..searchCompleter = searchCompleter;

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await tester.pump();

    searchCompleter.completeError(const AuthApiException(statusCode: 502, message: 'Stale search failed'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-results-section')), findsNothing);
    expect(find.text('Stale search failed'), findsNothing);
    expect(find.text('Search failed. Check your torrent indexers.'), findsNothing);
  });

  testWidgets('search and submission scopes progress and shows job failure', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()
      ..endpointsResult = [_indexerOne, _clientOne, _clientTwo]
      ..releasesResult = [_releaseOne, _releaseTwo];
    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();
    await tester.enterText(_searchField, 'book');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final resultsSection = find.byKey(const Key('acquisition-results-section'));
    expect(resultsSection, findsOneWidget);
    expect(find.descendant(of: resultsSection, matching: find.text('Release One')), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Release One'), 400, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client One').last);
    await tester.pump();

    expect(_submissionItem(tester, _releaseOne, _clientOne).enabled, isFalse);
    expect(_submissionItem(tester, _releaseOne, _clientTwo).enabled, isTrue);

    final releaseTwoTile = find.ancestor(of: find.text('Release Two'), matching: find.byType(ListTile));
    final releaseTwoMenu = find.descendant(
      of: releaseTwoTile,
      matching: find.byType(PopupMenuButton<AcquisitionEndpoint>),
    );
    expect(tester.widget<PopupMenuButton<AcquisitionEndpoint>>(releaseTwoMenu).enabled, isTrue);

    apiClient.submissionCompleters[_fakeSubmissionKey(_releaseOne, _clientOne.id)]!.complete(
      _job(status: 'failed', error: 'Transmission rejected the release'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transmission rejected the release'), findsOneWidget);
    expect(find.text('Sent to Client One.'), findsNothing);
  });

  testWidgets('acquisition page uses the constrained settings-section layout', (tester) async {
    final apiClient = _FakeAcquisitionApiClient();

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Acquisition'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('acquisition-search-section')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-sources-section')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-clients-section')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-apps-section')), findsOneWidget);
    expect(find.text('Search releases'), findsOneWidget);
    expect(find.text('No sources configured'), findsOneWidget);
    expect(find.text('No download clients configured'), findsOneWidget);
    expect(find.text('No connected apps configured'), findsOneWidget);
    expect(find.text('Torrent indexers'), findsNothing);
    expect(find.byType(SettingsCard), findsNWidgets(4));
    expect(find.byType(Card), findsNothing);

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.padding, const EdgeInsets.all(Spacing.md));
    expect(
      find.ancestor(
        of: find.byKey(const Key('acquisition-search-section')),
        matching: find.byWidgetPredicate((widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 760),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('acquisition-search-section')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Column && widget.crossAxisAlignment == CrossAxisAlignment.stretch,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.byKey(const Key('acquisition-search-section')), matching: find.byType(Center)),
      findsOneWidget,
    );
  });

  testWidgets('integration rows expose role status and contextual action variants', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_indexerOne, _pausedClient, _readarr];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Prowlarr • indexer-one.local • Enabled'), findsOneWidget);
    expect(find.text('Transmission • paused-client.local • Paused'), findsOneWidget);
    expect(find.text('Readarr • readarr.local • Enabled'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('acquisition-endpoint-indexer-1')),
        matching: find.byIcon(Icons.travel_explore),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('acquisition-endpoint-paused-client')),
        matching: find.byIcon(Icons.downloading_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('acquisition-endpoint-arr-1')),
        matching: find.byIcon(Icons.auto_awesome_motion_outlined),
      ),
      findsOneWidget,
    );

    expect(_endpointMenuValues(tester, _indexerOne), ['edit', 'delete']);
    expect(_endpointMenuValues(tester, _pausedClient), ['edit', 'delete']);
    expect(_endpointMenuValues(tester, _readarr), ['edit', 'run', 'delete']);
    expect(find.byTooltip('Actions for Indexer One'), findsOneWidget);
    expect(find.byTooltip('Actions for Paused Client'), findsOneWidget);
    expect(find.byTooltip('Actions for Readarr'), findsOneWidget);

    await tester.tap(find.byKey(const Key('acquisition-endpoint-indexer-1')));
    await tester.pumpAndSettle();

    expect(find.text('Edit integration'), findsOneWidget);
  });

  testWidgets('section Add offers only matching integration types', (tester) async {
    final apiClient = _FakeAcquisitionApiClient();

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    await _tapSectionAdd(tester, 'acquisition-sources-section');
    expect(_editorKind(tester), AcquisitionEndpointKind.prowlarr);
    expect(_editorKinds(tester), [AcquisitionEndpointKind.prowlarr]);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await _tapSectionAdd(tester, 'acquisition-clients-section');
    expect(_editorKind(tester), AcquisitionEndpointKind.qbittorrent);
    expect(_editorKinds(tester), [AcquisitionEndpointKind.qbittorrent, AcquisitionEndpointKind.deluge]);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await _tapSectionAdd(tester, 'acquisition-apps-section');
    expect(_editorKind(tester), AcquisitionEndpointKind.readarr);
    expect(_editorKinds(tester), [AcquisitionEndpointKind.readarr]);
  });

  testWidgets('section Add is absent when the matching capability group is empty', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()
      ..capabilitiesResult = const AcquisitionCapabilities(
        enabled: true,
        endpointKinds: [AcquisitionEndpointKind.qbittorrent],
        indexerKinds: [],
        downloadClientKinds: [AcquisitionEndpointKind.qbittorrent],
        arrKinds: [],
        arrCommands: {},
      );

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(_sectionAdd('acquisition-sources-section'), findsNothing);
    expect(_sectionAdd('acquisition-clients-section'), findsOneWidget);
    expect(_sectionAdd('acquisition-apps-section'), findsNothing);
  });

  testWidgets('disabled Arr integration cannot run', (tester) async {
    final apiClient = _FakeAcquisitionApiClient()..endpointsResult = [_disabledReadarr];

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    expect(_endpointMenuItem(tester, _disabledReadarr, 'run').enabled, isFalse);

    _selectEndpointMenu(tester, _disabledReadarr, 'run');
    await tester.pump();

    expect(apiClient.arrEndpointIds, isEmpty);
  });

  testWidgets('active Arr run parses manual IDs and disables Run while pending', (tester) async {
    final completer = Completer<AcquisitionJob>();
    final apiClient = _FakeAcquisitionApiClient()
      ..endpointsResult = [_readarr]
      ..arrCommandCompleter = completer;

    await tester.pumpWidget(await _buildPage(apiClient));
    await tester.pumpAndSettle();

    _selectEndpointMenu(tester, _readarr, 'run');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search books'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'IDs'), '42, invalid, 84');
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(apiClient.arrEndpointIds, ['arr-1']);
    expect(apiClient.arrCommands, ['BookSearch']);
    expect(apiClient.arrIds, [
      [42, 84],
    ]);
    expect(_endpointMenuItem(tester, _readarr, 'run').enabled, isFalse);

    completer.complete(_job(status: 'submitted'));
    await tester.pumpAndSettle();

    expect(_endpointMenuItem(tester, _readarr, 'run').enabled, isTrue);
  });
}

final _searchField = find.widgetWithText(TextField, 'Title, author, movie, album, or series');

AcquisitionEndpointKind? _editorKind(WidgetTester tester) {
  return tester
      .widget<DropdownButtonFormField<AcquisitionEndpointKind>>(
        find.byType(DropdownButtonFormField<AcquisitionEndpointKind>),
      )
      .initialValue;
}

List<AcquisitionEndpointKind> _editorKinds(WidgetTester tester) {
  final field = find.byType(DropdownButtonFormField<AcquisitionEndpointKind>);
  final dropdown = find.descendant(of: field, matching: find.byType(DropdownButton<AcquisitionEndpointKind>));

  return tester.widget<DropdownButton<AcquisitionEndpointKind>>(dropdown).items!.map((item) => item.value!).toList();
}

Finder _sectionAdd(String sectionKey) {
  return find.descendant(of: find.byKey(Key(sectionKey)), matching: find.widgetWithText(TextButton, 'Add'));
}

Future<void> _tapSectionAdd(WidgetTester tester, String sectionKey) async {
  final addButton = _sectionAdd(sectionKey);

  expect(addButton, findsOneWidget);

  await tester.ensureVisible(addButton);
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

List<String?> _endpointMenuValues(WidgetTester tester, AcquisitionEndpoint endpoint) {
  final menuFinder = find.descendant(
    of: find.byKey(Key('acquisition-endpoint-${endpoint.id}')),
    matching: find.byType(PopupMenuButton<String>),
  );
  final menu = tester.widget<PopupMenuButton<String>>(menuFinder);

  return menu
      .itemBuilder(tester.element(menuFinder))
      .whereType<PopupMenuItem<String>>()
      .map((item) => item.value)
      .toList();
}

PopupMenuItem<String> _endpointMenuItem(WidgetTester tester, AcquisitionEndpoint endpoint, String value) {
  final menuFinder = find.descendant(
    of: find.byKey(Key('acquisition-endpoint-${endpoint.id}')),
    matching: find.byType(PopupMenuButton<String>),
  );
  final menu = tester.widget<PopupMenuButton<String>>(menuFinder);

  return menu
      .itemBuilder(tester.element(menuFinder))
      .whereType<PopupMenuItem<String>>()
      .singleWhere((item) => item.value == value);
}

void _selectEndpointMenu(WidgetTester tester, AcquisitionEndpoint endpoint, String value) {
  final menuFinder = find.descendant(
    of: find.byKey(Key('acquisition-endpoint-${endpoint.id}')),
    matching: find.byType(PopupMenuButton<String>),
  );
  final menu = tester.widget<PopupMenuButton<String>>(menuFinder);

  menu.onSelected?.call(value);
}

PopupMenuItem<AcquisitionEndpoint> _submissionItem(
  WidgetTester tester,
  TorrentRelease release,
  AcquisitionEndpoint client,
) {
  final menu = _submissionMenu(tester, release);
  final releaseTile = find.ancestor(of: find.text(release.title), matching: find.byType(ListTile));
  final menuFinder = find.descendant(of: releaseTile, matching: find.byType(PopupMenuButton<AcquisitionEndpoint>));

  return menu
      .itemBuilder(tester.element(menuFinder))
      .whereType<PopupMenuItem<AcquisitionEndpoint>>()
      .singleWhere((item) => item.value == client);
}

PopupMenuButton<AcquisitionEndpoint> _submissionMenu(WidgetTester tester, TorrentRelease release) {
  final releaseTile = find.ancestor(of: find.text(release.title), matching: find.byType(ListTile));
  final menuFinder = find.descendant(of: releaseTile, matching: find.byType(PopupMenuButton<AcquisitionEndpoint>));

  return tester.widget<PopupMenuButton<AcquisitionEndpoint>>(menuFinder);
}

String _fakeSubmissionKey(TorrentRelease release, String endpointId) {
  return '${release.indexer}\u001f${release.downloadUrl}\u001f$endpointId';
}

final _indexerOne = AcquisitionEndpoint(
  id: 'indexer-1',
  name: 'Indexer One',
  kind: AcquisitionEndpointKind.prowlarr,
  baseUrl: Uri.parse('http://indexer-one.local'),
  enabled: true,
);
final _indexerTwo = AcquisitionEndpoint(
  id: 'indexer-2',
  name: 'Indexer Two',
  kind: AcquisitionEndpointKind.prowlarr,
  baseUrl: Uri.parse('http://indexer-two.local'),
  enabled: true,
);
final _clientOne = AcquisitionEndpoint(
  id: 'client-1',
  name: 'Client One',
  kind: AcquisitionEndpointKind.transmission,
  baseUrl: Uri.parse('http://client-one.local'),
  enabled: true,
);
final _clientTwo = AcquisitionEndpoint(
  id: 'client-2',
  name: 'Client Two',
  kind: AcquisitionEndpointKind.qbittorrent,
  baseUrl: Uri.parse('http://client-two.local'),
  enabled: true,
);
final _pausedClient = AcquisitionEndpoint(
  id: 'paused-client',
  name: 'Paused Client',
  kind: AcquisitionEndpointKind.transmission,
  baseUrl: Uri.parse('http://paused-client.local'),
  enabled: false,
);
final _readarr = AcquisitionEndpoint(
  id: 'arr-1',
  name: 'Readarr',
  kind: AcquisitionEndpointKind.readarr,
  baseUrl: Uri.parse('http://readarr.local'),
  enabled: true,
);
final _disabledReadarr = AcquisitionEndpoint(
  id: 'arr-disabled',
  name: 'Disabled Readarr',
  kind: AcquisitionEndpointKind.readarr,
  baseUrl: Uri.parse('http://readarr-disabled.local'),
  enabled: false,
);
const _releaseOne = TorrentRelease(
  title: 'Release One',
  downloadUrl: 'magnet:?xt=urn:btih:release-one',
  protocol: 'torrent',
  indexer: 'Indexer One',
);
const _releaseTwo = TorrentRelease(
  title: 'Release Two',
  downloadUrl: 'magnet:?xt=urn:btih:release-two',
  protocol: 'torrent',
  indexer: 'Indexer One',
);
const _releaseMirror = TorrentRelease(
  title: 'Release Mirror',
  downloadUrl: 'magnet:?xt=urn:btih:release-one',
  protocol: 'torrent',
  indexer: 'Indexer Two',
);

AcquisitionJob _job({required String status, String? error}) {
  return AcquisitionJob(
    id: 'job-1',
    endpointId: 'client-1',
    ruleId: null,
    title: 'Release One',
    downloadUrl: _releaseOne.downloadUrl,
    status: status,
    clientReference: null,
    error: error,
    createdAt: null,
  );
}

Future<Widget> _buildPage(_FakeAcquisitionApiClient apiClient) async {
  final prefs = await SharedPreferences.getInstance();
  final authProvider = AuthProvider(prefs, repository: _FakeAuthRepository(), bootstrapOnCreate: false);
  await authProvider.bootstrap();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<PreferencesProvider>(create: (_) => PreferencesProvider(prefs)),
      ChangeNotifierProvider<SyncSettingsProvider>(create: (_) => SyncSettingsProvider(prefs, officialConfig: _config)),
    ],
    child: MaterialApp(home: AcquisitionPage(clientFactory: (_) => apiClient)),
  );
}

AuthTokens _tokens() {
  return AuthTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    tokenType: 'Bearer',
    expiresIn: 3600,
    user: PapyrusUser(
      userId: '11111111-1111-1111-1111-111111111111',
      email: 'reader@example.com',
      displayName: 'Reader',
      avatarUrl: null,
      emailVerified: true,
      createdAt: null,
      lastLoginAt: null,
    ),
  );
}
