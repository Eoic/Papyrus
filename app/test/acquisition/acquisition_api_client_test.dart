import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papyrus/acquisition/acquisition_api_client.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';

void main() {
  test('uses acquisition capabilities endpoint with bearer auth', () async {
    final seenPaths = <String>[];
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        seenPaths.add(request.url.path);
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'enabled': true,
            'endpoint_kinds': ['qbittorrent', 'prowlarr', 'readarr'],
            'indexer_kinds': ['prowlarr'],
            'download_client_kinds': ['qbittorrent'],
            'arr_kinds': ['readarr'],
            'arr_commands': {
              'readarr': ['BookSearch'],
            },
          }),
          200,
        );
      }),
    );

    final capabilities = await client.capabilities('access-token');

    expect(seenPaths, ['/v1/acquisition/capabilities']);
    expect(capabilities.downloadClientKinds, [AcquisitionEndpointKind.qbittorrent]);
    expect(capabilities.arrCommands[AcquisitionEndpointKind.readarr], ['BookSearch']);
  });

  test('sends the qBittorrent download root when creating and updating endpoints', () async {
    final requestBodies = <Map<String, dynamic>>[];
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'endpoint_id': 'client-1',
            'name': 'qBittorrent',
            'kind': 'qbittorrent',
            'base_url': 'http://qbittorrent.local:8082',
            'download_root': '/downloads',
            'enabled': true,
          }),
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );

    await client.createEndpoint(
      accessToken: 'access-token',
      name: 'qBittorrent',
      kind: AcquisitionEndpointKind.qbittorrent,
      baseUrl: Uri.parse('http://qbittorrent.local:8082'),
      downloadRoot: '/downloads',
    );
    await client.updateEndpoint(accessToken: 'access-token', endpointId: 'client-1', downloadRoot: '/new-downloads');

    expect(requestBodies[0]['download_root'], '/downloads');
    expect(requestBodies[1], {'download_root': '/new-downloads'});
  });

  test('submits release tokens as a partial-success batch', () async {
    late Map<String, dynamic> requestBody;
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/acquisition/submissions/batch');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'items': [
              {'index': 0, 'job': _jobJson(status: 'submitted'), 'error': null},
              {'index': 1, 'job': null, 'error': 'Release token expired'},
            ],
          }),
          201,
        );
      }),
    );

    final result = await client.submitReleaseBatch(
      accessToken: 'access-token',
      endpointId: 'client-1',
      releases: const [
        TorrentRelease(title: 'Example', releaseToken: 'token-1', protocol: 'torrent', indexer: 'Prowlarr'),
        TorrentRelease(title: 'Other', releaseToken: 'token-2', protocol: 'torrent', indexer: 'Prowlarr'),
      ],
    );

    expect(requestBody['endpoint_id'], 'client-1');
    expect(requestBody['release_tokens'], ['token-1', 'token-2']);
    expect(result.items.first.job?.status, AcquisitionJobStatus.submitted);
    expect(result.items.last.error, 'Release token expired');
  });

  test('uses paginated job lifecycle request shapes', () async {
    final requests = <http.Request>[];
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        requests.add(request);

        if (request.method == 'GET' && request.url.path.endsWith('/files')) {
          return http.Response(
            jsonEncode([
              {
                'index': 0,
                'name': 'Example.epub',
                'size_bytes': 4096,
                'progress_basis_points': 10000,
                'priority': 1,
                'supported': true,
              },
            ]),
            200,
          );
        }
        if (request.method == 'GET' && request.url.path == '/v1/acquisition/jobs') {
          return http.Response(
            jsonEncode({
              'items': [_jobJson(status: 'downloading')],
              'total': 1,
              'limit': 25,
              'offset': 5,
            }),
            200,
          );
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }

        return http.Response(jsonEncode(_jobJson(status: 'downloading')), 200);
      }),
    );

    final page = await client.listJobs(accessToken: 'access-token', limit: 25, offset: 5);
    await client.getJob(accessToken: 'access-token', jobId: 'job-1');
    final files = await client.listJobFiles(accessToken: 'access-token', jobId: 'job-1');
    await client.selectJobFile(accessToken: 'access-token', jobId: 'job-1', fileIndex: 2);
    await client.cancelJob(accessToken: 'access-token', jobId: 'job-1');
    await client.retryJobImport(accessToken: 'access-token', jobId: 'job-1');
    await client.removeJob(accessToken: 'access-token', jobId: 'job-1');

    expect(page.total, 1);
    expect(files.single.name, 'Example.epub');
    expect(requests[0].url.queryParameters, {'limit': '25', 'offset': '5'});
    expect(requests[3].method, 'POST');
    expect(jsonDecode(requests[3].body), {'file_index': 2});
    expect(requests[4].url.path, '/v1/acquisition/jobs/job-1/cancel');
    expect(requests[5].url.path, '/v1/acquisition/jobs/job-1/retry-import');
    expect(requests[6].method, 'DELETE');
  });

  test('tests an unsaved endpoint without sending irrelevant credentials', () async {
    late Map<String, dynamic> requestBody;
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/acquisition/endpoints/test');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    await client.testEndpoint(
      accessToken: 'access-token',
      kind: AcquisitionEndpointKind.prowlarr,
      baseUrl: Uri.parse('http://prowlarr.local:9696'),
      apiKey: 'secret',
    );

    expect(requestBody, {'kind': 'prowlarr', 'base_url': 'http://prowlarr.local:9696', 'api_key': 'secret'});
  });

  test('tests an edited endpoint with only supplied overrides', () async {
    late Map<String, dynamic> requestBody;
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    await client.testEndpoint(
      accessToken: 'access-token',
      endpointId: 'endpoint-1',
      baseUrl: Uri.parse('http://edited.local:9696'),
    );

    expect(requestBody, {'endpoint_id': 'endpoint-1', 'base_url': 'http://edited.local:9696'});
  });

  test('surfaces FastAPI detail errors from connection tests', () async {
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient(
        (_) async => http.Response(jsonEncode({'detail': 'Prowlarr connection test failed'}), 502),
      ),
    );

    await expectLater(
      client.testEndpoint(
        accessToken: 'access-token',
        kind: AcquisitionEndpointKind.prowlarr,
        baseUrl: Uri.parse('http://prowlarr.local:9696'),
      ),
      throwsA(
        isA<Exception>().having((error) => error.toString(), 'message', contains('Prowlarr connection test failed')),
      ),
    );
  });
}

Map<String, dynamic> _jobJson({required String status}) => {
  'job_id': 'job-1',
  'endpoint_id': 'client-1',
  'rule_id': null,
  'book_id': 'book-1',
  'title': 'Example',
  'status': status,
  'client_reference': null,
  'client_hash': 'hash-1',
  'client_state': 'downloading',
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
  'submitted_at': null,
  'started_at': null,
  'completed_at': null,
  'cancelled_at': null,
};
