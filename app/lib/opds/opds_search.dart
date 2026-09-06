import 'package:xml/xml.dart';

import 'opds_models.dart';
import 'opds_xml_parser.dart' show xmlBase;

class OpdsSearch {
  static String expand(String template, String query) {
    final decoded = template
        .replaceAll(RegExp('%7b', caseSensitive: false), '{')
        .replaceAll(RegExp('%7d', caseSensitive: false), '}');
    return decoded.replaceAllMapped(RegExp(r'\{([^{}]+)\}'), (match) {
      final expression = match[1]!;
      if (expression == 'searchTerms' || expression == 'searchTerms?') {
        return _encode(query);
      }
      if (expression.endsWith('?')) return '';
      const defaults = {
        'startIndex': '1',
        'startPage': '1',
        'count': '20',
        'language': '*',
        'inputEncoding': 'UTF-8',
        'outputEncoding': 'UTF-8',
      };
      if (defaults.containsKey(expression)) return defaults[expression]!;
      if (RegExp(r'^[+#./;?&]|(^|,)query(?:[,*:]|$)').hasMatch(expression)) {
        return _expandScalar(expression, query);
      }
      throw FormatException('Unsupported required search parameter: $expression');
    });
  }

  static String _expandScalar(String expression, String query) {
    const operators = {'+', '#', '.', '/', ';', '?', '&'};
    final operator = operators.contains(expression[0]) ? expression[0] : '';
    final variables = (operator.isEmpty ? expression : expression.substring(1)).split(',');
    final values = <String>[];
    for (final variable in variables) {
      final match = RegExp(r'^query(?::([1-9][0-9]{0,3})|\*)?$').firstMatch(variable);
      if (match == null) continue;
      final prefix = match[1] == null ? null : int.parse(match[1]!);
      final value = prefix == null ? query : String.fromCharCodes(query.runes.take(prefix));
      final encoded = _encode(value, allowReserved: operator == '+' || operator == '#');
      values.add(switch (operator) {
        '?' || '&' => 'query=$encoded',
        ';' => value.isEmpty ? 'query' : 'query=$encoded',
        _ => encoded,
      });
    }
    if (values.isEmpty) return '';
    final prefix = operator == '+' ? '' : operator;
    final separator = switch (operator) {
      '?' || '&' => '&',
      '.' || '/' || ';' => operator,
      _ => ',',
    };
    return '$prefix${values.join(separator)}';
  }

  // Uri.encodeComponent leaves some reserved characters unescaped; RFC6570's
  // simple and query expansions allow only the unreserved character set.
  static String _encode(String value, {bool allowReserved = false}) {
    final encoded = Uri.encodeComponent(
      value,
    ).replaceAllMapped(RegExp(r"[!'()*]"), (match) => '%${match[0]!.codeUnitAt(0).toRadixString(16).toUpperCase()}');
    if (!allowReserved) return encoded;
    return encoded
        .replaceAllMapped(RegExp(r'%[0-9A-F]{2}'), (match) {
          final char = String.fromCharCode(int.parse(match[0]!.substring(1), radix: 16));
          return r":/?#[]@!$&'()*+,;=".contains(char) ? char : match[0]!;
        })
        .replaceAllMapped(RegExp(r'%25([0-9a-fA-F]{2})'), (match) => '%${match[1]}');
  }

  static OpdsLink fromOpenSearch(String xml, Uri uri) {
    final XmlElement root;
    try {
      root = XmlDocument.parse(xml).rootElement;
    } on XmlException {
      throw const FormatException('The OpenSearch description is malformed.');
    }
    const namespace = 'http://a9.com/-/spec/opensearch/1.1/';
    if (root.name.local != 'OpenSearchDescription' || root.name.namespaceUri != namespace) {
      throw const FormatException('The response is not an OpenSearch description.');
    }
    final base = xmlBase(root, uri);
    for (final element in root.childElements) {
      if (element.name.local != 'Url' || element.name.namespaceUri != namespace) continue;
      final method = element.getAttribute('method')?.toUpperCase() ?? 'GET';
      final type = element.getAttribute('type');
      final mime = type?.split(';').first.trim().toLowerCase();
      final template = element.getAttribute('template');
      if (method != 'GET' ||
          template == null ||
          !{'application/atom+xml', 'application/opds+json'}.contains(mime) ||
          !RegExp(r'\{(?:searchTerms\??|query)\}').hasMatch(template)) {
        continue;
      }
      try {
        expand(template, '');
      } on FormatException {
        continue;
      }
      return OpdsLink(
        uri: xmlBase(element, base).resolve(template),
        type: type,
        rels: const ['search'],
        templated: true,
      );
    }
    throw const FormatException('No supported OPDS GET search endpoint was found.');
  }
}
