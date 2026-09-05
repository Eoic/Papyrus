import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/providers/book_details_provider.dart';
import 'package:papyrus/providers/bookmarks_provider.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';

import '../helpers/test_helpers.dart';
import '../powersync/powersync_service_test.dart' show OfflineConnector;

void main() {
  late Directory directory;
  late PapyrusPowerSyncService service;
  late DataStore store;
  late BookmarksProvider bookmarks;
  late BookDetailsProvider details;
  final original = Bookmark(
    id: 'bookmark',
    bookId: 'book',
    position: 0.25,
    pageNumber: 30,
    chapterTitle: 'Chapter',
    note: 'Original note',
    createdAt: DateTime.utc(2026),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('papyrus-bookmark-edit-');
    service = PapyrusPowerSyncService(
      connectorFactory: OfflineConnector.new,
      connectAuthenticated: false,
      pathResolver: (mode, profile, user) async =>
          '${directory.path}/${mode == LibraryDatabaseMode.guest ? 'guest' : '$profile-$user'}.db',
    );
    await service.activateGuest();
    await service.upsert(buildTestBook(id: 'book'));
    await service.bookmarks.upsert(original);
    store = DataStore(bookRepository: service);
    bookmarks = BookmarksProvider()..attach(store);
    details = BookDetailsProvider()..setDataStore(store);
  });

  tearDown(() async {
    bookmarks.dispose();
    details.dispose();
    await store.disposeBookRepository();
    await service.close();
    await directory.delete(recursive: true);
  });

  test('note edit preserves remotely changed color and location', () async {
    final repository = store.libraryRepository!.bookmarks;
    await service.bookmarks.upsert(original.copyWith(colorHex: '#2196F3', pageNumber: 40));
    await bookmarks.updateBookmarkNote(original.id, null, previous: original, repository: repository);
    final saved = await service.bookmarks.getById(original.id);
    expect(saved!.note, isNull);
    expect(saved.colorHex, '#2196F3');
    expect(saved.pageNumber, 40);
  });

  test('details color edit preserves a remotely changed note', () async {
    final repository = store.libraryRepository!.bookmarks;
    await service.bookmarks.upsert(original.copyWith(note: 'Remote note'));
    await details.updateBookmarkColor(original.id, '#2196F3', previous: original, repository: repository);
    final saved = await service.bookmarks.getById(original.id);
    expect(saved!.note, 'Remote note');
    expect(saved.colorHex, '#2196F3');
  });

  test('bookmark edits, creation and deletion cannot cross a profile switch', () async {
    final repository = store.libraryRepository!.bookmarks;
    await service.activateAuthenticated('other-account');
    await service.upsert(buildTestBook(id: 'book'));
    await service.bookmarks.upsert(original.copyWith(note: 'Other account note'));
    await expectLater(
      bookmarks.updateBookmarkNote(original.id, 'Stale note', previous: original, repository: repository),
      throwsStateError,
    );
    await expectLater(
      details.updateBookmarkColor(original.id, '#2196F3', previous: original, repository: repository),
      throwsStateError,
    );
    await expectLater(
      details.addBookmark(original.copyWith(id: 'new-bookmark'), repository: repository),
      throwsStateError,
    );
    await expectLater(bookmarks.deleteBookmark(original.id, repository: repository), throwsStateError);
    expect((await service.bookmarks.getById(original.id))!.note, 'Other account note');
    expect(await service.bookmarks.getById('new-bookmark'), isNull);
  });
}
