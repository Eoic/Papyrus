import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:papyrus/media/media_models.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/powersync/book_metadata_sync_state.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/providers/auth_provider.dart';

enum BookAccountStatus { saved, syncing, failed }

enum BookDeviceStatus { checking, available, missing }

typedef LocalBookFileChecker = Future<bool> Function(String bookId);

BookAccountStatus? resolveBookAccountStatus({
  required Book book,
  required bool isAccountLibrary,
  bool metadataPending = false,
  bool metadataFailed = false,
  List<MediaUploadTask> mediaTasks = const [],
}) {
  if (!isAccountLibrary) return null;

  final bookFileTasks = mediaTasks.where((task) => task.bookId == book.id && task.kind == MediaKind.bookFile);
  if (metadataFailed || bookFileTasks.any((task) => task.status == MediaUploadTaskStatus.failed)) {
    return BookAccountStatus.failed;
  }
  if (metadataPending || bookFileTasks.isNotEmpty || (!book.isPhysical && book.fileMediaId == null)) {
    return BookAccountStatus.syncing;
  }
  return BookAccountStatus.saved;
}

class BookStorageStatusController extends ChangeNotifier {
  final AuthProvider? _authProvider;
  final PapyrusPowerSyncService? _powerSyncService;
  final MediaUploadQueue? _mediaUploadQueue;
  final LocalBookFileChecker _hasBookFile;

  final Map<String, BookDeviceStatus> _deviceStatuses = {};
  final Map<String, Future<void>> _deviceChecks = {};
  StreamSubscription<BookMetadataSyncState>? _metadataSubscription;
  BookMetadataSyncState _metadataState = const BookMetadataSyncState();

  BookStorageStatusController({
    required AuthProvider authProvider,
    required PapyrusPowerSyncService powerSyncService,
    required MediaUploadQueue mediaUploadQueue,
    required LocalBookFileChecker hasBookFile,
  }) : _authProvider = authProvider,
       _powerSyncService = powerSyncService,
       _mediaUploadQueue = mediaUploadQueue,
       _hasBookFile = hasBookFile,
       _metadataState = powerSyncService.bookMetadataSyncState {
    authProvider.addListener(_notify);
    mediaUploadQueue.addListener(_notify);
    _metadataSubscription = powerSyncService.bookMetadataSyncStates.listen((state) {
      _metadataState = state;
      notifyListeners();
    });
  }

  @visibleForTesting
  BookStorageStatusController.detached({required LocalBookFileChecker hasBookFile})
    : _authProvider = null,
      _powerSyncService = null,
      _mediaUploadQueue = null,
      _hasBookFile = hasBookFile;

  BookAccountStatus? accountStatus(Book book) {
    final authProvider = _authProvider;
    final powerSyncService = _powerSyncService;
    final mediaUploadQueue = _mediaUploadQueue;
    final isAccountLibrary =
        authProvider != null &&
        powerSyncService != null &&
        authProvider.isSignedIn &&
        !authProvider.isOfflineMode &&
        powerSyncService.mode == LibraryDatabaseMode.authenticated;
    return resolveBookAccountStatus(
      book: book,
      isAccountLibrary: isAccountLibrary,
      metadataPending: _metadataState.isPending(book.id),
      metadataFailed: _metadataState.hasFailed(book.id),
      mediaTasks: mediaUploadQueue?.pendingTasks ?? const [],
    );
  }

  BookDeviceStatus? deviceStatus(Book book) {
    if (book.isPhysical) return null;
    return _deviceStatuses[book.id] ?? BookDeviceStatus.checking;
  }

  Future<void> ensureDeviceStatus(Book book) {
    if (book.isPhysical || _deviceStatuses.containsKey(book.id)) {
      return Future<void>.value();
    }
    return _deviceChecks.putIfAbsent(book.id, () async {
      try {
        final exists = await _hasBookFile(book.id);
        _deviceStatuses[book.id] = exists ? BookDeviceStatus.available : BookDeviceStatus.missing;
        notifyListeners();
      } catch (error) {
        debugPrint('Could not check local file for ${book.id}: $error');
        _deviceStatuses[book.id] = BookDeviceStatus.missing;
        notifyListeners();
      } finally {
        _deviceChecks.remove(book.id);
      }
    });
  }

  void markAvailable(String bookId) {
    if (_deviceStatuses[bookId] == BookDeviceStatus.available) return;
    _deviceStatuses[bookId] = BookDeviceStatus.available;
    notifyListeners();
  }

  void invalidate(String bookId) {
    if (_deviceStatuses.remove(bookId) != null) {
      notifyListeners();
    }
  }

  void _notify() => notifyListeners();

  @override
  void dispose() {
    _authProvider?.removeListener(_notify);
    _mediaUploadQueue?.removeListener(_notify);
    unawaited(_metadataSubscription?.cancel());
    super.dispose();
  }
}
