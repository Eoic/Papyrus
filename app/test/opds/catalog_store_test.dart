import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_catalog_store.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform fake exercises the real SharedPreferences cache and write path.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class MemorySecrets implements OpdsSecretStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _FailingPreferences extends InMemorySharedPreferencesStore {
  _FailingPreferences() : super.empty();

  bool rejectWrites = false;
  Object? writeError;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (writeError != null) throw writeError!;
    if (rejectWrites) return false;
    return super.setValue(valueType, key, value);
  }
}

class _FailingSecrets extends MemorySecrets {
  Object? writeError;

  @override
  Future<void> write(String key, String value) async {
    if (writeError != null) throw writeError!;
    await super.write(key, value);
  }
}

void main() {
  const scope = 'guest';
  const catalogKey = 'papyrus.opds.catalogs.guest';
  const secretKey = '$catalogKey.one.credentials';
  final originA = OpdsCatalog(id: 'one', name: 'One', uri: Uri.parse('https://one.test/feed'));
  final originB = OpdsCatalog(id: 'one', name: 'Two', uri: Uri.parse('https://two.test/feed'));

  Future<SharedPreferences> failingPreferences(_FailingPreferences platform) async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = platform;
    return SharedPreferences.getInstance();
  }

  test('isolates catalogs and credentials by account, and deletes both', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final secrets = MemorySecrets();
    final store = OpdsCatalogStore(prefs, secrets: secrets);
    final catalog = OpdsCatalog(id: 'one', name: 'Private', uri: Uri.parse('https://books.test/feed'));
    await store.save(
      'server--alice',
      catalog,
      credentials: const OpdsCredentials(username: 'alice', password: 'secret'),
    );
    expect(store.load('server--alice').single.name, 'Private');
    expect(store.load('server--bob'), isEmpty);
    expect(store.load('local--guest'), isEmpty);
    expect((await store.credentials('server--alice', 'one'))?.password, 'secret');
    expect(await store.credentials('server--bob', 'one'), isNull);
    expect(prefs.getKeys().map(prefs.get).join(), isNot(contains('secret')));
    await store.remove('server--alice', 'one');
    expect(store.load('server--alice'), isEmpty);
    expect(secrets.values, isEmpty);
  });

  test('changing a catalog origin clears saved credentials', () async {
    SharedPreferences.setMockInitialValues({});
    final store = OpdsCatalogStore(await SharedPreferences.getInstance(), secrets: MemorySecrets());
    await store.save(
      'guest',
      OpdsCatalog(id: 'one', name: 'One', uri: Uri.parse('https://one.test')),
      credentials: const OpdsCredentials(username: 'u', password: 'p'),
    );
    await store.save('guest', OpdsCatalog(id: 'one', name: 'Two', uri: Uri.parse('https://two.test')));
    expect(await store.credentials('guest', 'one'), isNull);
  });

  test('credentials are bound to their saved origin and refuse a mismatched catalog', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final secrets = MemorySecrets();
    final store = OpdsCatalogStore(prefs, secrets: secrets);
    await store.save(
      scope,
      originA,
      credentials: const OpdsCredentials(username: 'alice', password: 'origin-a'),
    );
    expect((jsonDecode(secrets.values[secretKey]!) as Map)['origin'], originA.uri.origin);
    await prefs.setString(catalogKey, jsonEncode([originB.toJson()]));
    expect(await OpdsCatalogStore(prefs, secrets: secrets).credentials(scope, 'one'), isNull);
    await prefs.setString(catalogKey, '[]');
    expect(await store.credentials(scope, 'one'), isNull);
  });

  test('legacy secrets without an origin are not returned', () async {
    SharedPreferences.setMockInitialValues({
      catalogKey: jsonEncode([originA.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();
    final secrets = MemorySecrets()..values[secretKey] = jsonEncode({'username': 'alice', 'password': 'unbound'});
    expect(await OpdsCatalogStore(prefs, secrets: secrets).credentials(scope, 'one'), isNull);
  });

  for (final throwsOnWrite in [false, true]) {
    final mode = throwsOnWrite ? 'throws' : 'returns false';
    test('save restores catalog cache and old credentials when preferences $mode', () async {
      final platform = _FailingPreferences();
      final prefs = await failingPreferences(platform);
      final secrets = MemorySecrets();
      final store = OpdsCatalogStore(prefs, secrets: secrets);
      await store.save(
        scope,
        originA,
        credentials: const OpdsCredentials(username: 'alice', password: 'origin-a'),
      );
      final originalJson = prefs.getString(catalogKey);
      final error = StateError('Preference save failed');
      platform.rejectWrites = !throwsOnWrite;
      platform.writeError = throwsOnWrite ? error : null;

      await expectLater(
        store.save(
          scope,
          originB,
          credentials: const OpdsCredentials(username: 'bob', password: 'origin-b'),
        ),
        throwsOnWrite ? throwsA(same(error)) : throwsA(isA<OpdsException>()),
      );
      expect(prefs.getString(catalogKey), originalJson);
      final reloaded = OpdsCatalogStore(prefs, secrets: secrets);
      expect(reloaded.load(scope).single.uri, originA.uri);
      expect((await reloaded.credentials(scope, 'one'))?.password, 'origin-a');

      // Even a different writer changing the cached catalog cannot rebind A's secret.
      platform.rejectWrites = false;
      platform.writeError = null;
      await prefs.setString(catalogKey, jsonEncode([originB.toJson()]));
      expect(await reloaded.credentials(scope, 'one'), isNull);
    });

    test('failed remove keeps catalog and credentials when preferences $mode', () async {
      final platform = _FailingPreferences();
      final prefs = await failingPreferences(platform);
      final secrets = MemorySecrets();
      final store = OpdsCatalogStore(prefs, secrets: secrets);
      await store.save(
        scope,
        originA,
        credentials: const OpdsCredentials(username: 'alice', password: 'origin-a'),
      );
      final originalJson = prefs.getString(catalogKey);
      final error = StateError('Preference removal failed');
      platform.rejectWrites = !throwsOnWrite;
      platform.writeError = throwsOnWrite ? error : null;

      await expectLater(
        store.remove(scope, 'one'),
        throwsOnWrite ? throwsA(same(error)) : throwsA(isA<OpdsException>()),
      );
      expect(prefs.getString(catalogKey), originalJson);
      final reloaded = OpdsCatalogStore(prefs, secrets: secrets);
      expect(reloaded.load(scope).single.uri, originA.uri);
      expect((await reloaded.credentials(scope, 'one'))?.password, 'origin-a');
    });

    test('failed initial save removes new catalog and secret when preferences $mode', () async {
      final platform = _FailingPreferences();
      final prefs = await failingPreferences(platform);
      final secrets = MemorySecrets();
      final store = OpdsCatalogStore(prefs, secrets: secrets);
      platform.rejectWrites = !throwsOnWrite;
      platform.writeError = throwsOnWrite ? StateError('Preference save failed') : null;
      await expectLater(
        store.save(
          scope,
          originA,
          credentials: const OpdsCredentials(username: 'alice', password: 'origin-a'),
        ),
        throwsA(anything),
      );
      expect(prefs.containsKey(catalogKey), isFalse);
      expect(store.load(scope), isEmpty);
      expect(secrets.values, isEmpty);
    });
  }

  test('rollback attempts both stores and preserves the original error if compensation fails', () async {
    final platform = _FailingPreferences();
    final prefs = await failingPreferences(platform);
    final secrets = _FailingSecrets();
    final store = OpdsCatalogStore(prefs, secrets: secrets);
    await store.save(
      scope,
      originA,
      credentials: const OpdsCredentials(username: 'alice', password: 'origin-a'),
    );
    final originalJson = prefs.getString(catalogKey);
    final originalError = StateError('Preference save failed');
    platform.writeError = originalError;
    secrets.writeError = StateError('Secret rollback failed');
    await expectLater(store.save(scope, originB), throwsA(same(originalError)));
    expect(prefs.getString(catalogKey), originalJson);
    expect(await store.credentials(scope, 'one'), isNull);
  });
}
