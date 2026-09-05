import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/book_shelf_relation.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/powersync/papyrus_schema.dart';
import 'package:powersync/powersync.dart';

import 'powersync_service_test.dart' show OfflineConnector;

void main() {
  late Directory directory;
  final now = DateTime.utc(2026, 9, 5);

  PapyrusPowerSyncService service() => PapyrusPowerSyncService(
    connectorFactory: OfflineConnector.new,
    connectAuthenticated: false,
    pathResolver: (mode, profile, user) async =>
        '${directory.path}/${mode == LibraryDatabaseMode.guest ? 'guest' : '$profile-$user'}.db',
  );

  setUp(() async => directory = await Directory.systemTemp.createTemp('papyrus-library-'));
  tearDown(() async => directory.delete(recursive: true));

  test('schema expansion keeps queued legacy books and promotes local metadata once', () async {
    final dbPath = '${directory.path}/official-one.db';
    final legacy = PowerSyncDatabase(
      path: dbPath,
      schema: const Schema([
        Table('books', [
          Column.text('title'),
          Column.text('author'),
          Column.text('added_at'),
          Column.text('custom_metadata'),
        ]),
      ]),
    );
    await legacy.initialize();
    await legacy.execute('INSERT INTO books (id, title, author, added_at, custom_metadata) VALUES (?, ?, ?, ?, ?)', [
      'book',
      'Legacy',
      'Author',
      now.toIso8601String(),
      jsonEncode({
        'is_physical': true,
        'file_format': 'epub',
        'physical_location': 'Old room',
        'custom_metadata': {'preserved': 'yes'},
      }),
    ]);
    final before = await legacy.getAll('SELECT data FROM ps_crud');
    await legacy.close();
    final upgraded = service();
    await upgraded.activateAuthenticated('one');
    final book = (await upgraded.getById('book'))!;
    expect(book.isPhysical, isTrue);
    expect(book.fileFormat, BookFormat.epub);
    expect(book.customMetadata, {'preserved': 'yes'});
    await upgraded.scopedBooks.update(book.copyWith(clearPhysicalLocation: true), previous: book);
    await upgraded.close();
    final reopened = service();
    await reopened.activateAuthenticated('one');
    expect((await reopened.getById('book'))?.physicalLocation, isNull);
    await reopened.close();
    final inspect = PowerSyncDatabase(path: dbPath, schema: papyrusAccountSchema);
    await inspect.initialize();
    final after = await inspect.getAll('SELECT data FROM ps_crud');
    expect(after.map((row) => row['data']), containsAll(before.map((row) => row['data'])));
    await inspect.close();
  });

  test('membership edits are atomic and preserve concurrent additions', () async {
    final db = service();
    await db.activateGuest();
    await db.upsert(Book(id: 'book', title: 'Book', author: 'Author', addedAt: now));
    for (final id in ['a', 'b', 'c']) {
      await db.shelves.upsert(Shelf(id: id, name: id, createdAt: now, updatedAt: now));
    }
    await db.memberships.updateMemberships(bookIds: {'book'}, shelfIds: ['a', 'b']);
    await db.memberships.updateMemberships(bookIds: {'book'}, shelfIds: ['c'], previousShelfIds: {'a'});
    expect(await db.bookShelves.getById('book:a'), isNull);
    expect(await db.bookShelves.getById('book:b'), isNotNull);
    expect(await db.bookShelves.getById('book:c'), isNotNull);
    await expectLater(db.memberships.updateMemberships(bookIds: {'book'}, shelfIds: ['missing']), throwsStateError);
    expect(await db.bookShelves.getById('book:b'), isNotNull);
    expect(await db.bookShelves.getById('book:c'), isNotNull);
    await db.close();
  });

  test('legacy migration skips invalid values and preserves an explicit cleared column', () async {
    final dbPath = '${directory.path}/official-one.db';
    final cached = PowerSyncDatabase(path: dbPath, schema: papyrusAccountSchema);
    await cached.initialize();
    await cached.execute(
      'INSERT INTO books (id, title, author, added_at, physical_location, custom_metadata) VALUES (?, ?, ?, ?, ?, ?)',
      [
        'book',
        'Book',
        'Author',
        now.toIso8601String(),
        null,
        jsonEncode({
          'physical_location': 'Stale room',
          'file_size': 'invalid',
          'series_number': 'not a number',
          'custom_metadata': {'preserved': true},
        }),
      ],
    );
    final count = (await cached.getAll('SELECT data FROM ps_crud')).length;
    await cached.close();
    final upgraded = service();
    await upgraded.activateAuthenticated('one');
    final book = (await upgraded.getById('book'))!;
    expect(book.physicalLocation, isNull);
    expect(book.fileSize, isNull);
    expect(book.seriesNumber, isNull);
    expect(book.customMetadata, {'preserved': true});
    await upgraded.close();
    final inspect = PowerSyncDatabase(path: dbPath, schema: papyrusAccountSchema);
    await inspect.initialize();
    expect((await inspect.getAll('SELECT data FROM ps_crud')).length, count);
    await inspect.close();
  });

  test('shelf deletion reparents children and hierarchy cycles are rejected', () async {
    final db = service();
    await db.activateGuest();
    final parent = Shelf(id: 'parent', name: 'Parent', createdAt: now, updatedAt: now);
    await db.shelves.upsert(parent);
    await db.shelves.upsert(Shelf(id: 'child', name: 'Child', parentShelfId: 'parent', createdAt: now, updatedAt: now));
    await expectLater(db.shelves.upsert(parent.copyWith(parentShelfId: 'child')), throwsStateError);
    await db.shelves.delete('parent');
    expect((await db.shelves.getById('child'))?.parentShelfId, isNull);
    await db.close();
  });

  test('all library records persist offline and book deletion removes dependents', () async {
    final first = service();
    await first.activateGuest();
    await first.upsert(Book(id: 'book', title: 'Book', author: 'Author', addedAt: now));
    await first.shelves.upsert(Shelf(id: 'shelf', name: 'Shelf', createdAt: now, updatedAt: now));
    await first.tags.upsert(Tag(id: 'tag', name: 'Topic', colorHex: '#123456', createdAt: now));
    await first.notes.upsert(Note(id: 'note', bookId: 'book', title: 'Note', content: 'Content', createdAt: now));
    await first.annotations.upsert(
      Annotation(
        id: 'annotation',
        bookId: 'book',
        selectedText: 'Quote',
        location: const BookLocation(pageNumber: 5),
        createdAt: now,
      ),
    );
    await first.bookShelves.upsert(BookShelfRelation(bookId: 'book', shelfId: 'shelf', addedAt: now));
    await first.close();

    final second = service();
    await second.activateGuest();
    expect((await second.shelves.getById('shelf'))?.name, 'Shelf');
    expect((await second.tags.getById('tag'))?.name, 'Topic');
    expect((await second.notes.getById('note'))?.content, 'Content');
    expect((await second.annotations.getById('annotation'))?.location.pageNumber, 5);
    expect(await second.bookShelves.getById('book:shelf'), isNotNull);
    await second.delete('book');
    expect(await second.notes.getById('note'), isNull);
    expect(await second.annotations.getById('annotation'), isNull);
    expect(await second.bookShelves.getById('book:shelf'), isNull);
    expect(await second.shelves.getById('shelf'), isNotNull);
    await second.close();
  });

  test('stale editor updates only changed fields and can clear nullable values', () async {
    final db = service();
    await db.activateGuest();
    final original = Shelf(id: 'shelf', name: 'Old', description: 'Description', createdAt: now, updatedAt: now);
    await db.shelves.upsert(original);
    await db.shelves.upsert(original.copyWith(name: 'Remote'));
    await db.shelves.upsert(original.copyWith(clearDescription: true), previous: original);
    final result = await db.shelves.getById('shelf');
    expect(result?.name, 'Remote');
    expect(result?.description, isNull);
    await db.close();
  });

  test('guest and account libraries remain separate and old scope handles cannot write', () async {
    final db = service();
    await db.activateGuest();
    final guestShelves = db.shelves;
    await guestShelves.upsert(Shelf(id: 'guest', name: 'Guest', createdAt: now, updatedAt: now));
    await db.activateAuthenticated('one');
    expect(await db.shelves.getById('guest'), isNull);
    await expectLater(guestShelves.delete('guest'), throwsStateError);
    await db.shelves.upsert(Shelf(id: 'account', name: 'Account', createdAt: now, updatedAt: now));
    expect(db.syncState.hasPendingWrites, isTrue);
    await db.activateAuthenticated('two');
    expect(await db.shelves.getById('account'), isNull);
    await db.activateGuest();
    expect(await db.shelves.getById('guest'), isNotNull);
    await db.close();
  });
}
