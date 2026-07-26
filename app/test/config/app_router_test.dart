import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_models.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/auth/token_store.dart';
import 'package:papyrus/config/app_router.dart';
import 'package:papyrus/providers/acquisition_availability_provider.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryRefreshTokenStorage implements RefreshTokenStorage {
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

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository()
    : super(
        apiClient: AuthApiClient(config: PapyrusApiConfig(serverBaseUri: Uri.parse('http://server.test'))),
        tokenStore: TokenStore(MemoryRefreshTokenStorage()),
      );

  AuthTokens? bootstrapResult;

  @override
  Future<AuthTokens?> bootstrap() async {
    return bootstrapResult;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('redirects signed-out users away from protected routes', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = AuthProvider(prefs, repository: FakeAuthRepository(), bootstrapOnCreate: false);

    await provider.bootstrap();

    final appRouter = await _buildRouter(authProvider: provider, prefs: prefs);

    expect(appRouter.redirectForPath('/library/books'), '/');
    expect(appRouter.redirectForPath('/login'), isNull);
    expect(appRouter.redirectForPath('/reset-password'), isNull);
  });

  test('redirects signed-in users away from auth routes', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = FakeAuthRepository()..bootstrapResult = _tokens();
    final provider = AuthProvider(prefs, repository: repository, bootstrapOnCreate: false);

    await provider.bootstrap();

    final appRouter = await _buildRouter(authProvider: provider, prefs: prefs);

    expect(appRouter.redirectForPath('/login'), '/library/books');
    expect(appRouter.redirectForPath('/reset-password'), '/library/books');
    expect(appRouter.redirectForPath('/library/books'), isNull);
  });

  test('offline mode bypasses protected-route auth redirect', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = AuthProvider(prefs, repository: FakeAuthRepository(), bootstrapOnCreate: false);

    await provider.bootstrap();
    provider.setOfflineMode(true);

    final appRouter = await _buildRouter(authProvider: provider, prefs: prefs);

    expect(appRouter.redirectForPath('/library/books'), isNull);
  });

  test('book edit has a stable reloadable URL', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = AuthProvider(prefs, repository: FakeAuthRepository(), bootstrapOnCreate: false);
    final appRouter = await _buildRouter(authProvider: provider, prefs: prefs);

    expect(appRouter.router.namedLocation('BOOK_EDIT', pathParameters: {'bookId': 'book-1'}), '/library/edit/book-1');
  });

  test('acquisition route requires explicit opt-in', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = FakeAuthRepository()..bootstrapResult = _tokens();
    final provider = AuthProvider(prefs, repository: repository, bootstrapOnCreate: false);
    final preferences = PreferencesProvider(prefs);
    final syncSettings = _syncSettings(prefs);
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

    await provider.bootstrap();

    final appRouter = AppRouter(
      authProvider: provider,
      preferencesProvider: preferences,
      syncSettingsProvider: syncSettings,
      acquisitionAvailabilityProvider: availability,
    );

    expect(appRouter.redirectForPath('/acquisition'), '/profile');

    preferences.acquisitionEnabled = true;

    expect(appRouter.redirectForPath('/acquisition'), '/profile');

    await availability.refresh(syncSettings.activeApiConfig.serverBaseUri);

    expect(appRouter.redirectForPath('/acquisition'), isNull);
  });
}

Future<AppRouter> _buildRouter({required AuthProvider authProvider, required SharedPreferences prefs}) async {
  final syncSettings = _syncSettings(prefs);
  return AppRouter(
    authProvider: authProvider,
    preferencesProvider: PreferencesProvider(prefs),
    syncSettingsProvider: syncSettings,
    acquisitionAvailabilityProvider: AcquisitionAvailabilityProvider(
      loadCapabilities: (_) async => const AcquisitionCapabilities(
        enabled: false,
        endpointKinds: [],
        indexerKinds: [],
        downloadClientKinds: [],
        arrKinds: [],
        arrCommands: {},
      ),
    ),
  );
}

SyncSettingsProvider _syncSettings(SharedPreferences prefs) {
  return SyncSettingsProvider(prefs, officialConfig: PapyrusApiConfig(serverBaseUri: Uri.parse('http://server.test')));
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
