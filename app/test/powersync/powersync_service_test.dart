import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:path/path.dart' as path;
import 'package:powersync/powersync.dart';

class OfflineConnector extends PowerSyncBackendConnector {
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async => null;

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {}
}

Book _book(String id) {
  return Book(id: id, title: 'Persistent guest book', author: 'Author', addedAt: DateTime.utc(2026, 1, 1));
}

void main() {
  late Directory directory;

  test('pending refresh does not supersede a transport status event', () {
    final revisions = SyncStateRevisionCoordinator();
    final transportRevision = revisions.beginTransportUpdate();

    expect(revisions.observeForPendingRefresh(), transportRevision);
    expect(revisions.isCurrent(transportRevision), isTrue);

    revisions.beginTransportUpdate();
    expect(revisions.isCurrent(transportRevision), isFalse);
  });

  test('late subscribers receive the current sync state', () async {
    final updates = StreamController<SyncState>.broadcast(sync: true);
    addTearDown(updates.close);
    var current = const SyncState();

    current = const SyncState(connected: true);
    updates.add(current);

    final received = await streamWithCurrentValue(currentValue: () => current, updates: updates.stream).first;

    expect(received.connected, isTrue);
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('papyrus-powersync-test-');
  });

  tearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  PapyrusPowerSyncService service() {
    return PapyrusPowerSyncService(
      connectorFactory: OfflineConnector.new,
      connectAuthenticated: false,
      pathResolver: (mode, profileKey, userId) async => path.join(
        directory.path,
        mode == LibraryDatabaseMode.guest ? 'guest.db' : 'account-${profileKey ?? 'default'}-${userId ?? 'none'}.db',
      ),
    );
  }

  test('guest books persist when the service is reopened', () async {
    final first = service();
    await first.activateGuest();
    await first.upsert(_book('guest-book'));
    await first.close();

    final second = service();
    await second.activateGuest();

    expect((await second.getById('guest-book'))?.title, 'Persistent guest book');
    await second.close();
  });

  test('getById waits for database activation', () async {
    final allowPathResolution = Completer<void>();
    final first = PapyrusPowerSyncService(
      connectorFactory: OfflineConnector.new,
      connectAuthenticated: false,
      pathResolver: (mode, profileKey, userId) async {
        await allowPathResolution.future;
        return path.join(directory.path, 'delayed-guest.db');
      },
    );

    final activation = first.activateGuest();
    final lookup = first.getById('missing-book');
    allowPathResolution.complete();

    await activation;
    expect(await lookup, isNull);
    await first.close();
  });

  test('activation emits the database snapshot instead of a synthetic empty snapshot', () async {
    final allowPathResolution = Completer<void>();
    final firstSnapshot = Completer<List<Book>>();
    final first = PapyrusPowerSyncService(
      connectorFactory: OfflineConnector.new,
      connectAuthenticated: false,
      pathResolver: (mode, profileKey, userId) async {
        await allowPathResolution.future;
        return path.join(directory.path, 'snapshot-guest.db');
      },
    );
    final subscription = first.watchAll().listen((books) {
      if (!firstSnapshot.isCompleted) firstSnapshot.complete(books);
    });

    final activation = first.activateGuest();
    await Future<void>.delayed(Duration.zero);

    expect(firstSnapshot.isCompleted, isFalse);
    allowPathResolution.complete();
    await activation;
    expect(await firstSnapshot.future, isEmpty);

    await subscription.cancel();
    await first.close();
  });

  test('authenticated books are cleared on deactivation', () async {
    final first = service();
    await first.activateAuthenticated('user-one');
    await first.upsert(_book('account-book'));
    await first.deactivate();
    await first.close();

    final second = service();
    await second.activateAuthenticated('user-one');

    expect(await second.getById('account-book'), isNull);
    await second.close();
  });

  test('authenticated writes expose the affected book as pending', () async {
    final first = service();
    await first.activateAuthenticated('user-one');

    await first.upsert(_book('account-book'));

    expect(first.bookMetadataSyncState.pendingBookIds, contains('account-book'));
    await first.close();
  });

  test('clearGuestLibrary removes only guest-local books', () async {
    final first = service();
    await first.activateGuest();
    await first.upsert(_book('guest-book'));

    await first.clearGuestLibrary();

    expect(await first.getById('guest-book'), isNull);
    await first.close();
  });

  test('clearAuthenticatedCache removes local account cache for the active account', () async {
    final first = service();
    await first.activateAuthenticated('user-one');
    await first.upsert(_book('account-book'));

    await first.clearAuthenticatedCache();

    expect(first.mode, LibraryDatabaseMode.authenticated);
    expect(await first.getById('account-book'), isNull);
    await first.close();
  });

  test('reconnect requires an authenticated database', () async {
    final first = service();
    await first.activateGuest();

    expect(first.reconnect(), throwsStateError);
    await first.close();
  });

  test('authenticated cache is isolated by sync server profile', () async {
    final first = service();
    await first.activateAuthenticated('user-one', profileKey: 'official');
    await first.upsert(_book('official-book'));

    await first.activateAuthenticated('user-one', profileKey: 'custom-local');

    expect(await first.getById('official-book'), isNull);
    await first.upsert(_book('custom-book'));

    await first.activateAuthenticated('user-one', profileKey: 'official');

    expect((await first.getById('official-book'))?.title, 'Persistent guest book');
    expect(await first.getById('custom-book'), isNull);
    await first.close();
  });
}
