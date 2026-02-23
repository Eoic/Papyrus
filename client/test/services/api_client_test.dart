import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('creates instance with base URL', () {
      final client = ApiClient(baseUrl: 'http://localhost:8080');
      expect(client.baseUrl, 'http://localhost:8080');
    });

    test('builds URL with path', () {
      final client = ApiClient(baseUrl: 'http://localhost:8080');
      final uri = client.buildUri('/v1/feed');
      expect(uri.toString(), 'http://localhost:8080/v1/feed');
    });

    test('builds URL with query params', () {
      final client = ApiClient(baseUrl: 'http://localhost:8080');
      final uri = client.buildUri(
        '/v1/catalog/search',
        queryParams: {'q': 'dune'},
      );
      expect(uri.toString(), 'http://localhost:8080/v1/catalog/search?q=dune');
    });
  });
}
