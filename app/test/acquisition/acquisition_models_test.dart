import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';

void main() {
  test('recognizes a magnet release returned by an indexer', () {
    final release = TorrentRelease.fromJson({
      'title': 'Example book',
      'download_url': 'magnet:?xt=urn:btih:example',
      'protocol': 'torrent',
      'indexer': 'Prowlarr',
      'seeders': 12,
    });

    expect(release.isMagnet, isTrue);
    expect(release.seeders, 12);
  });

  test('parses torrent-only capabilities', () {
    final capabilities = AcquisitionCapabilities.fromJson({
      'enabled': true,
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
  });

  test('parses disabled capabilities and failed jobs', () {
    final capabilities = AcquisitionCapabilities.fromJson({'enabled': false});
    final job = AcquisitionJob.fromJson({
      'job_id': 'job-1',
      'endpoint_id': null,
      'rule_id': null,
      'title': 'Release',
      'download_url': 'magnet:?xt=urn:btih:test',
      'status': 'failed',
      'client_reference': null,
      'error': 'Transmission rejected the release',
      'created_at': '2026-07-17T12:00:00Z',
    });

    expect(capabilities.enabled, isFalse);
    expect(capabilities.endpointKinds, isEmpty);
    expect(job.endpointId, isNull);
    expect(job.isSubmitted, isFalse);
    expect(job.error, 'Transmission rejected the release');
  });
}
