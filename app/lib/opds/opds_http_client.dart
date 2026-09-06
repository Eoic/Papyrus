import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:papyrus/opds/opds_models.dart';

class OpdsException implements Exception {
  const OpdsException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OpdsCancelled extends OpdsException {
  const OpdsCancelled() : super('Download cancelled.');
}

class OpdsCancellation {
  bool _cancelled = false;
  final Set<void Function()> _listeners = {};
  bool get isCancelled => _cancelled;
  void check() {
    if (_cancelled) throw const OpdsCancelled();
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners.toList()) {
      listener();
    }
    _listeners.clear();
  }

  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function() listener) => _listeners.remove(listener);
}

class OpdsResponse {
  const OpdsResponse({required this.uri, required this.bytes, required this.headers});
  final Uri uri;
  final Uint8List bytes;
  final Map<String, String> headers;
  String get text => utf8.decode(bytes);
}

/// Uses a fresh HTTP client for every resource without Papyrus bearer tokens.
class OpdsHttpClient {
  OpdsHttpClient({http.Client Function()? clientFactory}) : _clientFactory = clientFactory ?? http.Client.new;
  final http.Client Function() _clientFactory;

  static Uri validateUri(Uri uri) {
    if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const OpdsException('Enter an HTTP or HTTPS URL without embedded credentials.');
    }
    return uri;
  }

  Future<OpdsResponse> get(
    OpdsCatalog catalog,
    Uri uri, {
    OpdsCredentials? credentials,
    OpdsCancellation? cancellation,
    void Function(int received, int? total)? onProgress,
    int maxBytes = 8 * 1024 * 1024,
  }) async {
    validateUri(catalog.uri);
    validateUri(uri);
    cancellation?.check();
    final client = _clientFactory();
    cancellation?.addListener(client.close);
    try {
      var current = uri;
      for (var redirects = 0; redirects <= 5; redirects++) {
        cancellation?.check();
        final request = http.Request('GET', validateUri(current))..followRedirects = kIsWeb;
        if (current.origin == catalog.uri.origin && credentials != null) {
          request.headers['authorization'] =
              'Basic ${base64Encode(utf8.encode('${credentials.username}:${credentials.password}'))}';
        }
        final response = await client.send(request).timeout(const Duration(seconds: 30));
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          final location = response.headers['location'];
          await response.stream.drain<void>().timeout(const Duration(seconds: 30));
          if (location == null) throw const OpdsException('The catalog returned an invalid redirect.');
          current = current.resolve(location);
          continue;
        }
        if (response.statusCode == 401) {
          throw const OpdsException('Check the catalog username and password, then retry with updated credentials.');
        }
        if (response.statusCode == 403) {
          throw const OpdsException('This catalog denied access. Check your account permissions.');
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw OpdsException('The catalog returned HTTP ${response.statusCode}. Please retry later.');
        }
        final total = response.contentLength;
        if (total != null && total > maxBytes) throw const OpdsException('This resource is too large to load.');
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
          cancellation?.check();
          if (bytes.length + chunk.length > maxBytes) throw const OpdsException('This resource is too large to load.');
          bytes.add(chunk);
          onProgress?.call(bytes.length, total);
        }
        cancellation?.check();
        final finalUri = response is http.BaseResponseWithUrl ? (response as http.BaseResponseWithUrl).url : current;
        return OpdsResponse(uri: validateUri(finalUri), bytes: bytes.takeBytes(), headers: response.headers);
      }
      throw const OpdsException('The catalog redirected too many times. Check its URL.');
    } on OpdsException {
      rethrow;
    } catch (_) {
      cancellation?.check();
      throw OpdsException(
        kIsWeb
            ? 'Could not connect. Check the URL and connection. Browser security or catalog CORS settings may prevent access.'
            : 'Could not connect. Check the catalog URL and your connection, then retry.',
      );
    } finally {
      cancellation?.removeListener(client.close);
      client.close();
    }
  }
}
