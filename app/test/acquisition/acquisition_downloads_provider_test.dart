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
    expect(provider.jobById('job-1')?.status, AcquisitionJobStatus.downloading);
    expect(provider.jobById('missing'), isNull);
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
    final gateway = _FakeGateway(
      endpointsError: StateError('https://download-client.local/settings?token=secret'),
      searchError: const AuthApiException(statusCode: 503, message: 'indexer down'),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.refreshConfiguration();
    await provider.searchRemote('  remote book  ');

    expect(provider.remoteQuery, 'remote book');
    expect(provider.remoteResults, isEmpty);
    expect(provider.searchError, 'Could not search connected sources. Check the enabled indexers and try again.');
    expect(provider.error, 'Could not load download settings. Try again.');

    provider.dispose();
  });

  test('search failure does not populate the general error state', () async {
    final provider = AcquisitionDownloadsProvider(
      gateway: _FakeGateway(searchError: const AuthApiException(statusCode: 503, message: 'indexer down')),
      pollingInterval: Duration.zero,
    );

    await provider.searchRemote('  remote book  ');

    expect(provider.remoteQuery, 'remote book');
    expect(provider.remoteResults, isEmpty);
    expect(provider.searchError, 'Could not search connected sources. Check the enabled indexers and try again.');
    expect(provider.error, isNull);

    provider.dispose();
  });

  test('clearing remote state invalidates a hung search without blocking the next search', () async {
    final oldSearch = Completer<List<TorrentRelease>>();
    final gateway = _FakeGateway(
      searchResponses: [
        oldSearch.future,
        const [TorrentRelease(title: 'New', releaseToken: 'new-token', protocol: 'torrent', indexer: 'Prowlarr')],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    final oldOperation = provider.searchRemote('old');
    expect(provider.isSearching, isTrue);

    provider.clearRemoteResults();

    expect(provider.isSearching, isFalse);
    expect(provider.remoteQuery, isNull);

    await provider.searchRemote('new');

    expect(provider.remoteQuery, 'new');
    expect(provider.remoteResults.single.releaseToken, 'new-token');
    expect(provider.isSearching, isFalse);

    oldSearch.complete(const [
      TorrentRelease(title: 'Old', releaseToken: 'old-token', protocol: 'torrent', indexer: 'Prowlarr'),
    ]);
    await oldOperation;

    expect(provider.remoteQuery, 'new');
    expect(provider.remoteResults.single.releaseToken, 'new-token');
    expect(provider.isSearching, isFalse);

    provider.dispose();
  });

  test('maps job refresh gateway failures to a safe general error', () async {
    final provider = AcquisitionDownloadsProvider(
      gateway: _FakeGateway(jobListError: StateError('https://download-client.local/jobs?token=secret')),
      pollingInterval: Duration.zero,
    );

    await provider.refreshJobs();

    expect(provider.error, 'Could not refresh downloads. Try again.');

    provider.dispose();
  });

  test('maps download file operation failures to safe general errors', () async {
    final provider = AcquisitionDownloadsProvider(
      gateway: _FakeGateway(
        filesError: StateError('https://download-client.local/files?token=secret'),
        selectFileError: StateError('https://download-client.local/file-selection?token=secret'),
        retryImportError: StateError('https://download-client.local/retry-import?token=secret'),
      ),
      pollingInterval: Duration.zero,
    );

    final filesResult = await provider.listJobFiles('job-1');
    expect(filesResult.isSuccess, isFalse);
    expect(filesResult.files, isEmpty);
    expect(filesResult.error, 'Could not load download files. Try again.');
    expect(provider.error, 'Could not load download files. Try again.');

    final selectFileOutcome = await provider.selectJobFile('job-1', 0);
    expect(selectFileOutcome.failed, isTrue);
    expect(selectFileOutcome.error, 'Could not select the download file. Try again.');
    expect(provider.error, selectFileOutcome.error);

    final retryOutcome = await provider.retryJobImport('job-1');
    expect(retryOutcome.failed, isTrue);
    expect(retryOutcome.error, 'Could not retry the download import. Try again.');
    expect(provider.error, retryOutcome.error);

    provider.dispose();
  });

  test('maps cancel and removal gateway failures to safe general errors', () async {
    final cancelProvider = AcquisitionDownloadsProvider(
      gateway: _FakeGateway(
        jobPages: [
          AcquisitionJobPage(items: [_job(status: AcquisitionJobStatus.downloading)], total: 1, limit: 100, offset: 0),
        ],
        cancelError: StateError('https://download-client.local/cancel?token=secret'),
      ),
      pollingInterval: Duration.zero,
    );
    await cancelProvider.refreshJobs();
    cancelProvider.toggleJobSelection('job-1');
    final cancelOutcome = await cancelProvider.cancelSelectedJobs();

    expect(cancelOutcome.failed, isTrue);
    expect(cancelOutcome.error, 'Could not cancel the download. Try again.');
    expect(cancelProvider.error, cancelOutcome.error);
    expect(cancelProvider.selectedJobIds, {'job-1'});
    cancelProvider.dispose();

    final removeProvider = AcquisitionDownloadsProvider(
      gateway: _FakeGateway(
        jobPages: [
          AcquisitionJobPage(items: [_job(status: AcquisitionJobStatus.failed)], total: 1, limit: 100, offset: 0),
        ],
        removeError: StateError('https://download-client.local/jobs/job-1?token=secret'),
      ),
      pollingInterval: Duration.zero,
    );
    await removeProvider.refreshJobs();
    removeProvider.toggleJobSelection('job-1');
    final removeOutcome = await removeProvider.removeSelectedJobs();

    expect(removeOutcome.failed, isTrue);
    expect(removeOutcome.error, 'Could not remove the download. Try again.');
    expect(removeProvider.error, removeOutcome.error);
    expect(removeProvider.selectedJobIds, {'job-1'});
    removeProvider.dispose();
  });

  test('retrying selected jobs retains only failed selections', () async {
    final gateway = _FakeGateway(
      jobPages: [
        AcquisitionJobPage(
          items: [
            _job(id: 'job-1', status: AcquisitionJobStatus.failed, retryable: true),
            _job(id: 'job-2', status: AcquisitionJobStatus.failed, retryable: true),
          ],
          total: 2,
          limit: 100,
          offset: 0,
        ),
      ],
      retryImportErrorsByJobId: {'job-2': StateError('raw retry failure with token=secret')},
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    await provider.refreshJobs();
    provider.toggleJobSelection('job-1');
    provider.toggleJobSelection('job-2');

    final outcome = await provider.retrySelectedJobs();

    expect(outcome.failed, isTrue);
    expect(outcome.error, 'Could not retry the download import. Try again.');
    expect(provider.selectedJobIds, {'job-2'});
    expect(gateway.retriedJobIds, ['job-1']);

    provider.dispose();
  });

  test('cancels one job without changing independent job selection', () async {
    final gateway = _FakeGateway(
      jobPages: [
        AcquisitionJobPage(
          items: [
            _job(id: 'job-1', status: AcquisitionJobStatus.downloading),
            _job(id: 'job-2', status: AcquisitionJobStatus.downloading),
          ],
          total: 2,
          limit: 100,
          offset: 0,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.refreshJobs();
    provider.toggleJobSelection('job-2');
    await provider.cancelJob('job-1');

    expect(gateway.cancelledJobIds, ['job-1']);
    expect(provider.jobs.where((job) => job.id == 'job-1').single.status, AcquisitionJobStatus.cancelled);
    expect(provider.selectedJobIds, {'job-2'});

    provider.dispose();
  });

  test('successful single cancellation clears a pre-existing provider error', () async {
    final gateway = _FakeGateway(filesError: StateError('https://download-client.local/files?token=secret'));
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    await provider.listJobFiles('job-1');
    expect(provider.error, 'Could not load download files. Try again.');

    await provider.cancelJob('job-1');

    expect(provider.error, isNull);
    expect(provider.jobById('job-1')?.status, AcquisitionJobStatus.cancelled);

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

  test('reselects a failed release that was toggled off while submitting', () async {
    final submission = Completer<BatchSubmissionResponse>();
    final gateway = _FakeGateway(batchCompleter: submission);
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const release = TorrentRelease(title: 'One', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr');

    provider.setRemoteResults('query', const [release]);
    provider.toggleReleaseSelection('token-1');
    final operation = provider.submitSelectedReleases('endpoint-1');
    provider.toggleReleaseSelection('token-1');

    submission.complete(
      const BatchSubmissionResponse(items: [BatchSubmissionItem(index: 0, job: null, error: 'rejected')]),
    );
    await operation;

    expect(provider.selectedReleaseTokens, {'token-1'});
    expect(provider.submissionErrorsByReleaseToken, {'token-1': 'The download client rejected this release.'});

    provider.dispose();
  });

  test('ignores an older submission after a newer search starts', () async {
    final submission = Completer<BatchSubmissionResponse>();
    final search = Completer<List<TorrentRelease>>();
    final gateway = _FakeGateway(batchCompleter: submission, searchCompleter: search);
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    const oldReleases = [
      TorrentRelease(title: 'Old one', releaseToken: 'old-1', protocol: 'torrent', indexer: 'Prowlarr'),
      TorrentRelease(title: 'Old two', releaseToken: 'old-2', protocol: 'torrent', indexer: 'Prowlarr'),
    ];

    provider.setRemoteResults('old', oldReleases);
    provider.selectAllRemoteReleases();
    final submissionOperation = provider.submitSelectedReleases('endpoint-1');
    final searchOperation = provider.searchRemote('new');

    search.complete(const [
      TorrentRelease(title: 'New', releaseToken: 'new-1', protocol: 'torrent', indexer: 'Prowlarr'),
    ]);
    await searchOperation;
    provider.toggleReleaseSelection('new-1');

    submission.complete(
      BatchSubmissionResponse(
        items: [
          BatchSubmissionItem(index: 0, job: _job(status: AcquisitionJobStatus.submitted), error: null),
          const BatchSubmissionItem(index: 1, job: null, error: 'rejected'),
        ],
      ),
    );
    await submissionOperation;

    expect(provider.remoteQuery, 'new');
    expect(provider.remoteResults.single.releaseToken, 'new-1');
    expect(provider.selectedReleaseTokens, {'new-1'});
    expect(provider.submissionErrorsByReleaseToken, isEmpty);
    expect(provider.jobs, isEmpty);

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
    await tester.pump();
    expect(gateway.listJobCalls, 3);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(gateway.listJobCalls, 4);

    provider.dispose();
  });

  testWidgets('keeps discovering external jobs after the visible library initially refreshes empty', (tester) async {
    final gateway = _FakeGateway(
      jobPages: [
        const AcquisitionJobPage(items: [], total: 0, limit: 100, offset: 0),
        AcquisitionJobPage(
          items: [_job(id: 'external-job', status: AcquisitionJobStatus.downloading)],
          total: 1,
          limit: 100,
          offset: 0,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(
      gateway: gateway,
      visiblePollingInterval: const Duration(seconds: 2),
      foregroundPollingInterval: const Duration(seconds: 10),
    );

    expect(provider.jobs, isEmpty);

    provider.setLibraryVisible(true);
    await tester.pump();

    expect(gateway.listJobCalls, 1);
    expect(provider.jobs, isEmpty);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(gateway.listJobCalls, 2);
    expect(provider.jobs.single.id, 'external-job');

    provider.dispose();
  });

  testWidgets('discovers an externally created job on resume with no known jobs', (tester) async {
    final gateway = _FakeGateway(
      jobPages: [
        const AcquisitionJobPage(items: [], total: 0, limit: 100, offset: 0),
        AcquisitionJobPage(
          items: [_job(id: 'resumed-job', status: AcquisitionJobStatus.queued)],
          total: 1,
          limit: 100,
          offset: 0,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);

    provider.setLibraryVisible(true);
    await tester.pump();
    expect(provider.jobs, isEmpty);

    provider.didChangeAppLifecycleState(AppLifecycleState.paused);
    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    expect(gateway.listJobCalls, 2);
    expect(provider.jobs.single.id, 'resumed-job');

    provider.dispose();
  });
}

class _FakeGateway implements AcquisitionDownloadsGateway {
  final List<AcquisitionEndpoint> endpoints;
  final List<AcquisitionJobPage> jobPages;
  final BatchSubmissionResponse batchResult;
  final Completer<BatchSubmissionResponse>? batchCompleter;
  final AcquisitionJobPage? repeatedJobPage;
  final Object? endpointsError;
  final Object? jobListError;
  final Object? searchError;
  final Completer<List<TorrentRelease>>? searchCompleter;
  final List<Object> _searchResponses;
  final Object? filesError;
  final Object? selectFileError;
  final Object? retryImportError;
  final Map<String, Object> retryImportErrorsByJobId;
  final Object? cancelError;
  final Object? removeError;
  List<String> submittedTokens = [];
  final List<int> jobOffsets = [];
  int listJobCalls = 0;
  final List<String> cancelledJobIds = [];
  final List<String> retriedJobIds = [];
  bool closed = false;

  _FakeGateway({
    this.endpoints = const [],
    this.jobPages = const [],
    this.batchResult = const BatchSubmissionResponse(items: []),
    this.batchCompleter,
    this.repeatedJobPage,
    this.endpointsError,
    this.jobListError,
    this.searchError,
    this.searchCompleter,
    List<Object> searchResponses = const [],
    this.filesError,
    this.selectFileError,
    this.retryImportError,
    this.retryImportErrorsByJobId = const {},
    this.cancelError,
    this.removeError,
  }) : _searchResponses = [...searchResponses];

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints() async {
    if (endpointsError case final error?) {
      throw error;
    }

    return endpoints;
  }

  @override
  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0}) async {
    listJobCalls += 1;
    jobOffsets.add(offset);
    if (jobListError case final error?) {
      throw error;
    }
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

    if (_searchResponses.isNotEmpty) {
      final response = _searchResponses.removeAt(0);

      if (response is Future<List<TorrentRelease>>) {
        return response;
      }
      if (response is List<TorrentRelease>) {
        return response;
      }

      throw response;
    }

    if (searchCompleter case final completer?) {
      return completer.future;
    }

    return const [];
  }

  @override
  Future<AcquisitionJob> cancelJob(String jobId) async {
    if (cancelError case final error?) {
      throw error;
    }

    cancelledJobIds.add(jobId);

    return _job(id: jobId, status: AcquisitionJobStatus.cancelled);
  }

  @override
  Future<void> removeJob(String jobId) async {
    if (removeError case final error?) {
      throw error;
    }
  }

  @override
  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId) async {
    if (filesError case final error?) {
      throw error;
    }

    return const [];
  }

  @override
  Future<AcquisitionJob> selectJobFile(String jobId, int fileIndex) async {
    if (selectFileError case final error?) {
      throw error;
    }

    return _job(status: AcquisitionJobStatus.downloading);
  }

  @override
  Future<AcquisitionJob> retryJobImport(String jobId) async {
    if (retryImportErrorsByJobId[jobId] case final error?) {
      throw error;
    }

    if (retryImportError case final error?) {
      throw error;
    }

    retriedJobIds.add(jobId);

    return _job(id: jobId, status: AcquisitionJobStatus.downloading);
  }

  @override
  void close() {
    closed = true;
  }
}

AcquisitionJob _job({String id = 'job-1', required AcquisitionJobStatus status, bool retryable = false}) {
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
    submittedAt: retryable ? DateTime(2026) : null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
  );
}
