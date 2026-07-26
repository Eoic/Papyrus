import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/acquisition_job_sheets.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

void main() {
  testWidgets('shows download details in a content-height Papyrus bottom sheet', (tester) async {
    final semantics = tester.ensureSemantics();
    final gateway = _RecordingGateway();
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    final job = _job(
      status: AcquisitionJobStatus.downloading,
      selectedFilePath: '/downloads/Example Book.epub',
      error: 'https://client.local/api?password=secret',
    );

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheetHandle), findsOneWidget);
    expect(find.text('Example Book'), findsOneWidget);
    expect(find.text('Downloading 42%'), findsOneWidget);
    expect(find.text('1.0 MB of 4.0 MB'), findsOneWidget);
    expect(find.text('2.0 MB/s'), findsOneWidget);
    expect(find.text('3 min remaining'), findsOneWidget);
    expect(find.text('Example Book.epub'), findsOneWidget);
    expect(find.textContaining('/downloads/'), findsNothing);
    expect(find.textContaining('client.local'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text('endpoint-secret'), findsNothing);
    expect(find.text('hash-secret'), findsNothing);
    expect(find.text('technical-client-state'), findsNothing);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.42);
    expect(
      tester.getSemantics(find.byKey(const Key('acquisition-job-details-title'))).flagsCollection.isHeader,
      isTrue,
    );

    final title = tester.widget<Text>(find.text('Example Book'));
    final titleContext = tester.element(find.text('Example Book'));
    expect(title.style, Theme.of(titleContext).textTheme.headlineSmall);

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(
      sheet.shape,
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    );

    final content = find.byKey(const Key('acquisition-job-details-content'));
    final padding = tester.widget<Padding>(content);
    expect(padding.padding, const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg));
    expect(tester.getSize(find.byType(BottomSheet)).height, lessThan(900));

    semantics.dispose();
  });

  testWidgets('shows only Cancel for an active download', (tester) async {
    final job = _job(status: AcquisitionJobStatus.downloading);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Cancel'), findsOneWidget);
    expect(find.text('Retry import'), findsNothing);
    expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
  });

  testWidgets('confirms and cancels one job without using another bottom sheet', (tester) async {
    final job = _job(status: AcquisitionJobStatus.downloading);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Cancel download'), findsNWidgets(2));
    expect(find.text('Cancel "Example Book"?'), findsOneWidget);

    final destructiveAction = find.widgetWithText(FilledButton, 'Cancel download');
    final button = tester.widget<FilledButton>(destructiveAction);
    final colorScheme = Theme.of(tester.element(destructiveAction)).colorScheme;
    expect(button.style?.backgroundColor?.resolve(<WidgetState>{}), colorScheme.error);

    await tester.tap(destructiveAction);
    await tester.pumpAndSettle();

    expect(gateway.cancelledJobIds, ['job-1']);
  });

  testWidgets('failed cancellation shows a safe message and reopens the actionable details', (tester) async {
    final job = _job(status: AcquisitionJobStatus.downloading);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      cancelError: StateError('raw cancel failure at https://client.invalid?token=secret'),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel download'));
    await tester.pumpAndSettle();

    expect(find.text('Could not cancel the download. Try again.'), findsOneWidget);
    expect(find.textContaining('client.invalid'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('offers supported files only when file selection is needed', (tester) async {
    final job = _job(status: AcquisitionJobStatus.needsFileSelection);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      files: const [
        AcquisitionFileCandidate(
          index: 2,
          name: 'Example Book.epub',
          sizeBytes: 2 * 1024 * 1024,
          progressBasisPoints: 10000,
          priority: 1,
          supported: true,
        ),
        AcquisitionFileCandidate(
          index: 3,
          name: 'Cover.jpg',
          sizeBytes: 512,
          progressBasisPoints: 10000,
          priority: 1,
          supported: false,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Select file'), findsOneWidget);
    expect(find.text('Example Book.epub'), findsOneWidget);
    expect(find.text('2.0 MB'), findsOneWidget);
    expect(find.text('Cover.jpg'), findsNothing);
    expect(find.text('Retry import'), findsNothing);

    await tester.tap(find.text('Example Book.epub'));
    await tester.pumpAndSettle();

    expect(gateway.selectedFile, ('job-1', 2));
  });

  testWidgets('failed file selection shows a safe message and keeps the choice retryable', (tester) async {
    final job = _job(status: AcquisitionJobStatus.needsFileSelection);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      files: const [
        AcquisitionFileCandidate(
          index: 2,
          name: 'Example Book.epub',
          sizeBytes: 2 * 1024 * 1024,
          progressBasisPoints: 10000,
          priority: 1,
          supported: true,
        ),
      ],
      selectFileError: StateError('raw file failure at https://client.invalid?token=secret'),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Example Book.epub'));
    await tester.pumpAndSettle();

    expect(find.text('Could not select the download file. Try again.'), findsOneWidget);
    expect(find.textContaining('client.invalid'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Example Book.epub'), findsOneWidget);
  });

  testWidgets('offers Retry import only for retryable failed imports', (tester) async {
    final job = _job(status: AcquisitionJobStatus.failed, submittedAt: DateTime(2026));
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Retry import'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Select file'), findsNothing);
    expect(find.textContaining('technical backend failure'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry import'));
    await tester.pumpAndSettle();

    expect(gateway.retriedJobIds, ['job-1']);
  });

  testWidgets('failed import retry shows a safe message and reopens the actionable details', (tester) async {
    final job = _job(status: AcquisitionJobStatus.failed, submittedAt: DateTime(2026));
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      retryError: StateError('raw retry failure at https://client.invalid?token=secret'),
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Retry import'));
    await tester.pumpAndSettle();

    expect(find.text('Could not retry the download import. Try again.'), findsOneWidget);
    expect(find.textContaining('client.invalid'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry import'), findsOneWidget);
  });

  testWidgets('terminal jobs expose no contextual actions', (tester) async {
    final job = _job(status: AcquisitionJobStatus.completed);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Retry import'), findsNothing);
    expect(find.text('Select file'), findsNothing);
  });

  testWidgets('attention compatibility wrapper delegates to the details sheet', (tester) async {
    final provider = AcquisitionDownloadsProvider(gateway: _RecordingGateway(), pollingInterval: Duration.zero);
    addTearDown(provider.dispose);

    await _pumpLauncher(
      tester,
      provider: provider,
      job: _job(status: AcquisitionJobStatus.unknown),
      useCompatibilityWrapper: true,
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Example Book'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.textContaining('mystery_state'), findsNothing);
  });

  testWidgets('rebuilds details from live provider job updates', (tester) async {
    final downloading = _job(status: AcquisitionJobStatus.downloading);
    final importing = _job(status: AcquisitionJobStatus.importing);
    final gateway = _RecordingGateway(
      jobResponses: [
        [downloading],
        [importing],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: downloading);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Downloading 42%'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Cancel'), findsOneWidget);

    await provider.refreshJobs();
    await tester.pump();

    expect(find.text('Adding to library'), findsOneWidget);
    expect(find.text('Downloading 42%'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('suppresses stale cancellation after the live job completes', (tester) async {
    final downloading = _job(status: AcquisitionJobStatus.downloading);
    final completed = _job(status: AcquisitionJobStatus.completed);
    final gateway = _RecordingGateway(
      jobResponses: [
        [downloading],
        [completed],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: downloading);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
    await tester.pumpAndSettle();

    await provider.refreshJobs();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel download'));
    await tester.pumpAndSettle();

    expect(gateway.cancelledJobIds, isEmpty);
    expect(provider.jobById('job-1')?.status, AcquisitionJobStatus.completed);
  });

  testWidgets('suppresses a stale import retry after the live job completes', (tester) async {
    final failed = _job(status: AcquisitionJobStatus.failed, submittedAt: DateTime(2026));
    final completed = _job(status: AcquisitionJobStatus.completed);
    final gateway = _RecordingGateway(
      jobResponses: [
        [failed],
        [completed],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: failed);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    final staleRetry = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry import')).onPressed!;

    await provider.refreshJobs();
    staleRetry();
    await tester.pumpAndSettle();

    expect(gateway.retriedJobIds, isEmpty);
    expect(provider.jobById('job-1')?.status, AcquisitionJobStatus.completed);
  });

  testWidgets('suppresses a stale file selection after the live job completes', (tester) async {
    final needsFile = _job(status: AcquisitionJobStatus.needsFileSelection);
    final completed = _job(status: AcquisitionJobStatus.completed);
    final gateway = _RecordingGateway(
      jobResponses: [
        [needsFile],
        [completed],
      ],
      files: const [
        AcquisitionFileCandidate(
          index: 2,
          name: 'Example Book.epub',
          sizeBytes: 2 * 1024 * 1024,
          progressBasisPoints: 10000,
          priority: 1,
          supported: true,
        ),
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: needsFile);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    final staleFileSelection = tester
        .widget<ListTile>(find.ancestor(of: find.text('Example Book.epub'), matching: find.byType(ListTile)))
        .onTap!;

    await provider.refreshJobs();
    staleFileSelection();
    await tester.pumpAndSettle();

    expect(gateway.selectedFile, isNull);
    expect(provider.jobById('job-1')?.status, AcquisitionJobStatus.completed);
  });

  testWidgets('opens immediately and shows loading while file choices are pending', (tester) async {
    final job = _job(status: AcquisitionJobStatus.needsFileSelection);
    final filesCompleter = Completer<List<AcquisitionFileCandidate>>();
    addTearDown(() {
      if (!filesCompleter.isCompleted) {
        filesCompleter.complete(const []);
      }
    });
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      fileResponses: [filesCompleter.future],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Loading files…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No supported book files found.'), findsNothing);

    filesCompleter.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('Loading files…'), findsNothing);
    expect(find.text('No supported book files found.'), findsOneWidget);
  });

  testWidgets('shows a safe file error and retries in the sheet', (tester) async {
    final job = _job(status: AcquisitionJobStatus.needsFileSelection);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      fileResponses: [
        StateError('https://client.local/files?password=secret'),
        const <AcquisitionFileCandidate>[
          AcquisitionFileCandidate(
            index: 4,
            name: 'Retry Book.epub',
            sizeBytes: 1024,
            progressBasisPoints: 10000,
            priority: 1,
            supported: true,
          ),
        ],
      ],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load download files. Try again.'), findsOneWidget);
    expect(find.textContaining('client.local'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    expect(find.text('No supported book files found.'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(gateway.fileLoadCalls, 2);
    expect(find.text('Retry Book.epub'), findsOneWidget);
    expect(find.text('Could not load download files. Try again.'), findsNothing);
    expect(provider.error, isNull);
  });

  testWidgets('shows the genuine empty state only after a successful file response', (tester) async {
    final job = _job(status: AcquisitionJobStatus.needsFileSelection);
    final gateway = _RecordingGateway(
      jobResponses: [
        [job],
      ],
      fileResponses: const [<AcquisitionFileCandidate>[]],
    );
    final provider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
    addTearDown(provider.dispose);
    await provider.refreshJobs();

    await _pumpLauncher(tester, provider: provider, job: job);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('No supported book files found.'), findsOneWidget);
    expect(find.text('Could not load download files. Try again.'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required AcquisitionDownloadsProvider provider,
  required AcquisitionJob job,
  bool useCompatibilityWrapper = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () {
              if (useCompatibilityWrapper) {
                showAcquisitionJobAttentionSheet(context: context, provider: provider, job: job);
              } else {
                showAcquisitionJobDetailsSheet(context: context, provider: provider, job: job);
              }
            },
            child: const Text('Open details'),
          ),
        ),
      ),
    ),
  );
}

class _RecordingGateway implements AcquisitionDownloadsGateway {
  _RecordingGateway({
    this.files = const [],
    List<List<AcquisitionJob>> jobResponses = const [],
    List<Object>? fileResponses,
    this.cancelError,
    this.retryError,
    this.selectFileError,
  }) : _jobResponses = [...jobResponses],
       _fileResponses = [...?fileResponses];

  final List<AcquisitionFileCandidate> files;
  final List<List<AcquisitionJob>> _jobResponses;
  final List<Object> _fileResponses;
  final Object? cancelError;
  final Object? retryError;
  final Object? selectFileError;
  final List<String> cancelledJobIds = [];
  final List<String> retriedJobIds = [];
  List<AcquisitionJob> _lastJobs = const [];
  int fileLoadCalls = 0;
  (String, int)? selectedFile;

  @override
  Future<AcquisitionJob> cancelJob(String jobId) async {
    if (cancelError case final error?) {
      throw error;
    }

    cancelledJobIds.add(jobId);

    return _job(status: AcquisitionJobStatus.cancelled);
  }

  @override
  void close() {}

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints() async => const [];

  @override
  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId) async {
    fileLoadCalls += 1;

    if (_fileResponses.isEmpty) {
      return files;
    }

    final response = _fileResponses.removeAt(0);

    if (response is Future<List<AcquisitionFileCandidate>>) {
      return response;
    }
    if (response is List<AcquisitionFileCandidate>) {
      return response;
    }

    throw response;
  }

  @override
  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0}) async {
    if (_jobResponses.isNotEmpty) {
      _lastJobs = _jobResponses.removeAt(0);
    }

    return AcquisitionJobPage(items: _lastJobs, total: _lastJobs.length, limit: limit, offset: offset);
  }

  @override
  Future<void> removeJob(String jobId) async {}

  @override
  Future<AcquisitionJob> retryJobImport(String jobId) async {
    if (retryError case final error?) {
      throw error;
    }

    retriedJobIds.add(jobId);

    return _job(status: AcquisitionJobStatus.importing);
  }

  @override
  Future<List<TorrentRelease>> search(String query, {List<String>? endpointIds}) async => const [];

  @override
  Future<AcquisitionJob> selectJobFile(String jobId, int fileIndex) async {
    if (selectFileError case final error?) {
      throw error;
    }

    selectedFile = (jobId, fileIndex);

    return _job(status: AcquisitionJobStatus.importing);
  }

  @override
  Future<BatchSubmissionResponse> submitReleaseBatch({
    required String endpointId,
    required List<TorrentRelease> releases,
  }) async {
    return const BatchSubmissionResponse(items: []);
  }
}

AcquisitionJob _job({
  required AcquisitionJobStatus status,
  String? selectedFilePath,
  String? error = 'technical backend failure',
  DateTime? submittedAt,
}) {
  return AcquisitionJob(
    id: 'job-1',
    endpointId: 'endpoint-secret',
    ruleId: 'rule-secret',
    bookId: null,
    title: 'Example Book',
    status: status,
    rawStatus: status == AcquisitionJobStatus.unknown ? 'mystery_state' : status.apiValue,
    clientReference: 'client-reference-secret',
    clientHash: 'hash-secret',
    clientState: 'technical-client-state',
    progressBasisPoints: 4200,
    downloadedBytes: 1024 * 1024,
    totalBytes: 4 * 1024 * 1024,
    downloadSpeedBytesPerSecond: 2 * 1024 * 1024,
    etaSeconds: 180,
    selectedFilePath: selectedFilePath,
    retryCount: 1,
    error: error,
    nextPollAt: null,
    createdAt: null,
    updatedAt: null,
    submittedAt: submittedAt,
    startedAt: null,
    completedAt: status == AcquisitionJobStatus.completed ? DateTime(2026) : null,
    cancelledAt: null,
  );
}
