import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OpdsSecretStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureOpdsSecretStorage implements OpdsSecretStorage {
  const SecureOpdsSecretStorage();
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class OpdsCatalogStore {
  OpdsCatalogStore(this._prefs, {OpdsSecretStorage? secrets}) : _secrets = secrets ?? const SecureOpdsSecretStorage();
  final SharedPreferences _prefs;
  final OpdsSecretStorage _secrets;
  Future<void> _pending = Future.value();
  String _key(String scope) => 'papyrus.opds.catalogs.${Uri.encodeComponent(scope)}';
  String _secretKey(String scope, String id) => '${_key(scope)}.${Uri.encodeComponent(id)}.credentials';

  List<OpdsCatalog> load(String scope) {
    final raw = _prefs.getString(_key(scope));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => OpdsCatalog.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      throw const OpdsException('Saved catalogs could not be read.');
    }
  }

  Future<OpdsCredentials?> credentials(String scope, String id, {String? expectedOrigin}) async {
    final raw = await _secrets.read(_secretKey(scope, id));
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final catalogs = load(scope);
    final index = catalogs.indexWhere((entry) => entry.id == id);
    if (index < 0 ||
        data['origin'] != catalogs[index].uri.origin ||
        (expectedOrigin != null && data['origin'] != expectedOrigin)) {
      return null;
    }
    return OpdsCredentials(username: data['username'] as String, password: data['password'] as String);
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  /// Omitted credentials preserve the existing secret unless the origin changes.
  Future<void> save(String scope, OpdsCatalog catalog, {OpdsCredentials? credentials, bool clearCredentials = false}) =>
      _serialize(() async {
        OpdsHttpClient.validateUri(catalog.uri);
        if (catalog.name.trim().isEmpty || catalog.id.isEmpty) throw const OpdsException('Enter a catalog name.');
        final catalogKey = _key(scope);
        final oldCatalogs = _prefs.getString(catalogKey);
        final catalogs = load(scope);
        final index = catalogs.indexWhere((entry) => entry.id == catalog.id);
        final originChanged = index >= 0 && catalogs[index].uri.origin != catalog.uri.origin;
        final key = _secretKey(scope, catalog.id);
        final oldSecret = await _secrets.read(key);
        try {
          if (credentials != null) {
            await _secrets.write(
              key,
              jsonEncode({
                'origin': catalog.uri.origin,
                'username': credentials.username,
                'password': credentials.password,
              }),
            );
          } else if (clearCredentials || originChanged) {
            await _secrets.delete(key);
          }
          if (index < 0) {
            catalogs.add(catalog);
          } else {
            catalogs[index] = catalog;
          }
          if (!await _prefs.setString(catalogKey, jsonEncode(catalogs.map((e) => e.toJson()).toList()))) {
            throw const OpdsException('Could not save this catalog.');
          }
        } catch (_) {
          await _restore(catalogKey, oldCatalogs, key, oldSecret);
          rethrow;
        }
      });

  Future<void> remove(String scope, String id) => _serialize(() async {
    final catalogKey = _key(scope);
    final oldCatalogs = _prefs.getString(catalogKey);
    final catalogs = load(scope)..removeWhere((entry) => entry.id == id);
    final key = _secretKey(scope, id);
    final oldSecret = await _secrets.read(key);
    try {
      await _secrets.delete(key);
      if (!await _prefs.setString(catalogKey, jsonEncode(catalogs.map((e) => e.toJson()).toList()))) {
        throw const OpdsException('Could not remove this catalog.');
      }
    } catch (_) {
      await _restore(catalogKey, oldCatalogs, key, oldSecret);
      rethrow;
    }
  });

  Future<void> _restore(String catalogKey, String? oldCatalogs, String secretKey, String? oldSecret) async {
    try {
      // SharedPreferences changes its cache before the backend completes. These
      // calls restore the cache even if the compensating backend write fails.
      if (oldCatalogs == null) {
        await _prefs.remove(catalogKey);
      } else {
        await _prefs.setString(catalogKey, oldCatalogs);
      }
    } catch (_) {
      // Still attempt secret restoration and preserve the original failure.
    }
    try {
      if (oldSecret == null) {
        await _secrets.delete(secretKey);
      } else {
        await _secrets.write(secretKey, oldSecret);
      }
    } catch (_) {
      // Compensation is best effort; origin binding rejects any stale secret.
    }
  }
}
