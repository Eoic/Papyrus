import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_parser.dart';

void main() {
  final uri = Uri.parse('https://books.test/opds');
  test('rejects JSON without catalog structure or valid publication members', () {
    for (final body in [
      '{"metadata":{"title":"x"}}',
      '{"metadata":{"title":"x"},"publications":[false]}',
      '{"metadata":{"title":"x"},"publications":[{}]}',
    ]) {
      expect(() => OpdsParser.parse(body, uri), throwsFormatException);
    }
  });
  test('selects supported keyword search after an HTML search link', () {
    final feed = OpdsParser.parse('''{"metadata":{"title":"Books"},"navigation":[],"links":[
      {"rel":"search","href":"/website-search","type":"text/html"},
      {"rel":"search","href":"/opds-search{?query}","type":"application/opds+json","templated":true}]}''', uri);
    expect(feed.searchLink!.template, contains('opds-search{?query}'));
  });
}
