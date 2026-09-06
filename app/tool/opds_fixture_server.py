#!/usr/bin/env python3
"""Serve deterministic OPDS fixtures using only the Python standard library.

Run from app/: python3 tool/opds_fixture_server.py --port 8766
Then: flutter test test/opds/network_smoke_test.dart \
    --dart-define=OPDS_SMOKE_URL=http://127.0.0.1:8766
Add --platform chrome for the same checks through the browser HTTP transport.
Protected routes use the fixture credentials reader / secret.
"""

import argparse
import base64
import io
import json
import struct
import zlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit
from xml.sax.saxutils import escape
from zipfile import ZIP_DEFLATED, ZIP_STORED, ZipFile


ATOM = "http://www.w3.org/2005/Atom"
ACQUISITION = "http://opds-spec.org/acquisition"
BASIC_AUTH = "Basic " + base64.b64encode(b"reader:secret").decode("ascii")
XML_TYPE = "application/atom+xml;profile=opds-catalog"
JSON_TYPE = "application/opds+json"


def make_epub():
    """Build a small EPUB 3 publication without downloading external fixtures."""
    buffer = io.BytesIO()
    with ZipFile(buffer, "w") as archive:
        archive.writestr("mimetype", "application/epub+zip", compress_type=ZIP_STORED)
        archive.writestr(
            "META-INF/container.xml",
            '<?xml version="1.0"?><container version="1.0" '
            'xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
            '<rootfiles><rootfile full-path="EPUB/package.opf" '
            'media-type="application/oebps-package+xml"/></rootfiles></container>',
            compress_type=ZIP_DEFLATED,
        )
        archive.writestr(
            "EPUB/package.opf",
            '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" '
            'version="3.0" unique-identifier="book-id">'
            '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
            '<dc:identifier id="book-id">urn:papyrus:network-fixture</dc:identifier>'
            '<dc:title>Network fixture book</dc:title><dc:language>en</dc:language>'
            '<dc:creator>Fixture Author</dc:creator>'
            '<meta property="dcterms:modified">2026-01-01T00:00:00Z</meta>'
            '</metadata><manifest><item id="chapter" href="chapter.xhtml" '
            'media-type="application/xhtml+xml"/>'
            '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" '
            'properties="nav"/></manifest><spine><itemref idref="chapter"/>'
            '</spine></package>',
            compress_type=ZIP_DEFLATED,
        )
        archive.writestr(
            "EPUB/chapter.xhtml",
            '<html xmlns="http://www.w3.org/1999/xhtml"><head>'
            '<title>Network fixture book</title></head><body>'
            '<h1>Network fixture book</h1><p>A local smoke test publication.</p>'
            '</body></html>',
            compress_type=ZIP_DEFLATED,
        )
        archive.writestr(
            "EPUB/nav.xhtml",
            '<html xmlns="http://www.w3.org/1999/xhtml" '
            'xmlns:epub="http://www.idpf.org/2007/ops"><head><title>Contents</title>'
            '</head><body><nav epub:type="toc"><h1>Contents</h1><ol>'
            '<li><a href="chapter.xhtml">Network fixture book</a></li>'
            '</ol></nav></body></html>',
            compress_type=ZIP_DEFLATED,
        )
    return buffer.getvalue()


EPUB_BYTES = make_epub()


def cover_png():
    """A small solid cover fixture for exercising image decoding and layout."""
    def chunk(kind, payload):
        return struct.pack('!I', len(payload)) + kind + payload + struct.pack('!I', zlib.crc32(kind + payload))
    pixels = b''.join(b'\x00' + bytes((70, 80, 105)) * 96 for _ in range(144))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', 96, 144, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(pixels)) + chunk(b'IEND', b''))


def xml_publication(detail=False):
    download = "../../book.epub" if detail else "../book.epub"
    details = "one.xml" if detail else "details/one.xml"
    description = "Complete publication details." if detail else "A fixture book."
    return (
        f'<entry xmlns="{ATOM}" xmlns:dc="http://purl.org/dc/terms/">'
        '<id>urn:papyrus:network-fixture</id><title>Network fixture book</title>'
        '<updated>2026-01-01T00:00:00Z</updated>'
        '<author><name>Fixture Author</name></author><dc:language>en</dc:language>'
        f'<content type="text">{description}</content>'
        f'<link rel="alternate" type="{XML_TYPE};type=entry" href="{details}"/>'
        f'<link rel="{ACQUISITION}" type="application/epub+zip" href="{download}"/>'
        '</entry>'
    )


def xml_feed(title, content):
    return (
        f'<?xml version="1.0"?><feed xmlns="{ATOM}" xml:base="./">'
        f'<id>urn:papyrus:fixture-feed</id><title>{escape(title)}</title>'
        '<updated>2026-01-01T00:00:00Z</updated>'
        '<author><name>Fixture Author</name></author>'
        f'{content}</feed>'
    )


def json_publication(detail=False):
    return {
        "metadata": {
            "identifier": "urn:papyrus:network-fixture",
            "title": "Network fixture book",
            "author": {"name": "Fixture Author"},
            "language": "en",
            "description": "Complete publication details." if detail else "A fixture book.",
        },
        "links": [
            {
                "rel": "self",
                "type": "application/opds-publication+json",
                "href": "one.json" if detail else "details/one.json",
            },
            {
                "rel": "download",
                "type": "application/epub+zip",
                "href": "../../book.epub" if detail else "../book.epub",
            },
        ],
    }


class FixtureHandler(BaseHTTPRequestHandler):
    def respond(self, status, body=b"", content_type="text/plain; charset=utf-8", cors=True, **headers):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        if cors:
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
            self.send_header("Access-Control-Expose-Headers", "Content-Type, Content-Length, Location")
            self.send_header("Access-Control-Allow-Private-Network", "true")
        self.send_header("Cache-Control", "no-store")
        for name, value in headers.items():
            self.send_header(name.replace("_", "-"), value)
        self.end_headers()
        self.wfile.write(body)

    def json_response(self, body, content_type=JSON_TYPE):
        self.respond(200, json.dumps(body, ensure_ascii=False), content_type)

    def do_OPTIONS(self):
        self.respond(204)

    def do_GET(self):
        request = urlsplit(self.path)
        path = request.path
        if path == '/no-cors/redirect':
            self.respond(302, cors=False, Location='/no-cors/book.epub')
            return
        if path == '/no-cors/book.epub':
            self.respond(200, EPUB_BYTES, 'application/epub+zip', cors=False)
            return
        if path.startswith("/protected/") and self.headers.get("Authorization") != BASIC_AUTH:
            self.respond(401, "Fixture credentials required.", WWW_Authenticate='Basic realm="OPDS fixture"')
            return
        if path == "/auth-probe":
            self.json_response({"authorizationReceived": self.headers.get("Authorization") is not None})
            return
        if path == "/protected/cross-origin":
            self.respond(302, Location=f"http://localhost:{self.server.server_port}/auth-probe")
            return
        for access in ("public", "protected"):
            for version, extension in (("v1", "xml"), ("v2", "json")):
                if path == f"/{access}/redirect-{version}":
                    self.respond(302, Location=f"/{access}/{version}/books/feed.{extension}")
                    return
        parts = path.strip("/").split("/", 2)
        if len(parts) != 3 or parts[0] not in ("public", "protected") or parts[1] not in ("v1", "v2"):
            self.respond(404, "Unknown fixture route.")
            return
        _, version, resource = parts
        if resource == "book.epub":
            self.respond(200, EPUB_BYTES, "application/epub+zip")
            return
        query = parse_qs(request.query)
        if version == "v1":
            self.serve_xml(resource, query)
        else:
            self.serve_json(resource, query)

    def serve_xml(self, resource, query):
        if resource == "catalog.xml":
            content = (
                '<link rel="search" type="application/opensearchdescription+xml" href="search.xml"/>'
                '<entry><id>urn:papyrus:all-books</id><title>All books</title>'
                '<updated>2026-01-01T00:00:00Z</updated>'
                f'<link rel="subsection" type="{XML_TYPE};kind=acquisition" href="books/feed.xml"/></entry>'
            )
            self.respond(200, xml_feed("Fixture catalog", content), XML_TYPE)
        elif resource == "search.xml":
            self.respond(
                200,
                '<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">'
                '<ShortName>Fixture search</ShortName><Description>Local book search</Description>'
                f'<Url type="{XML_TYPE}" template="books/search?q={{searchTerms}}"/>'
                '</OpenSearchDescription>',
                "application/opensearchdescription+xml",
            )
        elif resource == "books/details/one.xml":
            self.respond(200, xml_publication(detail=True), XML_TYPE + ";type=entry")
        elif resource in ("books/feed.xml", "books/page2.xml", "books/search"):
            title = "Books"
            links = '<link rel="next" href="page2.xml"/>'
            if resource == "books/page2.xml":
                title, links = "Second page", '<link rel="previous" href="feed.xml"/>'
            elif resource == "books/search":
                title = "Search: " + query.get("q", [""])[0]
                links = ""
            self.respond(200, xml_feed(title, links + xml_publication()), XML_TYPE)
        else:
            self.respond(404, "Unknown XML fixture route.")

    def serve_json(self, resource, query):
        if resource == 'blocked.json':
            publication = json_publication()
            publication['links'] = [{'rel': 'download', 'type': 'application/epub+zip',
                                     'href': '/no-cors/redirect'}]
            self.json_response({'metadata': {'title': 'Browser-restricted downloads'}, 'publications': [publication]})
        elif resource == "cover.png":
            self.respond(200, cover_png(), "image/png")
        elif resource == "showcase.json":
            titles = [("Pride and Prejudice", "Jane Austen"), ("Crime and Punishment", "Fyodor Dostoyevsky"),
                      ("The Odyssey", "Homer"), ("Alice’s Adventures in Wonderland", "Lewis Carroll"),
                      ("A Room with a View", "E. M. Forster"), ("The Adventures of Sherlock Holmes", "Arthur Conan Doyle")]
            books = []
            for index, (title, author) in enumerate(titles):
                book = json_publication()
                book['metadata'].update(identifier=f'preview-{index}', title=title, author=author,
                    publisher='Fixture Library', description=(
                        '<p>A classic story from the catalog, ready to add to your personal library.</p>'
                        '<p>This preview includes a longer catalog description to check reading comfort on small screens. '
                        'The description keeps its paragraphs, while download options stay easy to find.</p>'
                        '<p>Edition notes: this copy includes the original text. Catalogs can provide multiple editions '
                        'of the same work, with different illustrations and file formats.</p>'
                        '<p>Source: local OPDS fixture. Rights: demonstration metadata.</p>'))
                book['links'] = [
                    {'rel': 'download', 'type': 'application/epub+zip', 'href': 'book.epub', 'title': 'EPUB with illustrations'},
                    {'rel': 'download', 'type': 'application/pdf', 'href': 'book.pdf', 'title': 'PDF'},
                    {'rel': 'http://opds-spec.org/acquisition/buy', 'type': 'text/html', 'href': 'purchase', 'title': 'Purchase edition'},
                ]
                if index % 2 == 0:
                    book['images'] = [{'href': 'cover.png', 'type': 'image/png'}]
                books.append(book)
            self.json_response({'metadata': {'title': 'Popular classics'},
                'navigation': [{'title': 'Browse by author', 'description': 'Find your favorite writers', 'href': 'sections.json'},
                               {'title': 'Recently added', 'description': 'New books in the collection', 'href': 'sections.json'}],
                'links': [{'rel': 'search', 'href': 'search{?query}', 'templated': True},
                          {'rel': 'next', 'href': 'sections.json'}],
                'publications': books})
        elif resource == 'sections.json':
            self.json_response({'metadata': {'title': 'Browse the collection'},
                'navigation': [{'title': f'Collected works, volume {index + 1}',
                    'description': 'By a catalog author', 'href': 'showcase.json'} for index in range(24)],
                'links': [{'rel': 'previous', 'href': 'showcase.json'}]})
        elif resource == "catalog.json":
            self.json_response({
                "metadata": {"title": "Fixture catalog"},
                "links": [{"rel": "search", "href": "search{?query}", "templated": True, "type": JSON_TYPE}],
                "navigation": [{"title": "All books", "href": "books/feed.json", "type": JSON_TYPE}],
            })
        elif resource == "books/details/one.json":
            self.json_response(json_publication(detail=True), "application/opds-publication+json")
        elif resource in ("books/feed.json", "books/page2.json", "search"):
            title = "Books"
            links = [{"rel": "next", "href": "page2.json", "type": JSON_TYPE}]
            publication = json_publication()
            if resource == "books/page2.json":
                title, links = "Second page", [{"rel": "previous", "href": "feed.json", "type": JSON_TYPE}]
            elif resource == "search":
                title, links = "Search: " + query.get("query", [""])[0], []
                publication["links"][0]["href"] = "books/details/one.json"
                publication["links"][1]["href"] = "book.epub"
            self.json_response({"metadata": {"title": title}, "links": links, "publications": [publication]})
        else:
            self.respond(404, "Unknown JSON fixture route.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8766)
    args = parser.parse_args()
    with ThreadingHTTPServer(("127.0.0.1", args.port), FixtureHandler) as server:
        print(f"OPDS fixtures: http://127.0.0.1:{server.server_port}", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
