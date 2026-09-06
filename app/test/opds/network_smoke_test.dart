import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/opds/opds_parser.dart';
import 'package:papyrus/opds/opds_search.dart';

const _smokeUrl = String.fromEnvironment('OPDS_SMOKE_URL');
const _credentials = OpdsCredentials(username: 'reader', password: 'secret');

void main() {
  group('local OPDS network smoke', () {
    final base = Uri.parse(_smokeUrl);
    final gateway = OpdsHttpClient();

    Future<OpdsFeed> fetch(OpdsCatalog catalog, Uri uri, {OpdsCredentials? credentials}) async {
      final response = await gateway.get(catalog, uri, credentials: credentials);
      return OpdsParser.parse(response.text, response.uri, contentType: response.headers['content-type']);
    }

    for (final version in ['v1', 'v2']) {
      for (final protected in [false, true]) {
        final access = protected ? 'protected' : 'public';
        final extension = version == 'v1' ? 'xml' : 'json';
        test('$access $version navigation, details, search, pagination and EPUB download', () async {
          final catalog = OpdsCatalog(
            id: '$access-$version',
            name: 'Fixture',
            uri: base.resolve('/$access/$version/catalog.$extension'),
          );
          final credentials = protected ? _credentials : null;
          final root = await fetch(catalog, catalog.uri, credentials: credentials);
          expect(root.title, 'Fixture catalog');
          final booksUri = root.navigation.single.uri;
          expect(booksUri.path, '/$access/$version/books/feed.$extension');
          final books = await fetch(catalog, booksUri, credentials: credentials);
          final publication = books.publications.single;
          expect(publication.title, 'Network fixture book');
          expect(publication.authors, ['Fixture Author']);

          final detail = await fetch(catalog, publication.detailLink!.uri, credentials: credentials);
          expect(detail.publications.single.description, 'Complete publication details.');
          final next = await fetch(catalog, books.nextLink!.uri, credentials: credentials);
          expect(next.title, 'Second page');
          expect(next.previousLink!.uri, booksUri);

          var search = root.searchLink!;
          if (version == 'v1') {
            final description = await gateway.get(catalog, search.uri, credentials: credentials);
            search = OpdsSearch.fromOpenSearch(description.text, description.uri);
          }
          const query = 'tea & coffee ž';
          final results = await fetch(
            catalog,
            Uri.parse(OpdsSearch.expand(search.template, query)),
            credentials: credentials,
          );
          expect(results.title, 'Search: $query');

          final download = publication.links.singleWhere((link) => link.supportedExtension == 'epub');
          expect(download.uri.path, '/$access/$version/book.epub');
          final received = <int>[];
          final response = await gateway.get(
            catalog,
            download.uri,
            credentials: credentials,
            onProgress: (bytes, total) => received.add(bytes),
          );
          expect(received.last, response.bytes.length);
          final archive = ZipDecoder().decodeBytes(response.bytes, verify: true);
          expect(utf8.decode(archive.findFile('mimetype')!.content), 'application/epub+zip');
          expect(archive.findFile('META-INF/container.xml'), isNotNull);
          expect(utf8.decode(archive.findFile('EPUB/package.opf')!.content), contains('Network fixture book'));
        });
      }
    }

    test('protected catalog rejects missing and incorrect credentials', () async {
      final catalog = OpdsCatalog(id: 'auth', name: 'Protected', uri: base.resolve('/protected/v1/catalog.xml'));
      for (final credentials in [null, const OpdsCredentials(username: 'reader', password: 'wrong')]) {
        await expectLater(
          gateway.get(catalog, catalog.uri, credentials: credentials),
          throwsA(isA<OpdsException>().having((error) => error.message, 'message', contains('credentials'))),
        );
      }
    });

    for (final version in ['v1', 'v2']) {
      test('$version redirects retain the final URL for relative publication links', () async {
        final extension = version == 'v1' ? 'xml' : 'json';
        final catalog = OpdsCatalog(
          id: 'redirect-$version',
          name: 'Redirect',
          uri: base.resolve('/protected/redirect-$version'),
        );
        final response = await gateway.get(catalog, catalog.uri, credentials: _credentials);
        expect(response.uri.path, '/protected/$version/books/feed.$extension');
        final feed = OpdsParser.parse(response.text, response.uri);
        final download = feed.publications.single.links.singleWhere((link) => link.supportedExtension == 'epub');
        expect(download.uri.path, '/protected/$version/book.epub');
        expect((await gateway.get(catalog, download.uri, credentials: _credentials)).bytes.take(2), [0x50, 0x4b]);
      });
    }

    test('cross-origin redirect never forwards Basic credentials', () async {
      final catalog = OpdsCatalog(
        id: 'redirect-auth',
        name: 'Redirect auth',
        uri: base.resolve('/protected/cross-origin'),
      );
      final response = await gateway.get(catalog, catalog.uri, credentials: _credentials);
      expect(response.uri.host, 'localhost');
      expect(response.uri.origin, isNot(catalog.uri.origin));
      expect(jsonDecode(response.text), {'authorizationReceived': false});
    });
  }, skip: _smokeUrl.isEmpty ? 'Set OPDS_SMOKE_URL to the running local fixture server.' : false);
}
