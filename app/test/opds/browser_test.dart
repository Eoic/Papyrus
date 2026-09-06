import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papyrus/opds/opds_browser.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';

void main() {
  final catalog = OpdsCatalog(id: 'c', name: 'Books', uri: Uri.parse('https://books.test/feed'));
  test('late feed results cannot replace the current navigation', () async {
    final oldResponse = Completer<http.Response>();
    final browser = OpdsBrowser(
      httpClient: OpdsHttpClient(
        clientFactory: () => MockClient((request) async {
          if (request.url.path == '/old') return oldResponse.future;
          return http.Response('{"metadata":{"title":"New"},"navigation":[]}', 200);
        }),
      ),
    );
    final old = browser.load(catalog, Uri.parse('https://books.test/old'));
    await Future<void>.delayed(Duration.zero);
    await browser.load(catalog, Uri.parse('https://books.test/new'));
    oldResponse.complete(http.Response('{"metadata":{"title":"Old"},"navigation":[]}', 200));
    await old;
    expect(browser.feed?.title, 'New');
    browser.dispose();
  });

  test('resolves root search while browsing a subsection', () async {
    final browser = OpdsBrowser(
      httpClient: OpdsHttpClient(
        clientFactory: () => MockClient((request) async {
          return http.Response(
            request.url.path == '/feed'
                ? '{"metadata":{"title":"Root"},"links":[{"rel":"search","href":"search{?query}","templated":true,"type":"application/opds+json"}],"navigation":[]}'
                : '{"metadata":{"title":"Section"},"navigation":[]}',
            200,
          );
        }),
      ),
    );
    await browser.load(catalog, Uri.parse('https://books.test/section'));
    final uri = await browser.search('a & b');
    expect(uri.queryParameters['query'], 'a & b');
    browser.dispose();
  });
}
