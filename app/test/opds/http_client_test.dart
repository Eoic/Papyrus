import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';

void main() {
  final catalog = OpdsCatalog(id: 'one', name: 'Books', uri: Uri.parse('https://books.test/opds'));
  const credentials = OpdsCredentials(username: 'reader', password: 'secret');

  test('sends Basic auth only to the catalog origin including redirects', () async {
    final seen = <http.Request>[];
    final gateway = OpdsHttpClient(
      clientFactory: () => MockClient((request) async {
        seen.add(request);
        if (request.url.host == 'books.test') {
          return http.Response('', 302, headers: {'location': 'https://cdn.test/book.epub'});
        }
        return http.Response('book', 200);
      }),
    );
    final response = await gateway.get(catalog, catalog.uri, credentials: credentials);
    expect(seen.first.headers['authorization'], 'Basic ${base64Encode(utf8.encode('reader:secret'))}');
    expect(seen.last.headers.containsKey('authorization'), isFalse);
    expect(response.uri, Uri.parse('https://cdn.test/book.epub'));
    expect(utf8.decode(response.bytes), 'book');
  });

  test('reports authentication errors without exposing credentials', () async {
    final gateway = OpdsHttpClient(clientFactory: () => MockClient((_) async => http.Response('private', 401)));
    await expectLater(
      gateway.get(catalog, catalog.uri, credentials: credentials),
      throwsA(isA<OpdsException>().having((e) => e.message, 'message', contains('credentials'))),
    );
  });

  test('rejects unsafe and credential-bearing resource URLs', () async {
    final gateway = OpdsHttpClient();
    for (final url in ['file:///etc/passwd', 'https://reader:secret@books.test/opds']) {
      await expectLater(gateway.get(catalog, Uri.parse(url)), throwsA(isA<OpdsException>()));
    }
  });

  test('enforces response size and reports progress', () async {
    final gateway = OpdsHttpClient(clientFactory: () => MockClient((_) async => http.Response('12345', 200)));
    await expectLater(gateway.get(catalog, catalog.uri, maxBytes: 4), throwsA(isA<OpdsException>()));
    final progress = <int>[];
    await gateway.get(catalog, catalog.uri, onProgress: (received, total) => progress.add(received));
    expect(progress.last, 5);
  });

  test('cancelled operations cannot start requests', () async {
    final cancellation = OpdsCancellation()..cancel();
    await expectLater(
      OpdsHttpClient().get(catalog, catalog.uri, cancellation: cancellation),
      throwsA(isA<OpdsCancelled>()),
    );
  });
}
