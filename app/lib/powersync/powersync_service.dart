import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:papyrus/data/repositories/book_repository.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/powersync/book_metadata_sync_state.dart';
import 'package:papyrus/powersync/papyrus_schema.dart';
import 'package:papyrus/powersync/powersync_book_mapper.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

typedef PowerSyncConnectorFactory = PowerSyncBackendConnector Function();
typedef LibraryDatabasePathResolver =
    Future<String> Function(LibraryDatabaseMode mode, String? profileKey, String? userId);

class SyncStateRevisionCoordinator {
  int _revision = 0;

  int beginTransportUpdate() => ++_revision;

  int observeForPendingRefresh() => _revision;

  bool isCurrent(int revision) => revision == _revision;

  void invalidate() => _revision++;
}

class PapyrusPowerSyncService implements BookRepository {
  final PowerSyncConnectorFactory connectorFactory;
  final LibraryDatabasePathResolver? pathResolver;
  final bool connectAuthenticated;

  final StreamController<List<Book>> _booksController = StreamController<List<Book>>.broadcast();
  final StreamController<SyncState> _syncStateController = StreamController<SyncState>.broadcast();
  final StreamController<BookMetadataSyncState> _bookMetadataSyncStateController =
      StreamController<BookMetadataSyncState>.broadcast();

  PowerSyncDatabase? _database;
  StreamSubscription? _booksSubscription;
  StreamSubscription? _statusSubscription;
  Future<void>? _modeOperation;
  LibraryDatabaseMode? _mode;
  String? _authenticatedUserId;
  String? _authenticatedProfileKey;
  SyncState _syncState = const SyncState();
  BookMetadataSyncState _bookMetadataSyncState = const BookMetadataSyncState();
  final SyncStateRevisionCoordinator _syncStateRevisions = SyncStateRevisionCoordinator();

  PapyrusPowerSyncService({required this.connectorFactory, this.pathResolver, this.connectAuthenticated = true});

  LibraryDatabaseMode? get mode => _mode;
  SyncState get syncState => _syncState;
  Stream<SyncState> get syncStates => _syncStateController.stream;
  BookMetadataSyncState get bookMetadataSyncState => _bookMetadataSyncState;
  Stream<BookMetadataSyncState> get bookMetadataSyncStates => _bookMetadataSyncStateController.stream;

  Future<void> activateGuest() => _switchMode(LibraryDatabaseMode.guest);

  Future<void> activateAuthenticated(String userId, {String profileKey = 'official'}) {
    return _switchMode(
      LibraryDatabaseMode.authenticated,
      authenticatedUserId: userId,
      authenticatedProfileKey: profileKey,
    );
  }

  Future<void> setOnline(bool online) async {
    await _modeOperation;
    if (_mode != LibraryDatabaseMode.authenticated) {
      throw StateError('Only authenticated libraries can connect to PowerSync');
    }
    final database = _requireDatabase();
    if (online) {
      await database.connect(connector: connectorFactory());
    } else {
      await database.disconnect();
    }
  }

  Future<void> reconnect() async {
    await _modeOperation;
    if (_mode != LibraryDatabaseMode.authenticated) {
      throw StateError('Only authenticated libraries can connect to PowerSync');
    }
    final database = _requireDatabase();
    _watchStatus(database);
    await database.disconnect();
    await database.connect(connector: connectorFactory());
  }

  Future<void> clearGuestLibrary() async {
    await _modeOperation;
    if (_mode != LibraryDatabaseMode.guest) {
      throw StateError('Only guest libraries can be cleared with clearGuestLibrary');
    }
    final database = _requireDatabase();
    await database.execute('DELETE FROM books');
    _booksController.add(const []);
    _setSyncState(const SyncState());
    _setBookMetadataSyncState(const BookMetadataSyncState());
  }

  Future<void> clearAuthenticatedCache() async {
    await _modeOperation;
    if (_mode != LibraryDatabaseMode.authenticated) {
      throw StateError('Only authenticated libraries can clear the account cache');
    }
    final userId = _authenticatedUserId;
    final profileKey = _authenticatedProfileKey ?? 'official';
    if (userId == null) {
      throw StateError('Authenticated library is missing a user id');
    }

    await _closeActive(clearAuthenticated: true);
    _mode = null;
    _authenticatedUserId = null;
    _authenticatedProfileKey = null;
    _booksController.add(const []);
    _setSyncState(const SyncState());
    _setBookMetadataSyncState(const BookMetadataSyncState());
    await activateAuthenticated(userId, profileKey: profileKey);
  }

  Future<void> deactivate({bool clearAuthenticated = true}) async {
    await _modeOperation;
    await _closeActive(clearAuthenticated: clearAuthenticated);
    _mode = null;
    _authenticatedUserId = null;
    _authenticatedProfileKey = null;
    _booksController.add(const []);
    _setSyncState(const SyncState());
    _setBookMetadataSyncState(const BookMetadataSyncState());
  }

  @override
  Stream<List<Book>> watchAll() => _booksController.stream;

  @override
  Future<Book?> getById(String id) async {
    await _modeOperation;
    final database = _requireDatabase();
    final row = await database.getOptional('SELECT * FROM books WHERE id = ?', [id]);
    return row == null ? null : PowerSyncBookMapper.fromRow(Map<String, Object?>.from(row));
  }

  @override
  Future<void> upsert(Book book) async {
    final database = _requireDatabase();
    final row = PowerSyncBookMapper.toRow(book);
    final existing = await database.getOptional('SELECT id FROM books WHERE id = ?', [book.id]);
    if (existing == null) {
      await database.execute(PowerSyncBookMapper.insertSql(), PowerSyncBookMapper.rowParameters(row));
    } else {
      await database.execute(PowerSyncBookMapper.updateSql(), PowerSyncBookMapper.updateParameters(row));
    }
    await _refreshPendingWrites();
  }

  @override
  Future<void> delete(String id) async {
    final database = _requireDatabase();
    await database.execute('DELETE FROM books WHERE id = ?', [id]);
    await _refreshPendingWrites();
  }

  Future<void> close() async {
    await _modeOperation;
    await _closeActive(clearAuthenticated: false);
    await _booksController.close();
    await _syncStateController.close();
    await _bookMetadataSyncStateController.close();
  }

  Future<void> _switchMode(LibraryDatabaseMode mode, {String? authenticatedUserId, String? authenticatedProfileKey}) {
    final previousOperation = _modeOperation;
    final operation = (() async {
      await previousOperation;
      if (_mode == mode &&
          _database != null &&
          (mode == LibraryDatabaseMode.guest ||
              (_authenticatedUserId == authenticatedUserId && _authenticatedProfileKey == authenticatedProfileKey))) {
        return;
      }
      await _performModeSwitch(mode, authenticatedUserId, authenticatedProfileKey);
    })();
    _modeOperation = operation;
    return operation.whenComplete(() {
      if (identical(_modeOperation, operation)) {
        _modeOperation = null;
      }
    });
  }

  Future<void> _performModeSwitch(
    LibraryDatabaseMode mode,
    String? authenticatedUserId,
    String? authenticatedProfileKey,
  ) async {
    await _closeActive(clearAuthenticated: false);
    _setSyncState(const SyncState());
    _setBookMetadataSyncState(const BookMetadataSyncState());
    _mode = mode;
    _authenticatedUserId = authenticatedUserId;
    _authenticatedProfileKey = authenticatedProfileKey;

    final database = PowerSyncDatabase(
      schema: mode == LibraryDatabaseMode.guest ? papyrusGuestSchema : papyrusAccountSchema,
      path: await _databasePath(mode),
    );
    await database.initialize();
    _database = database;
    _watchBooks(database);

    if (mode == LibraryDatabaseMode.authenticated && connectAuthenticated) {
      _watchStatus(database);
      await database.connect(connector: connectorFactory());
    } else {
      _setSyncState(const SyncState());
      _setBookMetadataSyncState(const BookMetadataSyncState());
    }
  }

  void _watchBooks(PowerSyncDatabase database) {
    unawaited(_booksSubscription?.cancel());
    _booksSubscription = database
        .watch('SELECT * FROM books ORDER BY added_at DESC', triggerOnTables: ['books'])
        .listen((rows) {
          _booksController.add(rows.map((row) => PowerSyncBookMapper.fromRow(Map<String, Object?>.from(row))).toList());
        });
  }

  void _watchStatus(PowerSyncDatabase database) {
    unawaited(_statusSubscription?.cancel());
    _statusSubscription = database.statusStream.listen((status) async {
      await _setStatusFromPowerSync(status);
    });
    unawaited(_setStatusFromPowerSync(database.currentStatus));
  }

  Future<void> _setStatusFromPowerSync(SyncStatus status) async {
    final revision = _syncStateRevisions.beginTransportUpdate();
    final pending = await _readPendingWrites();
    if (!_syncStateRevisions.isCurrent(revision)) return;

    _setBookMetadataSyncState(
      BookMetadataSyncState(
        pendingBookIds: pending.bookIds,
        failedBookIds: status.uploadError == null ? const {} : pending.bookIds,
      ),
    );
    _setSyncState(
      SyncState(
        connected: status.connected,
        connecting: status.connecting,
        uploading: status.uploading,
        downloading: status.downloading,
        hasPendingWrites: pending.any,
        lastSyncedAt: status.lastSyncedAt,
        uploadError: status.uploadError,
        downloadError: status.downloadError,
      ),
    );
  }

  Future<void> _refreshPendingWrites() async {
    final revision = _syncStateRevisions.observeForPendingRefresh();
    final pending = await _readPendingWrites();
    if (!_syncStateRevisions.isCurrent(revision)) return;

    final current = _syncState;
    _setBookMetadataSyncState(
      BookMetadataSyncState(
        pendingBookIds: pending.bookIds,
        failedBookIds: current.uploadError == null ? const {} : pending.bookIds,
      ),
    );
    _setSyncState(
      SyncState(
        connected: current.connected,
        connecting: current.connecting,
        uploading: current.uploading,
        downloading: current.downloading,
        hasPendingWrites: pending.any,
        lastSyncedAt: current.lastSyncedAt,
        uploadError: current.uploadError,
        downloadError: current.downloadError,
      ),
    );
  }

  Future<void> refreshBookMetadataSyncState() => _refreshPendingWrites();

  Future<_PendingWrites> _readPendingWrites() async {
    final database = _database;
    if (database == null || _mode != LibraryDatabaseMode.authenticated) {
      return const _PendingWrites();
    }
    final rows = await database.getAll('SELECT data FROM ps_crud');
    final bookIds = <String>{};
    for (final row in rows) {
      final rawData = row['data'];
      if (rawData is! String) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(rawData);
      } on FormatException {
        continue;
      }
      if (decoded case {'type': 'books', 'id': final String id}) {
        bookIds.add(id);
      }
    }
    return _PendingWrites(any: rows.isNotEmpty, bookIds: bookIds);
  }

  void _setSyncState(SyncState state) {
    _syncState = state;
    if (!_syncStateController.isClosed) {
      _syncStateController.add(state);
    }
  }

  void _setBookMetadataSyncState(BookMetadataSyncState state) {
    _bookMetadataSyncState = state;
    if (!_bookMetadataSyncStateController.isClosed) {
      _bookMetadataSyncStateController.add(state);
    }
  }

  PowerSyncDatabase _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw StateError('Library database is not active');
    }
    return database;
  }

  Future<void> _closeActive({required bool clearAuthenticated}) async {
    _syncStateRevisions.invalidate();
    await _booksSubscription?.cancel();
    await _statusSubscription?.cancel();
    _booksSubscription = null;
    _statusSubscription = null;

    final database = _database;
    final mode = _mode;
    _database = null;
    if (database == null) {
      return;
    }

    if (mode == LibraryDatabaseMode.authenticated && clearAuthenticated) {
      await database.disconnectAndClear(clearLocal: true);
    } else if (mode == LibraryDatabaseMode.authenticated) {
      await database.disconnect();
    }
    await database.close();
  }

  Future<String> _databasePath(LibraryDatabaseMode mode) async {
    final customResolver = pathResolver;
    if (customResolver != null) {
      return customResolver(mode, _authenticatedProfileKey, _authenticatedUserId);
    }

    final fileName = mode == LibraryDatabaseMode.guest
        ? 'papyrus-guest.db'
        : 'papyrus-account-${_safeFileComponent(_authenticatedProfileKey ?? 'official')}-${_safeFileComponent(_authenticatedUserId ?? 'anonymous')}.db';
    if (kIsWeb) {
      return fileName;
    }
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, fileName);
  }

  String _safeFileComponent(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  }
}

class _PendingWrites {
  final bool any;
  final Set<String> bookIds;

  const _PendingWrites({this.any = false, this.bookIds = const {}});
}
