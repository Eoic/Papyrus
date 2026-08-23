# Book Import Sheet Refactor Design

## Goal

Simplify `book_import_sheet.dart` by separating import orchestration from presentation and removing repeated item-card presentation code. Preserve the existing user-visible behavior, import concurrency, web-worker integration, error messages, cleanup guarantees, and the current uncommitted `BrowseArea` sizing change.

## Scope

This is a behavior-preserving refactor. It does not change `BookImportService`, `book_worker.js`, supported formats, persistence, or the number of imports processed concurrently.

The refactor will produce four focused units:

1. `book_import_sheet.dart` remains the public entry point. It owns modal/provider wiring, creates and disposes the controller, renders controller state, and handles navigation and snackbars.
2. `book_import_controller.dart` owns selected files, batch items, phase transitions, processing tokens and in-flight futures, retry behavior, commit behavior, temporary-file cleanup, and close coordination.
3. `book_import_sheet_sections.dart` contains the selecting, processing, and summary layouts plus selection-only presentation.
4. `book_import_item_card.dart` contains shared import-item presentation used by processing and summary rows, including title, subtitle, cover, fallback icon, status, and actions.

## Controller Contract

`BookImportController` receives the existing injected operations: file picker, processor, committer, deleter, and optional completion callback. It exposes read-only state and commands for browsing, clearing or removing selections, starting imports, retrying or removing batch items, and requesting close.

The controller uses `ChangeNotifier` so the sheet can rebuild from one state owner. It guards notifications after disposal. Commands that can fail in a way requiring UI feedback return a small result value; the sheet remains responsible for snackbars and navigation because those require `BuildContext`.

The existing safety behavior remains intact:

- Imports start concurrently.
- Per-item tokens prevent stale processing results from overwriting newer state.
- In-flight processing and cleanup operations are deduplicated.
- Closing waits for processing and removes temporary files for uncommitted items.
- Parse retries repeat parse and commit; commit retries repeat only commit.
- Completion is emitted at most once after all items settle.

## Presentation

The sheet listens to the controller and selects one of the three phase widgets. Phase widgets receive immutable values and callbacks rather than accessing controller internals directly.

Processing and summary cards use a shared item presentation model derived from `BookImportBatchItem`. Differences such as progress indicators, success/failure styling, retry actions, and remove actions remain configurable without duplicating title, subtitle, cover, and fallback-icon logic.

No labels, button availability, layout behavior, or modal sizing will intentionally change. The existing `MainAxisSize.max` change in `_BrowseArea` will be preserved.

## Error Handling and Lifecycle

Processor and committer exceptions continue to become safe per-item messages. Picker failures remain inline. Cleanup failures continue to block the destructive action and produce the same snackbar. Controller disposal prevents late async completions from notifying a dead widget while allowing already-started cleanup work to finish safely.

## Tests and Verification

Add focused controller tests covering:

- successful parse and commit through the summary phase;
- processing failure followed by retry;
- commit failure followed by commit-only retry;
- close waiting for active processing and cleaning uncommitted temporary files;
- deduplicated cleanup and single completion notification.

Add a lightweight widget test covering selection, processing, and summary rendering through injected callbacks. Run Dart formatting, targeted tests, and Flutter analysis for all changed files.

## Non-goals

- Performance changes or new scheduling rules.
- Web-worker changes.
- New import formats.
- Visual redesign.
- Changes to repository or persistence behavior.
