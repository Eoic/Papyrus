import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_models.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/auth/token_store.dart';
import 'package:papyrus/main.dart';
import 'package:papyrus/providers/acquisition_availability_provider.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads and caches enabled capability state by server', () async {
    final calls = <Uri>[];
    final provider = AcquisitionAvailabilityProvider(
      loadCapabilities: (serverBaseUri) async {
        calls.add(serverBaseUri);
        return const AcquisitionCapabilities(
          enabled: true,
          endpointKinds: [],
          indexerKinds: [],
          downloadClientKinds: [],
          arrKinds: [],
          arrCommands: {},
        );
      },
    );
    final server = Uri.parse('https://api.test');

    await provider.refresh(server);
    await provider.refresh(server);

    expect(provider.state, AcquisitionAvailabilityState.available);
    expect(provider.isAvailableFor(server), isTrue);
    expect(provider.managedDownloadsReadyFor(server), isTrue);
    expect(calls, [server]);
  });

  test('treats disabled, failed, and unknown servers as unavailable', () async {
    final provider = AcquisitionAvailabilityProvider(
      loadCapabilities: (_) async => const AcquisitionCapabilities(
        enabled: false,
        endpointKinds: [],
        indexerKinds: [],
        downloadClientKinds: [],
        arrKinds: [],
        arrCommands: {},
      ),
    );
    final server = Uri.parse('https://api.test');

    expect(provider.isAvailableFor(server), isFalse);

    await provider.refresh(server);

    expect(provider.state, AcquisitionAvailabilityState.unavailable);
    expect(provider.isAvailableFor(server), isFalse);
    expect(provider.managedDownloadsReadyFor(server), isFalse);
    expect(provider.isAvailableFor(Uri.parse('https://another.test')), isFalse);
    expect(provider.managedDownloadsReadyFor(Uri.parse('https://another.test')), isFalse);
  });

  testWidgets('production composition supplies and synchronizes managed downloads', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final initialRepository = _FakeAuthRepository()..bootstrapResult = _tokens();
    final authProvider = AuthProvider(prefs, repository: initialRepository, bootstrapOnCreate: false);
    final initialServer = Uri.parse('https://api.test');
    final replacementServer = Uri.parse('https://replacement.test');
    var activeConfig = PapyrusApiConfig(serverBaseUri: initialServer);
    final loadedServers = <Uri>[];
    final availabilityProvider = AcquisitionAvailabilityProvider(
      loadCapabilities: (serverBaseUri) async {
        loadedServers.add(serverBaseUri);
        return AcquisitionCapabilities(
          enabled: true,
          managedDownloadsReady: serverBaseUri == initialServer,
          endpointKinds: const [],
          indexerKinds: const [],
          downloadClientKinds: const [],
          arrKinds: const [],
          arrCommands: const {},
        );
      },
    );
    final downloadsProvider = AcquisitionDownloadsProvider(pollingInterval: Duration.zero);
    final gateways = <_FakeDownloadsGateway>[];
    final gatewayConfigs = <PapyrusApiConfig>[];
    final composition = AcquisitionDownloadsComposition(
      authProvider: authProvider,
      availabilityProvider: availabilityProvider,
      activeApiConfig: () => activeConfig,
      downloadsProvider: downloadsProvider,
      gatewayFactory: (_, config) {
        final gateway = _FakeDownloadsGateway();
        gateways.add(gateway);
        gatewayConfigs.add(config);
        return gateway;
      },
    );

    await authProvider.bootstrap();
    await tester.pump();
    await tester.pump();

    AcquisitionDownloadsProvider? suppliedProvider;
    await tester.pumpWidget(
      MultiProvider(
        providers: [composition.providerRegistration()],
        child: Builder(
          builder: (context) {
            suppliedProvider = context.read<AcquisitionDownloadsProvider>();
            return const SizedBox();
          },
        ),
      ),
    );

    expect(suppliedProvider, same(downloadsProvider));
    expect(downloadsProvider.isConfigured, isTrue);
    expect(downloadsProvider.isManagedAcquisitionReady, isTrue);
    expect(loadedServers, [initialServer]);
    expect(gateways, hasLength(1));
    expect(gatewayConfigs.single.serverBaseUri, initialServer);

    activeConfig = PapyrusApiConfig(serverBaseUri: replacementServer);
    composition.handleServerChanged();

    expect(downloadsProvider.isConfigured, isFalse);
    expect(gateways.single.closed, isTrue);

    final replacementRepository = _FakeAuthRepository()..bootstrapResult = _tokens();
    await authProvider.replaceRepository(replacementRepository);
    await tester.pump();
    await tester.pump();

    expect(downloadsProvider.isConfigured, isTrue);
    expect(downloadsProvider.isManagedAcquisitionReady, isFalse);
    expect(loadedServers, [initialServer, replacementServer]);
    expect(gateways, hasLength(2));
    expect(gatewayConfigs.last.serverBaseUri, replacementServer);

    await authProvider.signOut();

    expect(downloadsProvider.isConfigured, isFalse);
    expect(gateways.last.closed, isTrue);

    await authProvider.login(email: 'reader@example.com', password: 'secret');
    await tester.pump();
    await tester.pump();

    expect(downloadsProvider.isConfigured, isTrue);
    expect(gateways, hasLength(3));

    authProvider.setOfflineMode(true);

    expect(downloadsProvider.isConfigured, isFalse);
    expect(gateways.last.closed, isTrue);

    await authProvider.login(email: 'reader@example.com', password: 'secret');
    await tester.pump();
    await tester.pump();

    expect(downloadsProvider.isConfigured, isTrue);
    expect(gateways, hasLength(4));

    await tester.pumpWidget(const SizedBox());
    composition.dispose();

    expect(gateways.last.closed, isTrue);

    await authProvider.signOut();

    expect(gateways, hasLength(4));

    availabilityProvider.dispose();
    authProvider.dispose();
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: AuthApiClient(config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test'))),
        tokenStore: TokenStore(_MemoryRefreshTokenStorage()),
      );

  AuthTokens? bootstrapResult;

  @override
  Future<AuthTokens?> bootstrap() async => bootstrapResult;

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
    required String clientType,
    String? deviceLabel,
  }) async {
    return _tokens();
  }

  @override
  Future<void> logout() async {}
}

class _MemoryRefreshTokenStorage implements RefreshTokenStorage {
  @override
  Future<void> delete() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String refreshToken) async {}
}

class _FakeDownloadsGateway implements AcquisitionDownloadsGateway {
  bool closed = false;

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints() async {
    return [
      AcquisitionEndpoint(
        id: 'indexer',
        name: 'Indexer',
        kind: AcquisitionEndpointKind.prowlarr,
        baseUrl: Uri.parse('https://indexer.test'),
        enabled: true,
      ),
      AcquisitionEndpoint(
        id: 'client',
        name: 'qBittorrent',
        kind: AcquisitionEndpointKind.qbittorrent,
        baseUrl: Uri.parse('https://qbittorrent.test'),
        downloadRoot: '/downloads',
        enabled: true,
      ),
    ];
  }

  @override
  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0}) async {
    return AcquisitionJobPage(items: const [], total: 0, limit: limit, offset: offset);
  }

  @override
  void close() {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
