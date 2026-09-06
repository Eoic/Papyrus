import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/opds/opds_parser.dart';
import 'package:papyrus/opds/opds_search.dart';

void main() {
  final uri = Uri.parse('https://books.example/catalog/index');
  const acquisition = 'http://opds-spec.org/acquisition';

  test('catalog serialization excludes embedded credentials', () {
    final catalog = OpdsCatalog(id: 'one', name: 'Books', uri: Uri.parse('https://user:secret@books.example/catalog'));
    expect(catalog.uri.userInfo, isEmpty);
    expect(jsonEncode(catalog.toJson()), isNot(contains('secret')));
    final restored = OpdsCatalog.fromJson(catalog.toJson());
    expect(restored.id, 'one');
    expect(restored.name, 'Books');
    expect(restored.uri, catalog.uri);
  });

  test('sniffs XML with generic MIME and resolves nested xml:base', () {
    final feed = OpdsParser.parse(
      '''
      <a:feed xmlns:a="http://www.w3.org/2005/Atom"
        xmlns:other="urn:not-atom" xml:base="../root/">
        <other:title>Wrong title</other:title><a:title>Catalog</a:title>
        <a:link rel="next" href="?page=2"/>
        <a:entry xml:base="sections/">
          <a:title>Fiction</a:title>
          <a:link rel="subsection" type="application/atom+xml"
            xml:base="../genres/" href="fiction"/>
        </a:entry>
      </a:feed>''',
      uri,
      contentType: 'application/octet-stream',
    );
    expect(feed.title, 'Catalog');
    expect(feed.navigation.single.title, 'Fiction');
    expect(feed.navigation.single.uri.toString(), 'https://books.example/root/genres/fiction');
    expect(feed.nextLink!.uri.toString(), 'https://books.example/root/?page=2');
  });

  test('parses Atom publication details, metadata and indirect acquisitions', () {
    final publication = OpdsParser.parse('''
      <entry xmlns="http://www.w3.org/2005/Atom"
        xmlns:dc="http://purl.org/dc/terms/"
        xmlns:opds="http://opds-spec.org/2010/catalog">
        <id>urn:book:1</id><title>Book</title>
        <author><name>Alice</name></author><author><name>Bob</name></author>
        <content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml"><p>A story.</p></div></content>
        <dc:publisher>Press</dc:publisher><dc:language>lt</dc:language>
        <dc:identifier>urn:uuid:other</dc:identifier>
        <dc:identifier>urn:isbn:9781234567890</dc:identifier>
        <link rel="alternate" type="application/atom+xml;type=entry;profile=opds-catalog" href="details/1"/>
        <link rel="http://opds-spec.org/image/thumbnail" type="image/jpeg" href="../cover.jpg"/>
        <link rel="$acquisition" type="application/epub+zip" href="1.epub"/>
        <link rel="$acquisition" type="application/vnd.adobe.adept+xml" href="1.acsm">
          <opds:indirectAcquisition type="application/epub+zip"/>
        </link>
      </entry>''', uri).publications.single;
    expect(publication.id, 'urn:book:1');
    expect(publication.authors, ['Alice', 'Bob']);
    expect(publication.description, 'A story.');
    expect(publication.publisher, 'Press');
    expect(publication.language, 'lt');
    expect(publication.isbn, '9781234567890');
    expect(publication.images.single.uri.toString(), 'https://books.example/cover.jpg');
    expect(publication.detailLink!.uri.path, '/catalog/details/1');
    expect(publication.links.where((link) => link.supportedExtension != null).length, 1);
    expect(publication.links.last.indirect, isTrue);
  });

  test('Atom facet groups and publication collections preserve grouping', () {
    final feed = OpdsParser.parse('''
      <feed xmlns="http://www.w3.org/2005/Atom"
        xmlns:o="http://opds-spec.org/2010/catalog">
        <title>Grouped</title>
        <link rel="http://opds-spec.org/facet" title="English" href="?lang=en" o:facetGroup="Language"/>
        <entry><id>1</id><title>First</title>
          <link rel="collection" title="Featured" href="featured"/>
          <link rel="$acquisition" href="1.pdf" type="application/pdf"/>
        </entry>
        <entry><id>2</id><title>Second</title>
          <link rel="collection" title="Featured" href="featured"/>
          <link rel="$acquisition" href="2.pdf" type="application/pdf"/>
        </entry>
      </feed>''', uri);
    expect(feed.facets.single.title, 'Language');
    expect(feed.facets.single.links.single.title, 'English');
    expect(feed.groups.single.title, 'Featured');
    expect(feed.groups.single.publications.map((book) => book.title), ['First', 'Second']);
    expect(feed.publications, isEmpty);
  });

  test('JSON feed supports groups, facets, rel arrays and metadata variants', () {
    final feed = OpdsParser.parse(
      jsonEncode({
        'metadata': {
          'title': {'en': 'Catalog', 'lt': 'Katalogas'},
        },
        'links': [
          {
            'rel': ['self', 'next'],
            'href': '?page=2',
          },
          {'rel': 'previous', 'href': '?page=0'},
          {'rel': 'search', 'href': 'search{?query,author}', 'templated': true},
        ],
        'navigation': [
          {'title': 'Genres', 'href': 'genres'},
        ],
        'groups': [
          {
            'metadata': {'title': 'Featured'},
            'links': [
              {'rel': 'self', 'href': 'featured'},
            ],
            'publications': [
              {
                'metadata': {
                  'identifier': 'urn:isbn:9781234567890',
                  'title': 'Book',
                  'author': [
                    'Alice',
                    {
                      'name': {'en': 'Bob'},
                    },
                  ],
                  'publisher': [
                    {'name': 'Press'},
                  ],
                  'language': ['en', 'lt'],
                  'description': '<p>A <b>story</b>.</p>',
                },
                'links': [
                  {'rel': acquisition, 'href': 'download', 'type': 'application/pdf'},
                ],
                'images': [
                  {'href': '/cover.jpg', 'type': 'image/jpeg'},
                ],
              },
            ],
          },
        ],
        'facets': [
          {
            'metadata': {'title': 'Language'},
            'links': [
              {'title': 'English', 'href': '?lang=en'},
            ],
          },
        ],
      }),
      uri,
      contentType: 'text/plain',
    );
    expect(feed.title, 'Catalog');
    expect(feed.nextLink!.uri.query, 'page=2');
    expect(feed.previousLink!.uri.query, 'page=0');
    expect(feed.navigation.single.uri.path, '/catalog/genres');
    expect(feed.searchLink!.template, 'https://books.example/catalog/search{?query,author}');
    final book = feed.groups.single.publications.single;
    expect(book.authors, ['Alice', 'Bob']);
    expect(book.publisher, 'Press');
    expect(book.language, 'en, lt');
    expect(book.isbn, '9781234567890');
    expect(book.description, 'A story.');
    expect(feed.facets.single.links.single.title, 'English');
  });

  test('JSON standalone publication and indirect acquisition are recognized', () {
    final feed = OpdsParser.parse(
      '''{
      "metadata":{"title":"A book","identifier":"id"},
      "links":[{"rel":"$acquisition", "href":"file.epub", "type":"application/epub+zip",
        "properties":{"indirectAcquisition":[{"type":"application/pdf"}]}}]
    }''',
      uri,
      contentType: 'application/opds-publication+json',
    );
    expect(feed.publications.single.title, 'A book');
    expect(feed.publications.single.links.single.indirect, isTrue);
    expect(feed.publications.single.links.single.supportedExtension, isNull);
  });

  test('does not invent a publication from an empty JSON feed', () {
    expect(OpdsParser.parse('{"metadata":{"title":"Empty"},"publications":[]}', uri).publications, isEmpty);
  });

  test('rejects HTML, wrong Atom namespaces, malformed and unrelated JSON', () {
    for (final body in [
      '<html><title>Login</title></html>',
      '<feed xmlns="urn:wrong"><title>Wrong</title></feed>',
      '<feed xmlns="http://www.w3.org/2005/Atom">',
      '{"error":"Forbidden"}',
      '[1,2]',
      '{broken',
      '',
    ]) {
      expect(() => OpdsParser.parse(body, uri), throwsFormatException, reason: body);
    }
  });

  test('models expose only supported direct downloadable acquisitions', () {
    OpdsLink link(String href, String? type, {String rel = acquisition, bool indirect = false}) =>
        OpdsLink(uri: uri.resolve(href), type: type, rels: [rel], indirect: indirect);
    expect(link('download', 'application/epub+zip').supportedExtension, 'epub');
    expect(link('FILE.CBZ?token=x', null).supportedExtension, 'cbz');
    expect(link('book.mobi', 'application/octet-stream').supportedExtension, 'mobi');
    expect(link('book.epub', 'text/html').supportedExtension, isNull);
    expect(link('book.epub', 'application/vnd.adobe.adept+xml').supportedExtension, isNull);
    expect(link('book.epub', 'application/epub+zip', rel: '$acquisition/buy').supportedExtension, isNull);
    expect(link('book.epub', 'application/epub+zip', rel: '$acquisition/borrow').supportedExtension, isNull);
    expect(link('book.epub', 'application/epub+zip', indirect: true).supportedExtension, isNull);
    expect(link('book.epub', null, rel: 'alternate').isAcquisition, isFalse);
    expect(link('book', 'application/epub+zip', rel: '$acquisition/open-access').supportedExtension, 'epub');
    expect(link('book', 'application/pdf', rel: '$acquisition/sample').supportedExtension, 'pdf');
    expect(link('book', 'application/x-cbr').supportedExtension, 'cbr');
    expect(link('book', 'application/vnd.amazon.mobi8-ebook').supportedExtension, 'azw3');
    expect(link('book', 'text/plain; charset=utf-8').supportedExtension, 'txt');
  });

  test('model collections cannot change after parsing', () {
    final source = <String>['Alice'];
    final book = OpdsPublication(id: 'id', title: 'Book', authors: source);
    source.add('Bob');
    expect(book.authors, ['Alice']);
    expect(() => book.authors.add('Mallory'), throwsUnsupportedError);
  });

  test('accepts OPDS2 compact acquisition relations and excludes transactions', () {
    for (final rel in ['acquisition', 'download', 'preview']) {
      final link = OpdsLink(uri: uri.resolve('book.epub'), rels: [rel]);
      expect(link.isAcquisition, isTrue, reason: rel);
      expect(link.supportedExtension, 'epub', reason: rel);
    }
    for (final rel in ['buy', 'borrow', 'subscribe']) {
      final link = OpdsLink(uri: uri.resolve('book.epub'), rels: [rel]);
      expect(link.isAcquisition, isTrue, reason: rel);
      expect(link.supportedExtension, isNull, reason: rel);
    }
    final feed = OpdsParser.parse('''{
      "metadata":{"title":"Book"},
      "links":[{"rel":"download","href":"book.epub"}]
    }''', uri);
    expect(feed.publications.single.title, 'Book');
  });

  test('rejects invalid JSON member types with a format error', () {
    expect(() => OpdsParser.parse('{"metadata":{"title":"Broken"},"publications":{}}', uri), throwsFormatException);
  });

  test('Atom escaped HTML and XHTML descriptions preserve word boundaries', () {
    for (final content in [
      '<content type="html">&lt;p&gt;One&lt;/p&gt;&lt;p&gt;Two &amp;amp; three&lt;/p&gt;</content>',
      '<content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml"><p>One</p><p>Two &amp; three</p></div></content>',
    ]) {
      final feed = OpdsParser.parse('''<entry xmlns="http://www.w3.org/2005/Atom">
        <title>Book</title>$content</entry>''', uri);
      expect(feed.publications.single.description, 'One\n\nTwo & three');
    }
  });

  test('expands RFC6570 query parameters and safely encodes scalar input', () {
    expect(
      OpdsSearch.expand('https://example.test/search{?query,author}', 'A & B/ž'),
      'https://example.test/search?query=A%20%26%20B%2F%C5%BE',
    );
    expect(
      OpdsSearch.expand('https://example.test/search?format=json{&query,lang}', 'a+b'),
      'https://example.test/search?format=json&query=a%2Bb',
    );
    expect(OpdsSearch.expand('https://example.test/search?q={query}', 'a b'), 'https://example.test/search?q=a%20b');
    expect(
      OpdsSearch.expand(Uri.parse('https://example.test/search{?query}').toString(), 'book'),
      'https://example.test/search?query=book',
    );
  });

  test('expands OpenSearch parameters with defaults and optional omissions', () {
    expect(
      OpdsSearch.expand(
        'https://example.test/?q={searchTerms}&start={startIndex}&page={startPage}&n={count?}&lang={language?}&encoding={inputEncoding}',
        'tea & coffee',
      ),
      'https://example.test/?q=tea%20%26%20coffee&start=1&page=1&n=&lang=&encoding=UTF-8',
    );
    expect(() => OpdsSearch.expand('https://example.test/?q={unknown}', 'book'), throwsFormatException);
  });

  test('expands RFC6570 scalar operators, prefix modifiers and omitted variables', () {
    expect(OpdsSearch.expand('https://example.test/{query:3}', 'žabc'), 'https://example.test/%C5%BEab');
    expect(OpdsSearch.expand('https://example.test{/query}', 'a/b'), 'https://example.test/a%2Fb');
    expect(OpdsSearch.expand('https://example.test{;query}', ''), 'https://example.test;query');
    expect(OpdsSearch.expand('https://example.test{#query}', 'a/b?c'), 'https://example.test#a/b?c');
    expect(OpdsSearch.expand('https://example.test/{+query}', 'a/b'), 'https://example.test/a/b');
    expect(OpdsSearch.expand('https://example.test/{query,author}', 'a b'), 'https://example.test/a%20b');
    expect(OpdsSearch.expand('https://example.test{?query:2,author}', 'abc'), 'https://example.test?query=ab');
    expect(OpdsSearch.expand('https://example.test{?query*}', 'a b'), 'https://example.test?query=a%20b');
  });

  test('selects supported GET OpenSearch URL and resolves its XML base', () {
    final link = OpdsSearch.fromOpenSearch('''
      <OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/" xml:base="../">
        <Url type="text/html" template="html?q={searchTerms}"/>
        <Url type="application/atom+xml" method="POST" template="post?q={searchTerms}"/>
        <Url type="application/atom+xml;profile=opds-catalog" xml:base="v1/"
          template="search?q={searchTerms}&amp;page={startPage?}"/>
      </OpenSearchDescription>''', uri);
    expect(link.templated, isTrue);
    expect(link.hasRel('search'), isTrue);
    expect(OpdsSearch.expand(link.template, 'two words'), 'https://books.example/v1/search?q=two%20words&page=');
  });

  test('rejects unsupported OpenSearch descriptions', () {
    for (final xml in [
      '<html/>',
      '<OpenSearchDescription xmlns="urn:wrong"><Url type="application/atom+xml" template="/?q={searchTerms}"/></OpenSearchDescription>',
      '<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/"><Url type="text/html" template="/?q={searchTerms}"/></OpenSearchDescription>',
    ]) {
      expect(() => OpdsSearch.fromOpenSearch(xml, uri), throwsFormatException);
    }
  });
}
