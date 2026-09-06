import 'package:flutter/foundation.dart';
import 'package:papyrus/opds/opds_browser.dart';
import 'package:papyrus/opds/opds_catalog_store.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';

class OpdsCatalogs extends ChangeNotifier {
  OpdsCatalogs(this.store);
  final OpdsCatalogStore store;
  String? _scope;
  String? get scope => _scope;
  int revision = 0;
  List<OpdsCatalog> catalogs = const [];
  String? error;
  bool _disposed = false;
  OpdsCatalog? find(String id) {
    for (final catalog in catalogs) {
      if (catalog.id == id) return catalog;
    }
    return null;
  }

  void setScope(String? scope) {
    if (_scope == scope) return;
    _scope = scope;
    reload();
  }

  void reload() {
    revision++;
    error = null;
    try {
      catalogs = _scope == null ? const [] : List.unmodifiable(store.load(_scope!));
    } catch (failure) {
      catalogs = const [];
      error = opdsErrorMessage(failure);
    }
    if (!_disposed) notifyListeners();
  }

  Future<OpdsCredentials?> credentials(String id) async {
    final scope = _scope;
    if (scope == null) throw const OpdsException('Wait for the library account to finish loading.');
    final catalog = find(id);
    final currentRevision = revision;
    if (catalog == null) throw const OpdsCancelled();
    final credentials = await store.credentials(scope, id, expectedOrigin: catalog.uri.origin);
    if (_scope != scope || revision != currentRevision || _disposed) throw const OpdsCancelled();
    return credentials;
  }

  Future<void> save(OpdsCatalog catalog, {OpdsCredentials? credentials, bool clearCredentials = false}) async {
    final scope = _scope;
    if (scope == null) throw const OpdsException('Wait for the library account to finish loading.');
    await store.save(scope, catalog, credentials: credentials, clearCredentials: clearCredentials);
    if (_scope == scope && !_disposed) reload();
  }

  Future<void> remove(String id) async {
    final scope = _scope;
    if (scope == null) return;
    await store.remove(scope, id);
    if (_scope == scope && !_disposed) reload();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
