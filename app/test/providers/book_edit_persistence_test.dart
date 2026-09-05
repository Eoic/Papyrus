import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/book_edit_provider.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';

import '../helpers/test_helpers.dart';
import '../powersync/powersync_service_test.dart' show OfflineConnector;

void main() {
  late Directory directory;
  late PapyrusPowerSyncService service;
  late DataStore store;
  late BookEditProvider editor;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('papyrus-editor-');
    service = PapyrusPowerSyncService(
      connectorFactory: OfflineConnector.new,
      connectAuthenticated: false,
      pathResolver: (mode, profile, user) async =>
          '${directory.path}/${mode == LibraryDatabaseMode.guest ? 'guest' : '$profile-$user'}.db',
    );
    await service.activateGuest();
    await service.upsert(buildTestBook(id: 'book', title: 'Original', author: 'Original author'));
    store = DataStore(bookRepository: service);
    editor = BookEditProvider()..setDataStore(store);
    await editor.loadBook('book');
  });

  tearDown(() async {
    editor.dispose();
    await store.disposeBookRepository();
    await service.close();
    await directory.delete(recursive: true);
  });

  test('saving a stale editor preserves an unrelated remote field', () async {
    final original = editor.originalBook!;
    editor.updateTitle('Edited title');
    await service.scopedBooks.update(original.copyWith(author: 'Remote author'), previous: original);

    expect(await editor.save(), isTrue);
    final saved = await service.getById('book');
    expect(saved?.title, 'Edited title');
    expect(saved?.author, 'Remote author');
  });

  test('an editor opened in guest scope cannot save into another account', () async {
    editor.updateTitle('Stale edit');
    await service.activateAuthenticated('other-account');
    await service.upsert(buildTestBook(id: 'book', title: 'Other account'));

    expect(await editor.save(), isFalse);
    expect(editor.error, contains('Failed to save book'));
    expect((await service.getById('book'))?.title, 'Other account');
    await service.activateGuest();
    expect((await service.getById('book'))?.title, 'Original');
  });
}
