import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_models.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/auth/token_store.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/repositories/book_repository.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/pages/profile_page.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/acquisition_availability_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRefreshTokenStorage implements RefreshTokenStorage {
  String? value;

  @override
  Future<void> delete() async {
    value = null;
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String refreshToken) async {
    value = refreshToken;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: AuthApiClient(config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test'))),
        tokenStore: TokenStore(_MemoryRefreshTokenStorage()),
      );

  AuthTokens? bootstrapResult;

  @override
  Future<AuthTokens?> bootstrap() async {
    return bootstrapResult;
  }

  @override
  Future<void> clearTokens() async {}
}

class _OfflineConnector extends PowerSyncBackendConnector {
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async => null;

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {}
}

class _FakePowerSyncService extends PapyrusPowerSyncService {
  _FakePowerSyncService({required this.currentMode, required this.currentSyncState})
    : super(connectorFactory: _OfflineConnector.new, connectAuthenticated: false);

  LibraryDatabaseMode? currentMode;
  SyncState currentSyncState;
  int reconnectCalls = 0;
  int clearGuestLibraryCalls = 0;
  int clearAuthenticatedCacheCalls = 0;

  @override
  LibraryDatabaseMode? get mode => currentMode;

  @override
  SyncState get syncState => currentSyncState;

  @override
  Stream<SyncState> get syncStates => Stream.value(currentSyncState);

  @override
  Future<void> reconnect() async {
    reconnectCalls += 1;
  }

  @override
  Future<void> clearGuestLibrary() async {
    clearGuestLibraryCalls += 1;
  }

  @override
  Future<void> clearAuthenticatedCache() async {
    clearAuthenticatedCacheCalls += 1;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AuthProvider> buildAuthProvider({bool guest = false, bool signedIn = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final repository = _FakeAuthRepository();
    if (signedIn) {
      repository.bootstrapResult = _tokens();
    }
    final provider = AuthProvider(prefs, repository: repository, bootstrapOnCreate: false);
    await provider.bootstrap();
    if (guest) {
      provider.setOfflineMode(true);
    }
    return provider;
  }

  Future<Widget> buildPage({
    required AuthProvider authProvider,
    required _FakePowerSyncService powerSyncService,
    Size screenSize = const Size(400, 900),
    SyncSettingsProvider? syncSettingsProvider,
    DataStore? dataStore,
    MediaUploadQueue? mediaUploadQueue,
    AcquisitionAvailabilityProvider? acquisitionAvailabilityProvider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final config = PapyrusApiConfig(
      serverBaseUri: Uri.parse('https://api.test'),
      powerSyncServiceUri: Uri.parse('https://data-sync.test'),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
        ChangeNotifierProvider<MediaUploadQueue>.value(value: mediaUploadQueue ?? MediaUploadQueue(prefs)),
        ChangeNotifierProvider<SyncSettingsProvider>.value(
          value: syncSettingsProvider ?? SyncSettingsProvider(prefs, officialConfig: config),
        ),
        Provider<PapyrusPowerSyncService>.value(value: powerSyncService),
        StreamProvider<SyncState>.value(value: powerSyncService.syncStates, initialData: powerSyncService.syncState),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AcquisitionAvailabilityProvider>.value(
          value:
              acquisitionAvailabilityProvider ??
              AcquisitionAvailabilityProvider(
                loadCapabilities: (_) async => const AcquisitionCapabilities(
                  enabled: false,
                  endpointKinds: [],
                  indexerKinds: [],
                  downloadClientKinds: [],
                  arrKinds: [],
                  arrCommands: {},
                ),
              ),
        ),
        ChangeNotifierProvider<PreferencesProvider>(create: (_) => PreferencesProvider(prefs)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const ProfilePage(),
        ),
      ),
    );
  }

  testWidgets('offline storage sync UI is local-first and hides sync internals', (tester) async {
    final auth = await buildAuthProvider(guest: true);
    final service = _FakePowerSyncService(currentMode: LibraryDatabaseMode.guest, currentSyncState: const SyncState());

    await tester.pumpWidget(await buildPage(authProvider: auth, powerSyncService: service));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Storage'), 400);
    await tester.pumpAndSettle();

    expect(find.text('Stored on this device'), findsOneWidget);
    expect(find.text('Export or import a backup'), findsOneWidget);
    expect(find.text('Clear local library'), findsOneWidget);
    expect(find.textContaining('Nothing is sent to Papyrus servers'), findsOneWidget);
    expect(find.text('Guest local'), findsNothing);
    expect(find.text('papyrus-guest.db'), findsNothing);
    expect(find.text('Metadata sync off'), findsNothing);
    expect(find.text('Clear guest library'), findsNothing);
    expect(find.text('https://api.test'), findsNothing);
    expect(find.text('https://data-sync.test'), findsNothing);
    expect(find.text('Current mode'), findsNothing);
    expect(find.text('Local database'), findsNothing);
    expect(find.text('Metadata sync'), findsNothing);
    expect(find.text('Media storage'), findsNothing);
    expect(find.text('Storage backend'), findsNothing);
    expect(find.text('Sync enabled'), findsNothing);
    expect(find.text('Sync interval'), findsNothing);
    expect(find.text('Conflict resolution'), findsNothing);
    expect(find.text('Add storage backend'), findsNothing);
    expect(find.text('Pending changes'), findsNothing);
    expect(find.text('No pending local writes'), findsNothing);
  });

  testWidgets('authenticated profile hides acquisition management when server is unavailable', (tester) async {
    final auth = await buildAuthProvider(signedIn: true);
    final service = _FakePowerSyncService(
      currentMode: LibraryDatabaseMode.authenticated,
      currentSyncState: const SyncState(connected: true),
    );
    final availability = AcquisitionAvailabilityProvider(
      loadCapabilities: (_) async => const AcquisitionCapabilities(
        enabled: false,
        endpointKinds: [],
        indexerKinds: [],
        downloadClientKinds: [],
        arrKinds: [],
        arrCommands: {},
      ),
    );
    await availability.refresh(Uri.parse('https://api.test'));

    await tester.pumpWidget(
      await buildPage(authProvider: auth, powerSyncService: service, acquisitionAvailabilityProvider: availability),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Storage'), 400);
    await tester.pumpAndSettle();

    expect(find.text('Torrent acquisition'), findsOneWidget);

    await tester.tap(find.text('Torrent acquisition'));
    await tester.pumpAndSettle();

    expect(find.text('Torrent & automation'), findsNothing);
  });

  testWidgets('offline desktop storage sync is local-first and hides sync internals', (tester) async {
    final auth = await buildAuthProvider(guest: true);
    final service = _FakePowerSyncService(currentMode: LibraryDatabaseMode.guest, currentSyncState: const SyncState());

    await tester.pumpWidget(
      await buildPage(authProvider: auth, powerSyncService: service, screenSize: const Size(1200, 900)),
    );
    await tester.pump();
    await tester.tap(find.text('Storage').first);
    await tester.pump();

    expect(find.text('Library storage'), findsOneWidget);
    expect(find.text('Your library is stored on this device.'), findsOneWidget);
    expect(find.textContaining('Nothing is sent to Papyrus servers'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    expect(find.text('Clear local library'), findsOneWidget);
    expect(find.text('Guest local'), findsNothing);
    expect(find.text('papyrus-guest.db'), findsNothing);
    expect(find.text('Metadata sync off'), findsNothing);
    expect(find.text('Clear guest library'), findsNothing);
    expect(find.text('Current mode'), findsNothing);
    expect(find.text('Local database'), findsNothing);
    expect(find.text('Metadata sync'), findsNothing);
    expect(find.text('Media storage'), findsNothing);
    expect(find.text('Pending changes'), findsNothing);
    expect(find.text('No pending local writes'), findsNothing);
  });

  testWidgets('authenticated storage sync UI shows data sync and hides implementation details', (tester) async {
    final auth = await buildAuthProvider(signedIn: true);
    final dataStore = dataStoreWithBooks([
      testBook(id: 'book-1', title: 'Small book', fileSize: 100 * 1024 * 1024),
      testBook(id: 'book-2', title: 'Large book', fileSize: 250 * 1024 * 1024),
    ]);
    final service = _FakePowerSyncService(
      currentMode: LibraryDatabaseMode.authenticated,
      currentSyncState: SyncState(connected: true, lastSyncedAt: DateTime.utc(2026, 6, 27, 10, 30)),
    );
    final availability = AcquisitionAvailabilityProvider(
      loadCapabilities: (_) async => const AcquisitionCapabilities(
        enabled: true,
        endpointKinds: [],
        indexerKinds: [],
        downloadClientKinds: [],
        arrKinds: [],
        arrCommands: {},
      ),
    );
    await availability.refresh(Uri.parse('https://api.test'));

    await tester.pumpWidget(
      await buildPage(
        authProvider: auth,
        powerSyncService: service,
        screenSize: const Size(1200, 900),
        dataStore: dataStore,
        acquisitionAvailabilityProvider: availability,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage').first);
    await tester.pumpAndSettle();

    expect(find.text('Data sync'), findsOneWidget);
    expect(find.text('Official server'), findsWidgets);
    expect(find.text('350 MB used, 674 MB available of 1 GB'), findsOneWidget);
    expect(find.text('Connected'), findsWidgets);
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Manage servers'), findsOneWidget);
    expect(find.text('Torrent acquisition'), findsOneWidget);
    expect(find.text('Torrent & automation'), findsNothing);
    expect(find.text('Clear local copy'), findsOneWidget);
    expect(find.text('Clear account local cache'), findsNothing);
    expect(find.text('Pending changes'), findsNothing);
    expect(find.text('Metadata sync'), findsNothing);
    expect(find.text('PowerSync service'), findsNothing);
    expect(find.textContaining('PowerSync'), findsNothing);
    expect(find.text('Library storage'), findsNothing);
    expect(find.text('Media storage'), findsNothing);
    expect(find.text('Local database'), findsNothing);
    expect(find.text('Server-scoped account cache'), findsNothing);

    await tester.ensureVisible(find.text('Reconnect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconnect'));
    await tester.pump();

    expect(service.reconnectCalls, 1);

    await tester.tap(find.text('Torrent acquisition'));
    await tester.pumpAndSettle();

    expect(find.text('Torrent & automation'), findsOneWidget);
  });

  testWidgets('manage servers lists official and custom servers for switching', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final syncSettings = SyncSettingsProvider(
      prefs,
      officialConfig: PapyrusApiConfig(
        serverBaseUri: Uri.parse('https://api.test'),
        powerSyncServiceUri: Uri.parse('https://data-sync.test'),
      ),
      discoveryFetcher: (serverUrl) async => DataSyncDiscoverySettings(
        dataSyncUri: Uri.parse('https://sync.${serverUrl.host}'),
        fileStorageQuotaBytes: 1_073_741_824,
      ),
    );
    await syncSettings.addCustomServer('https://reader.example');
    syncSettings.selectServer(SyncSettingsProvider.officialServerId);
    final auth = await buildAuthProvider(signedIn: true);
    final service = _FakePowerSyncService(
      currentMode: LibraryDatabaseMode.authenticated,
      currentSyncState: const SyncState(connected: true),
    );

    await tester.pumpWidget(
      await buildPage(authProvider: auth, powerSyncService: service, syncSettingsProvider: syncSettings),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Storage'), 400);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage servers'));
    await tester.pumpAndSettle();

    expect(find.text('Sync servers'), findsOneWidget);
    expect(find.text('Official server'), findsWidgets);
    expect(find.text('reader.example'), findsOneWidget);
    expect(find.text('Add custom server'), findsOneWidget);
  });

  testWidgets('storage sync UI shows pending writes and sync errors', (tester) async {
    final auth = await buildAuthProvider(signedIn: true);
    final service = _FakePowerSyncService(
      currentMode: LibraryDatabaseMode.authenticated,
      currentSyncState: const SyncState(connected: true, hasPendingWrites: true, uploadError: 'upload failed'),
    );

    await tester.pumpWidget(
      await buildPage(authProvider: auth, powerSyncService: service, screenSize: const Size(1200, 900)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage').first);
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsWidgets);
    expect(find.text('Sync error: upload failed'), findsOneWidget);
    expect(find.text('Pending changes'), findsNothing);
    expect(find.text('Local changes pending upload'), findsNothing);
  });
}

DataStore dataStoreWithBooks(List<Book> books) {
  final repository = InMemoryBookRepository()..replaceAll(books);
  return DataStore(bookRepository: repository);
}

Book testBook({required String id, required String title, int? fileSize}) {
  return Book(id: id, title: title, author: 'Author', fileSize: fileSize, addedAt: DateTime.utc(2026, 6, 27));
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
