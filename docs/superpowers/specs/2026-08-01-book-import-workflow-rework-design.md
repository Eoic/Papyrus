# Book Import Workflow Rework Design

## Overview

Rework book import into distinct, consistently styled bottom sheets. Digital import becomes a confirmed multi-file workflow with per-book results, retry and removal controls, and one final library commit. Physical import adopts the same fixed-header and fixed-footer structure.

## Problem

The add-book method sheet currently replaces its own content with the digital import widget. This keeps the same modal route and mixes method selection, file selection, processing, preview, and commit state in one component. Digital import accepts only one file, and its actions scroll with the content. The physical form keeps its save action in the header rather than using the fixed footer established by Advanced filters.

## Goals

- Open digital and physical import as independent modal routes after the method sheet closes.
- Let users select and confirm multiple digital files in one operation.
- Present processing and commit results as removable book rows with explicit statuses.
- Support retrying failed files without reopening the workflow.
- Give digital selection, import results, and physical entry fixed headers and footers.
- Preserve the existing import, metadata extraction, storage, and commit services.

## Non-goals

- Background imports that survive navigation or application restarts.
- Import history or persistent import queues.
- Editing extracted digital-book metadata before commit.
- Changing supported file formats or the underlying metadata parsers.
- Adding online acquisition behavior to this workflow.

## Component Design

### AddBookChoiceSheet

The method sheet remains selection-only. Its result enum gains a digital-import choice. After the choice route has fully completed, the caller opens either `DigitalBookImportSheet`, `AddPhysicalBookSheet`, or online search. The method sheet never swaps its own body.

### AddBookSheetScaffold

The three add-book sheets share a small layout component that renders:

- a fixed drag handle and title/close header;
- a divider;
- one expanded scrollable body supplied by the sheet;
- a fixed footer with a top border and safe-area handling.

Spacing, surface color, border treatment, and action placement match `LibraryAdvancedFilterSheet`. The shared component defines layout only; each sheet owns its actions and state.

### DigitalBookImportSheet

This sheet owns only file selection and confirmation.

- The file picker uses multi-selection and reads file bytes.
- Supported extensions remain platform-specific: EPUB on web and the existing native format list elsewhere.
- The body initially presents a browse action, then a scrollable filename list.
- Every selected row can be removed before processing.
- Reopening the picker replaces the current selection.
- The footer contains Cancel and `Import N books`.
- The primary action is disabled until at least one readable file remains.

Confirming closes this sheet and immediately opens `BookImportResultsSheet` with the selected files.

### BookImportResultsSheet

The results sheet starts processing when it opens. Its body is a scrollable list of one row per selected file. Each row includes the filename, extracted title and author when available, status, and contextual actions.

Processing statuses are:

- queued;
- processing;
- ready;
- failed.

Ready rows may be removed before the final action. Failed rows provide Retry and Remove. A processing retry uses the original in-memory bytes and replaces the row’s prior error state.

The fixed footer contains Cancel and `Add N to library`. The primary action is enabled only when processing has settled and at least one ready row remains. Its count includes only ready rows.

During final commit, row actions and sheet dismissal are disabled. Commit states are adding, added, and failed. Ready rows are committed individually through `BookImportCommitService`. If every retained row is added, the sheet closes and reports the total added. If a commit fails, successfully added rows remain final, failed rows remain visible, and the sheet stays open so the user can retry that row’s commit or remove it without duplicating successful books.

### AddPhysicalBookSheet

The existing form and validation remain unchanged. The form becomes the scrollable body of the shared sheet scaffold. The fixed header contains the handle, title, and close action. The fixed footer contains Cancel and Add; Add uses the existing validation and save behavior.

## Batch State

Each selected file becomes a workflow-local immutable batch item containing:

- a stable item ID;
- filename and optional bytes, allowing unreadable picker results to become failed rows;
- current processing or commit status;
- optional `BookImportResult`;
- optional user-safe error message.

The workflow remains local to the results sheet and does not introduce provider-level or application-global state. Items process independently so the UI updates as each file finishes.

## Cleanup and Dismissal

- Removing a ready row deletes the temporary imported book file created by `BookImportService`.
- Retrying metadata processing starts from the original bytes; retrying a commit reuses its existing parsed result and temporary file.
- Cancelling, closing, or dismissing the results sheet deletes every successful-but-uncommitted temporary file.
- Added rows are never cleaned by sheet dismissal.
- Dismissal is blocked only while final commits are running.
- Failed parsing rows have no committed library record and retain their source bytes only until the sheet closes.

## Error Handling

File-read failures appear as failed rows rather than aborting the batch. Processing and commit errors are isolated to their rows. One failure never prevents other files from becoming ready or being added. Raw internal exceptions are converted to concise user-facing messages while remaining available to existing logging where applicable.

## Verification

Widget and model tests will verify:

- digital selection opens on a new modal route after the method sheet dismisses;
- multi-file selection, confirmation counts, and pre-processing removal;
- fixed header, scrolling body, and fixed footer structure for all three sheets;
- independent queued, processing, ready, and failed states;
- retry and removal behavior;
- cleanup of successful-but-uncommitted temporary files;
- final commit of only retained ready rows;
- partial commit failure without duplicate additions;
- physical form validation and Add behavior from the footer.

Run targeted Flutter tests during implementation, followed by `flutter analyze` and the complete Flutter test suite.

## Assumptions

- Selected file bytes may remain in memory for the lifetime of the results sheet.
- Processing can run concurrently through the existing import service.
- A fresh multi-file picker result replaces the digital selection draft.
- The final action adds every retained ready row; per-row inclusion is controlled through Remove.
- The current supported-format lists remain the source of truth.
