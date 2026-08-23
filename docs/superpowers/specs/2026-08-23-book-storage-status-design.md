# Per-book account and device status design

## Problem

Papyrus is local-first. A book can remain visible after a reload because it is
stored in the browser's local PowerSync database even when the backend and file
storage services were unavailable. The current global sync card does not make
that distinction clear and can display stale connection information. Users
therefore cannot tell whether a book is safely stored in their account or
whether its file is available on the current device.

The runtime investigation for this design confirmed that a reported book had
reached the backend and file storage after services returned, while the client
still displayed `Offline` and `No completed sync yet`. The design must make
per-book state explicit and prevent older asynchronous global status updates
from overwriting newer ones.

## Goals

- Show whether each authenticated book is syncing, saved to the account, or in
  a failed sync state.
- Show local digital-file availability without confusing it with account sync.
- Keep book-card navigation unchanged: tapping a card opens book details.
- Download a missing book file only when the user chooses to start reading.
- Derive states from existing local-first queues and confirmed server data.
- Keep local availability probes lightweight on web and native platforms.

## Non-goals

- Polling a new backend status endpoint.
- Uploading or downloading files merely to calculate status.
- Requiring cover upload to finish before a book is considered saved.
- Applying local-file status to physical books.
- Redesigning the library card beyond the new state treatments.

## State model

`BookStorageStatusController` exposes two independent states for every book.

### Account state

`BookAccountStatus` has three values:

- `syncing`: required account work is pending and remains retryable.
- `saved`: all required data has been acknowledged by the server.
- `failed`: required account work has failed in a way that needs user action.

Guest books do not have an account state and do not show an account badge.

For authenticated physical books:

- A pending metadata write means `syncing`.
- A definitive metadata failure means `failed`.
- Acknowledged metadata means `saved`.

For authenticated digital books:

- A pending metadata write or pending book-file upload means `syncing`.
- A definitive metadata or book-file failure means `failed`.
- The book is `saved` only when its metadata is acknowledged and the local
  PowerSync row contains a server-confirmed, non-empty `fileMediaId`.

Cover uploads are excluded from this calculation. Network loss and temporary
service outages remain `syncing` because the queues retry them automatically.
`failed` is reserved for actionable conditions such as rejected metadata or
exhausted file-storage quota.

### Device state

`BookDeviceStatus` has three values:

- `checking`: local availability has not yet been established.
- `available`: the current device has the digital book file.
- `missing`: the current device does not have the digital book file.

Physical books do not receive a device state. While a digital book is being
checked, its card keeps the normal appearance to prevent a gray flash during
list loading.

## Architecture

### PowerSync service boundary

`PapyrusPowerSyncService` exposes per-book metadata state without leaking the
`ps_crud` table or PowerSync transaction details into widgets.

- On authenticated database activation, it reconstructs pending book IDs from
  the PowerSync write queue.
- A local book insert or update marks that book pending immediately.
- The connector reports the affected book IDs when an upload transaction is
  accepted and completed.
- Acknowledgement clears their pending metadata state.
- A definitive upload rejection records a per-book failure. Transient
  connection errors leave the books pending.
- Changes are exposed as a stream or listenable map keyed by book ID.

The global `SyncState` adapter must also serialize status calculations or use a
generation guard. An older asynchronous pending-write query may not publish
after a newer PowerSync status has already been observed.

### Combined per-book controller

`BookStorageStatusController` combines:

- the current account/guest mode;
- per-book PowerSync metadata state;
- `MediaUploadQueue` tasks for `MediaKind.bookFile`;
- each book's server-confirmed `fileMediaId`; and
- the local availability probe.

This keeps card and details-page rules in one testable component. Widgets
receive resolved display states rather than reproducing business rules.

### Lightweight local availability

The existing local file reader returns the full file, which is inappropriate
for checking every visible card. Add `hasBookFile(bookId)` alongside the
existing read/store/delete operations:

- Web asks the existing book worker whether the OPFS entry exists and does not
  transfer file bytes to the UI isolate.
- Native platforms use a filesystem existence check and do not open the file.

Availability results are cached by book ID. Import completion, successful
download, local deletion, cache clearing, and account/profile changes
invalidate the relevant entries.

## Library-card presentation

The existing format badge remains at the cover's bottom-left. Authenticated
books receive a compact account badge at bottom-right:

- `Saved` with `cloud_done_outlined`.
- `Syncing…` with `sync`.
- `Sync failed` with `sync_problem_outlined`.

The badge uses icon and text so color is not the sole indicator. It is
informational and not a separate touch target. Desktop provides a tooltip, and
the card's semantic label includes the full account state.

When a digital book is confirmed missing locally:

- its cover is desaturated;
- its card surface receives a subtle neutral tint;
- title and author retain accessible contrast; and
- its semantic label includes `Not available on this device`.

The whole card must not be faded with reduced opacity. Physical books and
digital books in the `checking` or `available` states retain the normal visual
treatment.

## Details page and reader launch

Tapping any library card continues to open the book details page. No download
starts during card navigation.

The reading action behaves as follows:

- Local file available: show `Start reading` and open the reader normally.
- Local file missing and book saved to account: show `Download and read`.
- Download active: disable the action, show `Downloading…`, and provide
  an indeterminate progress indicator. Byte-level progress is outside this
  scope because the existing download API returns the completed byte buffer.
- Download failure: retain the details page and show an inline error with a
  `Try again` action.
- Local file missing while account state is `syncing`: disable reading and
  explain that the book file is still being saved to the account.
- Local file missing while account state is `failed`: disable reading and
  direct the user to retry the failed sync/upload.

`Download and read` uses the existing `MediaCacheService.ensureBookFileCached`
path. After a successful cache write, it invalidates device status, resolves it
as `available`, and opens the reader. If the device is offline, the inline
failure message explains that the file is not stored locally and a connection
is required.

## Error and recovery behavior

- Temporary backend, PowerSync, or storage unavailability leaves affected
  books in `syncing`; automatic retries continue.
- A file-storage quota rejection produces `failed` and exposes the existing
  retry/recovery path.
- A definitive metadata rejection produces `failed` for every affected book in
  that upload transaction.
- A failed local availability probe is not treated as `missing`; it remains
  unresolved and may be retried to avoid falsely graying the card.
- Status text must not expose credentials, private endpoints, or raw exception
  strings.

## Validation

Testing remains focused on the new state boundaries:

- Unit-test the physical and digital account-state truth table.
- Unit-test transient versus definitive failures.
- Unit-test local availability caching and invalidation.
- Test web OPFS and native existence checks without reading full files.
- Widget-test all three badges, guest behavior, and the missing-local tint.
- Widget-test details-page reading states and download retry behavior.
- Regression-test that superseded global status calculations cannot replace a
  newer connected/synced state.

No broad test-suite expansion or unrelated library-card refactor is included.
