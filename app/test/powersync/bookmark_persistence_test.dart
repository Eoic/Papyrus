import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/powersync/library_row_mapper.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';

import '../helpers/test_helpers.dart';
import 'powersync_service_test.dart' show OfflineConnector;

void main() {
  test('bookmark fields round-trip through SQLite values', () {
    final bookmark = Bookmark(
      id: 'mark',
      bookId: 'book',
      position: 0.25,
      pageNumber: 25,
      chapterTitle: 'Chapter',
      note: 'Remember',
      colorHex: '#2196F3',
      createdAt: DateTime.utc(2026),
    );
    expect(bookmarkRowMapper.fromRow(bookmarkRowMapper.toRow(bookmark)).toJson(), bookmark.toJson());
  });

  for (final guest in [true, false]) {
    test('bookmarks persist, merge, clear, react, and isolate in ${guest ? 'guest' : 'account'} storage', () async {
      final directory = await Directory.systemTemp.createTemp('papyrus-bookmarks-');
      PapyrusPowerSyncService open() => PapyrusPowerSyncService(
        connectorFactory: OfflineConnector.new,
        connectAuthenticated: false,
        pathResolver: (mode, profile, user) async =>
            '${directory.path}/${mode == LibraryDatabaseMode.guest ? 'guest' : '$profile-$user'}.db',
      );
      Future<void> activate(PapyrusPowerSyncService db) => guest ? db.activateGuest() : db.activateAuthenticated('one');
      var db = open();
      await activate(db);
      await db.upsert(buildTestBook(id: 'book', isPhysical: true));
      final bookmark = Bookmark(
        id: 'mark',
        bookId: 'book',
        position: 0.2,
        pageNumber: 20,
        chapterTitle: 'Chapter',
        note: 'Remember',
        createdAt: DateTime.utc(2026),
      );
      await db.bookmarks.upsert(bookmark);
      await db.watchLibrary().firstWhere((snapshot) => snapshot.bookmarks.isNotEmpty);
      final store = DataStore(bookRepository: db);
      await store.waitUntilLoaded();
      expect(store.bookmarks.single.note, 'Remember');
      await db.bookmarks.upsert(bookmark.copyWith(colorHex: '#2196F3'), previous: bookmark);
      await db.bookmarks.upsert(bookmark.copyWith(note: null, chapterTitle: null), previous: bookmark);
      await db.watchLibrary().firstWhere((snapshot) => snapshot.bookmarks.single.note == null);
      expect((await db.bookmarks.getById('mark'))?.colorHex, '#2196F3');
      expect((await db.bookmarks.getById('mark'))?.chapterTitle, isNull);
      await store.disposeBookRepository();
      await db.close();
      db = open();
      await activate(db);
      expect((await db.bookmarks.getById('mark'))?.note, isNull);
      expect((await db.bookmarks.getById('mark'))?.pageNumber, 20);
      expect(db.syncState.hasPendingWrites, !guest);
      final old = db.bookmarks;
      await db.activateAuthenticated('other');
      expect(await db.bookmarks.getById('mark'), isNull);
      await expectLater(old.upsert(bookmark), throwsStateError);
      await activate(db);
      await db.delete('book');
      expect(await db.bookmarks.getById('mark'), isNull);
      await db.close();
      await directory.delete(recursive: true);
    });
  }
}
