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

  test('submits a selected release to a torrent client', () async {
    late Map<String, dynamic> requestBody;
    final client = AcquisitionApiClient(
      config: PapyrusApiConfig(serverBaseUri: Uri.parse('https://api.test')),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/acquisition/submissions');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'job_id': 'job-1',
            'endpoint_id': 'client-1',
            'rule_id': null,
            'title': 'Example',
            'download_url': 'magnet:?xt=urn:btih:example',
            'status': 'failed',
            'client_reference': null,
            'error': 'Transmission rejected the release',
            'created_at': null,
          }),
          201,
        );
      }),
    );

    final job = await client.submitRelease(
      accessToken: 'access-token',
      endpointId: 'client-1',
      release: const TorrentRelease(
        title: 'Example',
        downloadUrl: 'magnet:?xt=urn:btih:example',
        protocol: 'torrent',
        indexer: 'Prowlarr',
      ),
    );

    expect(requestBody['endpoint_id'], 'client-1');
    expect(requestBody['download_url'], 'magnet:?xt=urn:btih:example');
    expect(job.isSubmitted, isFalse);
    expect(job.error, 'Transmission rejected the release');
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
