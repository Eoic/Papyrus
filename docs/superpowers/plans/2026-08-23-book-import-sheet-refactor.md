# Book Import Sheet Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the 1,151-line book import sheet into a controller and focused presentation widgets without changing import behavior.

**Architecture:** A `ChangeNotifier` controller owns the existing async state machine and exposes read-only state plus commands. `BookImportSheet` retains provider/modal integration and UI-only side effects, focused section widgets render each phase, and one shared item card centralizes repeated presentation.

**Tech Stack:** Flutter 3.44, Dart 3.12, Provider, `flutter_test`

---

## File Structure

- Create `app/lib/widgets/add_book/book_import_controller.dart`: import state, async pipeline, retries, cleanup, and close results.
- Create `app/lib/widgets/add_book/book_import_item_card.dart`: shared processing/summary item presentation.
- Create `app/lib/widgets/add_book/book_import_sheet_sections.dart`: selecting, processing, and summary layouts.
- Modify `app/lib/widgets/add_book/book_import_sheet.dart`: public modal wiring and controller-backed composition only.
- Create `app/test/widgets/add_book/book_import_controller_test.dart`: controller state and lifecycle tests.
- Create `app/test/widgets/add_book/book_import_sheet_test.dart`: behavior-preserving widget coverage.

### Task 1: Extract and test the controller

**Files:**
- Create: `app/lib/widgets/add_book/book_import_controller.dart`
- Create: `app/test/widgets/add_book/book_import_controller_test.dart`

- [ ] **Step 1: Write failing controller tests**

Create injected fakes and cover success, parse retry, commit-only retry, close cleanup, cleanup deduplication, and one-shot completion through this API:

```dart
final controller = BookImportController(
  pickFiles: () async => [SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1]))],
  processor: (bytes, filename) async => result,
  committer: (result, filename) async => book,
  deleteBookFile: deletedBookIds.add,
  onCompleted: completions.add,
);

await controller.browse();
controller.startImport();
await pumpEventQueue();

expect(controller.phase, BookImportPhase.summary);
expect(controller.items.single.status, BookImportBatchStatus.added);
expect(completions, hasLength(1));
```

For close cleanup, hold processing with a `Completer<BookImportResult>`, call `requestClose()`, complete processing, and assert that close waits and deletes the temporary result.

- [ ] **Step 2: Run the tests and verify they fail**

```bash
cd app
flutter test test/widgets/add_book/book_import_controller_test.dart
```

Expected: compilation fails because the controller does not exist.

- [ ] **Step 3: Implement the controller contract**

```dart
typedef DigitalBookFilePicker = Future<List<SelectedBookFile>> Function();
typedef BookImportProcessor = Future<BookImportResult> Function(Uint8List bytes, String filename);
typedef ImportedBookFileDeleter = Future<void> Function(String bookId);
typedef ImportedBookCommitter = Future<Book> Function(BookImportResult result, String sourceFilename);

enum BookImportPhase { selecting, processing, summary }
enum BookImportCloseResult { closed, processingCleanupFailed, cleanupFailed }
enum BookImportRemoveResult { removed, ignored, cleanupFailed }

class BookImportController extends ChangeNotifier {
  BookImportController({
    required DigitalBookFilePicker pickFiles,
    required BookImportProcessor processor,
    required ImportedBookFileDeleter deleteBookFile,
    required ImportedBookCommitter committer,
    ValueChanged<List<Book>>? onCompleted,
  });

  BookImportPhase get phase;
  List<SelectedBookFile> get files;
  List<SelectedBookFile> get readableFiles;
  List<BookImportBatchItem> get items;
  bool get isPicking;
  String? get pickerError;
  bool get isClosing;
  bool get allSettled;
  bool get anyProcessing;
  int get successCount;
  int get failureCount;

  Future<void> browse();
  void removeFile(SelectedBookFile file);
  void clearSelection();
  void startImport();
  Future<void> retryItem(String id);
  Future<BookImportRemoveResult> removeItem(String id);
  Future<BookImportCloseResult> requestClose();
}
```

Move the existing orchestration without changing ordering or parallel behavior. Preserve processing-token validation, in-flight processing and cleanup maps, cleaned IDs, and close-future deduplication. Replace `mounted` with `_disposed`; call `notifyListeners()` only while active.

- [ ] **Step 4: Run controller tests**

Run the Step 2 command. Expected: all controller tests pass.

### Task 2: Extract shared item presentation

**Files:**
- Create: `app/lib/widgets/add_book/book_import_item_card.dart`
- Create: `app/test/widgets/add_book/book_import_sheet_test.dart`

- [ ] **Step 1: Write failing item-card widget tests**

Cover processing, added, and failed states, including action visibility:

```dart
await tester.pumpWidget(MaterialApp(
  home: Scaffold(
    body: BookImportItemCard(
      item: failedItem,
      presentation: BookImportItemCardPresentation.progress,
      onRetry: () {},
      onRemove: () {},
    ),
  ),
));
expect(find.text('Retry'), findsOneWidget);
expect(find.byTooltip('Remove failed.epub'), findsOneWidget);
```

- [ ] **Step 2: Run the focused test and verify failure**

```bash
cd app
flutter test test/widgets/add_book/book_import_sheet_test.dart
```

Expected: compilation fails because the shared card does not exist.

- [ ] **Step 3: Implement the shared card**

```dart
enum BookImportItemCardPresentation { progress, summary }

class BookImportItemCard extends StatelessWidget {
  const BookImportItemCard({
    super.key,
    required this.item,
    required this.presentation,
    this.onRetry,
    this.onRemove,
  });

  final BookImportBatchItem item;
  final BookImportItemCardPresentation presentation;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;
}
```

Move the existing display title, subtitle, cover, fallback icon, status, and actions here. Preserve keys, animation durations, colors, spacing, tooltips, max lines, and labels. Use the enum only for genuine progress/summary differences.

- [ ] **Step 4: Run the focused widget test**

Run the Step 2 command. Expected: item-card tests pass.

### Task 3: Extract phases and rewire the sheet

**Files:**
- Create: `app/lib/widgets/add_book/book_import_sheet_sections.dart`
- Modify: `app/lib/widgets/add_book/book_import_sheet.dart`
- Modify: `app/test/widgets/add_book/book_import_sheet_test.dart`

- [ ] **Step 1: Add failing full-sheet tests**

Pump the sheet with injected callbacks and cover browse, import, summary, picker failure, retry, cleanup-failure snackbar, close, and the existing expanded browse layout:

```dart
await tester.tap(find.text('Browse files'));
await tester.pump();
expect(find.text('1 file selected'), findsOneWidget);
await tester.tap(find.text('Import 1 book'));
await tester.pumpAndSettle();
expect(find.text('Import complete'), findsOneWidget);
expect(find.text('1 book added'), findsOneWidget);
```

- [ ] **Step 2: Run the sheet test before rewiring**

Run the Task 2 test command. Expected: the new extraction-specific assertions fail.

- [ ] **Step 3: Move phase UI into focused widgets**

Create `BookImportSelectingSection`, `BookImportProcessingSection`, and `BookImportSummarySection`. Pass immutable values and callbacks; do not add async state. Keep the browse area and selected-file card private to this file, preserving `mainAxisSize: MainAxisSize.max`. Use `BookImportItemCard` for processing and summary lists.

- [ ] **Step 4: Rewire `BookImportSheet`**

Keep `show()` and `_commitResult()` unchanged. Create the controller with closures that reference the current widget callbacks:

```dart
late final BookImportController _controller;

@override
void initState() {
  super.initState();
  _controller = BookImportController(
    pickFiles: () => widget.pickFiles(),
    processor: (bytes, filename) => widget.processor(bytes, filename),
    deleteBookFile: (bookId) => widget.deleteBookFile(bookId),
    committer: (result, filename) => widget.committer(result, filename),
    onCompleted: (books) => widget.onCompleted?.call(books),
  );
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

Render with `ListenableBuilder` and switch on `controller.phase`. Convert controller close/remove results into the existing snackbars and call `widget.onClose()` only for `BookImportCloseResult.closed`. Re-export callback typedefs from the controller file for source compatibility.

- [ ] **Step 5: Run controller and sheet tests**

```bash
cd app
flutter test test/widgets/add_book/book_import_controller_test.dart test/widgets/add_book/book_import_sheet_test.dart
```

Expected: all tests pass.

### Task 4: Format and verify

**Files:** Verify all files above.

- [ ] **Step 1: Format changed Dart files**

```bash
cd app
dart format lib/widgets/add_book/book_import_controller.dart lib/widgets/add_book/book_import_item_card.dart lib/widgets/add_book/book_import_sheet_sections.dart lib/widgets/add_book/book_import_sheet.dart test/widgets/add_book/book_import_controller_test.dart test/widgets/add_book/book_import_sheet_test.dart
```

Expected: formatting completes without errors.

- [ ] **Step 2: Run static analysis**

```bash
cd app
flutter analyze lib/widgets/add_book/book_import_controller.dart lib/widgets/add_book/book_import_item_card.dart lib/widgets/add_book/book_import_sheet_sections.dart lib/widgets/add_book/book_import_sheet.dart test/widgets/add_book/book_import_controller_test.dart test/widgets/add_book/book_import_sheet_test.dart
```

Expected: no issues found.

- [ ] **Step 3: Run the add-book widget suite**

```bash
cd app
flutter test test/widgets/add_book
```

Expected: all tests pass.

- [ ] **Step 4: Inspect the final diff**

```bash
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors; only planned files, the uncommitted plan, and the pre-existing browse-area change appear. Leave implementation changes uncommitted for review.
