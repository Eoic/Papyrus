import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/opds/opds_catalog_store.dart';
import 'package:papyrus/opds/opds_catalogs.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_store_test.dart' show MemorySecrets;

class DelayedSecrets extends MemorySecrets {
  Completer<String?>? nextRead;
  @override
  Future<String?> read(String key) {
    final pending = nextRead;
    nextRead = null;
    return pending?.future ?? super.read(key);
  }
}

void main() {
  test('credential lookups are invalidated by edits and scope changes', () async {
    SharedPreferences.setMockInitialValues({});
    final secrets = DelayedSecrets();
    final catalogs = OpdsCatalogs(OpdsCatalogStore(await SharedPreferences.getInstance(), secrets: secrets))
      ..setScope('guest');
    await catalogs.save(
      OpdsCatalog(id: 'c', name: 'One', uri: Uri.parse('https://one.test')),
      credentials: const OpdsCredentials(username: 'one', password: 'secret'),
    );
    final oldSecret = secrets.values.values.single;
    final pending = secrets.nextRead = Completer<String?>();
    final lookup = catalogs.credentials('c');
    final expectation = expectLater(lookup, throwsA(isA<OpdsCancelled>()));
    await catalogs.save(
      OpdsCatalog(id: 'c', name: 'Two', uri: Uri.parse('https://two.test')),
      credentials: const OpdsCredentials(username: 'two', password: 'secret'),
    );
    pending.complete(oldSecret);
    await expectation;
    final pendingScope = secrets.nextRead = Completer<String?>();
    final scopeLookup = catalogs.credentials('c');
    final scopeExpectation = expectLater(scopeLookup, throwsA(isA<OpdsCancelled>()));
    catalogs.setScope('another-account');
    pendingScope.complete(null);
    await scopeExpectation;
    catalogs.dispose();
  });
}
