import 'package:flutter/foundation.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/opds/opds_parser.dart';
import 'package:papyrus/opds/opds_search.dart';

class OpdsBrowser extends ChangeNotifier {
  OpdsBrowser({OpdsHttpClient? httpClient}) : httpClient = httpClient ?? OpdsHttpClient();
  final OpdsHttpClient httpClient;
  OpdsFeed? feed;
  String? error;
  bool loading = false;
  OpdsCatalog? _catalog;
  OpdsCredentials? _credentials;
  OpdsCancellation _cancellation = OpdsCancellation();
  bool _disposed = false;

  Future<OpdsFeed> _fetch(OpdsCatalog catalog, Uri uri, OpdsCancellation token, OpdsCredentials? credentials) async {
    final response = await httpClient.get(catalog, uri, credentials: credentials, cancellation: token);
    return OpdsParser.parse(response.text, response.uri, contentType: response.headers['content-type']);
  }

  Future<void> load(OpdsCatalog catalog, Uri uri, {OpdsCredentials? credentials}) async {
    _cancellation.cancel();
    final token = _cancellation = OpdsCancellation();
    _catalog = catalog;
    _credentials = credentials;
    feed = null;
    error = null;
    loading = true;
    _notify();
    try {
      final loaded = await _fetch(catalog, uri, token, credentials);
      if (token.isCancelled || _disposed) return;
      feed = loaded;
    } on OpdsCancelled {
      return;
    } catch (failure) {
      if (token.isCancelled || _disposed) return;
      error = opdsErrorMessage(failure);
    } finally {
      if (!token.isCancelled && !_disposed) {
        loading = false;
        _notify();
      }
    }
  }

  Future<Uri> search(String query) async {
    final catalog = _catalog;
    if (catalog == null || query.trim().isEmpty) throw const OpdsException('Enter a search term.');
    final token = _cancellation;
    var link = feed?.searchLink;
    link ??= (await _fetch(catalog, catalog.uri, token, _credentials)).searchLink;
    token.check();
    if (link == null) throw const OpdsException('This catalog does not advertise keyword search.');
    if (link.type?.split(';').first.trim().toLowerCase() == 'application/opensearchdescription+xml') {
      final response = await httpClient.get(catalog, link.uri, credentials: _credentials, cancellation: token);
      link = OpdsSearch.fromOpenSearch(response.text, response.uri);
    }
    token.check();
    return OpdsHttpClient.validateUri(Uri.parse(OpdsSearch.expand(link.template, query.trim())));
  }

  void clear() {
    _cancellation.cancel();
    _catalog = null;
    _credentials = null;
    feed = null;
    error = null;
    loading = false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }
}

String opdsErrorMessage(Object error) {
  if (error is OpdsException) return error.message;
  if (error is FormatException) return 'This response is not a supported OPDS catalog. Check the catalog URL.';
  return 'Could not load this catalog. Check its settings and retry.';
}
