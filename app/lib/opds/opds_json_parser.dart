import 'dart:convert';

import 'opds_models.dart';

class OpdsJsonParser {
  static OpdsFeed parse(String body, Uri uri, {String? contentType}) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['metadata'] is! Map) {
      throw const FormatException('The response is not an OPDS JSON document.');
    }
    final metadata = _object(decoded['metadata']);
    final title = _text(metadata['title']);
    if (title == null) {
      throw const FormatException('The OPDS document has no title.');
    }
    final links = _links(decoded['links'], uri);
    final hasFeedContent = ['publications', 'navigation', 'groups'].any(decoded.containsKey);
    final isPublication =
        !hasFeedContent &&
        ((contentType ?? '').toLowerCase().startsWith('application/opds-publication+json') ||
            links.any((link) => link.isAcquisition));
    if (!hasFeedContent && !isPublication) {
      throw const FormatException('The JSON document contains no OPDS collections.');
    }
    return OpdsFeed(
      uri: uri,
      title: title,
      links: isPublication ? const [] : links,
      navigation: _links(decoded['navigation'], uri),
      publications: isPublication
          ? [_publication(decoded, uri)]
          : _objects(decoded['publications']).map((book) => _publication(book, uri)).toList(),
      groups: _objects(decoded['groups']).map((group) => _group(group, uri)).toList(),
      facets: _objects(decoded['facets']).map((group) => _group(group, uri)).toList(),
    );
  }

  static OpdsGroup _group(Map<String, dynamic> json, Uri uri) => OpdsGroup(
    title: _text(_object(json['metadata'])['title']) ?? 'Untitled group',
    links: _links(json['links'], uri),
    navigation: _links(json['navigation'], uri),
    publications: _objects(json['publications']).map((book) => _publication(book, uri)).toList(),
  );

  static OpdsPublication _publication(Map<String, dynamic> json, Uri uri) {
    final metadata = _object(json['metadata']);
    final links = _links(json['links'], uri);
    final identifier = _text(metadata['identifier']);
    final title = _text(metadata['title']);
    if (title == null) throw const FormatException('An OPDS publication has no metadata title.');
    return OpdsPublication(
      id: identifier ?? (links.isNotEmpty ? links.first.uri.toString() : title),
      title: title,
      authors: _names(metadata['author']),
      description: _text(metadata['description']),
      publisher: _joined(_names(metadata['publisher'])),
      language: _joined(_names(metadata['language'])),
      isbn: opdsIsbn(identifier),
      links: links,
      images: _links(json['images'], uri),
    );
  }

  static List<OpdsLink> _links(dynamic value, Uri uri) {
    final result = <OpdsLink>[];
    for (final json in _objects(value)) {
      final href = json['href'];
      if (href is! String || href.trim().isEmpty) continue;
      final properties = _object(json['properties']);
      final indirect = properties['indirectAcquisition'];
      result.add(
        OpdsLink(
          uri: uri.resolve(href),
          title: _text(json['title']),
          type: json['type'] is String ? json['type'] as String : null,
          rels: json['rel'] is String
              ? (json['rel'] as String).split(RegExp(r'\s+'))
              : (json['rel'] is List ? (json['rel'] as List).whereType<String>().toList() : const []),
          templated: json['templated'] == true,
          indirect: indirect != null && (indirect is! List || indirect.isNotEmpty),
        ),
      );
    }
    return result;
  }

  static Map<String, dynamic> _object(dynamic value) => value is Map<String, dynamic> ? value : const {};

  static Iterable<Map<String, dynamic>> _objects(dynamic value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('An OPDS collection must be an array.');
    }
    if (value.any((item) => item is! Map<String, dynamic>)) {
      throw const FormatException('An OPDS collection contains an invalid member.');
    }
    return value.cast<Map<String, dynamic>>();
  }

  static String? _text(dynamic value) {
    if (value is String) {
      final text = opdsPlainText(value);
      return text.isEmpty ? null : text;
    }
    if (value is Map) {
      if (value.containsKey('name')) return _text(value['name']);
      for (final localized in value.values) {
        final text = _text(localized);
        if (text != null) return text;
      }
    }
    return null;
  }

  static List<String> _names(dynamic value) {
    final values = value is List ? value : [value];
    return values.map(_text).whereType<String>().toList();
  }

  static String? _joined(List<String> values) => values.isEmpty ? null : values.join(', ');
}
