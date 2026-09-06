import 'opds_json_parser.dart';
import 'opds_models.dart';
import 'opds_xml_parser.dart';

class OpdsParser {
  /// Inspect the document as catalogs commonly use generic HTTP media types.
  static OpdsFeed parse(String body, Uri uri, {String? contentType}) {
    final text = body.replaceFirst(RegExp(r'^\uFEFF'), '').trimLeft();
    if (text.startsWith('{')) {
      return OpdsJsonParser.parse(text, uri, contentType: contentType);
    }
    if (text.startsWith('<')) return OpdsXmlParser.parse(text, uri);
    throw const FormatException('The response is not an OPDS catalog.');
  }
}
