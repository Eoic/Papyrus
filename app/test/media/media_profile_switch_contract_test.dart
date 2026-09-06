import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OPDS catalogs become available only after the target database activates', () {
    final source = File('lib/main.dart').readAsStringSync();
    final activation = source.substring(
      source.indexOf('Future<void> _applyPowerSyncAuthState()'),
      source.indexOf('void _clearAuthStateOperation'),
    );
    expect(
      activation.indexOf('_opdsCatalogs.setScope(scope.persistenceKey)'),
      greaterThan(activation.indexOf('await _powerSyncService.activateAuthenticated')),
    );
    expect(
      activation.indexOf('_opdsCatalogs.setScope(MediaStorageScope.localGuest.persistenceKey)'),
      greaterThan(activation.indexOf('await _powerSyncService.activateGuest')),
    );
  });
  test('profile switch publishes its key with the replacement repository', () {
    final source = File('lib/main.dart').readAsStringSync();
    final handler = source.substring(
      source.indexOf('void _handleSyncSettingsChanged()'),
      source.indexOf('Future<void> _refreshMediaUsage()'),
    );

    expect(handler, contains('_switchActiveSyncProfile(nextProfileKey, nextConfig)'));
    expect(handler.indexOf('_activeProfileKey = nextProfileKey'), greaterThan(handler.indexOf('_buildAuthRepository')));
  });

  test('upload processing rechecks profile transition after scope activation', () {
    final source = File('lib/main.dart').readAsStringSync();
    final processor = source.substring(
      source.indexOf('Future<void> _processMediaUploads()'),
      source.indexOf('@override\n  Widget build'),
    );

    expect(RegExp(r'_switchingSyncProfile').allMatches(processor), hasLength(greaterThanOrEqualTo(2)));
    expect(processor, contains('!identical(repository, _authRepository)'));
  });

  test('successful cover upload promotes the captured pending cover best effort', () {
    final source = File('lib/main.dart').readAsStringSync();
    final processor = source.substring(
      source.indexOf('Future<void> _processMediaUploads()'),
      source.indexOf('@override\n  Widget build'),
    );

    expect(processor, contains('uploadAndPersistCover('));
    expect(processor, contains('scope: scope'));
    expect(processor, contains('promotePendingCover: _bookImportService.promotePendingCoverFile'));
    expect(processor, contains("library: 'papyrus cover promotion'"));
  });

  test('production import delegates scoped cover persistence and queueing to the commit boundary', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final processor = mainSource.substring(
      mainSource.indexOf('Future<void> _processMediaUploads()'),
      mainSource.indexOf('@override\n  Widget build'),
    );
    expect(processor, contains('readPendingCover: _bookImportService.getPendingCoverFile'));

    final importSource = File('lib/widgets/add_book/book_import_results_sheet.dart').readAsStringSync();
    final commitStart = importSource.indexOf('static Future<Book> _commitResult(');
    final commit = importSource.substring(
      commitStart,
      importSource.indexOf('/// Opens the processing step', commitStart),
    );
    expect(commit, contains('BookImportSession.fromContext(context).commit(result, sourceFilename)'));
    final session = File('lib/services/book_import_session.dart').readAsStringSync();
    expect(session, contains('final scope = authenticated ? queue.activeScope : null;'));
    expect(session, contains("throw StateError('Cannot import account media without an active media storage scope')"));
    expect(session, contains('storePendingCover: importService.storePendingCoverFile'));
    expect(session, contains('storeGuestCover: importService.storeGuestCoverFile'));
    expect(session, contains('deletePendingCover: importService.deletePendingCoverFile'));
    expect(session, contains('deleteGuestCover: importService.deleteGuestCoverFile'));
    expect(session, contains('final repository = dataStore.requireBookRepository();'));
    expect(session, contains('dataStore.addBookToRepositoryAndWait(repository, book)'));
    expect(session, contains('dataStore.deleteBookFromRepositoryAndWait(repository, id)'));
    expect(session, contains('enqueueImportedBookMedia: queue.enqueueImportedBookMedia'));
    expect(session, contains('isLibraryContextCurrent: isCurrent'));
    expect(session, contains('dataStore.isBookRepositoryCurrent(repository)'));
    expect(session, contains('queue.activeScope == scope'));
    expect(session, contains('accountScope: scope'));
    expect(session, isNot(contains('bytesToDataUri')));
  });

  test('import commit guard prevents repeat commits and disables mutable actions', () {
    final source = File('lib/widgets/add_book/book_import_results_sheet.dart').readAsStringSync();
    final addStart = source.indexOf('Future<void> _addReadyBooks()');
    final add = source.substring(addStart, source.indexOf('Future<void> _retryCommit', addStart));

    expect(add, contains('if (!_canAdd) return;'));
    expect(add, contains('_isAdding = true'));
    expect(add, contains('_isAdding = false'));
    expect(source, contains('canClose: !_isClosing && !_isAdding'));
    expect(source, contains('onPressed: _canAdd ? () => unawaited(_addReadyBooks()) : null'));
    expect(source, contains('onRemove: _isClosing || _isAdding ? null'));
  });
}
