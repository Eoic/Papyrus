import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';

void main() {
  test('is ready only with an enabled indexer and managed qBittorrent client', () async {
    final gateway = _FakeGateway(
      endpoints: [
        AcquisitionEndpoint(
          id: 'indexer-1',
          name: 'Prowlarr',
          kind: AcquisitionEndpointKind.prowlarr,
          baseUrl: Uri.parse('http://prowlarr.local'),
          enabled: true,
        ),
        AcquisitionEndpoint(
          id: 'client-1',
          name: 'qBittorrent',
          kind: AcquisitionEndpointKind.qbittorrent,
          baseUrl: Uri.parse('http://qbittorrent.local'),
          downloadRoot: '/downloads',
          enabled: true,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.refreshConfiguration();

    expect(provider.isManagedAcquisitionReady, isTrue);
    expect(provider.downloadClients.single.id, 'client-1');

    provider.dispose();
  });

  test('reconciles polled jobs and keeps download selection separate', () async {
    final gateway = _FakeGateway(
      jobPages: [
        AcquisitionJobPage(items: [_job(status: AcquisitionJobStatus.downloading)], total: 1, limit: 50, offset: 0),
        AcquisitionJobPage(items: [_job(status: AcquisitionJobStatus.completed)], total: 1, limit: 50, offset: 0),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.refreshJobs();
    provider.toggleJobSelection('job-1');

    expect(provider.jobs.single.status, AcquisitionJobStatus.downloading);
    expect(provider.jobsByBookId['book-1']?.status, AcquisitionJobStatus.downloading);
    expect(provider.activeCount, 1);
    expect(provider.selectedJobIds, {'job-1'});

    await provider.refreshJobs();

    expect(provider.jobs.single.status, AcquisitionJobStatus.completed);
    expect(provider.jobsByBookId, isEmpty);
    expect(provider.activeCount, 0);
    expect(provider.selectedJobIds, {'job-1'});

    provider.dispose();
  });

  test('search keeps task state separate from job refresh errors', () async {
    final gateway = _FakeGateway(searchError: const AuthApiException(statusCode: 503, message: 'indexer down'));
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.refreshJobs();
    await provider.searchRemote('  remote book  ');

    expect(provider.remoteQuery, 'remote book');
    expect(provider.remoteResults, isEmpty);
    expect(provider.searchError, 'Could not search connected sources. Check the enabled indexers and try again.');
    expect(provider.error, isNull);

    provider.dispose();
  });

  test('submits selected remote releases and preserves only failed selections', () async {
    final gateway = _FakeGateway(
      batchResult: BatchSubmissionResponse(
        items: [
          BatchSubmissionItem(index: 0, job: _job(status: AcquisitionJobStatus.submitted), error: null),
          const BatchSubmissionItem(index: 1, job: null, error: 'Release token expired'),
        ],
      ),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const releases = [
      TorrentRelease(title: 'One', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr'),
      TorrentRelease(title: 'Two', releaseToken: 'token-2', protocol: 'torrent', indexer: 'Prowlarr'),
    ];

    provider.setRemoteResults('query', releases);
    provider.toggleReleaseSelection('token-1');
    provider.toggleReleaseSelection('token-2');
    final outcome = await provider.submitSelectedReleases('endpoint-1');

    expect(gateway.submittedTokens, ['token-1', 'token-2']);
    expect(provider.jobs.single.status, AcquisitionJobStatus.submitted);
    expect(outcome.successfulCount, 1);
    expect(outcome.failuresByReleaseToken, {'token-2': 'This release could not be sent to the download client.'});
    expect(outcome.failedCount, 1);
    expect(outcome.allSucceeded, isFalse);
    expect(provider.submissionErrorsByReleaseToken, outcome.failuresByReleaseToken);
    expect(provider.submissionErrors, ['This release could not be sent to the download client.']);
    expect(provider.selectedReleaseTokens, {'token-2'});

    provider.dispose();
  });

  test('reports complete batch success and deselects every release', () async {
    final gateway = _FakeGateway(
      batchResult: BatchSubmissionResponse(
        items: [
          BatchSubmissionItem(
            index: 0,
            job: _job(id: 'job-1', status: AcquisitionJobStatus.submitted),
            error: null,
          ),
          BatchSubmissionItem(
            index: 1,
            job: _job(id: 'job-2', status: AcquisitionJobStatus.submitted),
            error: null,
          ),
        ],
      ),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const releases = [
      TorrentRelease(title: 'One', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr'),
      TorrentRelease(title: 'Two', releaseToken: 'token-2', protocol: 'torrent', indexer: 'Prowlarr'),
    ];

    provider.setRemoteResults('query', releases);
    provider.selectAllRemoteReleases();
    final outcome = await provider.submitSelectedReleases('endpoint-1');

    expect(outcome.successfulCount, 2);
    expect(outcome.failuresByReleaseToken, isEmpty);
    expect(outcome.allSucceeded, isTrue);
    expect(provider.selectedReleaseTokens, isEmpty);
    expect(provider.jobs, hasLength(2));

    provider.dispose();
  });

  test('reports complete batch failure and keeps every release selected', () async {
    final gateway = _FakeGateway(
      batchResult: const BatchSubmissionResponse(
        items: [
          BatchSubmissionItem(index: 0, job: null, error: 'timeout while contacting endpoint-1'),
          BatchSubmissionItem(index: 1, job: null, error: 'authentication error at https://client.local'),
        ],
      ),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const releases = [
      TorrentRelease(title: 'One', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr'),
      TorrentRelease(title: 'Two', releaseToken: 'token-2', protocol: 'torrent', indexer: 'Prowlarr'),
    ];

    provider.setRemoteResults('query', releases);
    provider.selectAllRemoteReleases();
    final outcome = await provider.submitSelectedReleases('endpoint-1');

    expect(outcome.successfulCount, 0);
    expect(outcome.failedCount, 2);
    expect(outcome.allSucceeded, isFalse);
    expect(provider.selectedReleaseTokens, {'token-1', 'token-2'});
    expect(provider.jobs, isEmpty);

    provider.dispose();
  });

  test('loads every jobs page so older active downloads remain visible', () async {
    final gateway = _FakeGateway(
      jobPages: [
        AcquisitionJobPage(
          items: [_job(id: 'job-new', status: AcquisitionJobStatus.completed)],
          total: 2,
          limit: 1,
          offset: 0,
        ),
        AcquisitionJobPage(
          items: [_job(id: 'job-active', status: AcquisitionJobStatus.downloading)],
          total: 2,
          limit: 1,
          offset: 1,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.refreshJobs();

    expect(provider.jobs.map((job) => job.id), containsAll(['job-new', 'job-active']));
    expect(provider.activeCount, 1);
    expect(gateway.jobOffsets, [0, 1]);

    provider.dispose();
  });

  test('discards a submission completed after the gateway changes', () async {
    final submission = Completer<BatchSubmissionResponse>();
    final firstGateway = _FakeGateway(batchCompleter: submission);
    final secondGateway = _FakeGateway();
    final provider = AcquisitionDownloadsProvider(gateway: firstGateway, pollingInterval: Duration.zero);
    const release = TorrentRelease(title: 'One', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr');
    provider.setRemoteResults('query', const [release]);
    provider.toggleReleaseSelection('token-1');

    final operation = provider.submitSelectedReleases('endpoint-1');
    provider.setGateway(secondGateway);
    submission.complete(
      BatchSubmissionResponse(
        items: [BatchSubmissionItem(index: 0, job: _job(status: AcquisitionJobStatus.submitted), error: null)],
      ),
    );
    await operation;

    expect(provider.jobs, isEmpty);
    expect(firstGateway.closed, isTrue);

    provider.dispose();
  });

  test('treats malformed, out-of-range, and omitted batch items as failed', () async {
    final gateway = _FakeGateway(
      batchResult: BatchSubmissionResponse(
        items: [
          BatchSubmissionItem(index: 0, job: _job(status: AcquisitionJobStatus.submitted), error: null),
          const BatchSubmissionItem(index: 1, job: null, error: null),
          const BatchSubmissionItem(index: 20, job: null, error: 'rejected'),
        ],
      ),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const releases = [
      TorrentRelease(title: 'One', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr'),
      TorrentRelease(title: 'Two', releaseToken: 'token-2', protocol: 'torrent', indexer: 'Prowlarr'),
      TorrentRelease(title: 'Three', releaseToken: 'token-3', protocol: 'torrent', indexer: 'Prowlarr'),
    ];

    provider.setRemoteResults('query', releases);
    provider.selectAllRemoteReleases();
    final outcome = await provider.submitSelectedReleases('endpoint-1');

    expect(outcome.successfulCount, 1);
    expect(outcome.failuresByReleaseToken, {
      'token-2': 'The download client did not return a result for this release.',
      'token-3': 'The download client did not return a result for this release.',
    });
    expect(provider.selectedReleaseTokens, {'token-2', 'token-3'});
    expect(provider.jobs, hasLength(1));

    provider.dispose();
  });

  test('clears stale row errors when a new search starts', () async {
    final search = Completer<List<TorrentRelease>>();
    final gateway = _FakeGateway(
      batchResult: const BatchSubmissionResponse(items: [BatchSubmissionItem(index: 0, job: null, error: 'rejected')]),
      searchCompleter: search,
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const release = TorrentRelease(title: 'Old', releaseToken: 'token-old', protocol: 'torrent', indexer: 'Prowlarr');

    provider.setRemoteResults('old', const [release]);
    provider.toggleReleaseSelection('token-old');
    await provider.submitSelectedReleases('endpoint-1');
    final operation = provider.searchRemote(' new ');

    expect(provider.remoteQuery, 'new');
    expect(provider.remoteResults, isEmpty);
    expect(provider.submissionErrorsByReleaseToken, isEmpty);
    expect(provider.selectedReleaseTokens, isEmpty);

    search.complete(const [
      TorrentRelease(title: 'New', releaseToken: 'token-new', protocol: 'torrent', indexer: 'Prowlarr'),
    ]);
    await operation;

    expect(provider.remoteResults.single.releaseToken, 'token-new');

    provider.dispose();
  });

  test('makes submission outcome failures immutable at the boundary', () {
    final failures = {'token-1': 'failed'};
    final outcome = AcquisitionSubmissionOutcome(successfulCount: 0, failuresByReleaseToken: failures);

    failures['token-2'] = 'later mutation';

    expect(outcome.failuresByReleaseToken, {'token-1': 'failed'});
    expect(() => outcome.failuresByReleaseToken['token-3'] = 'not allowed', throwsUnsupportedError);
  });

  testWidgets('uses visible polling and stops while the application is backgrounded', (tester) async {
    final gateway = _FakeGateway(
      repeatedJobPage: AcquisitionJobPage(
        items: [_job(status: AcquisitionJobStatus.downloading)],
        total: 1,
        limit: 100,
        offset: 0,
      ),
    );
    final provider = AcquisitionDownloadsProvider(
      gateway: gateway,
      visiblePollingInterval: const Duration(seconds: 2),
      foregroundPollingInterval: const Duration(seconds: 10),
    );
    provider.setLibraryVisible(true);

    await provider.refreshJobs();
    expect(gateway.listJobCalls, 1);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(gateway.listJobCalls, 2);

    provider.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 4));
    expect(gateway.listJobCalls, 2);

    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(gateway.listJobCalls, 3);

    provider.dispose();
  });
}

class _FakeGateway implements AcquisitionDownloadsGateway {
  final List<AcquisitionEndpoint> endpoints;
  final List<AcquisitionJobPage> jobPages;
  final BatchSubmissionResponse batchResult;
  final Completer<BatchSubmissionResponse>? batchCompleter;
  final AcquisitionJobPage? repeatedJobPage;
  final List<TorrentRelease> searchResults;
  final Object? searchError;
  final Completer<List<TorrentRelease>>? searchCompleter;
  List<String> submittedTokens = [];
  final List<int> jobOffsets = [];
  int listJobCalls = 0;
  bool closed = false;

  _FakeGateway({
    this.endpoints = const [],
    this.jobPages = const [],
    this.batchResult = const BatchSubmissionResponse(items: []),
    this.batchCompleter,
    this.repeatedJobPage,
    this.searchResults = const [],
    this.searchError,
    this.searchCompleter,
  });

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints() async => endpoints;

  @override
  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0}) async {
    listJobCalls += 1;
    jobOffsets.add(offset);
    if (jobPages.isNotEmpty) {
      return jobPages.removeAt(0);
    }
    return repeatedJobPage ?? const AcquisitionJobPage(items: [], total: 0, limit: 50, offset: 0);
  }

  @override
  Future<BatchSubmissionResponse> submitReleaseBatch({
    required String endpointId,
    required List<TorrentRelease> releases,
  }) async {
    submittedTokens = releases.map((release) => release.releaseToken).toList();
    if (batchCompleter case final completer?) {
      return completer.future;
    }
    return batchResult;
  }

  @override
  Future<List<TorrentRelease>> search(String query, {List<String>? endpointIds}) async {
    if (searchError case final error?) {
      throw error;
    }

    if (searchCompleter case final completer?) {
      return completer.future;
    }

    return searchResults;
  }

  @override
  Future<AcquisitionJob> cancelJob(String jobId) async => _job(status: AcquisitionJobStatus.cancelled);

  @override
  Future<void> removeJob(String jobId) async {}

  @override
  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId) async => const [];

  @override
  Future<AcquisitionJob> selectJobFile(String jobId, int fileIndex) async {
    return _job(status: AcquisitionJobStatus.downloading);
  }

  @override
  Future<AcquisitionJob> retryJobImport(String jobId) async {
    return _job(status: AcquisitionJobStatus.downloading);
  }

  @override
  void close() {
    closed = true;
  }
}

AcquisitionJob _job({String id = 'job-1', required AcquisitionJobStatus status}) {
  return AcquisitionJob(
    id: id,
    endpointId: 'endpoint-1',
    ruleId: null,
    bookId: 'book-1',
    title: 'Example',
    status: status,
    clientReference: null,
    clientHash: 'hash-1',
    clientState: status.apiValue,
    progressBasisPoints: status == AcquisitionJobStatus.completed ? 10000 : 5000,
    downloadedBytes: 512,
    totalBytes: 1024,
    downloadSpeedBytesPerSecond: 128,
    etaSeconds: 4,
    selectedFilePath: null,
    retryCount: 0,
    error: null,
    nextPollAt: null,
    createdAt: null,
    updatedAt: null,
    submittedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
  );
}
