import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';

void main() {
  test('parses a token-only torrent release without exposing its URL', () {
    final release = TorrentRelease.fromJson({
      'title': 'Example book',
      'release_token': 'encrypted-release-token',
      'protocol': 'torrent',
      'indexer': 'Prowlarr',
      'seeders': 12,
      'size_bytes': 2048,
      'publish_date': '2026-07-25T12:00:00Z',
      'format_hints': ['epub', 'pdf'],
    });

    expect(release.releaseToken, 'encrypted-release-token');
    expect(release.seeders, 12);
    expect(release.sizeBytes, 2048);
    expect(release.publishDate, DateTime.utc(2026, 7, 25, 12));
    expect(release.formatHints, ['epub', 'pdf']);
  });

  test('parses torrent-only capabilities', () {
    final capabilities = AcquisitionCapabilities.fromJson({
      'enabled': true,
      'managed_downloads_ready': true,
      'endpoint_kinds': ['qbittorrent', 'transmission', 'deluge', 'prowlarr', 'torznab', 'readarr'],
      'indexer_kinds': ['prowlarr', 'torznab'],
      'download_client_kinds': ['qbittorrent', 'transmission', 'deluge'],
      'arr_kinds': ['readarr'],
      'arr_commands': {
        'readarr': ['AuthorSearch', 'BookSearch'],
      },
    });

    expect(capabilities.indexerKinds, [AcquisitionEndpointKind.prowlarr, AcquisitionEndpointKind.torznab]);
    expect(capabilities.downloadClientKinds, [
      AcquisitionEndpointKind.qbittorrent,
      AcquisitionEndpointKind.transmission,
      AcquisitionEndpointKind.deluge,
    ]);
    expect(capabilities.arrCommands[AcquisitionEndpointKind.readarr], ['AuthorSearch', 'BookSearch']);
    expect(capabilities.enabled, isTrue);
    expect(capabilities.managedDownloadsReady, isTrue);
  });

  test('parses every acquisition job state and nullable progress fields', () {
    const states = [
      'queued',
      'submitted',
      'downloading',
      'needs_file_selection',
      'importing',
      'completed',
      'failed',
      'cancelled',
    ];

    final jobs = states
        .map(
          (status) => AcquisitionJob.fromJson({
            'job_id': 'job-$status',
            'endpoint_id': 'endpoint-1',
            'rule_id': null,
            'book_id': 'book-1',
            'title': 'Release',
            'status': status,
            'client_reference': null,
            'client_hash': null,
            'client_state': null,
            'progress_basis_points': null,
            'downloaded_bytes': null,
            'total_bytes': null,
            'download_speed_bytes_per_second': null,
            'eta_seconds': null,
            'selected_file_path': null,
            'retry_count': 0,
            'error': null,
            'next_poll_at': null,
            'created_at': null,
            'updated_at': null,
            'submitted_at': null,
            'started_at': null,
            'completed_at': null,
            'cancelled_at': null,
          }),
        )
        .toList();

    expect(jobs.map((job) => job.status.apiValue), states);
    expect(jobs.first.progress, isNull);
    expect(jobs[2].isActive, isTrue);
    expect(jobs[3].requiresAttention, isTrue);
    expect(jobs.last.isTerminal, isTrue);
  });

  test('maps an unknown future job state without failing the jobs response', () {
    final job = AcquisitionJob.fromJson(_jobJson(status: 'verifying'));

    expect(job.status, AcquisitionJobStatus.unknown);
    expect(job.rawStatus, 'verifying');
    expect(job.requiresAttention, isTrue);
  });

  test('allows import retry only after qBittorrent submission succeeded', () {
    final rejected = AcquisitionJob.fromJson(_jobJson(status: 'failed'));
    final submitted = AcquisitionJob.fromJson(_jobJson(status: 'failed', submittedAt: '2026-07-25T12:00:00Z'));

    expect(rejected.canRetryImport, isFalse);
    expect(submitted.canRetryImport, isTrue);
  });

  test('parses paginated jobs, partial batch results, and file candidates', () {
    final page = AcquisitionJobPage.fromJson({
      'items': [_jobJson(status: 'downloading')],
      'total': 1,
      'limit': 50,
      'offset': 0,
    });
    final batch = BatchSubmissionResponse.fromJson({
      'items': [
        {'index': 0, 'job': _jobJson(status: 'submitted'), 'error': null},
        {'index': 1, 'job': null, 'error': 'Release token expired'},
      ],
    });
    final candidate = AcquisitionFileCandidate.fromJson({
      'index': 2,
      'name': 'Example.epub',
      'size_bytes': 4096,
      'progress_basis_points': 10000,
      'priority': 1,
      'supported': true,
    });

    expect(page.items.single.status, AcquisitionJobStatus.downloading);
    expect(batch.items.first.job?.status, AcquisitionJobStatus.submitted);
    expect(batch.items.last.error, 'Release token expired');
    expect(candidate.name, 'Example.epub');
    expect(candidate.progress, 1);
  });
}

Map<String, dynamic> _jobJson({required String status, String? submittedAt}) => {
  'job_id': 'job-1',
  'endpoint_id': 'endpoint-1',
  'rule_id': null,
  'book_id': 'book-1',
  'title': 'Release',
  'status': status,
  'client_reference': null,
  'client_hash': null,
  'client_state': null,
  'progress_basis_points': 5000,
  'downloaded_bytes': 512,
  'total_bytes': 1024,
  'download_speed_bytes_per_second': 128,
  'eta_seconds': 4,
  'selected_file_path': null,
  'retry_count': 0,
  'error': null,
  'next_poll_at': null,
  'created_at': null,
  'updated_at': null,
  'submitted_at': submittedAt,
  'started_at': null,
  'completed_at': null,
  'cancelled_at': null,
};
