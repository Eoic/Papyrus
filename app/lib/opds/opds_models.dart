/// A saved catalog contains no authentication secrets.
class OpdsCatalog {
  OpdsCatalog({required this.id, required this.name, required Uri uri}) : uri = uri.replace(userInfo: '');

  final String id;
  final String name;
  final Uri uri;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'uri': uri.toString()};

  factory OpdsCatalog.fromJson(Map<String, dynamic> json) =>
      OpdsCatalog(id: json['id'] as String, name: json['name'] as String, uri: Uri.parse(json['uri'] as String));
}

class OpdsCredentials {
  const OpdsCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class OpdsLink {
  OpdsLink({
    required this.uri,
    this.title,
    this.type,
    List<String> rels = const [],
    this.templated = false,
    this.indirect = false,
  }) : rels = List.unmodifiable(rels);

  final Uri uri;
  final String? title;
  final String? type;
  final List<String> rels;
  final bool templated;
  final bool indirect;

  /// Uri escapes braces; leave other escaped bytes intact when expanding.
  String get template => uri
      .toString()
      .replaceAll(RegExp('%7b', caseSensitive: false), '{')
      .replaceAll(RegExp('%7d', caseSensitive: false), '}');

  bool hasRel(String rel) => rels.contains(rel);

  bool get isAcquisition => rels.any(
    (rel) =>
        rel == 'http://opds-spec.org/acquisition' ||
        rel.startsWith('http://opds-spec.org/acquisition/') ||
        {'acquisition', 'download', 'preview', 'buy', 'borrow', 'subscribe'}.contains(rel),
  );

  /// Formats that can go straight to the existing local book importer.
  String? get supportedExtension {
    const directRelations = {
      'http://opds-spec.org/acquisition',
      'http://opds-spec.org/acquisition/open-access',
      'http://opds-spec.org/acquisition/sample',
      'acquisition',
      'download',
      'preview',
    };
    if (indirect || templated || !rels.any(directRelations.contains)) return null;
    const extensions = {
      'application/epub+zip': 'epub',
      'application/pdf': 'pdf',
      'application/x-mobipocket-ebook': 'mobi',
      'application/vnd.amazon.mobi8-ebook': 'azw3',
      'application/x-cbz': 'cbz',
      'application/vnd.comicbook+zip': 'cbz',
      'application/x-cbr': 'cbr',
      'application/vnd.comicbook-rar': 'cbr',
      'text/plain': 'txt',
    };
    final mime = type?.split(';').first.trim().toLowerCase();
    if (extensions.containsKey(mime)) return extensions[mime];
    if (mime != null && mime.isNotEmpty && mime != 'application/octet-stream') {
      return null;
    }
    final extension = uri.path.split('.').last.toLowerCase();
    return extensions.values.contains(extension) ? extension : null;
  }
}

class OpdsPublication {
  OpdsPublication({
    required this.id,
    required this.title,
    List<String> authors = const [],
    this.description,
    this.publisher,
    this.language,
    this.isbn,
    List<OpdsLink> links = const [],
    List<OpdsLink> images = const [],
  }) : authors = List.unmodifiable(authors),
       links = List.unmodifiable(links),
       images = List.unmodifiable(images);

  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? publisher;
  final String? language;
  final String? isbn;
  final List<OpdsLink> links;
  final List<OpdsLink> images;

  OpdsLink? get detailLink {
    for (final link in links) {
      final type = link.type?.toLowerCase() ?? '';
      if ((link.hasRel('alternate') || link.hasRel('self')) &&
          (type.startsWith('application/opds-publication+json') ||
              (type.startsWith('application/atom+xml') && RegExp(r'type\s*=\s*"?entry').hasMatch(type)))) {
        return link;
      }
    }
    return null;
  }
}

class OpdsGroup {
  OpdsGroup({
    required this.title,
    List<OpdsLink> navigation = const [],
    List<OpdsPublication> publications = const [],
    List<OpdsLink> links = const [],
  }) : navigation = List.unmodifiable(navigation),
       publications = List.unmodifiable(publications),
       links = List.unmodifiable(links);

  final String title;
  final List<OpdsLink> navigation;
  final List<OpdsPublication> publications;
  final List<OpdsLink> links;
}

class OpdsFeed {
  OpdsFeed({
    required this.uri,
    required this.title,
    List<OpdsLink> links = const [],
    List<OpdsLink> navigation = const [],
    List<OpdsPublication> publications = const [],
    List<OpdsGroup> groups = const [],
    List<OpdsGroup> facets = const [],
  }) : links = List.unmodifiable(links),
       navigation = List.unmodifiable(navigation),
       publications = List.unmodifiable(publications),
       groups = List.unmodifiable(groups),
       facets = List.unmodifiable(facets);

  final Uri uri;
  final String title;
  final List<OpdsLink> links;
  final List<OpdsLink> navigation;
  final List<OpdsPublication> publications;
  final List<OpdsGroup> groups;
  final List<OpdsGroup> facets;

  OpdsLink? _link(String rel) {
    for (final link in links) {
      if (link.hasRel(rel)) return link;
    }
    return null;
  }

  OpdsLink? get searchLink {
    for (final link in links.where((link) => link.hasRel('search'))) {
      final mime = link.type?.split(';').first.trim().toLowerCase();
      if (mime == 'application/opensearchdescription+xml') return link;
      if ((mime == null || mime.isEmpty || mime == 'application/opds+json' || mime == 'application/atom+xml') &&
          RegExp(r'\{[^}]*\b(query|searchTerms)\b').hasMatch(link.template)) {
        return link;
      }
    }
    return null;
  }

  OpdsLink? get nextLink => _link('next');
  OpdsLink? get previousLink => _link('previous') ?? _link('prev');
}

/// Descriptions are displayed as plain text rather than executing catalog HTML.
String opdsPlainText(String input) => input
    .replaceAll(RegExp(r'<(script|style)\b[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false), '')
    .replaceAll(RegExp(r'</?(?:p|div|br|li|h[1-6])\b[^>]*>', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAllMapped(RegExp(r'&(#x[\da-fA-F]+|#\d+|amp|lt|gt|quot|apos|nbsp);'), (match) {
      const named = {'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' '};
      final entity = match[1]!;
      if (named.containsKey(entity)) return named[entity]!;
      final code = entity.startsWith('#x')
          ? int.tryParse(entity.substring(2), radix: 16)
          : int.tryParse(entity.substring(1));
      return code != null && code >= 0 && code <= 0x10ffff ? String.fromCharCode(code) : match[0]!;
    })
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String? opdsIsbn(String? identifier) {
  if (identifier == null) return null;
  final normalized = identifier
      .replaceFirst(RegExp(r'^(?:urn:)?isbn:', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^(?:\d{13}|\d{9}[\dXx])$').hasMatch(normalized) ? normalized.toUpperCase() : null;
}
