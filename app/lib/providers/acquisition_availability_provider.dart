import 'package:flutter/foundation.dart';
import 'package:papyrus/acquisition/acquisition_api_client.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/providers/auth_provider.dart';

enum AcquisitionAvailabilityState { unknown, loading, available, unavailable }

typedef AcquisitionCapabilitiesLoader = Future<AcquisitionCapabilities> Function(Uri serverBaseUri);

class AcquisitionAvailabilityProvider extends ChangeNotifier {
  final AuthProvider? _authProvider;
  final AcquisitionCapabilitiesLoader? _loadCapabilities;

  AcquisitionApiClient? _apiClient;
  Uri? _serverBaseUri;
  Future<void>? _refreshOperation;
  int _generation = 0;
  AcquisitionAvailabilityState _state = AcquisitionAvailabilityState.unknown;

  AcquisitionAvailabilityProvider({AuthProvider? authProvider, AcquisitionCapabilitiesLoader? loadCapabilities})
    : assert((authProvider == null) != (loadCapabilities == null), 'Provide either authProvider or loadCapabilities'),
      _authProvider = authProvider,
      _loadCapabilities = loadCapabilities;

  AcquisitionAvailabilityState get state => _state;

  bool isAvailableFor(Uri serverBaseUri) {
    return _serverBaseUri == serverBaseUri && _state == AcquisitionAvailabilityState.available;
  }

  Future<void> refresh(Uri serverBaseUri, {bool force = false}) {
    if (_serverBaseUri == serverBaseUri) {
      if (_state == AcquisitionAvailabilityState.loading) {
        return _refreshOperation ?? Future<void>.value();
      }
      if (!force && _state != AcquisitionAvailabilityState.unknown) {
        return Future<void>.value();
      }
    }

    if (_serverBaseUri != serverBaseUri) {
      _replaceServer(serverBaseUri);
    }

    final generation = ++_generation;
    _state = AcquisitionAvailabilityState.loading;
    notifyListeners();

    final operation = _load(serverBaseUri, generation);
    _refreshOperation = operation;
    return operation.whenComplete(() {
      if (identical(_refreshOperation, operation)) {
        _refreshOperation = null;
      }
    });
  }

  void clear() {
    _generation += 1;
    _apiClient?.close();
    _apiClient = null;
    _serverBaseUri = null;
    _refreshOperation = null;

    if (_state != AcquisitionAvailabilityState.unknown) {
      _state = AcquisitionAvailabilityState.unknown;
      notifyListeners();
    }
  }

  Future<void> _load(Uri serverBaseUri, int generation) async {
    try {
      final capabilities = await (_loadCapabilities != null
          ? _loadCapabilities(serverBaseUri)
          : _loadFromServer(serverBaseUri));
      if (generation != _generation || _serverBaseUri != serverBaseUri) {
        return;
      }

      _state = capabilities.enabled ? AcquisitionAvailabilityState.available : AcquisitionAvailabilityState.unavailable;
    } catch (_) {
      if (generation != _generation || _serverBaseUri != serverBaseUri) {
        return;
      }

      _state = AcquisitionAvailabilityState.unavailable;
    }

    notifyListeners();
  }

  Future<AcquisitionCapabilities> _loadFromServer(Uri serverBaseUri) {
    final apiClient = _apiClient ??= AcquisitionApiClient(config: PapyrusApiConfig(serverBaseUri: serverBaseUri));
    return _authProvider!.withFreshAccessToken(apiClient.capabilities);
  }

  void _replaceServer(Uri serverBaseUri) {
    _generation += 1;
    _apiClient?.close();
    _apiClient = null;
    _serverBaseUri = serverBaseUri;
    _refreshOperation = null;
    _state = AcquisitionAvailabilityState.unknown;
  }

  @override
  void dispose() {
    _generation += 1;
    _apiClient?.close();
    super.dispose();
  }
}
