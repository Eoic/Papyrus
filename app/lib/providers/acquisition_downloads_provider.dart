import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:papyrus/acquisition/acquisition_api_client.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/acquisition/acquisition_user_messages.dart';
import 'package:papyrus/providers/auth_provider.dart';

class AcquisitionSubmissionOutcome {
  final int successfulCount;
  final Map<String, String> failuresByReleaseToken;

  AcquisitionSubmissionOutcome({required this.successfulCount, required Map<String, String> failuresByReleaseToken})
    : failuresByReleaseToken = Map.unmodifiable(failuresByReleaseToken);

  int get failedCount => failuresByReleaseToken.length;

  bool get allSucceeded => failedCount == 0 && successfulCount > 0;
}

abstract interface class AcquisitionDownloadsGateway {
  Future<List<AcquisitionEndpoint>> listEndpoints();

  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0});

  Future<List<TorrentRelease>> search(String query, {List<String>? endpointIds});

  Future<BatchSubmissionResponse> submitReleaseBatch({
    required String endpointId,
    required List<TorrentRelease> releases,
  });

  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId);

  Future<AcquisitionJob> selectJobFile(String jobId, int fileIndex);

  Future<AcquisitionJob> cancelJob(String jobId);

  Future<AcquisitionJob> retryJobImport(String jobId);

  Future<void> removeJob(String jobId);

  void close();
}

class AuthenticatedAcquisitionDownloadsGateway implements AcquisitionDownloadsGateway {
  final AuthProvider _authProvider;
  final AcquisitionApiClient _apiClient;

  AuthenticatedAcquisitionDownloadsGateway({
    required AuthProvider authProvider,
    required AcquisitionApiClient apiClient,
  }) : _authProvider = authProvider,
       _apiClient = apiClient;

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints() {
    return _authProvider.withFreshAccessToken(_apiClient.listEndpoints);
  }

  @override
  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0}) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.listJobs(accessToken: accessToken, limit: limit, offset: offset),
    );
  }

  @override
  Future<List<TorrentRelease>> search(String query, {List<String>? endpointIds}) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.search(accessToken: accessToken, query: query, endpointIds: endpointIds),
    );
  }

  @override
  Future<BatchSubmissionResponse> submitReleaseBatch({
    required String endpointId,
    required List<TorrentRelease> releases,
  }) {
    return _authProvider.withFreshAccessToken(
      (accessToken) =>
          _apiClient.submitReleaseBatch(accessToken: accessToken, endpointId: endpointId, releases: releases),
    );
  }

  @override
  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.listJobFiles(accessToken: accessToken, jobId: jobId),
    );
  }

  @override
  Future<AcquisitionJob> selectJobFile(String jobId, int fileIndex) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.selectJobFile(accessToken: accessToken, jobId: jobId, fileIndex: fileIndex),
    );
  }

  @override
  Future<AcquisitionJob> cancelJob(String jobId) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.cancelJob(accessToken: accessToken, jobId: jobId),
    );
  }

  @override
  Future<AcquisitionJob> retryJobImport(String jobId) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.retryJobImport(accessToken: accessToken, jobId: jobId),
    );
  }

  @override
  Future<void> removeJob(String jobId) {
    return _authProvider.withFreshAccessToken(
      (accessToken) => _apiClient.removeJob(accessToken: accessToken, jobId: jobId),
    );
  }

  @override
  void close() {
    _apiClient.close();
  }
}

class AcquisitionDownloadsProvider extends ChangeNotifier with WidgetsBindingObserver {
  AcquisitionDownloadsGateway? _gateway;
  final Duration visiblePollingInterval;
  final Duration foregroundPollingInterval;
  final Map<String, AcquisitionJob> _jobs = {};
  final Set<String> _selectedJobIds = {};
  final Set<String> _selectedReleaseTokens = {};

  Timer? _pollTimer;
  List<AcquisitionEndpoint> _endpoints = const [];
  List<TorrentRelease> _remoteResults = const [];
  Map<String, String> _submissionErrorsByReleaseToken = const {};
  String? _remoteQuery;
  String? _searchError;
  String? _error;
  bool _isLoadingJobs = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _serverManagedDownloadsReady = true;
  bool _isLibraryVisible = false;
  bool _isForeground = true;
  bool _disposed = false;
  int _generation = 0;

  AcquisitionDownloadsProvider({
    AcquisitionDownloadsGateway? gateway,
    Duration? pollingInterval,
    Duration visiblePollingInterval = const Duration(seconds: 2),
    Duration foregroundPollingInterval = const Duration(seconds: 10),
  }) : _gateway = gateway,
       visiblePollingInterval = pollingInterval ?? visiblePollingInterval,
       foregroundPollingInterval = pollingInterval ?? foregroundPollingInterval {
    WidgetsBinding.instance.addObserver(this);
    _isForeground = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.resumed => true,
      _ => false,
    };
  }

  List<AcquisitionJob> get jobs {
    final values = _jobs.values.toList();
    values.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return values;
  }

  Map<String, AcquisitionJob> get jobsByBookId => {
    for (final job in _jobs.values)
      if (job.bookId != null && job.status != AcquisitionJobStatus.completed) job.bookId!: job,
  };

  List<TorrentRelease> get remoteResults => List.unmodifiable(_remoteResults);

  List<AcquisitionEndpoint> get downloadClients => _endpoints
      .where(
        (endpoint) =>
            endpoint.enabled &&
            endpoint.kind == AcquisitionEndpointKind.qbittorrent &&
            endpoint.downloadRoot?.isNotEmpty == true,
      )
      .toList();

  Set<String> get selectedJobIds => Set.unmodifiable(_selectedJobIds);

  Set<String> get selectedReleaseTokens => Set.unmodifiable(_selectedReleaseTokens);

  Map<String, String> get submissionErrorsByReleaseToken => _submissionErrorsByReleaseToken;

  List<String> get submissionErrors => List.unmodifiable(_submissionErrorsByReleaseToken.values);

  String? get remoteQuery => _remoteQuery;

  String? get searchError => _searchError;

  String? get error => _error;

  bool get isLoadingJobs => _isLoadingJobs;

  bool get isSearching => _isSearching;

  bool get isSubmitting => _isSubmitting;

  bool get isConfigured => _gateway != null;

  bool get isManagedAcquisitionReady {
    final hasIndexer = _endpoints.any((endpoint) => endpoint.enabled && endpoint.kind.isIndexer);

    return _serverManagedDownloadsReady && hasIndexer && downloadClients.isNotEmpty;
  }

  int get activeCount => _jobs.values.where((job) => job.isActive).length;

  int get attentionCount => _jobs.values.where((job) => job.requiresAttention).length;

  void setServerManagedDownloadsReady(bool ready) {
    if (_serverManagedDownloadsReady == ready || _disposed) {
      return;
    }

    _serverManagedDownloadsReady = ready;
    _notifyListeners();
  }

  void setLibraryVisible(bool visible) {
    if (_isLibraryVisible == visible || _disposed) {
      return;
    }

    _isLibraryVisible = visible;
    _schedulePolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;

    if (_isForeground == isForeground || _disposed) {
      return;
    }

    _isForeground = isForeground;
    _schedulePolling();
  }

  void setGateway(AcquisitionDownloadsGateway? gateway) {
    if (identical(_gateway, gateway) || _disposed) {
      return;
    }

    _generation += 1;
    _pollTimer?.cancel();
    _gateway?.close();
    _gateway = gateway;
    _jobs.clear();
    _endpoints = const [];
    _selectedJobIds.clear();
    _remoteResults = const [];
    _selectedReleaseTokens.clear();
    _submissionErrorsByReleaseToken = const {};
    _remoteQuery = null;
    _searchError = null;
    _error = null;
    _isLoadingJobs = false;
    _isSearching = false;
    _isSubmitting = false;
    _notifyListeners();

    if (gateway != null) {
      unawaited(refreshConfiguration());
      unawaited(refreshJobs());
    }
  }

  Future<void> refreshConfiguration() async {
    final gateway = _gateway;

    if (gateway == null || _disposed) {
      return;
    }

    final generation = _generation;

    try {
      final endpoints = await gateway.listEndpoints();

      if (!_isCurrent(gateway, generation)) {
        return;
      }

      _endpoints = List.unmodifiable(endpoints);
      _error = null;
    } catch (error) {
      if (_isCurrent(gateway, generation)) {
        _endpoints = const [];
        _error = error.toString();
      }
    }

    if (_isCurrent(gateway, generation)) {
      _notifyListeners();
    }
  }

  Future<void> refreshJobs() async {
    final gateway = _gateway;

    if (gateway == null || _isLoadingJobs || _disposed) {
      return;
    }

    final generation = _generation;
    _isLoadingJobs = true;
    _notifyListeners();

    try {
      const limit = 100;
      final jobs = <AcquisitionJob>[];
      var offset = 0;
      var total = 0;

      do {
        final page = await gateway.listJobs(limit: limit, offset: offset);

        if (!_isCurrent(gateway, generation)) {
          return;
        }

        jobs.addAll(page.items);
        total = page.total;

        if (page.items.isEmpty) {
          break;
        }

        offset += page.items.length;
      } while (offset < total);

      _jobs
        ..clear()
        ..addEntries(jobs.map((job) => MapEntry(job.id, job)));
      _selectedJobIds.removeWhere((jobId) => !_jobs.containsKey(jobId));
      _error = null;
    } catch (error) {
      if (_isCurrent(gateway, generation)) {
        _error = error.toString();
      }
    } finally {
      if (_isCurrent(gateway, generation)) {
        _isLoadingJobs = false;
        _schedulePolling();
        _notifyListeners();
      }
    }
  }

  Future<void> searchRemote(String query, {List<String>? endpointIds}) async {
    final gateway = _gateway;
    final normalized = query.trim();

    if (gateway == null || normalized.isEmpty || _isSearching || _disposed) {
      return;
    }

    final generation = _generation;
    _isSearching = true;
    _remoteQuery = normalized;
    _remoteResults = const [];
    _selectedReleaseTokens.clear();
    _submissionErrorsByReleaseToken = const {};
    _searchError = null;
    _notifyListeners();

    try {
      final results = await gateway.search(normalized, endpointIds: endpointIds);

      if (!_isCurrent(gateway, generation)) {
        return;
      }

      _remoteResults = List.unmodifiable(results);
    } catch (error) {
      if (_isCurrent(gateway, generation)) {
        _remoteResults = const [];
        _searchError = searchErrorMessage(error);
      }
    } finally {
      if (_isCurrent(gateway, generation)) {
        _isSearching = false;
        _notifyListeners();
      }
    }
  }

  void setRemoteResults(String query, List<TorrentRelease> results) {
    if (_disposed) {
      return;
    }

    _remoteQuery = query;
    _remoteResults = List.unmodifiable(results);
    _selectedReleaseTokens.clear();
    _submissionErrorsByReleaseToken = const {};
    _searchError = null;
    _notifyListeners();
  }

  void clearRemoteResults() {
    if (_disposed) {
      return;
    }

    _remoteQuery = null;
    _remoteResults = const [];
    _selectedReleaseTokens.clear();
    _submissionErrorsByReleaseToken = const {};
    _searchError = null;
    _notifyListeners();
  }

  void toggleReleaseSelection(String releaseToken) {
    if (_disposed) {
      return;
    }

    if (!_selectedReleaseTokens.add(releaseToken)) {
      _selectedReleaseTokens.remove(releaseToken);
    }

    _notifyListeners();
  }

  void selectAllRemoteReleases() {
    if (_disposed) {
      return;
    }

    _selectedReleaseTokens
      ..clear()
      ..addAll(_remoteResults.map((release) => release.releaseToken));
    _notifyListeners();
  }

  void clearReleaseSelection() {
    if (_disposed) {
      return;
    }

    _selectedReleaseTokens.clear();
    _notifyListeners();
  }

  void toggleJobSelection(String jobId) {
    if (_disposed) {
      return;
    }

    if (!_selectedJobIds.add(jobId)) {
      _selectedJobIds.remove(jobId);
    }

    _notifyListeners();
  }

  void clearJobSelection() {
    if (_disposed) {
      return;
    }

    _selectedJobIds.clear();
    _notifyListeners();
  }

  Future<AcquisitionSubmissionOutcome> submitSelectedReleases(String endpointId) async {
    final gateway = _gateway;

    if (gateway == null || _selectedReleaseTokens.isEmpty || _isSubmitting || _disposed) {
      return AcquisitionSubmissionOutcome(successfulCount: 0, failuresByReleaseToken: const {});
    }

    final generation = _generation;
    final selected = _remoteResults.where((release) => _selectedReleaseTokens.contains(release.releaseToken)).toList();

    if (selected.isEmpty) {
      return AcquisitionSubmissionOutcome(successfulCount: 0, failuresByReleaseToken: const {});
    }

    _isSubmitting = true;
    _submissionErrorsByReleaseToken = const {};
    _notifyListeners();

    try {
      final response = await gateway.submitReleaseBatch(endpointId: endpointId, releases: selected);

      if (!_isCurrent(gateway, generation)) {
        return AcquisitionSubmissionOutcome(successfulCount: 0, failuresByReleaseToken: const {});
      }

      final resultIndexes = <int>{};
      final failuresByReleaseToken = <String, String>{};
      var successfulCount = 0;

      for (final item in response.items) {
        if (item.index < 0 || item.index >= selected.length || resultIndexes.contains(item.index)) {
          continue;
        }

        if (item.job == null && item.error == null) {
          continue;
        }

        resultIndexes.add(item.index);
        final releaseToken = selected[item.index].releaseToken;

        if (item.job case final job?) {
          _jobs[job.id] = job;
          _selectedReleaseTokens.remove(releaseToken);
          successfulCount += 1;
        } else {
          failuresByReleaseToken[releaseToken] = submissionErrorMessage(item.error);
        }
      }

      for (var index = 0; index < selected.length; index += 1) {
        if (!resultIndexes.contains(index)) {
          failuresByReleaseToken[selected[index].releaseToken] =
              'The download client did not return a result for this release.';
        }
      }

      _submissionErrorsByReleaseToken = Map.unmodifiable(failuresByReleaseToken);
      _schedulePolling();

      return AcquisitionSubmissionOutcome(
        successfulCount: successfulCount,
        failuresByReleaseToken: failuresByReleaseToken,
      );
    } catch (error) {
      if (_isCurrent(gateway, generation)) {
        final failuresByReleaseToken = {
          for (final release in selected) release.releaseToken: submissionErrorMessage(error.toString()),
        };
        _submissionErrorsByReleaseToken = Map.unmodifiable(failuresByReleaseToken);

        return AcquisitionSubmissionOutcome(successfulCount: 0, failuresByReleaseToken: failuresByReleaseToken);
      }
    } finally {
      if (_isCurrent(gateway, generation)) {
        _isSubmitting = false;
        _notifyListeners();
      }
    }

    return AcquisitionSubmissionOutcome(successfulCount: 0, failuresByReleaseToken: const {});
  }

  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId) async {
    final gateway = _gateway;

    if (gateway == null || _disposed) {
      return const [];
    }

    final generation = _generation;
    final files = await gateway.listJobFiles(jobId);

    return _isCurrent(gateway, generation) ? files : const [];
  }

  Future<void> selectJobFile(String jobId, int fileIndex) async {
    final gateway = _gateway;

    if (gateway == null || _disposed) {
      return;
    }

    final generation = _generation;
    final job = await gateway.selectJobFile(jobId, fileIndex);

    if (_isCurrent(gateway, generation)) {
      _replaceJob(job);
    }
  }

  Future<void> retryJobImport(String jobId) async {
    final gateway = _gateway;

    if (gateway == null || _disposed) {
      return;
    }

    final generation = _generation;
    final job = await gateway.retryJobImport(jobId);

    if (_isCurrent(gateway, generation)) {
      _replaceJob(job);
    }
  }

  Future<void> cancelSelectedJobs() async {
    final gateway = _gateway;

    if (gateway == null || _disposed) {
      return;
    }

    final generation = _generation;

    for (final jobId in _selectedJobIds.toList()) {
      final job = _jobs[jobId];

      if (job != null && job.canCancel) {
        try {
          final cancelled = await gateway.cancelJob(jobId);

          if (!_isCurrent(gateway, generation)) {
            return;
          }

          _jobs[cancelled.id] = cancelled;
        } catch (error) {
          if (!_isCurrent(gateway, generation)) {
            return;
          }

          _error = error.toString();
        }
      }
    }

    _selectedJobIds.clear();
    _schedulePolling();
    _notifyListeners();
  }

  Future<void> removeSelectedJobs() async {
    final gateway = _gateway;

    if (gateway == null || _disposed) {
      return;
    }

    final generation = _generation;

    for (final jobId in _selectedJobIds.toList()) {
      final job = _jobs[jobId];

      if (job?.status == AcquisitionJobStatus.failed || job?.status == AcquisitionJobStatus.cancelled) {
        try {
          await gateway.removeJob(jobId);

          if (!_isCurrent(gateway, generation)) {
            return;
          }

          _jobs.remove(jobId);
        } catch (error) {
          if (!_isCurrent(gateway, generation)) {
            return;
          }

          _error = error.toString();
        }
      }
    }

    _selectedJobIds.clear();
    _notifyListeners();
  }

  void _replaceJob(AcquisitionJob job) {
    _jobs[job.id] = job;
    _error = null;
    _schedulePolling();
    _notifyListeners();
  }

  void _schedulePolling() {
    _pollTimer?.cancel();

    if (!_isForeground || _disposed || !_jobs.values.any((job) => job.isActive)) {
      return;
    }

    final interval = _isLibraryVisible ? visiblePollingInterval : foregroundPollingInterval;

    if (interval == Duration.zero) {
      return;
    }

    _pollTimer = Timer(interval, () {
      unawaited(refreshJobs());
    });
  }

  bool _isCurrent(AcquisitionDownloadsGateway gateway, int generation) {
    return !_disposed && generation == _generation && identical(_gateway, gateway);
  }

  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _generation += 1;
    _pollTimer?.cancel();
    _gateway?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
