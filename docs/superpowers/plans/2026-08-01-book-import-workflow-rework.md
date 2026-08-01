# Book Import Workflow Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-file, in-place digital import flow with independent fixed-layout selection and results sheets that support confirmed batch imports, retry, removal, cleanup, and partial commit failures, while moving physical import actions into a fixed footer.

**Architecture:** `AddBookChoiceSheet` returns a method choice and opens a new route only after the choice route completes. A workflow-local immutable batch item models every selected file and its processing or commit state. Three add-book sheets share a layout-only scaffold with a fixed header, expanded body, and fixed footer; the results sheet injects processing, deletion, and commit callbacks for deterministic widget tests while production callbacks use the existing import and commit services.

**Tech Stack:** Flutter, Dart, Provider, `file_picker`, existing `BookImportService` and `BookImportCommitService`, `flutter_test`.

---

## File Structure

- Create `app/lib/widgets/add_book/book_import_batch_item.dart` — selected-file value and immutable per-row state transitions.
- Create `app/lib/widgets/add_book/add_book_sheet_scaffold.dart` — fixed handle/header, expanded body, and fixed safe-area footer.
- Create `app/lib/widgets/add_book/digital_book_import_sheet.dart` — multi-file selection, confirmation, and pre-processing removal.
- Create `app/lib/widgets/add_book/book_import_results_sheet.dart` — processing, retry, removal, cleanup, commit, and results UI.
- Modify `app/lib/widgets/add_book/add_book_choice_sheet.dart` — selection-only routing.
- Modify `app/lib/widgets/add_book/add_physical_book_sheet.dart` — shared fixed layout and footer actions.
- Delete `app/lib/widgets/add_book/import_book_sheet.dart` after all production references move.
- Create `app/test/widgets/add_book/book_import_batch_item_test.dart`.
- Create `app/test/widgets/add_book/add_book_sheet_scaffold_test.dart`.
- Create `app/test/widgets/add_book/digital_book_import_sheet_test.dart`.
- Create `app/test/widgets/add_book/book_import_results_sheet_test.dart`.
- Modify `app/test/widgets/add_book/add_book_sheets_test.dart` — method routing and physical-sheet integration.
- Modify `app/test/media/media_profile_switch_contract_test.dart` — point commit-boundary contracts at the results sheet.

### Task 1: Model Batch Files and Row State

**Files:**
- Create: `app/lib/widgets/add_book/book_import_batch_item.dart`
- Test: `app/test/widgets/add_book/book_import_batch_item_test.dart`

- [ ] **Step 1: Write failing transition tests**

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/services/book_import_result.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';

void main() {
  const result = BookImportResult(
    bookId: 'book-1',
    title: 'Frankenstein',
    author: 'Mary Shelley',
    fileSize: 4,
    fileHash: 'hash',
    fileExtension: 'epub',
  );

  test('processing transitions preserve identity and clear stale errors', () {
    final file = SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1, 2, 3, 4]));
    final failed = BookImportBatchItem.queued(id: 'row-1', file: file)
        .startProcessing()
        .processingFailed('Could not process this file.');
    final ready = failed.startProcessing().processingSucceeded(result);

    expect(ready.id, 'row-1');
    expect(ready.status, BookImportBatchStatus.ready);
    expect(ready.result, same(result));
    expect(ready.errorMessage, isNull);
  });

  test('commit failure keeps the parsed result for retry', () {
    final file = SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1]));
    final failed = BookImportBatchItem.queued(id: 'row-1', file: file)
        .startProcessing()
        .processingSucceeded(result)
        .startAdding()
        .commitFailed('Could not add this book.');

    expect(failed.status, BookImportBatchStatus.commitFailed);
    expect(failed.result, same(result));
    expect(failed.canRetry, isTrue);
  });
}
```

- [ ] **Step 2: Run the model test and verify RED**

Run: `cd app && flutter test test/widgets/add_book/book_import_batch_item_test.dart`

Expected: compilation fails because `book_import_batch_item.dart` and its types do not exist.

- [ ] **Step 3: Implement the immutable batch types**

```dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:papyrus/services/book_import_result.dart';

@immutable
class SelectedBookFile {
  const SelectedBookFile({required this.name, required this.bytes});

  final String name;
  final Uint8List? bytes;
}

enum BookImportBatchStatus {
  queued,
  processing,
  ready,
  processingFailed,
  adding,
  added,
  commitFailed,
}

@immutable
class BookImportBatchItem {
  const BookImportBatchItem._({
    required this.id,
    required this.file,
    required this.status,
    this.result,
    this.errorMessage,
  });

  factory BookImportBatchItem.queued({required String id, required SelectedBookFile file}) {
    return BookImportBatchItem._(id: id, file: file, status: BookImportBatchStatus.queued);
  }

  final String id;
  final SelectedBookFile file;
  final BookImportBatchStatus status;
  final BookImportResult? result;
  final String? errorMessage;

  bool get canRetry =>
      status == BookImportBatchStatus.processingFailed || status == BookImportBatchStatus.commitFailed;
  bool get isSettled => status != BookImportBatchStatus.queued && status != BookImportBatchStatus.processing;
  bool get hasTemporaryFile => result != null && status != BookImportBatchStatus.added;

  BookImportBatchItem startProcessing() => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.processing,
  );

  BookImportBatchItem processingSucceeded(BookImportResult value) => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.ready,
    result: value,
  );

  BookImportBatchItem processingFailed(String message) => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.processingFailed,
    errorMessage: message,
  );

  BookImportBatchItem startAdding() => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.adding,
    result: result,
  );

  BookImportBatchItem added() => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.added,
    result: result,
  );

  BookImportBatchItem commitFailed(String message) => BookImportBatchItem._(
    id: id,
    file: file,
    status: BookImportBatchStatus.commitFailed,
    result: result,
    errorMessage: message,
  );
}
```

- [ ] **Step 4: Run the model test and verify GREEN**

Run: `cd app && flutter test test/widgets/add_book/book_import_batch_item_test.dart`

Expected: all batch-item tests pass.

- [ ] **Step 5: Commit the model**

```bash
git add app/lib/widgets/add_book/book_import_batch_item.dart app/test/widgets/add_book/book_import_batch_item_test.dart
git commit -m "PPR-26: Model batch book imports"
```

### Task 2: Add the Fixed Add-Book Sheet Layout and Migrate Physical Entry

**Files:**
- Create: `app/lib/widgets/add_book/add_book_sheet_scaffold.dart`
- Create: `app/test/widgets/add_book/add_book_sheet_scaffold_test.dart`
- Modify: `app/lib/widgets/add_book/add_physical_book_sheet.dart`
- Modify: `app/test/widgets/add_book/add_book_sheets_test.dart`

- [ ] **Step 1: Write failing fixed-layout tests**

```dart
Future<void> openPhysicalBookSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => AddPhysicalBookSheet.show(context),
            child: const Text('Open physical import'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open physical import'));
  await tester.pumpAndSettle();
}

testWidgets('header and footer remain fixed while the body scrolls', (tester) async {
  final controller = ScrollController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 500,
          child: AddBookSheetScaffold(
            title: 'Import books',
            onClose: () {},
            body: ListView(
              controller: controller,
              children: List.generate(40, (index) => Text('Row $index')),
            ),
            footer: const Text('Fixed footer', key: Key('fixed-footer')),
          ),
        ),
      ),
    ),
  );

  final headerTop = tester.getTopLeft(find.text('Import books'));
  final footerTop = tester.getTopLeft(find.byKey(const Key('fixed-footer')));
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pump();

  expect(tester.getTopLeft(find.text('Import books')), headerTop);
  expect(tester.getTopLeft(find.byKey(const Key('fixed-footer'))), footerTop);
});

testWidgets('physical Add action is rendered in the footer', (tester) async {
  await openPhysicalBookSheet(tester);

  expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
  expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);
  expect(
    find.descendant(
      of: find.byKey(const Key('add-book-sheet-footer')),
      matching: find.widgetWithText(FilledButton, 'Add'),
    ),
    findsOneWidget,
  );
});
```

- [ ] **Step 2: Run the scaffold and add-book sheet tests and verify RED**

Run: `cd app && flutter test test/widgets/add_book/add_book_sheet_scaffold_test.dart test/widgets/add_book/add_book_sheets_test.dart`

Expected: the scaffold type and fixed-footer keys are missing, and the physical Add action is still in `BottomSheetHeader`.

- [ ] **Step 3: Implement the shared layout**

Create `AddBookSheetScaffold` with this public interface and structure:

```dart
class AddBookSheetScaffold extends StatelessWidget {
  const AddBookSheetScaffold({
    super.key,
    required this.title,
    required this.onClose,
    required this.body,
    required this.footer,
    this.canClose = true,
  });

  final String title;
  final VoidCallback onClose;
  final Widget body;
  final Widget footer;
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          key: const Key('add-book-sheet-header'),
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
          child: Column(
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: canClose ? onClose : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
        Container(
          key: const Key('add-book-sheet-footer'),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: SafeArea(top: false, child: footer),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Move physical actions into the footer**

Replace the physical sheet’s top `BottomSheetHeader` and trailing body structure with `AddBookSheetScaffold`. Supply the existing form `ListView` as `body` and this footer:

```dart
Row(
  children: [
    const Spacer(),
    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
    const SizedBox(width: Spacing.sm),
    FilledButton(onPressed: _canSave ? _onSave : null, child: const Text('Add')),
  ],
)
```

Keep `MediaQuery.viewInsets.bottom` around the scaffold so the keyboard does not cover the footer.

- [ ] **Step 5: Run the focused tests and verify GREEN**

Run: `cd app && flutter test test/widgets/add_book/add_book_sheet_scaffold_test.dart test/widgets/add_book/add_book_sheets_test.dart`

Expected: fixed-layout and physical-footer tests pass.

- [ ] **Step 6: Commit the shared layout and physical migration**

```bash
git add app/lib/widgets/add_book/add_book_sheet_scaffold.dart app/lib/widgets/add_book/add_physical_book_sheet.dart app/test/widgets/add_book/add_book_sheet_scaffold_test.dart app/test/widgets/add_book/add_book_sheets_test.dart
git commit -m "PPR-26: Fix physical import sheet actions"
```

### Task 3: Build the Confirmed Multi-File Selection Sheet

**Files:**
- Create: `app/lib/widgets/add_book/digital_book_import_sheet.dart`
- Test: `app/test/widgets/add_book/digital_book_import_sheet_test.dart`

- [ ] **Step 1: Write failing selection and removal tests**

```dart
testWidgets('confirms multiple selected files and removes accidental selections', (tester) async {
  final files = [
    SelectedBookFile(name: 'one.epub', bytes: Uint8List.fromList([1])),
    SelectedBookFile(name: 'two.epub', bytes: Uint8List.fromList([2])),
  ];
  List<SelectedBookFile>? confirmed;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: DigitalBookImportSheet(
            pickFiles: () async => files,
            onConfirm: (value) => confirmed = value,
            onCancel: () {},
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Browse files'));
  await tester.pump();
  expect(find.text('one.epub'), findsOneWidget);
  expect(find.text('two.epub'), findsOneWidget);
  expect(find.text('Import 2 books'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('remove-two.epub')));
  await tester.pump();
  await tester.tap(find.text('Import 1 book'));

  expect(confirmed!.map((file) => file.name), ['one.epub']);
  expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
  expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);
});

testWidgets('a fresh picker result replaces the selection and unreadable files cannot confirm alone', (tester) async {
  var pickCount = 0;
  List<SelectedBookFile>? confirmed;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: DigitalBookImportSheet(
            pickFiles: () async {
              pickCount++;
              return pickCount == 1
                  ? [SelectedBookFile(name: 'first.epub', bytes: Uint8List.fromList([1]))]
                  : const [SelectedBookFile(name: 'unreadable.epub', bytes: null)];
            },
            onConfirm: (value) => confirmed = value,
            onCancel: () {},
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Browse files'));
  await tester.pump();
  await tester.tap(find.text('Browse files'));
  await tester.pump();

  expect(find.text('first.epub'), findsNothing);
  expect(find.text('unreadable.epub'), findsOneWidget);
  final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Import 1 book'));
  expect(button.onPressed, isNull);
  expect(confirmed, isNull);
});
```

- [ ] **Step 2: Run the digital sheet test and verify RED**

Run: `cd app && flutter test test/widgets/add_book/digital_book_import_sheet_test.dart`

Expected: compilation fails because `DigitalBookImportSheet` does not exist.

- [ ] **Step 3: Implement the picker adapter and sheet**

Define:

```dart
typedef DigitalBookFilePicker = Future<List<SelectedBookFile>> Function();

Future<List<SelectedBookFile>> pickDigitalBookFiles() async {
  final extensions = kIsWeb ? const ['epub'] : const ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    allowMultiple: true,
    withData: true,
  );
  if (result == null) return const [];
  return [for (final file in result.files) SelectedBookFile(name: file.name, bytes: file.bytes)];
}
```

Give `DigitalBookImportSheet` the testable constructor used above and a production `show` method that wraps it in a `DraggableScrollableSheet`. Use `AddBookSheetScaffold`, a `ListView` body, keyed remove buttons, and a footer containing Cancel plus a pluralized `Import N book(s)` button. Replacing the selection after each non-empty picker result must be one `setState` call.

- [ ] **Step 4: Run the selection tests and verify GREEN**

Run: `cd app && flutter test test/widgets/add_book/digital_book_import_sheet_test.dart`

Expected: multi-selection, replacement, removal, unreadable-file display, and confirmation tests pass.

- [ ] **Step 5: Commit the digital selection sheet**

```bash
git add app/lib/widgets/add_book/digital_book_import_sheet.dart app/test/widgets/add_book/digital_book_import_sheet_test.dart
git commit -m "PPR-26: Add batch digital import selection"
```

### Task 4: Process, Route, Retry, Remove, and Clean Batch Results

**Files:**
- Create: `app/lib/widgets/add_book/book_import_results_sheet.dart`
- Create: `app/test/widgets/add_book/book_import_results_sheet_test.dart`
- Modify: `app/lib/widgets/add_book/add_book_choice_sheet.dart`
- Modify: `app/test/widgets/add_book/add_book_sheets_test.dart`

- [ ] **Step 1: Write failing independent-result tests**

```dart
BookImportResult importResult(String filename, {required String bookId}) {
  return BookImportResult(
    bookId: bookId,
    title: filename,
    author: 'Author',
    fileSize: 1,
    fileHash: 'hash-$bookId',
    fileExtension: 'epub',
  );
}

Future<void> pumpResultsSheet(
  WidgetTester tester, {
  required List<SelectedBookFile> files,
  required BookImportProcessor processBook,
  required ImportedBookFileDeleter deleteBookFile,
  ImportedBookCommitter? commitBook,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 700,
          child: BookImportResultsSheet(
            files: files,
            processBook: processBook,
            deleteBookFile: deleteBookFile,
            commitBook: commitBook ??
                (result, _) async => Book(
                  id: result.bookId,
                  title: result.title,
                  author: result.author,
                  addedAt: DateTime(2026),
                ),
            onClose: () {},
            onCompleted: (_) {},
          ),
        ),
      ),
    ),
  );
}

testWidgets('processes rows independently and retries only the failed row', (tester) async {
  var failingAttempts = 0;
  final files = [
    SelectedBookFile(name: 'good.epub', bytes: Uint8List.fromList([1])),
    SelectedBookFile(name: 'bad.epub', bytes: Uint8List.fromList([2])),
  ];

  Future<BookImportResult> process(Uint8List bytes, String filename) async {
    if (filename == 'bad.epub' && failingAttempts++ == 0) throw StateError('broken');
    return importResult(filename, bookId: filename);
  }

  final deleted = <String>[];
  await pumpResultsSheet(
    tester,
    files: files,
    processBook: process,
    deleteBookFile: (bookId) async => deleted.add(bookId),
  );
  await tester.pumpAndSettle();

  expect(find.text('Ready'), findsOneWidget);
  expect(find.text('Failed'), findsOneWidget);
  expect(find.byKey(const Key('add-book-sheet-header')), findsOneWidget);
  expect(find.byKey(const Key('add-book-sheet-footer')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('retry-bad.epub')));
  await tester.pumpAndSettle();
  expect(find.text('Ready'), findsNWidgets(2));

  await tester.tap(find.byKey(const ValueKey('remove-good.epub')));
  await tester.pump();
  expect(deleted, contains('good.epub'));
});

testWidgets('digital import dismisses the method sheet before opening its own route', (tester) async {
  final observer = CountingNavigatorObserver();
  await pumpLauncher(tester, (context) => () => AddBookChoiceSheet.show(context), navigatorObservers: [observer]);
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  final barrier = find.byWidgetPredicate((widget) => widget is ModalBarrier && widget.color != null);
  final firstBarrier = tester.element(barrier);
  final pushesBeforeChoice = observer.pushCount;

  await tester.tap(find.text('Import digital books'));
  await tester.pumpAndSettle();

  expect(find.text('Import digital books'), findsWidgets);
  expect(observer.pushCount, pushesBeforeChoice + 1);
  expect(tester.element(barrier), isNot(same(firstBarrier)));
});
```

- [ ] **Step 2: Run the results test and verify RED**

Run: `cd app && flutter test test/widgets/add_book/book_import_results_sheet_test.dart`

Expected: the results sheet, callback typedefs, and status rows are missing.

- [ ] **Step 3: Implement processing and row actions**

Define these injectable callbacks:

```dart
typedef BookImportProcessor = Future<BookImportResult> Function(Uint8List bytes, String filename);
typedef ImportedBookFileDeleter = Future<void> Function(String bookId);
typedef ImportedBookCommitter = Future<Book> Function(BookImportResult result, String sourceFilename);
```

`BookImportResultsSheet.show` must resolve `BookImportService` from the caller’s provider and pass `importBook` and `deleteBookFile` into the sheet. In `initState`, create queued items with stable IDs and schedule `_processAll`. `_processItem` must:

1. mark only that row processing;
2. turn null bytes into a user-safe processing failure;
3. await the injected processor;
4. delete a late successful result immediately when the sheet has started closing;
5. otherwise mark the row ready or failed.

Use `AddBookSheetScaffold`, `PopScope`, a `ListView.separated`, and keyed Retry/Remove controls. `_removeItem` must await temporary-file deletion before removing a ready or commit-failed row. `_requestClose` must mark the sheet closing, clean every uncommitted result, allow pop, and then pop exactly once.

Remove `_showImport` from `AddBookChoiceSheet`, add `_AddBookChoice.importDigital`, and route after the method sheet has completed:

```dart
case _AddBookChoice.importDigital:
  final files = await DigitalBookImportSheet.show(context);
  if (!context.mounted || files == null || files.isEmpty) return;
  await BookImportResultsSheet.show(context, files: files);
case _AddBookChoice.addPhysical:
  await AddPhysicalBookSheet.show(context);
case _AddBookChoice.findOnline:
  onFindOnline?.call();
```

- [ ] **Step 4: Run processing, retry, removal, and cleanup tests and verify GREEN**

Run: `cd app && flutter test test/widgets/add_book/book_import_results_sheet_test.dart`

Expected: independent state, processing retry, row removal, late-result cleanup, and close cleanup tests pass.

- [ ] **Step 5: Run the method-routing test and verify GREEN**

Run: `cd app && flutter test test/widgets/add_book/add_book_sheets_test.dart`

Expected: digital and physical options both dismiss the method sheet and open distinct routes.

- [ ] **Step 6: Commit routing and result processing**

```bash
git add app/lib/widgets/add_book/add_book_choice_sheet.dart app/lib/widgets/add_book/book_import_results_sheet.dart app/test/widgets/add_book/add_book_sheets_test.dart app/test/widgets/add_book/book_import_results_sheet_test.dart
git commit -m "PPR-26: Add batch import results"
```

### Task 5: Commit Ready Books and Preserve Partial Failures

**Files:**
- Modify: `app/lib/widgets/add_book/book_import_results_sheet.dart`
- Modify: `app/test/widgets/add_book/book_import_results_sheet_test.dart`
- Modify: `app/test/media/media_profile_switch_contract_test.dart`

- [ ] **Step 1: Write failing batch-commit tests**

```dart
testWidgets('partial commit failure never recommits successful rows', (tester) async {
  final commits = <String>[];
  var secondAttempts = 0;
  final results = {
    'one.epub': importResult('One', bookId: 'one'),
    'two.epub': importResult('Two', bookId: 'two'),
  };
  await pumpResultsSheet(
    tester,
    files: [
      SelectedBookFile(name: 'one.epub', bytes: Uint8List.fromList([1])),
      SelectedBookFile(name: 'two.epub', bytes: Uint8List.fromList([2])),
    ],
    processBook: (_, filename) async => results[filename]!,
    deleteBookFile: (_) async {},
    commitBook: (result, _) async {
      commits.add(result.bookId);
      if (result.bookId == 'two' && secondAttempts++ == 0) throw StateError('commit failed');
      return Book(id: result.bookId, title: result.title, author: result.author, addedAt: DateTime(2026));
    },
  );

  await tester.tap(find.text('Add 2 to library'));
  await tester.pumpAndSettle();
  expect(commits, ['one', 'two']);
  expect(find.text('Added'), findsOneWidget);
  expect(find.text('Failed'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('retry-two.epub')));
  await tester.pumpAndSettle();
  expect(commits, ['one', 'two', 'two']);
});
```

- [ ] **Step 2: Run the commit tests and verify RED**

Run: `cd app && flutter test test/widgets/add_book/book_import_results_sheet_test.dart --plain-name "partial commit failure never recommits successful rows"`

Expected: the footer does not commit multiple ready rows or preserve per-row commit state.

- [ ] **Step 3: Move the production commit boundary into the results sheet**

Create `_commitResult(BookImportResult result, String sourceFilename)` by moving the current dependency resolution and `BookImportCommitService.commit` setup out of `ImportBookSheet._addToLibrary`. Preserve:

- repository capture through `requireBookRepository()`;
- account scope validation;
- pending and guest cover callbacks;
- repository add/delete compensation callbacks;
- upload queue callback;
- library-context validation;
- web OPFS and native local-file path behavior.

Implement `_addReadyBooks` so it snapshots only ready row IDs, marks them adding, commits each once, and updates each row to added or commit-failed. Disable close, remove, retry, and footer actions while any row is adding. A commit retry calls the committer only for that row. Close with an `Added N books to library` snackbar only when no retained ready, processing-failed, or commit-failed rows remain.

- [ ] **Step 4: Update the source contract to the new commit boundary**

Change `media_profile_switch_contract_test.dart` to read `lib/widgets/add_book/book_import_results_sheet.dart`, extract `_commitResult`, and retain its existing assertions for account scope, cover persistence, queueing, repository identity, and context validation. Replace the old single `_committing` source assertions with widget tests that prove actions are disabled during injected commit futures.

- [ ] **Step 5: Run commit, service, and contract tests and verify GREEN**

Run:

```bash
cd app
flutter test test/widgets/add_book/book_import_results_sheet_test.dart test/services/book_import_commit_service_test.dart test/media/media_profile_switch_contract_test.dart
```

Expected: batch commits, partial failure retry, no duplicate additions, and the existing media-profile safety contracts pass.

- [ ] **Step 6: Commit batch finalization**

```bash
git add app/lib/widgets/add_book/book_import_results_sheet.dart app/test/widgets/add_book/book_import_results_sheet_test.dart app/test/media/media_profile_switch_contract_test.dart
git commit -m "PPR-26: Commit batch book imports"
```

### Task 6: Remove the Legacy Combined Sheet and Verify the Feature

**Files:**
- Delete: `app/lib/widgets/add_book/import_book_sheet.dart`
- Modify: `app/test/widgets/add_book/add_book_sheets_test.dart`
- Inspect: all `app/lib` and `app/test` Dart files for stale imports and symbols.

- [ ] **Step 1: Run the focused tests before deleting the legacy sheet**

Run:

```bash
cd app
flutter test test/widgets/add_book/add_book_sheet_scaffold_test.dart test/widgets/add_book/digital_book_import_sheet_test.dart test/widgets/add_book/book_import_results_sheet_test.dart test/widgets/add_book/add_book_sheets_test.dart
```

Expected: the new workflow passes while the unused legacy file still exists.

- [ ] **Step 2: Delete the old sheet and remove stale references**

Delete `app/lib/widgets/add_book/import_book_sheet.dart`. Run:

```bash
rg -n "ImportBookSheet|import_book_sheet|_showImport" app/lib app/test
```

Expected: no matches. Update any remaining import or source-contract path to the new digital or results component rather than retaining compatibility aliases.

- [ ] **Step 3: Format and analyze**

Run:

```bash
cd app
dart format --set-exit-if-changed lib test
flutter analyze --no-fatal-warnings --no-fatal-infos
```

Expected: formatting makes no changes and analysis reports no issues.

- [ ] **Step 4: Run the complete test suite**

Run: `cd app && flutter test --reporter expanded`

Expected: every test passes; intentional skips remain skipped.

- [ ] **Step 5: Review the final diff**

Run:

```bash
git diff --check
git status --short
git diff --stat HEAD~6..HEAD
```

Expected: no whitespace errors, only PPR-26 import workflow files are changed, and no generated file is present.

- [ ] **Step 6: Commit final cleanup**

```bash
git add -A app/lib/widgets/add_book app/test/widgets/add_book app/test/media/media_profile_switch_contract_test.dart
git commit -m "PPR-26: Remove legacy book import sheet"
```
