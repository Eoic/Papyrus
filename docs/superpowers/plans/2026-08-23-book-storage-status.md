# Per-book Account and Device Status Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show server-confirmed per-book account state, visually mute digital books missing from the current device, and download a missing file only when reading starts.

**Architecture:** Extend the PowerSync boundary with an authoritative per-book metadata snapshot, then combine it with the existing media queue, `fileMediaId`, and an existence-only local-file probe in a focused controller. Cards consume resolved states; the details page owns download-and-read behavior. A generation guard prevents stale asynchronous global sync calculations from overwriting newer status.

**Tech Stack:** Flutter/Dart, Provider, PowerSync SQLite, OPFS Web Worker, native filesystem storage, Material 3, `flutter_test`.

**Note:** Commit steps are intentionally omitted because the user requested uncommitted work.

---

### Task 1: Make PowerSync status current and expose per-book metadata state

**Files:**
- Create: `app/lib/powersync/book_metadata_sync_state.dart`
- Modify: `app/lib/powersync/powersync_service.dart`
- Modify: `app/lib/powersync/papyrus_powersync_connector.dart`
- Modify: `app/lib/main.dart`
- Test: `app/test/powersync/powersync_service_test.dart`
- Test: `app/test/powersync/papyrus_powersync_connector_test.dart`

- [ ] **Step 1: Write failing tests for metadata acknowledgement and stale status suppression**

Add connector tests that build `CrudEntry` values for two books, assert that accepted book IDs are reported after `transaction.complete`, and assert that a definitive 4xx upload rejection reports the affected IDs. Add a service-level test seam for delayed pending-write reads and assert that an older `connected: false` calculation cannot replace a later `connected: true` calculation.

```dart
expect(acknowledgedBookIds, {'book-1', 'book-2'});
expect(failedBookIds, {'book-1', 'book-2'});
expect(service.syncState.connected, isTrue);
```

- [ ] **Step 2: Run the focused tests and confirm the new expectations fail**

```bash
cd app
flutter test test/powersync/papyrus_powersync_connector_test.dart
flutter test test/powersync/powersync_service_test.dart
```

Expected: failures because per-book callbacks/snapshots and superseded-status protection do not exist.

- [ ] **Step 3: Add the metadata snapshot model**

```dart
class BookMetadataSyncState {
  const BookMetadataSyncState({this.pendingBookIds = const {}, this.failedBookIds = const {}});

  final Set<String> pendingBookIds;
  final Set<String> failedBookIds;

  bool isPending(String bookId) => pendingBookIds.contains(bookId);
  bool hasFailed(String bookId) => failedBookIds.contains(bookId);
}
```

- [ ] **Step 4: Report transaction outcomes from the connector**

Preserve the existing media-upload trigger and add book-specific callbacks. Collect only entries whose `table == 'books'`. Invoke acknowledgement only after the server batch succeeds and `transaction.complete()` finishes. Report only non-retryable client errors as definitive; authentication, timeout, rate-limit, connection, and 5xx failures remain pending.

```dart
final Future<void> Function(Set<String> bookIds)? onBooksAcknowledged;
final void Function(Set<String> bookIds, Object error)? onBooksRejected;
```

- [ ] **Step 5: Derive pending IDs inside `PapyrusPowerSyncService`**

Read `SELECT data FROM ps_crud`, decode each JSON payload, and collect `id` where `type == 'books'`. Refresh after local `upsert`/`delete`, on PowerSync status changes, and after connector acknowledgement. Publish a broadcast snapshot and keep the latest value available synchronously.

```dart
BookMetadataSyncState get bookMetadataSyncState => _bookMetadataSyncState;
Stream<BookMetadataSyncState> get bookMetadataSyncStates => _bookMetadataSyncStateController.stream;
```

Clear a book's recorded failure when a new local mutation is made or the book is acknowledged.

- [ ] **Step 6: Prevent stale global status publication**

Increment a generation before each asynchronous status conversion. After the pending-write query completes, discard the result unless it still owns the newest generation.

```dart
final generation = ++_syncStatusGeneration;
final pending = await _hasPendingWrites();
if (generation != _syncStatusGeneration) return;
```

- [ ] **Step 7: Wire connector callbacks in `main.dart`**

Pass acknowledged/rejected IDs back into the already-created PowerSync service and retain `_processMediaUploads` as the general successful-upload callback.

- [ ] **Step 8: Run focused tests**

Run the two commands from Step 2. Expected: all tests pass.

---

### Task 2: Add an existence-only local book-file API

**Files:**
- Modify: `app/lib/services/book_import_service.dart`
- Modify: `app/lib/services/book_import_service_stub.dart`
- Modify: `app/web/book_worker.js`
- Test: `app/test/services/book_import_service_test.dart`
- Create: `app/test/services/book_import_service_web_test.dart`

- [ ] **Step 1: Write failing native and web contract tests**

Test that `hasBookFile(bookId)` is false before storage, true after storage/import, and false after deletion. The web test must run under Chrome and exercise the worker without returning file bytes.

```dart
expect(await service.hasBookFile('book-1'), isFalse);
await service.storeBookFile('book-1', 'epub', bytes);
expect(await service.hasBookFile('book-1'), isTrue);
```

- [ ] **Step 2: Run both focused tests and confirm failure**

```bash
cd app
flutter test test/services/book_import_service_test.dart
flutter test --platform chrome test/services/book_import_service_web_test.dart
```

Expected: compile failure because `hasBookFile` and the worker action do not exist.

- [ ] **Step 3: Implement native existence checks**

In the native/stub service, reuse the books directory and match the same safe book-ID basename used by `getBookFile`, but never call `readAsBytes`.

```dart
Future<bool> hasBookFile(String bookId) async {
  final booksDir = await _getBooksDirectory();
  return booksDir.listSync().whereType<File>().any(
    (file) => p.basenameWithoutExtension(file.path) == bookId,
  );
}
```

- [ ] **Step 4: Implement the OPFS worker action**

Add `hasFile` to the documented worker protocol. `opfsHasFile(bookId)` checks the books directory and known extensions with `getFileHandle(..., create: false)` but never calls `getFile()` or `arrayBuffer()`. The Dart web service sends `{type: 'hasFile', bookId}` and parses a boolean `exists` response with the same timeout/error cleanup used by other worker requests.

- [ ] **Step 5: Run both focused tests**

Run the commands from Step 2. Expected: native and Chrome tests pass.

---

### Task 3: Combine account and device states in one controller

**Files:**
- Create: `app/lib/providers/book_storage_status_controller.dart`
- Modify: `app/lib/main.dart`
- Test: `app/test/providers/book_storage_status_controller_test.dart`

- [ ] **Step 1: Write the failing status truth-table tests**

Cover authenticated physical and digital books, guest books, pending metadata, definitive metadata failure, pending/failed book-file tasks, missing `fileMediaId`, and server-confirmed saved state. Also test that device status starts at `checking`, probes once, caches the result, and can be invalidated.

```dart
expect(controller.accountStatusFor(digitalBook), BookAccountStatus.syncing);
expect(controller.deviceStatusFor(digitalBook), BookDeviceStatus.checking);
await controller.ensureDeviceStatus(digitalBook);
expect(controller.deviceStatusFor(digitalBook), BookDeviceStatus.missing);
```

- [ ] **Step 2: Run the controller test and confirm failure**

```bash
cd app
flutter test test/providers/book_storage_status_controller_test.dart
```

- [ ] **Step 3: Implement the controller**

```dart
enum BookAccountStatus { syncing, saved, failed }
enum BookDeviceStatus { checking, available, missing }

class BookStorageStatusController extends ChangeNotifier {
  BookAccountStatus? accountStatusFor(Book book);
  BookDeviceStatus? deviceStatusFor(Book book);
  Future<void> ensureDeviceStatus(Book book);
  void invalidateDeviceStatus(String bookId);
  void clearDeviceStatuses();
}
```

Account-state precedence is failure, then pending, then saved. Digital `saved` additionally requires a non-empty `fileMediaId`; cover tasks never participate. A retryable media task is pending even when it carries an informational error message.

Subscribe to `AuthProvider`, `MediaUploadQueue`, and the PowerSync metadata-state stream. Cache local probes by book ID and deduplicate in-flight probes. A probe exception leaves the state at `checking` instead of falsely returning `missing`.

- [ ] **Step 4: Wire lifecycle in `main.dart`**

Create the controller after auth, media queue, import service, and PowerSync service. Provide it through `ChangeNotifierProvider.value`, clear device state on profile/account scope changes, and dispose it before its dependencies.

- [ ] **Step 5: Run the focused controller test**

Run the command from Step 2. Expected: all truth-table and probe tests pass.

---

### Task 4: Render account badges and missing-local tint on book cards

**Files:**
- Modify: `app/lib/widgets/library/book_card.dart`
- Modify: `app/lib/pages/library_page.dart`
- Test: `app/test/widgets/library/book_card_test.dart`
- Test: `app/test/pages/library_page_test.dart`

- [ ] **Step 1: Write failing widget tests for every presentation state**

Test `Saved`, `Syncing…`, and `Sync failed` icon/text badges; no badge for guest/null account state; desaturated/tinted presentation only for `BookDeviceStatus.missing`; normal presentation for `checking`, `available`, and physical books; and semantic labels for account and device state.

- [ ] **Step 2: Run focused card and library tests and confirm failure**

```bash
cd app
flutter test test/widgets/library/book_card_test.dart
flutter test test/pages/library_page_test.dart
```

- [ ] **Step 3: Extend `BookCard` with resolved status inputs**

```dart
final BookAccountStatus? accountStatus;
final BookDeviceStatus? deviceStatus;
```

Place an informational account badge at the cover's bottom-right while retaining the format badge at bottom-left. Use Material theme tokens, icon plus label, a desktop tooltip, and no separate tap handler.

For missing digital files, apply a grayscale `ColorFiltered` treatment to the cover and a neutral themed card surface. Keep title/author contrast unchanged. Extend the card's explicit `Semantics` wrapper to announce the statuses without duplicating descendant semantics.

- [ ] **Step 4: Resolve state in `LibraryPage`**

Watch the optional `BookStorageStatusController`, request a deduplicated local probe for each visible ordinary book, and pass current values into `BookCard`. Acquisition placeholder/job cards remain unchanged.

- [ ] **Step 5: Run focused card and library tests**

Run the commands from Step 2. Expected: all pass with no overflow at existing mobile and desktop card sizes.

---

### Task 5: Download only from the details-page reading action

**Files:**
- Modify: `app/lib/pages/book_details_page.dart`
- Modify: `app/lib/widgets/book_details/book_header.dart`
- Modify: `app/lib/widgets/book_details/book_action_buttons.dart`
- Test: `app/test/pages/book_details_reader_test.dart`
- Test: `app/test/widgets/book_details/book_action_buttons_test.dart`

- [ ] **Step 1: Write failing reading-state tests**

Cover local EPUB opening immediately without download, saved remote EPUB showing `Download and read`, disabled downloading state, successful cache-and-open, inline failure with a `Try again` action, disabled pending/failed sync states, and unchanged physical/unsupported behavior.

- [ ] **Step 2: Run the focused tests and confirm failure**

```bash
cd app
flutter test test/pages/book_details_reader_test.dart
flutter test test/widgets/book_details/book_action_buttons_test.dart
```

- [ ] **Step 3: Add an explicit reading-action presentation model**

```dart
class BookReadingAction {
  const BookReadingAction({required this.label, required this.icon, this.enabled = true, this.loading = false});
  final String label;
  final IconData icon;
  final bool enabled;
  final bool loading;
}
```

Pass it through `BookHeader` to `BookActionButtons`. Render a compact progress indicator when loading and preserve 48dp touch sizing.

- [ ] **Step 4: Track details-page availability and download state**

Probe device state after the book loads. Replace the current unconditional `fileMediaId != null` preparation branch with:

1. open immediately when local file exists;
2. call `MediaCacheService.ensureBookFileCached` only for `Download and read`;
3. invalidate/re-probe the controller after the successful write;
4. open the reader after caching;
5. display a sanitized inline error and retry action on failure.

Do not start a download when the card or details page opens. Use an indeterminate progress indicator because the current media API returns a complete byte buffer rather than progress events.

- [ ] **Step 5: Run focused details and action-button tests**

Run the commands from Step 2. Expected: all pass.

---

### Task 6: Format and verify the integrated behavior

- [ ] **Step 1: Format changed Dart files**

```bash
cd app
dart format \
  lib/main.dart \
  lib/powersync \
  lib/providers/book_storage_status_controller.dart \
  lib/services/book_import_service.dart \
  lib/services/book_import_service_stub.dart \
  lib/pages/book_details_page.dart \
  lib/pages/library_page.dart \
  lib/widgets/book_details \
  lib/widgets/library/book_card.dart \
  test/powersync \
  test/providers/book_storage_status_controller_test.dart \
  test/services/book_import_service_test.dart \
  test/services/book_import_service_web_test.dart \
  test/pages/book_details_reader_test.dart \
  test/pages/library_page_test.dart \
  test/widgets/book_details/book_action_buttons_test.dart \
  test/widgets/library/book_card_test.dart
```

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run focused sync, storage, card, and details suites**

```bash
flutter test test/powersync test/providers/book_storage_status_controller_test.dart test/services/book_import_service_test.dart test/widgets/library/book_card_test.dart test/pages/book_details_reader_test.dart test/widgets/book_details/book_action_buttons_test.dart
flutter test --platform chrome test/services/book_import_service_web_test.dart
```

- [ ] **Step 4: Run broader affected widget suites**

```bash
flutter test test/widgets/add_book test/pages/library_page_test.dart test/pages/profile_storage_sync_test.dart
```

- [ ] **Step 5: Build web and check whitespace**

```bash
flutter build web --debug --dart-define-from-file=.dart_defines
git diff --check
```

Expected: web build succeeds and `git diff --check` produces no output.
