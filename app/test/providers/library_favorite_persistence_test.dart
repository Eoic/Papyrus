import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';

import '../helpers/test_helpers.dart';
import '../powersync/powersync_service_test.dart' show OfflineConnector;

void main() {
  test('favorites persist, follow remote changes, and remain scoped', () async {
    final directory = await Directory.systemTemp.createTemp('papyrus-favorites-');
    PapyrusPowerSyncService open() => PapyrusPowerSyncService(
      connectorFactory: OfflineConnector.new,
      connectAuthenticated: false,
      pathResolver: (mode, profile, user) async =>
          '${directory.path}/${mode == LibraryDatabaseMode.guest ? 'guest' : '$profile-$user'}.db',
    );
    var service = open();
    await service.activateGuest();
    await service.upsert(buildTestBook(id: 'book'));
    await service.watchLibrary().firstWhere((snapshot) => snapshot.books.isNotEmpty);
    final store = DataStore(bookRepository: service);
    await store.waitUntilLoaded();
    final provider = LibraryProvider(dataStore: store);
    final shelfProvider = LibraryProvider(favoriteDelegate: provider);
    await shelfProvider.toggleFavorite('book', false);
    expect((await service.getById('book'))?.isFavorite, isTrue);
    await service.watchLibrary().firstWhere((snapshot) => snapshot.books.single.isFavorite);
    final current = (await service.getById('book'))!;
    await service.scopedBooks.update(current.copyWith(isFavorite: false), previous: current);
    await service.watchLibrary().firstWhere((snapshot) => snapshot.books.single.isFavorite == false);
    await Future<void>.delayed(Duration.zero);
    expect(provider.isBookFavorite('book', true), isFalse);
    await provider.toggleFavorite('book', false);
    await service.watchLibrary().firstWhere((snapshot) => snapshot.books.single.isFavorite);
    await service.activateAuthenticated('other');
    await service.upsert(buildTestBook(id: 'book'));
    await service.watchLibrary().firstWhere((snapshot) => snapshot.books.isNotEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(provider.isBookFavorite('book', false), isFalse);
    shelfProvider.dispose();
    provider.dispose();
    await store.disposeBookRepository();
    await service.close();
    service = open();
    await service.activateGuest();
    expect((await service.getById('book'))?.isFavorite, isTrue);
    await service.close();
    await directory.delete(recursive: true);
  });
}
