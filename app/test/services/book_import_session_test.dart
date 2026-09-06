import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/auth/auth_models.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/repositories/book_repository.dart';
import 'package:papyrus/media/media_storage_scope.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/services/book_import_session.dart';
import 'package:papyrus/services/book_import_service_stub.dart';

class _Repository extends Fake implements BookRepository {}

class _DataStore extends Fake implements DataStore {
  final repository = _Repository();
  @override
  BookRepository requireBookRepository() => repository;
  @override
  bool isBookRepositoryCurrent(BookRepository repository) => identical(this.repository, repository);
}

class _Auth extends Fake implements AuthProvider {
  @override
  bool get isSignedIn => true;
  @override
  bool get isOfflineMode => false;
  @override
  PapyrusUser get user => PapyrusUser.fromJson({'user_id': 'bob'});
}

class _Queue extends Fake implements MediaUploadQueue {
  @override
  MediaStorageScope get activeScope => MediaStorageScope(profileKey: 'official', userId: 'alice');
}

class _Database extends Fake implements PapyrusPowerSyncService {
  _Database(this.mode);
  @override
  final LibraryDatabaseMode mode;
}

class _Importer extends Fake implements BookImportService {}

void main() {
  test('cannot capture the previous account media scope during account activation', () {
    expect(
      () => BookImportSession.capture(
        dataStore: _DataStore(),
        queue: _Queue(),
        importService: _Importer(),
        authProvider: _Auth(),
        powerSyncService: _Database(LibraryDatabaseMode.authenticated),
      ),
      throwsStateError,
    );
  });
  test('cannot capture a guest database while an authenticated account is activating', () {
    expect(
      () => BookImportSession.capture(
        dataStore: _DataStore(),
        queue: _Queue(),
        importService: _Importer(),
        authProvider: _Auth(),
        powerSyncService: _Database(LibraryDatabaseMode.guest),
      ),
      throwsStateError,
    );
  });
}
