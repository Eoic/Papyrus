# Books Acquisition UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate online book discovery and managed downloads into the existing Books page so local browsing stays unchanged, online results replace the grid only when explicitly requested, and accepted downloads appear as selectable progress placeholders in the ordinary grid/list.

**Architecture:** Keep the Books page in one of two page-local presentation modes: local library or online results. Keep remote query/results, release selection, job selection, polling, and submission outcomes in `AcquisitionDownloadsProvider`. Render server acquisition jobs as placeholders until their synchronized `Book` records arrive, then attach progress to the real book and finally let the normal synchronized book UI take over. Reuse the existing `SelectionHeader`, `EmptyState`, `QuickFilterChips`, `BottomSheetHandle`, add-book choice cards, and shelf-style destructive `AlertDialog`; do not introduce a download-management page or change the server contract.

**Tech Stack:** Flutter, Dart, Provider, existing Papyrus design tokens and shared widgets, `flutter_test`

---

## Constraints and invariants

- The approved design is `docs/superpowers/specs/2026-07-25-books-acquisition-ux-design.md`.
- Local search never sends a remote request.
- Remote search runs only after `Search online for “…”`, `Find books online`, or an explicit submit in online mode.
- Entering and leaving online mode preserves the local query, filters, sort, view mode, and ordinary book selection.
- Release selection, acquisition-job selection, and ordinary book selection are three independent states.
- Server jobs are the source of truth for progress and survive refresh/restart through the existing polling path.
- A completed book is never fabricated from a job response. The synchronized `Book` record replaces its placeholder.
- No server or database changes are expected. Stop and document a concrete contract defect before changing the server.
- Preserve unrelated changes already present in the working tree. Stage only the files listed by each task.

## Task 1: Make acquisition state support explicit search and partial retry

**Files:**

- Create: `lib/acquisition/acquisition_user_messages.dart`
- Create: `test/acquisition/acquisition_user_messages_test.dart`
- Modify: `lib/providers/acquisition_downloads_provider.dart`
- Modify: `test/acquisition/acquisition_downloads_provider_test.dart`

- [ ] **Step 1: Add failing provider tests for search and submission state**

Add tests proving:

```dart
test('search state is separate from job refresh errors', () async {
  final gateway = _FakeGateway(searchError: const AuthApiException(
    statusCode: 502,
    message: 'upstream request failed',
  ));
  final provider = AcquisitionDownloadsProvider(
    gateway: gateway,
    pollingInterval: Duration.zero,
  );

  await provider.searchRemote('Dune');

  expect(provider.remoteQuery, 'Dune');
  expect(provider.remoteResults, isEmpty);
  expect(provider.searchError, 'Could not search connected sources. Check the enabled indexers and try again.');
  expect(provider.error, isNull);
});

test('partial submission keeps only failed releases selected', () async {
  final gateway = _FakeGateway(
    batchResponse: BatchSubmissionResponse(items: [
      BatchSubmissionItem(index: 0, job: _job(id: 'job-1'), error: null),
      const BatchSubmissionItem(index: 1, job: null, error: 'download client rejected release'),
    ]),
  );
  final provider = AcquisitionDownloadsProvider(
    gateway: gateway,
    pollingInterval: Duration.zero,
  );
  provider.setRemoteResults('Dune', [_release('one'), _release('two')]);
  provider.selectAllReleases();

  final outcome = await provider.submitSelectedReleases('client-1');

  expect(outcome.successfulCount, 1);
  expect(outcome.failedCount, 1);
  expect(provider.selectedReleaseTokens, {'two'});
  expect(provider.submissionErrorsByReleaseToken.keys, {'two'});
  expect(provider.jobs.map((job) => job.id), contains('job-1'));
});
```

Also cover complete success, complete failure, an omitted/malformed batch item, and clearing stale row errors on a new search.

- [ ] **Step 2: Run the focused tests and confirm they fail for missing behavior**

Run:

```bash
flutter test test/acquisition/acquisition_downloads_provider_test.dart test/acquisition/acquisition_user_messages_test.dart
```

Expected: failures for the missing `searchError`, `submissionErrorsByReleaseToken`, and `AcquisitionSubmissionOutcome` APIs.

- [ ] **Step 3: Add task-focused error mapping**

Implement a small pure mapper. It must never expose URLs, endpoint IDs, stack strings, or exception class names.

```dart
import 'package:papyrus/auth/auth_api_client.dart';

String acquisitionSearchMessage(Object error) {
  if (error is AuthApiException) {
    return switch (error.statusCode) {
      401 || 403 => 'Your session expired. Sign in and try again.',
      502 || 503 || 504 => 'Could not search connected sources. Check the enabled indexers and try again.',
      _ => 'Could not search connected sources. Try again.',
    };
  }

  return 'Could not search connected sources. Try again.';
}

String acquisitionSubmissionMessage(String? detail) {
  final normalized = detail?.toLowerCase() ?? '';

  if (normalized.contains('auth')) {
    return 'The download client rejected its saved sign-in details.';
  }
  if (normalized.contains('timeout') || normalized.contains('timed out')) {
    return 'The download client did not respond in time.';
  }
  if (normalized.contains('reject')) {
    return 'The download client rejected this release.';
  }

  return 'This release could not be sent to the download client.';
}
```

Keep mapping deliberately small and test every branch. Do not map by presenting raw backend strings.

- [ ] **Step 4: Return a structured batch outcome and preserve failed selection**

Add:

```dart
class AcquisitionSubmissionOutcome {
  final int successfulCount;
  final Map<String, String> failuresByReleaseToken;

  const AcquisitionSubmissionOutcome({
    required this.successfulCount,
    required this.failuresByReleaseToken,
  });

  int get failedCount => failuresByReleaseToken.length;
  bool get allSucceeded => failedCount == 0 && successfulCount > 0;
}
```

Replace the provider's global submission-error list with:

```dart
Map<String, String> _submissionErrorsByReleaseToken = const {};
String? _searchError;

Map<String, String> get submissionErrorsByReleaseToken =>
    Map.unmodifiable(_submissionErrorsByReleaseToken);
String? get searchError => _searchError;

List<String> get submissionErrors =>
    List.unmodifiable(_submissionErrorsByReleaseToken.values);
```

During submission, preserve response-index correlation:

```dart
final selectedReleases = _remoteResults
    .where((release) => _selectedReleaseTokens.contains(release.releaseToken))
    .toList();
final successfulTokens = <String>{};
final failures = <String, String>{};
final handledIndexes = <int>{};

for (final item in response.items) {
  if (item.index < 0 || item.index >= selectedReleases.length) {
    continue;
  }

  handledIndexes.add(item.index);
  final release = selectedReleases[item.index];

  if (item.job case final job?) {
    _jobs[job.id] = job;
    successfulTokens.add(release.releaseToken);
  } else {
    failures[release.releaseToken] =
        acquisitionSubmissionMessage(item.error);
  }
}

for (var index = 0; index < selectedReleases.length; index++) {
  if (!handledIndexes.contains(index)) {
    failures[selectedReleases[index].releaseToken] =
        'The download client did not return a result for this release.';
  }
}

_selectedReleaseTokens
  ..removeAll(successfulTokens)
  ..addAll(failures.keys);
_submissionErrorsByReleaseToken = Map.unmodifiable(failures);
```

Set `remoteQuery` before starting the request so loading/error/empty all belong to the submitted query. Clear `searchError`, row errors, and release selection when a new query is submitted. Keep the existing generic `error` for polling/configuration failures only.

- [ ] **Step 5: Run provider and mapper tests**

Run:

```bash
dart format lib/acquisition/acquisition_user_messages.dart lib/providers/acquisition_downloads_provider.dart test/acquisition/acquisition_user_messages_test.dart test/acquisition/acquisition_downloads_provider_test.dart
flutter test test/acquisition/acquisition_downloads_provider_test.dart test/acquisition/acquisition_user_messages_test.dart
flutter analyze lib/acquisition/acquisition_user_messages.dart lib/providers/acquisition_downloads_provider.dart
```

Expected: all focused tests pass and analysis is clean.

- [ ] **Step 6: Commit Task 1**

```bash
git add lib/acquisition/acquisition_user_messages.dart lib/providers/acquisition_downloads_provider.dart test/acquisition/acquisition_user_messages_test.dart test/acquisition/acquisition_downloads_provider_test.dart
git commit -m "fix: preserve failed acquisition submissions"
```

## Task 2: Add the approved online-search entry points

**Files:**

- Modify: `lib/widgets/add_book/add_book_choice_sheet.dart`
- Modify: `test/widgets/add_book/add_book_sheets_test.dart`
- Create: `lib/widgets/library/online_books_header.dart`
- Create: `test/widgets/library/online_books_header_test.dart`

- [ ] **Step 1: Add failing add-book choice tests**

Add tests proving that `Find books online`:

- is absent when no callback is supplied;
- uses the existing `_ChoiceOption` appearance;
- closes the add-book sheet and invokes the page callback exactly once.

Use the intended API:

```dart
await AddBookChoiceSheet.show(
  context,
  onFindOnline: () => findOnlineCalls++,
);
```

- [ ] **Step 2: Run the add-book tests and confirm failure**

Run:

```bash
flutter test test/widgets/add_book/add_book_sheets_test.dart
```

Expected: failure because `onFindOnline` and the third option do not exist.

- [ ] **Step 3: Extend the existing choice sheet without duplicating its styling**

Change the constructor and `show` method:

```dart
const AddBookChoiceSheet({
  required this.callerContext,
  this.onFindOnline,
  super.key,
});

final VoidCallback? onFindOnline;

static Future<void> show(
  BuildContext context, {
  VoidCallback? onFindOnline,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.md,
        bottom: Spacing.lg,
      ),
      child: AddBookChoiceSheet(
        callerContext: context,
        onFindOnline: onFindOnline,
      ),
    ),
  );
}
```

Append the third `_ChoiceOption` only when `onFindOnline != null`:

```dart
if (onFindOnline != null) ...[
  const SizedBox(height: Spacing.sm),
  _ChoiceOption(
    icon: Icons.travel_explore_outlined,
    title: 'Find books online',
    subtitle: 'Search connected book sources',
    onTap: () {
      Navigator.of(context).pop();
      onFindOnline!();
    },
  ),
],
```

- [ ] **Step 4: Add failing tests for the contextual online header**

Create widget tests for:

- Back, `Online results`, and an explicit search field;
- `autofocus: true` when entered from Add book;
- no search callback on ordinary typing;
- search callback on keyboard submit and the search icon;
- disabled submit while searching or when trimmed input is empty;
- compact mobile and desktop layouts under `AppTheme.darkTheme`.

Use an API shaped like:

```dart
OnlineBooksHeader(
  controller: controller,
  autofocus: true,
  isSearching: false,
  onBack: onBack,
  onSearch: (query) => submitted.add(query),
)
```

- [ ] **Step 5: Implement the header using existing tokens**

Create a stateless responsive widget. Use `LayoutBuilder`, `Spacing`, existing header typography, `TextField`, and `IconButton`; do not invent a separate surface/card.

```dart
void _submit() {
  final query = controller.text.trim();
  if (query.isNotEmpty && !isSearching) {
    onSearch(query);
  }
}
```

Wrap the submit control in `ValueListenableBuilder<TextEditingValue>` listening to the supplied controller so its enabled state updates as the user types without making the header stateful.

Desktop uses one row: Back, title, expanded search. Mobile uses the existing compact header space with title/back above the full-width search field. Give Back and Search explicit tooltips.

- [ ] **Step 6: Run and commit Task 2**

Run:

```bash
dart format lib/widgets/add_book/add_book_choice_sheet.dart lib/widgets/library/online_books_header.dart test/widgets/add_book/add_book_sheets_test.dart test/widgets/library/online_books_header_test.dart
flutter test test/widgets/add_book/add_book_sheets_test.dart test/widgets/library/online_books_header_test.dart
flutter analyze lib/widgets/add_book/add_book_choice_sheet.dart lib/widgets/library/online_books_header.dart
```

Then:

```bash
git add lib/widgets/add_book/add_book_choice_sheet.dart lib/widgets/library/online_books_header.dart test/widgets/add_book/add_book_sheets_test.dart test/widgets/library/online_books_header_test.dart
git commit -m "feat: add online book search entry points"
```

## Task 3: Build online result states and retryable row errors

**Files:**

- Modify: `lib/widgets/library/remote_release_list.dart`
- Create: `lib/widgets/library/online_results_view.dart`
- Create: `test/widgets/library/remote_release_list_test.dart`
- Create: `test/widgets/library/online_results_view_test.dart`

- [ ] **Step 1: Write failing result-list tests**

Cover:

- full-width rows with checkbox, title, source, format, size, and seeders;
- selected-row treatment using the current color scheme;
- a concise inline error under only the failed release;
- row tap toggles selection;
- semantics expose the title and selected state.

Extend the constructor:

```dart
RemoteReleaseList(
  releases: releases,
  selectedReleaseTokens: const {'token-1'},
  errorsByReleaseToken: const {
    'token-1': 'The download client rejected this release.',
  },
  onToggleSelection: toggled.add,
)
```

- [ ] **Step 2: Write failing online-content tests**

Create tests for five mutually exclusive content states:

```dart
OnlineResultsView(
  hasSearched: false,
  isSearching: false,
  query: '',
  error: null,
  releases: const [],
  selectedReleaseTokens: const {},
  errorsByReleaseToken: const {},
  onRetry: () {},
  onToggleSelection: (_) {},
)
```

Expected states:

- initial: `Search connected sources`;
- loading: centered progress and query-aware label;
- error: task-focused message and `Try again`;
- empty: `No releases found` with query-aware guidance;
- results: `RemoteReleaseList`.

- [ ] **Step 3: Run tests and confirm they fail**

Run:

```bash
flutter test test/widgets/library/remote_release_list_test.dart test/widgets/library/online_results_view_test.dart
```

- [ ] **Step 4: Implement the result widgets**

Add `errorsByReleaseToken` to `RemoteReleaseList` and place the error below metadata using `colorScheme.error` and `bodySmall`. Preserve existing list padding and separators.

Implement `OnlineResultsView` as a pure state renderer using `EmptyState` for initial, error, and empty states. It must not initiate requests from `build`.

The error action is:

```dart
FilledButton.icon(
  onPressed: onRetry,
  icon: const Icon(Icons.refresh),
  label: const Text('Try again'),
)
```

- [ ] **Step 5: Run and commit Task 3**

Run:

```bash
dart format lib/widgets/library/remote_release_list.dart lib/widgets/library/online_results_view.dart test/widgets/library/remote_release_list_test.dart test/widgets/library/online_results_view_test.dart
flutter test test/widgets/library/remote_release_list_test.dart test/widgets/library/online_results_view_test.dart
flutter analyze lib/widgets/library/remote_release_list.dart lib/widgets/library/online_results_view.dart
```

Then:

```bash
git add lib/widgets/library/remote_release_list.dart lib/widgets/library/online_results_view.dart test/widgets/library/remote_release_list_test.dart test/widgets/library/online_results_view_test.dart
git commit -m "feat: add contextual online release results"
```

## Task 4: Render acquisition jobs as ordinary book placeholders

**Files:**

- Create: `lib/widgets/library/acquisition_status_text.dart`
- Create: `lib/widgets/library/acquisition_placeholder_card.dart`
- Create: `lib/widgets/library/acquisition_placeholder_list_item.dart`
- Create: `test/widgets/library/acquisition_placeholder_card_test.dart`
- Create: `test/widgets/library/acquisition_placeholder_list_item_test.dart`
- Modify: `lib/widgets/library/book_grid.dart`
- Modify: `lib/widgets/library/book_card.dart`
- Modify: `lib/widgets/library/book_list_item.dart`
- Modify: `test/widgets/library/book_card_test.dart`
- Create: `test/widgets/library/book_grid_test.dart`

- [ ] **Step 1: Add failing status and placeholder tests**

Test every status:

```dart
AcquisitionJobStatus.queued
AcquisitionJobStatus.submitted
AcquisitionJobStatus.downloading
AcquisitionJobStatus.needsFileSelection
AcquisitionJobStatus.importing
AcquisitionJobStatus.completed
AcquisitionJobStatus.failed
AcquisitionJobStatus.cancelled
AcquisitionJobStatus.unknown
```

For a downloading job with metrics, assert:

- release title;
- `42%`;
- formatted speed such as `1.5 MB/s`;
- formatted ETA such as `3 min remaining`;
- determinate `LinearProgressIndicator`;
- the same card dimensions and radius as `BookCard`.

For unknown progress, assert an indeterminate or status-only treatment without fake `0%`.

- [ ] **Step 2: Add failing grid reconciliation tests**

Use this intended `BookGrid` extension:

```dart
BookGrid(
  books: books,
  acquisitionJobsByBookId: {'book-1': linkedJob},
  placeholderJobs: [orphanJob],
  selectedAcquisitionJobIds: const {'job-orphan'},
  onAcquisitionTap: tappedJobs.add,
  onAcquisitionLongPress: selectedJobs.add,
  // existing book callbacks remain unchanged
)
```

Give every new constructor argument a backward-compatible default in Task 4 so the existing `LibraryPage` continues to compile until Task 7 wires the new behavior:

```dart
final List<AcquisitionJob> placeholderJobs;
final Set<String> selectedAcquisitionJobIds;
final ValueChanged<AcquisitionJob>? onAcquisitionTap;
final ValueChanged<AcquisitionJob>? onAcquisitionLongPress;

// Add these optional named parameters after the existing constructor fields:
  this.placeholderJobs = const [],
  this.selectedAcquisitionJobIds = const {},
  this.onAcquisitionTap,
  this.onAcquisitionLongPress,
```

Prove:

- a job without a synchronized book renders once as an orphan placeholder;
- a job whose `bookId` exists renders through the linked `BookCard`, not twice;
- tapping/long-pressing a linked or orphan job uses acquisition callbacks;
- ordinary books continue using ordinary book callbacks and selection;
- list and grid view can render the same job set.

- [ ] **Step 3: Run tests and confirm failure**

Run:

```bash
flutter test test/widgets/library/acquisition_placeholder_card_test.dart test/widgets/library/acquisition_placeholder_list_item_test.dart test/widgets/library/book_grid_test.dart test/widgets/library/book_card_test.dart
```

- [ ] **Step 4: Centralize status and metric formatting**

Create pure functions:

```dart
String acquisitionStatusLabel(AcquisitionJob job) => switch (job.status) {
  AcquisitionJobStatus.queued ||
  AcquisitionJobStatus.submitted => 'Queued',
  AcquisitionJobStatus.downloading => job.progress == null
      ? 'Downloading'
      : 'Downloading ${(job.progress! * 100).round()}%',
  AcquisitionJobStatus.needsFileSelection => 'Needs attention',
  AcquisitionJobStatus.importing => 'Adding to library',
  AcquisitionJobStatus.completed => 'Finishing import',
  AcquisitionJobStatus.failed => 'Download failed',
  AcquisitionJobStatus.cancelled => 'Cancelled',
  AcquisitionJobStatus.unknown => 'Needs attention',
};
```

Also add tested `formatBytes(int? bytes)`, `formatSpeed(int bytesPerSecond)`, and `formatEta(int seconds)` helpers. `formatBytes(null)` returns `—`. Reuse them from cards, list items, and the details sheet; remove duplicate private formatters.

- [ ] **Step 5: Implement the placeholder card and list item**

Use the ordinary card/list dimensions, radius, typography, selection outline, and title placement. Use a neutral cover:

```dart
Container(
  color: colorScheme.surfaceContainerHighest,
  child: Icon(
    Icons.menu_book_outlined,
    size: IconSizes.display,
    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
  ),
)
```

Overlay status and progress within the existing card structure. Do not use remote release artwork or add a separate dashboard-style panel.

- [ ] **Step 6: Reconcile jobs in `BookGrid`**

Keep book and job callbacks separate:

```dart
final acquisitionJob = acquisitionJobsByBookId[book.id];

return BookCard(
  book: book,
  acquisitionJob: acquisitionJob,
  isSelected: acquisitionJob == null
      ? selectedBookIds.contains(book.id)
      : selectedAcquisitionJobIds.contains(acquisitionJob.id),
  onTap: acquisitionJob == null
      ? () => onBookTap(book)
      : () => onAcquisitionTap(acquisitionJob),
  onLongPress: acquisitionJob == null
      ? () => onBookLongPress(book)
      : () => onAcquisitionLongPress(acquisitionJob),
);
```

Append `placeholderJobs` after synchronized books. The caller, not `BookGrid`, is responsible for passing only jobs whose `bookId` is not present in the current synchronized book set.

- [ ] **Step 7: Run and commit Task 4**

Run:

```bash
dart format lib/widgets/library/acquisition_status_text.dart lib/widgets/library/acquisition_placeholder_card.dart lib/widgets/library/acquisition_placeholder_list_item.dart lib/widgets/library/book_grid.dart lib/widgets/library/book_card.dart lib/widgets/library/book_list_item.dart test/widgets/library/acquisition_placeholder_card_test.dart test/widgets/library/acquisition_placeholder_list_item_test.dart test/widgets/library/book_grid_test.dart test/widgets/library/book_card_test.dart
flutter test test/widgets/library/acquisition_placeholder_card_test.dart test/widgets/library/acquisition_placeholder_list_item_test.dart test/widgets/library/book_grid_test.dart test/widgets/library/book_card_test.dart
flutter analyze lib/widgets/library/acquisition_status_text.dart lib/widgets/library/acquisition_placeholder_card.dart lib/widgets/library/acquisition_placeholder_list_item.dart lib/widgets/library/book_grid.dart lib/widgets/library/book_card.dart lib/widgets/library/book_list_item.dart
```

Then:

```bash
git add lib/widgets/library/acquisition_status_text.dart lib/widgets/library/acquisition_placeholder_card.dart lib/widgets/library/acquisition_placeholder_list_item.dart lib/widgets/library/book_grid.dart lib/widgets/library/book_card.dart lib/widgets/library/book_list_item.dart test/widgets/library/acquisition_placeholder_card_test.dart test/widgets/library/acquisition_placeholder_list_item_test.dart test/widgets/library/book_grid_test.dart test/widgets/library/book_card_test.dart
git commit -m "feat: show downloads as book placeholders"
```

## Task 5: Add the temporary Downloading filter without changing library-domain filters

**Files:**

- Modify: `lib/widgets/library/library_filter_chips.dart`
- Create: `test/widgets/library/library_filter_chips_test.dart`
- Create: `lib/widgets/library/acquisition_job_visibility.dart`
- Create: `test/widgets/library/acquisition_job_visibility_test.dart`

- [ ] **Step 1: Write failing visibility-policy tests**

Create pure helpers that receive synchronized book IDs and jobs. Prove:

- active, queued, failed, and attention-required jobs appear in the Downloading filter;
- completed jobs remain as an All-view placeholder only until their `Book` arrives;
- a linked active job filters in its synchronized `Book`;
- an orphan active job filters in its placeholder;
- no duplicate placeholder appears when `bookId` is synchronized;
- the Downloading chip disappears when no filterable job remains.

Use a result type:

```dart
class AcquisitionLibraryItems {
  final Map<String, AcquisitionJob> linkedJobsByBookId;
  final List<AcquisitionJob> orphanJobs;
  final Set<String> downloadingBookIds;
  final List<AcquisitionJob> downloadingOrphanJobs;

  bool get hasDownloadingItems =>
      downloadingBookIds.isNotEmpty || downloadingOrphanJobs.isNotEmpty;
}
```

- [ ] **Step 2: Write failing filter-chip tests**

Extend `LibraryFilterChips` without adding `downloading` to `LibraryFilterType`:

```dart
LibraryFilterChips(
  showDownloading: true,
  isDownloadingSelected: true,
  onDownloadingTapped: onDownloading,
  onLibraryFilterTapped: onLibraryFilter,
)
```

Prove:

- the chip is absent by default;
- it appears after the existing chips when requested;
- selecting it invokes only `onDownloadingTapped`;
- selecting an ordinary chip invokes `onLibraryFilterTapped` so the page can clear downloads-only mode;
- existing filter behavior remains unchanged when callbacks are omitted.

- [ ] **Step 3: Run tests and confirm failure**

Run:

```bash
flutter test test/widgets/library/acquisition_job_visibility_test.dart test/widgets/library/library_filter_chips_test.dart
```

- [ ] **Step 4: Implement the pure reconciliation policy**

Use status policy explicitly:

```dart
bool isDownloadingFilterStatus(AcquisitionJobStatus status) => switch (status) {
  AcquisitionJobStatus.queued ||
  AcquisitionJobStatus.submitted ||
  AcquisitionJobStatus.downloading ||
  AcquisitionJobStatus.needsFileSelection ||
  AcquisitionJobStatus.importing ||
  AcquisitionJobStatus.failed ||
  AcquisitionJobStatus.unknown => true,
  AcquisitionJobStatus.completed ||
  AcquisitionJobStatus.cancelled => false,
};
```

Cancelled jobs remain visible in All until the user removes them. Completed orphan jobs remain visible in All as `Finishing import` until synchronization supplies the book. Neither keeps the Downloading chip visible by itself.

- [ ] **Step 5: Extend the existing filter wrapper**

Build the optional dynamic entry with the existing `QuickFilterChipData`; do not duplicate `FilterChip` styling:

```dart
final filters = _filters
    .map(
      (filter) => QuickFilterChipData(
        label: filter.label,
        icon: filter.icon,
        isSelected: libraryProvider.isFilterActive(filter.type),
      ),
    )
    .toList();

if (showDownloading) {
  filters.add(
    QuickFilterChipData(
      label: 'Downloading',
      icon: Icons.downloading_outlined,
      isSelected: isDownloadingSelected,
    ),
  );
}
```

Dispatch the final index to `onDownloadingTapped`; dispatch ordinary indices through existing provider behavior and then call `onLibraryFilterTapped`. Make all new constructor fields optional with defaults (`false` or `null`) so existing callers compile before Task 7.

- [ ] **Step 6: Run and commit Task 5**

Run:

```bash
dart format lib/widgets/library/library_filter_chips.dart lib/widgets/library/acquisition_job_visibility.dart test/widgets/library/library_filter_chips_test.dart test/widgets/library/acquisition_job_visibility_test.dart
flutter test test/widgets/library/library_filter_chips_test.dart test/widgets/library/acquisition_job_visibility_test.dart
flutter analyze lib/widgets/library/library_filter_chips.dart lib/widgets/library/acquisition_job_visibility.dart
```

Then:

```bash
git add lib/widgets/library/library_filter_chips.dart lib/widgets/library/acquisition_job_visibility.dart test/widgets/library/library_filter_chips_test.dart test/widgets/library/acquisition_job_visibility_test.dart
git commit -m "feat: add downloading books filter"
```

## Task 6: Rebuild download details and destructive actions with existing Papyrus surfaces

**Files:**

- Modify: `lib/widgets/library/acquisition_job_sheets.dart`
- Create: `test/widgets/library/acquisition_job_sheets_test.dart`
- Create: `lib/widgets/library/acquisition_confirmation_dialog.dart`
- Create: `test/widgets/library/acquisition_confirmation_dialog_test.dart`

- [ ] **Step 1: Add failing details-sheet tests**

Test that opening a job uses:

- `showModalBottomSheet`;
- `BottomSheetHandle`;
- the same `AppRadius.xl`, `Spacing.md/lg`, and headline/body styles as existing Papyrus sheets;
- content-height sizing rather than viewport-filling constraints;
- title, status, progress, downloaded/total bytes, speed, ETA, and selected file when available;
- `Cancel`, `Retry import`, or file choices only when valid for the job.

Add the new general entry point:

```dart
showAcquisitionJobDetailsSheet(
  context: context,
  provider: provider,
  job: job,
)
```

Keep `showAcquisitionJobAttentionSheet` as a compatibility wrapper that delegates to the new function until `LibraryPage` is switched in Task 7:

```dart
Future<void> showAcquisitionJobAttentionSheet({
  required BuildContext context,
  required AcquisitionDownloadsProvider provider,
  required AcquisitionJob job,
}) {
  return showAcquisitionJobDetailsSheet(
    context: context,
    provider: provider,
    job: job,
  );
}
```

- [ ] **Step 2: Add failing confirmation-dialog tests**

Test exact surface and destructive treatment:

```dart
final confirmed = await showAcquisitionConfirmationDialog(
  context: context,
  title: 'Cancel downloads',
  message: 'Cancel 2 selected downloads?',
  actionLabel: 'Cancel downloads',
);
```

Assert:

- one `AlertDialog`;
- no `BottomSheet`;
- `TextButton('Cancel')`;
- a `FilledButton` whose background is `colorScheme.error`;
- cancel returns `false`, destructive action returns `true`.

- [ ] **Step 3: Run tests and confirm failure**

Run:

```bash
flutter test test/widgets/library/acquisition_job_sheets_test.dart test/widgets/library/acquisition_confirmation_dialog_test.dart
```

- [ ] **Step 4: Implement the standard details sheet**

Use:

```dart
await showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: false,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppRadius.xl),
    ),
  ),
  builder: (sheetContext) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.md,
      Spacing.lg,
      Spacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: Spacing.md),
        Text(job.title, style: Theme.of(sheetContext).textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(acquisitionStatusLabel(job)),
        if (job.progress case final progress?) ...[
          const SizedBox(height: Spacing.md),
          LinearProgressIndicator(value: progress),
        ],
        if (job.downloadedBytes != null || job.totalBytes != null)
          Text(
            '${formatBytes(job.downloadedBytes)} of '
            '${formatBytes(job.totalBytes)}',
          ),
        if (job.downloadSpeedBytesPerSecond case final speed?)
          Text(formatSpeed(speed)),
        if (job.etaSeconds case final eta?) Text(formatEta(eta)),
        if (job.selectedFilePath case final path?) Text(path),
      ],
    ),
  ),
);
```

Append the tested contextual action section after these metrics: supported file rows for `needsFileSelection`, Cancel for `job.canCancel`, and Retry import for `job.canRetryImport`. File selection remains inside this same details flow. Use the shared formatting functions from Task 4. Do not display endpoint IDs, torrent hashes, raw client states, or backend exception text.

- [ ] **Step 5: Implement the shelf-style confirmation helper**

Match `ShelvesPage._confirmDeleteShelf`:

```dart
return showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(dialogContext).colorScheme.error,
        ),
        child: Text(actionLabel),
      ),
    ],
  ),
) ?? false;
```

- [ ] **Step 6: Run and commit Task 6**

Run:

```bash
dart format lib/widgets/library/acquisition_job_sheets.dart lib/widgets/library/acquisition_confirmation_dialog.dart test/widgets/library/acquisition_job_sheets_test.dart test/widgets/library/acquisition_confirmation_dialog_test.dart
flutter test test/widgets/library/acquisition_job_sheets_test.dart test/widgets/library/acquisition_confirmation_dialog_test.dart
flutter analyze lib/widgets/library/acquisition_job_sheets.dart lib/widgets/library/acquisition_confirmation_dialog.dart
```

Then:

```bash
git add lib/widgets/library/acquisition_job_sheets.dart lib/widgets/library/acquisition_confirmation_dialog.dart test/widgets/library/acquisition_job_sheets_test.dart test/widgets/library/acquisition_confirmation_dialog_test.dart
git commit -m "feat: add consistent download actions"
```

## Task 7: Replace the bolted-on LibraryPage acquisition UI

**Files:**

- Modify: `lib/pages/library_page.dart`
- Modify: `test/pages/library_page_test.dart`
- Delete: `lib/widgets/library/acquisition_job_list.dart`

- [ ] **Step 1: Replace old page tests with failing approved-flow tests**

Remove assertions tied to `_buildAcquisitionActions`, a separate downloads screen, and the old `AcquisitionJobList`.

Add test groups for:

1. **Local mode**
   - ordinary local search makes zero gateway search calls;
   - unmatched non-empty query shows `Search online for “Dune”` only when acquisition is ready;
   - Add book shows `Find books online` only when ready;
   - no acquisition toolbar or Downloads button appears.
2. **Online mode**
   - empty-state action carries the current query and searches once;
   - Add book enters with empty focused field and does not search;
   - Back restores the exact local query/filter/view state;
   - loading, empty, error, retry, and results render in place of the grid.
3. **Release selection/submission**
   - selection uses `SelectionHeader`;
   - select all/deselect all work;
   - one client submits immediately;
   - multiple clients use a standard content-height choice bottom sheet;
   - all-success returns local;
   - partial/complete failure stays online with failed rows selected and annotated.
4. **Local placeholders**
   - orphan and linked jobs render without duplication;
   - completed orphan remains until synchronized book appears;
   - Downloading filter isolates linked books and orphan jobs;
   - job selection does not mutate ordinary book selection;
   - only valid bulk actions appear.
5. **Responsive regression**
   - mobile and desktop pump under the real application theme;
   - no infinite-width or overflow exception occurs.

- [ ] **Step 2: Run the page tests and confirm failure**

Run:

```bash
flutter test test/pages/library_page_test.dart
```

Expected: failures for the approved mode transitions and placeholder integration.

- [ ] **Step 3: Introduce page-local presentation state**

Replace `_showDownloads` with:

```dart
enum _BooksPresentationMode { local, online }

_BooksPresentationMode _presentationMode = _BooksPresentationMode.local;
bool _showDownloadingOnly = false;
late final TextEditingController _onlineSearchController;
```

Initialize/dispose the controller. Add:

```dart
void _enterOnlineMode(
  AcquisitionDownloadsProvider provider, {
  String initialQuery = '',
  bool submitImmediately = false,
}) {
  _onlineSearchController.text = initialQuery;
  setState(() => _presentationMode = _BooksPresentationMode.online);

  if (submitImmediately && initialQuery.trim().isNotEmpty) {
    unawaited(provider.searchRemote(initialQuery));
  }
}

void _leaveOnlineMode(AcquisitionDownloadsProvider provider) {
  provider.clearRemoteResults();
  setState(() => _presentationMode = _BooksPresentationMode.local);
}
```

Do not modify `LibraryProvider.searchQuery`, filters, sort, or selection in either method.

- [ ] **Step 4: Replace normal header actions**

Delete `_buildAcquisitionActions` and every caller.

In local mode, preserve the current desktop/mobile header and filter chips. Pass `onFindOnline` to both mobile and desktop `AddBookChoiceSheet.show` calls only when `downloadsProvider.isManagedAcquisitionReady`.

In online mode, replace the normal header region with `OnlineBooksHeader`. If release selection is non-empty, replace it with the existing `SelectionHeader`:

```dart
SelectionHeader(
  selectedCount: provider.selectedReleaseTokens.length,
  totalCount: provider.remoteResults.length,
  onClose: provider.clearReleaseSelection,
  onSelectAll: provider.selectAllReleases,
  onDeselectAll: provider.clearReleaseSelection,
  actions: FilledButton.icon(
    onPressed: provider.isSubmitting ? null : () => _submitSelected(provider),
    icon: const Icon(Icons.download_outlined),
    label: const Text('Download'),
  ),
)
```

On mobile, use the existing mobile selection action treatment if the button cannot fit safely; do not squeeze controls into an overflowing row.

- [ ] **Step 5: Replace the content switch**

Local content:

```dart
final items = buildAcquisitionLibraryItems(
  books: dataStore.books,
  jobs: downloadsProvider?.jobs ?? const [],
);
final visibleBooks = _showDownloadingOnly
    ? books.where((book) => items.downloadingBookIds.contains(book.id)).toList()
    : books;
final visiblePlaceholderJobs = _showDownloadingOnly
    ? items.downloadingOrphanJobs
    : items.orphanJobs;
```

Pass linked jobs and orphan jobs to grid/list rendering. Search orphan placeholders by `job.title` using the current local query before rendering them. Show `Downloading` through `LibraryFilterChips`; selecting it sets `_showDownloadingOnly = true`, while selecting any library filter clears it.

When local books and matching placeholders are empty for a non-empty local query, configure the existing `EmptyState`:

```dart
EmptyState(
  icon: Icons.search_off,
  title: 'No books found',
  subtitle: 'No books in your library match “$query”.',
  action: downloadsProvider?.isManagedAcquisitionReady == true
      ? FilledButton(
          onPressed: () => _enterOnlineMode(
            downloadsProvider!,
            initialQuery: query,
            submitImmediately: true,
          ),
          child: Text('Search online for “$query”'),
        )
      : null,
)
```

Online content always uses `OnlineResultsView`, replacing the grid in place.

- [ ] **Step 6: Implement submission transitions and client choice**

Use the enabled clients from `provider.downloadClients`.

```dart
Future<void> _submitSelected(
  AcquisitionDownloadsProvider provider,
) async {
  final client = provider.downloadClients.length == 1
      ? provider.downloadClients.single
      : await _chooseDownloadClient(provider.downloadClients);

  if (client == null || !mounted) {
    return;
  }

  final outcome = await provider.submitSelectedReleases(client.id);
  if (!mounted) {
    return;
  }

  if (outcome.allSucceeded) {
    _leaveOnlineMode(provider);
  }
}
```

The client chooser must use `BottomSheetHandle`, `AppRadius.xl`, existing sheet padding, and content-height `Column(mainAxisSize: MainAxisSize.min)`. Show user-defined client names only.

Partial/complete failure remains online because `allSucceeded` is false. Row errors and failed selection come directly from provider state. Successful jobs are already available to local placeholders even before leaving online mode.

- [ ] **Step 7: Implement acquisition selection and actions**

When a linked or orphan acquisition item is tapped, show `showAcquisitionJobDetailsSheet`. Long press toggles `provider.toggleJobSelection(job.id)`.

When job selection is non-empty, use `SelectionHeader` with:

```dart
final selectedJobs = provider.jobs
    .where((job) => provider.selectedJobIds.contains(job.id))
    .toList();
final canCancel = selectedJobs.isNotEmpty &&
    selectedJobs.every((job) => job.canCancel);
final canRetry = selectedJobs.isNotEmpty &&
    selectedJobs.every((job) => job.canRetryImport);
final canRemove = selectedJobs.isNotEmpty &&
    selectedJobs.every(
      (job) => job.status == AcquisitionJobStatus.cancelled ||
          job.status == AcquisitionJobStatus.failed,
    );
```

Show only actions valid for the entire selection. Cancel and Remove must first call `showAcquisitionConfirmationDialog`; Retry does not need destructive confirmation.

- [ ] **Step 8: Delete the obsolete separate job list**

Remove:

- import of `acquisition_job_list.dart`;
- `_showDownloads`;
- `_buildAcquisitionActions`;
- the old Downloads content branch;
- `lib/widgets/library/acquisition_job_list.dart`.

Retain `_visibleDownloadsProvider`, `didChangeDependencies`, `dispose`, and their `setLibraryVisible` calls because they drive polling lifecycle independently of the obsolete screen. Do not remove provider polling or job action methods.

- [ ] **Step 9: Run page and focused regression tests**

Run:

```bash
dart format lib/pages/library_page.dart test/pages/library_page_test.dart
flutter test test/pages/library_page_test.dart
flutter test test/widgets/add_book/add_book_sheets_test.dart test/widgets/library/online_books_header_test.dart test/widgets/library/online_results_view_test.dart test/widgets/library/book_grid_test.dart test/widgets/library/library_filter_chips_test.dart test/widgets/library/acquisition_job_sheets_test.dart test/widgets/library/acquisition_confirmation_dialog_test.dart
flutter analyze lib/pages/library_page.dart
```

Expected: all approved flows pass under the real theme with no layout exceptions.

- [ ] **Step 10: Commit Task 7**

```bash
git add lib/pages/library_page.dart test/pages/library_page_test.dart
git add -u lib/widgets/library/acquisition_job_list.dart
git commit -m "feat: integrate downloads into books page"
```

## Task 8: Verify restoration, replacement, accessibility, and the full client

**Files:**

- Modify if required by failures: files changed in Tasks 1–7 only
- Modify: `test/pages/library_page_test.dart`
- Modify: `test/acquisition/acquisition_downloads_provider_test.dart`

- [ ] **Step 1: Add any missing cross-boundary regression tests**

Before final verification, ensure tests explicitly prove:

```dart
// Restored active job after provider refresh:
await provider.refreshJobs();
expect(provider.jobs.single.status, AcquisitionJobStatus.downloading);

// Orphan job before synchronization:
expect(find.text('Dune release'), findsOneWidget);

// Same job after synchronized Book arrives:
dataStore.replaceBooksFromSync([bookWithMatchingId]);
await tester.pump();
expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
expect(find.text(bookWithMatchingId.title), findsOneWidget);
```

Also verify:

- search and action controls have tooltips/semantic labels;
- keyboard submit works;
- no action depends on hover;
- cancelled/failed cards remain removable in All;
- completed orphan placeholders do not keep the Downloading chip visible;
- gateway search call count remains zero during local typing.

- [ ] **Step 2: Run formatting checks**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Expected: exit 0.

- [ ] **Step 3: Run the full test suite**

Run:

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Run full static analysis**

Run:

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 5: Perform a local manual smoke test before any push**

With the existing local server and client:

1. Open Books and type a local query with matches; confirm no remote request and no UI change.
2. Type an unmatched query; confirm the explicit online action appears.
3. Enter online mode, go Back, and confirm local search/filter/view state is unchanged.
4. Search a real Prowlarr source and select multiple releases.
5. Submit to qBittorrent and confirm immediate placeholders in the ordinary Books grid.
6. Confirm progress, speed, and ETA update without opening another page.
7. Reload the app and confirm active placeholders restore.
8. Open a placeholder details sheet and exercise valid non-destructive actions.
9. Cancel one job and verify the shelf-style confirmation dialog and removable cancelled placeholder.
10. Let one download import and confirm the synchronized Book replaces its placeholder without duplication or manual refresh.
11. Repeat the layout check at mobile and desktop widths.

Record any environment-only limitation rather than weakening tests.

- [ ] **Step 6: Review the diff against the approved spec**

Run:

```bash
git diff --check
git diff --stat
git status --short
rg -n "check your indexers|Search releases|Torrent acquisition" lib test
```

Expected:

- no whitespace errors;
- no stale old acquisition copy;
- no unfinished implementation markers;
- only scoped client files are staged later.

- [ ] **Step 7: Commit final regression adjustments**

If Task 8 required code/test adjustments:

```bash
git add test/pages/library_page_test.dart test/acquisition/acquisition_downloads_provider_test.dart
git commit -m "test: cover books acquisition workflow"
```

If no adjustment was needed, do not create an empty commit.

## Completion gate

Do not claim completion until all of the following are true:

- `flutter test` passes.
- `flutter analyze` passes.
- `dart format --output=none --set-exit-if-changed lib test` passes.
- Local typing never calls the acquisition gateway.
- Online results replace the grid only in explicit online mode.
- Full success returns local; partial/complete failure stays online with failed rows selected.
- Job-only and linked placeholders are not duplicated.
- Job selection remains independent of ordinary book selection.
- Cancel and Remove use an `AlertDialog` matching shelf deletion, not a bottom sheet.
- Details and client choice use existing Papyrus bottom-sheet components and content-height sizing.
- The obsolete acquisition toolbar and separate job-list screen are gone.
- Manual smoke testing with real Prowlarr and qBittorrent succeeds before pushing.
