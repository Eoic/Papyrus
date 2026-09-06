import 'package:xml/xml.dart';

import 'opds_models.dart';

const _atom = 'http://www.w3.org/2005/Atom';
const _opds = 'http://opds-spec.org/2010/catalog';
const _dc = {'http://purl.org/dc/terms/', 'http://purl.org/dc/elements/1.1/'};

class OpdsXmlParser {
  static OpdsFeed parse(String body, Uri uri) {
    final XmlElement root;
    try {
      root = XmlDocument.parse(body).rootElement;
    } on XmlException {
      throw const FormatException('The OPDS XML document is malformed.');
    }
    if (root.name.namespaceUri != _atom || !{'feed', 'entry'}.contains(root.name.local)) {
      throw const FormatException('The response is not an Atom OPDS document.');
    }
    final base = xmlBase(root, uri);
    final title = _text(root, 'title') ?? 'Untitled catalog';
    if (root.name.local == 'entry') {
      return OpdsFeed(uri: uri, title: title, publications: [_publication(root, base)]);
    }
    final links = _links(root, base);
    final navigation = <OpdsLink>[];
    final publications = <OpdsPublication>[];
    final groups = <String, _GroupBuilder>{};
    for (final entry in _children(root, 'entry')) {
      final book = _publication(entry, xmlBase(entry, base));
      final isPublication = book.links.any((link) => link.isAcquisition) || book.detailLink != null;
      final entryNavigation = isPublication
          ? <OpdsLink>[]
          : book.links
                .where(_isNavigation)
                .map(
                  (link) => OpdsLink(
                    uri: link.uri,
                    title: link.title ?? book.title,
                    type: link.type,
                    rels: link.rels,
                    templated: link.templated,
                  ),
                )
                .toList();
      final collections = book.links.where((link) => link.hasRel('collection')).toList();
      if (collections.isEmpty) {
        if (isPublication) publications.add(book);
        navigation.addAll(entryNavigation);
      } else {
        for (final collection in collections) {
          final group = groups.putIfAbsent(
            collection.uri.toString(),
            () => _GroupBuilder(collection.title ?? 'Collection', [collection]),
          );
          if (isPublication) group.publications.add(book);
          group.navigation.addAll(entryNavigation);
        }
      }
    }
    final facets = <String, List<OpdsLink>>{};
    for (final element in _children(root, 'link')) {
      final link = _link(element, base);
      if (link == null || !link.hasRel('http://opds-spec.org/facet')) continue;
      final group = element.getAttribute('facetGroup', namespace: _opds) ?? 'Filters';
      facets.putIfAbsent(group, () => []).add(link);
    }
    return OpdsFeed(
      uri: uri,
      title: title,
      links: links,
      navigation: navigation,
      publications: publications,
      groups: groups.values.map((group) => group.build()).toList(),
      facets: facets.entries.map((entry) => OpdsGroup(title: entry.key, links: entry.value)).toList(),
    );
  }

  static bool _isNavigation(OpdsLink link) {
    if (link.hasRel('collection') ||
        link.hasRel('self') ||
        link.hasRel('http://opds-spec.org/image') ||
        link.hasRel('http://opds-spec.org/image/thumbnail')) {
      return false;
    }
    final mime = link.type?.split(';').first.trim().toLowerCase();
    return mime == null || mime == 'application/atom+xml' || mime == 'application/opds+json';
  }

  static OpdsPublication _publication(XmlElement entry, Uri base) {
    final links = _links(entry, base);
    final title = _text(entry, 'title') ?? 'Untitled publication';
    final identifiers = entry.childElements.where(
      (element) => element.name.local == 'identifier' && _dc.contains(element.name.namespaceUri),
    );
    String? isbn;
    for (final identifier in identifiers) {
      isbn = opdsIsbn(identifier.innerText);
      if (isbn != null) break;
    }
    return OpdsPublication(
      id: _text(entry, 'id') ?? (links.isNotEmpty ? links.first.uri.toString() : title),
      title: title,
      authors: _children(entry, 'author').map((author) => _text(author, 'name')).whereType<String>().toList(),
      description: _text(entry, 'content') ?? _text(entry, 'summary') ?? _dcText(entry, 'description'),
      publisher: _dcText(entry, 'publisher'),
      language: _dcText(entry, 'language'),
      isbn: isbn,
      links: links,
      images: links
          .where(
            (link) => link.hasRel('http://opds-spec.org/image/thumbnail') || link.hasRel('http://opds-spec.org/image'),
          )
          .toList(),
    );
  }

  static List<OpdsLink> _links(XmlElement parent, Uri base) =>
      _children(parent, 'link').map((element) => _link(element, base)).whereType<OpdsLink>().toList();

  static OpdsLink? _link(XmlElement element, Uri base) {
    final href = element.getAttribute('href');
    if (href == null || href.trim().isEmpty) return null;
    return OpdsLink(
      uri: xmlBase(element, base).resolve(href),
      title: element.getAttribute('title'),
      type: element.getAttribute('type'),
      rels: (element.getAttribute('rel') ?? 'alternate').split(RegExp(r'\s+')),
      templated: href.contains('{'),
      indirect: element.descendantElements.any(
        (child) => child.name.local == 'indirectAcquisition' && child.name.namespaceUri == _opds,
      ),
    );
  }

  static Iterable<XmlElement> _children(XmlElement parent, String local) =>
      parent.childElements.where((child) => child.name.local == local && child.name.namespaceUri == _atom);

  static String? _text(XmlElement parent, String local) {
    final children = _children(parent, local);
    if (children.isEmpty) return null;
    final element = children.first;
    final text = opdsPlainText(element.getAttribute('type') == 'xhtml' ? element.innerXml : element.innerText);
    return text.isEmpty ? null : text;
  }

  static String? _dcText(XmlElement parent, String local) {
    final children = parent.childElements.where(
      (child) => child.name.local == local && _dc.contains(child.name.namespaceUri),
    );
    return children.isEmpty ? null : opdsPlainText(children.first.innerText);
  }
}

/// Apply just this element's base; callers carry its ancestors' resolved base.
Uri xmlBase(XmlElement element, Uri inherited) {
  final base = element.getAttribute('xml:base');
  return base == null ? inherited : inherited.resolve(base);
}

class _GroupBuilder {
  _GroupBuilder(this.title, this.links);
  final String title;
  final List<OpdsLink> links;
  final navigation = <OpdsLink>[];
  final publications = <OpdsPublication>[];

  OpdsGroup build() => OpdsGroup(title: title, links: links, navigation: navigation, publications: publications);
}
