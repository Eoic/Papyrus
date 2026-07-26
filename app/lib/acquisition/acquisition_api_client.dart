import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';

class AcquisitionApiClient {
  final PapyrusApiConfig config;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  AcquisitionApiClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null;

  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<AcquisitionCapabilities> capabilities(String accessToken) async {
    final response = await _httpClient.get(
      config.endpoint('/acquisition/capabilities'),
      headers: _headers(accessToken),
    );
    return AcquisitionCapabilities.fromJson(_decodeObject(response));
  }

  Future<List<AcquisitionEndpoint>> listEndpoints(String accessToken) async {
    final response = await _httpClient.get(config.endpoint('/acquisition/endpoints'), headers: _headers(accessToken));
    return _decodeList(response).map(AcquisitionEndpoint.fromJson).toList();
  }

  Future<AcquisitionEndpoint> createEndpoint({
    required String accessToken,
    required String name,
    required AcquisitionEndpointKind kind,
    required Uri baseUrl,
    String? apiKey,
    String? username,
    String? password,
  }) async {
    final response = await _httpClient.post(
      config.endpoint('/acquisition/endpoints'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'name': name,
        'kind': kind.apiValue,
        'base_url': baseUrl.toString(),
        'api_key': ?apiKey,
        'username': ?username,
        'password': ?password,
      }),
    );
    return AcquisitionEndpoint.fromJson(_decodeObject(response));
  }

  Future<AcquisitionEndpoint> updateEndpoint({
    required String accessToken,
    required String endpointId,
    String? name,
    Uri? baseUrl,
    String? apiKey,
    String? username,
    String? password,
    bool? enabled,
  }) async {
    final response = await _httpClient.patch(
      config.endpoint('/acquisition/endpoints/$endpointId'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'name': ?name,
        'base_url': ?baseUrl?.toString(),
        'api_key': ?apiKey,
        'username': ?username,
        'password': ?password,
        'enabled': ?enabled,
      }),
    );
    return AcquisitionEndpoint.fromJson(_decodeObject(response));
  }

  Future<void> testEndpoint({
    required String accessToken,
    String? endpointId,
    AcquisitionEndpointKind? kind,
    Uri? baseUrl,
    String? apiKey,
    String? username,
    String? password,
  }) async {
    final response = await _httpClient.post(
      config.endpoint('/acquisition/endpoints/test'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'endpoint_id': ?endpointId,
        'kind': ?kind?.apiValue,
        'base_url': ?baseUrl?.toString(),
        'api_key': ?apiKey,
        'username': ?username,
        'password': ?password,
      }),
    );
    final result = _decodeObject(response);
    if (result['ok'] != true) {
      throw const AuthApiException(statusCode: 502, message: 'Connection test returned an invalid response');
    }
  }

  Future<void> deleteEndpoint({required String accessToken, required String endpointId}) async {
    final response = await _httpClient.delete(
      config.endpoint('/acquisition/endpoints/$endpointId'),
      headers: _headers(accessToken),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _decodeObject(response);
  }

  Future<List<TorrentRelease>> search({
    required String accessToken,
    required String query,
    List<String>? endpointIds,
  }) async {
    final response = await _httpClient.post(
      config.endpoint('/acquisition/search'),
      headers: _headers(accessToken),
      body: jsonEncode({'query': query, 'endpoint_ids': ?endpointIds}),
    );
    return _decodeList(response).map(TorrentRelease.fromJson).toList();
  }

  Future<AcquisitionJob> submitRelease({
    required String accessToken,
    required String endpointId,
    required TorrentRelease release,
    String? category,
    String? savePath,
  }) async {
    final response = await _httpClient.post(
      config.endpoint('/acquisition/submissions'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'endpoint_id': endpointId,
        'title': release.title,
        'download_url': release.downloadUrl,
        'category': ?category,
        'save_path': ?savePath,
      }),
    );
    return AcquisitionJob.fromJson(_decodeObject(response));
  }

  Future<AcquisitionJob> runArrCommand({
    required String accessToken,
    required String endpointId,
    required String command,
    required List<int> ids,
  }) async {
    final response = await _httpClient.post(
      config.endpoint('/acquisition/arr/$endpointId/commands'),
      headers: _headers(accessToken),
      body: jsonEncode({'command': command, 'ids': ids}),
    );
    return AcquisitionJob.fromJson(_decodeObject(response));
  }

  Map<String, String> _headers(String accessToken) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final error = decoded['error'];
    final detail = decoded['detail'];
    throw AuthApiException(
      statusCode: response.statusCode,
      message: error is Map<String, dynamic>
          ? error['message'] as String? ?? 'Acquisition request failed'
          : detail is String
          ? detail
          : 'Acquisition request failed',
    );
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decodeObject(response);
    }
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
