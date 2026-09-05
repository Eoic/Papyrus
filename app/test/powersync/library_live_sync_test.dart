import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/auth/token_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/powersync/papyrus_powersync_connector.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:uuid/uuid.dart';

class _MemoryRefreshStorage implements RefreshTokenStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String refreshToken) async => token = refreshToken;
  @override
  Future<void> delete() async => token = null;
}

Future<void> _eventually(Future<bool> Function() condition, String description) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Timed out: $description');
}

void main() {
  test(
    'live devices converge after offline restart and isolate another account',
    () async {
      final directory = await Directory.systemTemp.createTemp('papyrus-live-library-');
      final client = http.Client();
      final config = PapyrusApiConfig(serverBaseUri: Uri.parse('http://localhost:8080'));
      AuthRepository auth() => AuthRepository(
        apiClient: AuthApiClient(config: config, httpClient: client),
        tokenStore: TokenStore(_MemoryRefreshStorage()),
      );
      final firstAuth = auth();
      final secondAuth = auth();
      final otherAuth = auth();
      final suffix = const Uuid().v4();
      final email = 'sync-check-$suffix@example.com';
      final password = 'SyncCheck-$suffix';
      final owner = await firstAuth.register(
        email: email,
        password: password,
        displayName: 'Sync validation',
        clientType: 'desktop',
      );
      await secondAuth.login(email: email, password: password, clientType: 'desktop');
      final other = await otherAuth.register(
        email: 'other-$email',
        password: password,
        displayName: 'Isolation validation',
        clientType: 'desktop',
      );

      PapyrusPowerSyncService device(String name, AuthRepository repository, {bool connect = true}) {
        late PapyrusPowerSyncService result;
        result = PapyrusPowerSyncService(
          connectAuthenticated: connect,
          connectorFactory: () => PapyrusPowerSyncConnector(
            authRepository: repository,
            config: config,
            onUploadComplete: () => result.refreshBookMetadataSyncState(),
          ),
          pathResolver: (_, _, _) async => '${directory.path}/$name.db',
        );
        return result;
      }

      final first = device('one', firstAuth);
      var second = device('two', secondAuth);
      final outsider = device('other', otherAuth);
      final bookId = const Uuid().v4();
      final shelfId = const Uuid().v4();
      final tagId = const Uuid().v4();
      final noteId = const Uuid().v4();
      final annotationId = const Uuid().v4();
      final now = DateTime.now().toUtc();
      try {
        await first.activateAuthenticated(owner.user.userId);
        await second.activateAuthenticated(owner.user.userId);
        await outsider.activateAuthenticated(other.user.userId);
        await first.upsert(
          Book(
            id: bookId,
            title: 'Live book',
            author: 'Author',
            addedAt: now,
            publicationDate: DateTime.utc(2020),
            isPhysical: true,
            physicalLocation: 'Room A',
          ),
        );
        await first.shelves.upsert(Shelf(id: shelfId, name: 'Shelf', createdAt: now, updatedAt: now));
        await first.tags.upsert(Tag(id: tagId, name: 'Topic', colorHex: '#123456', createdAt: now));
        await first.notes.upsert(Note(id: noteId, bookId: bookId, title: 'Note', content: 'Original', createdAt: now));
        await first.annotations.upsert(
          Annotation(
            id: annotationId,
            bookId: bookId,
            selectedText: 'Quote',
            location: const BookLocation(pageNumber: 3),
            note: 'Attached',
            createdAt: now,
          ),
        );
        await first.memberships.updateMemberships(bookIds: {bookId}, shelfIds: [shelfId], tagIds: [tagId]);

        await _eventually(
          () async => await second.bookTags.getById('$bookId:$tagId') != null,
          'all domain rows reach device two',
        );
        expect((await second.shelves.getById(shelfId))?.name, 'Shelf');
        expect((await second.tags.getById(tagId))?.name, 'Topic');
        expect((await second.annotations.getById(annotationId))?.note, 'Attached');
        expect((await second.getById(bookId))?.publicationDate, DateTime.utc(2020));
        expect(await second.bookShelves.getById('$bookId:$shelfId'), isNotNull);

        await second.setOnline(false);
        final baselineNote = (await second.notes.getById(noteId))!;
        final baselineBook = (await second.getById(bookId))!;
        await second.notes.upsert(baselineNote.copyWith(content: 'Offline edit'), previous: baselineNote);
        await second.scopedBooks.update(baselineBook.copyWith(physicalLocation: 'Room B'), previous: baselineBook);
        await second.close();
        second = device('two', secondAuth, connect: false);
        await second.activateAuthenticated(owner.user.userId);
        expect((await second.notes.getById(noteId))?.content, 'Offline edit');
        final currentNote = (await first.notes.getById(noteId))!;
        final currentBook = (await first.getById(bookId))!;
        await first.notes.upsert(currentNote.copyWith(title: 'Remote title'), previous: currentNote);
        await first.scopedBooks.update(currentBook.copyWith(lentTo: 'Reader'), previous: currentBook);
        await _eventually(() async => !first.syncState.hasPendingWrites, 'online writes upload');
        await second.setOnline(true);
        await _eventually(
          () async => (await first.notes.getById(noteId))?.content == 'Offline edit',
          'offline writes upload after restart',
        );
        await _eventually(
          () async => (await second.notes.getById(noteId))?.title == 'Remote title',
          'different fields merge',
        );
        expect((await first.getById(bookId))?.physicalLocation, 'Room B');
        await _eventually(() async => (await second.getById(bookId))?.lentTo == 'Reader', 'promoted book fields merge');

        await second.setOnline(false);
        final offlineNote = (await second.notes.getById(noteId))!;
        await second.notes.upsert(offlineNote.copyWith(content: 'Last accepted'), previous: offlineNote);
        final onlineNote = (await first.notes.getById(noteId))!;
        await first.notes.upsert(onlineNote.copyWith(content: 'First accepted'), previous: onlineNote);
        final beforeClear = (await first.getById(bookId))!;
        await first.scopedBooks.update(beforeClear.copyWith(clearLentTo: true), previous: beforeClear);
        await _eventually(() async => !first.syncState.hasPendingWrites, 'first competing edit uploads');
        await second.setOnline(true);
        await _eventually(
          () async => (await first.notes.getById(noteId))?.content == 'Last accepted',
          'same-field conflicts follow server acceptance order',
        );
        await _eventually(() async => (await second.getById(bookId))?.lentTo == null, 'explicit null clears remotely');

        final topic = (await first.tags.getById(tagId))!;
        await first.tags.upsert(topic.copyWith(name: 'Renamed topic'), previous: topic);
        final annotation = (await first.annotations.getById(annotationId))!;
        await first.annotations.upsert(annotation.copyWith(note: 'Edited attachment'), previous: annotation);
        await first.memberships.updateMemberships(bookIds: {bookId}, shelfIds: [], previousShelfIds: {shelfId});
        await _eventually(
          () async =>
              await second.bookShelves.getById('$bookId:$shelfId') == null &&
              (await second.tags.getById(tagId))?.name == 'Renamed topic' &&
              (await second.annotations.getById(annotationId))?.note == 'Edited attachment',
          'membership removal and topic/annotation edits propagate',
        );

        await _eventually(() async => outsider.syncState.lastSyncedAt != null, 'other account checkpoint');
        expect(await outsider.getById(bookId), isNull);
        expect(await outsider.notes.getById(noteId), isNull);
        expect(await outsider.shelves.getById(shelfId), isNull);
        expect(await outsider.tags.getById(tagId), isNull);
        expect(await outsider.annotations.getById(annotationId), isNull);
        expect(await outsider.bookShelves.getById('$bookId:$shelfId'), isNull);
        expect(await outsider.bookTags.getById('$bookId:$tagId'), isNull);

        await second.setOnline(false);
        final stale = (await second.notes.getById(noteId))!;
        await second.notes.upsert(stale.copyWith(content: 'Stale after deletion'), previous: stale);
        await first.delete(bookId);
        await _eventually(() async => !first.syncState.hasPendingWrites, 'book deletion uploads');
        await second.setOnline(true);
        await _eventually(
          () async => await second.getById(bookId) == null && await second.notes.getById(noteId) == null,
          'deletion wins against offline edit',
        );
        expect(await second.annotations.getById(annotationId), isNull);
        expect(await second.bookShelves.getById('$bookId:$shelfId'), isNull);
        expect(await second.bookTags.getById('$bookId:$tagId'), isNull);
        await _eventually(() async => !second.syncState.hasPendingWrites, 'stale write queue drains');
        await first.shelves.delete(shelfId);
        await first.tags.delete(tagId);
        await _eventually(() async => !first.syncState.hasPendingWrites, 'cleanup uploads');
      } finally {
        await first.close();
        await second.close();
        await outsider.close();
        for (final repository in [firstAuth, otherAuth]) {
          final response = await client.delete(
            config.endpoint('/users/me'),
            headers: {
              'Authorization': 'Bearer ${repository.tokenStore.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'password': password}),
          );
          expect(response.statusCode, 204);
        }
        client.close();
        await directory.delete(recursive: true);
      }
    },
    skip: Platform.environment['PAPYRUS_LIVE_SYNC'] != '1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
