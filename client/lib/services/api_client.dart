import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// HTTP client for community API calls.
/// Attaches Firebase Auth JWT to all requests.
/// Community features are online-only — no offline queue.
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Build a URI from path and optional query parameters.
  Uri buildUri(String path, {Map<String, String>? queryParams}) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: path,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  /// Get the current Firebase Auth token.
  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Build headers with auth token.
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Perform a GET request.
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = buildUri(path, queryParams: queryParams);
    final headers = await _headers();
    final response = await _httpClient.get(uri, headers: headers);
    return ApiResponse.fromHttpResponse(response);
  }

  /// Perform a POST request.
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final uri = buildUri(path);
    final headers = await _headers();
    final response = await _httpClient.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return ApiResponse.fromHttpResponse(response);
  }

  /// Perform a PATCH request.
  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = buildUri(path);
    final headers = await _headers();
    final response = await _httpClient.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return ApiResponse.fromHttpResponse(response);
  }

  /// Perform a DELETE request.
  Future<ApiResponse> delete(String path) async {
    final uri = buildUri(path);
    final headers = await _headers();
    final response = await _httpClient.delete(uri, headers: headers);
    return ApiResponse.fromHttpResponse(response);
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Wrapper around HTTP response with convenience methods.
class ApiResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  const ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  factory ApiResponse.fromHttpResponse(http.Response response) {
    return ApiResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic>? get json =>
      body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : null;

  List<dynamic>? get jsonList =>
      body.isNotEmpty ? jsonDecode(body) as List<dynamic> : null;
}
