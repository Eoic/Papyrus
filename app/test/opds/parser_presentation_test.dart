import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/opds/opds_parser.dart';

void main() {
  final uri = Uri.parse('https://catalog.example/opds/index.xml');

  test('plain-text descriptions retain paragraph breaks without excessive whitespace', () {
    expect(
      opdsPlainText('  First   paragraph.\r\n\r\n\r\n  Second paragraph.  '),
      'First paragraph.\n\nSecond paragraph.',
    );
  });

  test('HTML blocks, line breaks and lists remain readable without markup', () {
    expect(
      opdsPlainText('''
      <div><h2>About this book</h2>
        <p>A long\n        paragraph with <em>emphasis</em> &amp; a link
          <a href="https://example.test">here</a>.</p>
        <p>Another paragraph.<br>On a new line.</p>
        <ul><li>First item</li><li>Second item</li></ul>
        <!-- invisible comment -->
        <script>alert('unsafe')</script><style>body { color: red; }</style>
      </div>'''),
      'About this book\n\nA long paragraph with emphasis & a link here.\n\n'
      'Another paragraph.\nOn a new line.\n\nFirst item\nSecond item',
    );
  });

  test('XHTML descriptions preserve metadata paragraphs across namespace prefixes', () {
    final feed = OpdsParser.parse('''
      <entry xmlns="http://www.w3.org/2005/Atom" xmlns:h="http://www.w3.org/1999/xhtml">
        <id>book-1</id><title>Book one</title>
        <content type="xhtml"><h:div>
          <h:p>This edition has images.</h:p>
          <h:p>Title:\n Book one</h:p>
          <h:p>Summary:\n A story with <h:em>some emphasis</h:em>.</h:p>
          <h:p>Language: English</h:p><h:p>Subject: Fiction</h:p>
        </h:div></content>
      </entry>''', uri);
    expect(
      feed.publications.single.description,
      'This edition has images.\n\nTitle: Book one\n\nSummary: A story with some emphasis.\n\n'
      'Language: English\n\nSubject: Fiction',
    );
  });

  test('JSON publication descriptions preserve paragraph formatting', () {
    final feed = OpdsParser.parse('''{
      "metadata":{"title":"Books"},
      "publications":[{"metadata":{"title":"Book one",
        "description":"<p>First paragraph.</p><p>Second &amp; last paragraph.</p>"}}]
    }''', uri);
    expect(feed.publications.single.description, 'First paragraph.\n\nSecond & last paragraph.');
  });

  test('authored partial entries can link to a complete acquisition feed', () {
    final feed = OpdsParser.parse('''
      <feed xmlns="http://www.w3.org/2005/Atom"><title>Books</title>
        <entry><id>book-1</id><title>Book one</title>
          <author><name>Book Author</name></author>
          <link rel="alternate" type='application/atom+xml;profile=opds-catalog;kind="acquisition"' href="book/1"/>
          <link rel="http://opds-spec.org/image" href="covers/1.jpg" type="image/jpeg"/>
        </entry>
      </feed>''', uri);
    final book = feed.publications.single;
    expect(feed.navigation, isEmpty);
    expect(book.title, 'Book one');
    expect(book.authors, ['Book Author']);
    expect(book.detailLink!.uri, uri.resolve('book/1'));
    expect(book.links.where((link) => link.isAcquisition), isEmpty);
  });

  test('category thumbnails and subsection author metadata do not imply publications', () {
    final feed = OpdsParser.parse('''
      <feed xmlns="http://www.w3.org/2005/Atom"><title>Browse</title>
        <entry><id>category</id><title>Fiction</title><summary>Stories to explore.</summary>
          <link rel="alternate" type="application/atom+xml;kind=acquisition" href="fiction"/>
          <link rel="http://opds-spec.org/image/thumbnail" href="fiction.jpg"/>
        </entry>
        <entry><id>author</id><title>Books by this author</title>
          <author><name>An Author</name></author>
          <link rel="subsection" type="application/atom+xml;kind=acquisition" href="author"/>
        </entry>
      </feed>''', uri);
    expect(feed.publications, isEmpty);
    expect(feed.navigation.map((link) => link.title), ['Fiction', 'Books by this author']);
    expect(feed.navigation.first.description, 'Stories to explore.');
    expect(feed.navigation.first.imageUri, uri.resolve('fiction.jpg'));
  });

  test('Gutenberg-style book navigation retains its author label and thumbnail', () {
    // Minimal shape observed at https://www.gutenberg.org/ebooks/search.opds/:
    // book links are subsections, with an author label in text content and a
    // data URI placeholder image. Keep their metadata without guessing a type.
    final feed = OpdsParser.parse('''
      <feed xmlns="http://www.w3.org/2005/Atom"><title>All Books</title>
        <entry><id>https://www.gutenberg.org/ebooks/1342.opds</id>
          <title>Pride and Prejudice</title><content type="text">Jane Austen</content>
          <link rel="subsection" type="application/atom+xml;profile=opds-catalog" href="/ebooks/1342.opds"/>
          <link rel="http://opds-spec.org/image/thumbnail" type="image/png" href="data:image/png;base64,AA=="/>
        </entry>
      </feed>''', Uri.parse('https://www.gutenberg.org/ebooks/search.opds/'));
    expect(feed.publications, isEmpty);
    final link = feed.navigation.single;
    expect(link.title, 'Pride and Prejudice');
    expect(link.description, 'Jane Austen');
    expect(link.uri.toString(), 'https://www.gutenberg.org/ebooks/1342.opds');
    expect(link.imageUri!.scheme, 'data');
  });

  test('JSON navigation retains optional descriptions and image links', () {
    final feed = OpdsParser.parse('''{
      "metadata":{"title":"Browse"},
      "navigation":[{"title":"Fiction","href":"fiction",
        "description":"<p>Stories to explore.</p>",
        "images":[{"href":"covers/fiction.jpg","type":"image/jpeg"}]}]
    }''', uri);
    expect(feed.navigation.single.description, 'Stories to explore.');
    expect(feed.navigation.single.imageUri, uri.resolve('covers/fiction.jpg'));
  });
}
