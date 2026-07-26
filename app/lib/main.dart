import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/auth/token_store.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/media/cover_upload_persistence.dart';
import 'package:papyrus/media/media_cache_service.dart';
import 'package:papyrus/media/media_models.dart';
import 'package:papyrus/media/media_storage_scope.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/platform/hot_restart_cleanup.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/papyrus_powersync_connector.dart';
import 'package:papyrus/powersync/sync_profile_switch_queue.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/acquisition_availability_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:papyrus/services/book_download_service.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/providers/sidebar_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_router.dart';

Future main() async {
  await runPreviousHotRestartCleanup();
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  runApp(Papyrus(prefs: prefs));
}

class Papyrus extends StatefulWidget {
  final SharedPreferences prefs;

  const Papyrus({super.key, required this.prefs});

  @override
  State<Papyrus> createState() => _PapyrusState();
}

class _PapyrusState extends State<Papyrus> {
  late final DataStore _dataStore;
  late final AuthProvider _authProvider;
  late final AcquisitionAvailabilityProvider _acquisitionAvailabilityProvider;
  late final PreferencesProvider _preferencesProvider;
  late final SyncSettingsProvider _syncSettingsProvider;
  late final MediaUploadQueue _mediaUploadQueue;
  late final BookImportService _bookImportService;
  late final PapyrusPowerSyncService _powerSyncService;
  late final PapyrusApiConfig _officialApiConfig;
  late AuthRepository _authRepository;
  late String _activeProfileKey;
  late final SyncProfileSwitchQueue _profileSwitchQueue;
  late final AppRouter _appRouter;
  bool _switchingSyncProfile = false;
  Future<void>? _authStateOperation;
  bool _authStateUpdateQueued = false;

  @override
  void initState() {
    super.initState();

    _officialApiConfig = PapyrusApiConfig.fromEnvironment();
    _syncSettingsProvider = SyncSettingsProvider(widget.prefs, officialConfig: _officialApiConfig);
    _activeProfileKey = _syncSettingsProvider.activeProfileKey;
    _authRepository = _buildAuthRepository(_syncSettingsProvider.activeApiConfig, _activeProfileKey);
    _profileSwitchQueue = SyncProfileSwitchQueue(
      initialProfileKey: _activeProfileKey,
      onError: (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace, library: 'papyrus sync profile lifecycle'),
        );
      },
    );

    _dataStore = DataStore();
    _preferencesProvider = PreferencesProvider(widget.prefs);
    _mediaUploadQueue = MediaUploadQueue(widget.prefs, onWorkAvailable: _processMediaUploads);
    _bookImportService = BookImportService();
    _authProvider = AuthProvider(widget.prefs, repository: _authRepository);
    _acquisitionAvailabilityProvider = AcquisitionAvailabilityProvider(authProvider: _authProvider);
    _powerSyncService = PapyrusPowerSyncService(
      connectorFactory: () => PapyrusPowerSyncConnector(
        authRepository: _authRepository,
        config: _syncSettingsProvider.activeApiConfig,
        onUploadComplete: _processMediaUploads,
      ),
    );
    registerHotRestartCleanup(_disposeDataServices);
    unawaited(_dataStore.attachBookRepository(_powerSyncService));
    _appRouter = AppRouter(
      authProvider: _authProvider,
      preferencesProvider: _preferencesProvider,
      syncSettingsProvider: _syncSettingsProvider,
      acquisitionAvailabilityProvider: _acquisitionAvailabilityProvider,
    );
    _authProvider.addListener(_syncPowerSyncAuthState);
    _authProvider.addListener(_syncAcquisitionAvailability);
    _syncSettingsProvider.addListener(_handleSyncSettingsChanged);
    _syncPowerSyncAuthState();
    _syncAcquisitionAvailability();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_syncPowerSyncAuthState);
    _authProvider.removeListener(_syncAcquisitionAvailability);
    _syncSettingsProvider.removeListener(_handleSyncSettingsChanged);
    unawaited(_disposeDataServices());
    _bookImportService.dispose();
    _acquisitionAvailabilityProvider.dispose();
    _authProvider.dispose();
    _syncSettingsProvider.dispose();
    _preferencesProvider.dispose();
    super.dispose();
  }

  AuthRepository _buildAuthRepository(PapyrusApiConfig config, String profileKey) {
    final tokenStore = TokenStore(SecureRefreshTokenStorage.scoped(profileKey));
    return AuthRepository(
      apiClient: AuthApiClient(config: config),
      tokenStore: tokenStore,
    );
  }

  Future<void> _disposeDataServices() async {
    await _dataStore.disposeBookRepository();
    await _powerSyncService.close();
  }

  void _syncPowerSyncAuthState() {
    if (_authStateOperation != null) {
      _authStateUpdateQueued = true;
      return;
    }

    final operation = _drainAuthStateUpdates();
    _authStateOperation = operation;
    operation.then(
      (_) => _clearAuthStateOperation(operation),
      onError: (Object error, StackTrace stackTrace) {
        _clearAuthStateOperation(operation);
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace, library: 'papyrus media/auth lifecycle'),
        );
      },
    );
  }

  Future<void> _drainAuthStateUpdates() async {
    do {
      _authStateUpdateQueued = false;
      await _applyPowerSyncAuthState();
    } while (_authStateUpdateQueued);
  }

  Future<void> _applyPowerSyncAuthState() async {
    final user = _authProvider.user;
    if (user != null && !_authProvider.isOfflineMode) {
      final userId = user.userId;
      await _mediaUploadQueue.activateScope(MediaStorageScope(profileKey: _activeProfileKey, userId: userId));
      await _powerSyncService.activateAuthenticated(userId, profileKey: _activeProfileKey);
      await _refreshMediaUsage();
      await _processMediaUploads();
      return;
    }

    if (_authProvider.isOfflineMode) {
      await _mediaUploadQueue.activateScope(null);
      await _powerSyncService.activateGuest();
      return;
    }

    await _mediaUploadQueue.activateScope(null);
    if (!_authProvider.isBootstrapping && _powerSyncService.mode != null) {
      await _powerSyncService.deactivate(clearAuthenticated: !_switchingSyncProfile);
    }
  }

  void _clearAuthStateOperation(Future<void> operation) {
    if (identical(_authStateOperation, operation)) {
      _authStateOperation = null;
    }
    if (_authStateUpdateQueued) {
      _syncPowerSyncAuthState();
    }
  }

  void _handleSyncSettingsChanged() {
    _acquisitionAvailabilityProvider.clear();
    final nextProfileKey = _syncSettingsProvider.activeProfileKey;
    final nextConfig = _syncSettingsProvider.activeApiConfig;
    _profileSwitchQueue.request(nextProfileKey, () => _switchActiveSyncProfile(nextProfileKey, nextConfig));
  }

  void _syncAcquisitionAvailability() {
    if (!_authProvider.isSignedIn || _authProvider.isOfflineMode) {
      _acquisitionAvailabilityProvider.clear();
      return;
    }

    unawaited(_acquisitionAvailabilityProvider.refresh(_syncSettingsProvider.activeApiConfig.serverBaseUri));
  }

  Future<void> _switchActiveSyncProfile(String nextProfileKey, PapyrusApiConfig nextConfig) async {
    _switchingSyncProfile = true;
    try {
      await _mediaUploadQueue.waitUntilIdle();
      await _mediaUploadQueue.activateScope(null);
      await _powerSyncService.deactivate(clearAuthenticated: false);
      _authRepository = _buildAuthRepository(nextConfig, nextProfileKey);
      _activeProfileKey = nextProfileKey;
      await _authProvider.replaceRepository(_authRepository, bootstrapNewRepository: !_authProvider.isOfflineMode);
      unawaited(_refreshMediaUsage());
    } finally {
      _switchingSyncProfile = false;
      _syncPowerSyncAuthState();
    }
  }

  Future<void> _refreshMediaUsage() async {
    if (!_authProvider.isSignedIn || _authProvider.isOfflineMode) return;
    final repository = _authRepository;
    try {
      await _mediaUploadQueue.refreshUsage(repository.fetchMediaUsage);
    } catch (_) {
      // Usage is informational; failed refresh must not block data sync.
    }
  }

  Future<void> _processMediaUploads() async {
    if (_switchingSyncProfile || !_authProvider.isSignedIn || _authProvider.isOfflineMode) return;
    final user = _authProvider.user;
    if (user == null) return;
    final profileKey = _activeProfileKey;
    final repository = _authRepository;
    final scope = MediaStorageScope(profileKey: profileKey, userId: user.userId);
    if (_mediaUploadQueue.activeScope != scope) {
      await _mediaUploadQueue.activateScope(scope);
    }
    if (_switchingSyncProfile || profileKey != _activeProfileKey || !identical(repository, _authRepository)) {
      return;
    }
    await _mediaUploadQueue.processPending(
      dataStore: _dataStore,
      readBookFile: _bookImportService.getBookFile,
      readPendingCover: _bookImportService.getPendingCoverFile,
      uploadMedia: (payload) => uploadAndPersistCover(
        scope: scope,
        payload: payload,
        uploadMedia: (payload) async {
          try {
            return await repository.uploadMedia(payload);
          } on AuthApiException catch (error) {
            if (error.statusCode == 409) {
              throw const MediaUploadException.storageFull();
            }
            rethrow;
          }
        },
        promotePendingCover: _bookImportService.promotePendingCoverFile,
        onPromotionError: (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, stack: stackTrace, library: 'papyrus cover promotion'),
          );
        },
      ),
    );
    if (identical(repository, _authRepository) && _mediaUploadQueue.activeScope == scope) {
      await _refreshMediaUsage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core data store - single source of truth
        ChangeNotifierProvider.value(value: _dataStore),
        ChangeNotifierProvider.value(value: _mediaUploadQueue),
        ChangeNotifierProvider.value(value: _syncSettingsProvider),
        Provider.value(value: _powerSyncService),
        Provider.value(value: _bookImportService),
        Provider(create: _createBookDownloadService),
        Provider(create: _createMediaCacheService),
        StreamProvider<SyncState>.value(value: _powerSyncService.syncStates, initialData: _powerSyncService.syncState),
        // Auth and UI state providers
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _acquisitionAvailabilityProvider),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider.value(value: _preferencesProvider),
      ],
      child: Consumer<PreferencesProvider>(
        builder: (context, preferencesProvider, child) {
          final isEink = preferencesProvider.isEinkMode;
          return MaterialApp.router(
            title: 'Papyrus',
            debugShowCheckedModeBanner: false,
            theme: isEink ? AppTheme.eink : AppTheme.light,
            darkTheme: isEink ? AppTheme.eink : AppTheme.dark,
            themeMode: isEink ? ThemeMode.light : preferencesProvider.themeMode,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}

BookDownloadService _createBookDownloadService(BuildContext _) => const BookDownloadService();

MediaCacheService _createMediaCacheService(BuildContext _) => MediaCacheService();
