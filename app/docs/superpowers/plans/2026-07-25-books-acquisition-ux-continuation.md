# Books acquisition UX continuation checkpoint

Saved: 2026-07-25

## Repository state

- Repository: `/home/karolis/Documents/Projects/Papyrus/client/app`
- Branch: `feature/torrent-acquisition`
- Current HEAD: `878241c fix: guard acquisition async operations`
- The active implementation agent was interrupted at the user's request.
- There are no uncommitted acquisition-task edits after the interruption.
- Task 8 has not started.

The existing implementation plan and approved design remain the source of truth:

- `docs/superpowers/plans/2026-07-25-books-acquisition-ux.md`
- `docs/superpowers/specs/2026-07-25-books-acquisition-ux-design.md`

## Completed work

Tasks 1 through 6 passed their spec and quality reviews.

Task 7 is implemented through these commits:

- `878f444 feat: integrate downloads into books page`
- `5588790 test: complete books acquisition acceptance coverage`
- `4c79e79 fix: harden acquisition provider state transitions`
- `51a5242 fix: harden books acquisition interactions`
- `9b192d4 fix: close acquisition lifecycle gaps`
- `878241c fix: guard acquisition async operations`

At `878241c`, Task 7 passed its final spec review. The latest focused verification passed 298 tests, scoped Flutter analysis, formatting, and diff checks.

## One remaining Task 7 quality blocker

An in-flight `refreshJobs()` can apply a stale server snapshot after a newer successful local job write.

Example:

1. Visible polling starts `listJobs()` and receives a delayed response containing a failed job.
2. The user successfully removes that job.
3. The delayed list response completes and replaces `_jobs` with its older snapshot.
4. The removed job is resurrected.

The same race can revert Cancel or Retry, or erase a newly submitted placeholder.

### Required fix

Add job-state revision or equivalent request ownership in `AcquisitionDownloadsProvider`:

- Capture the job-state revision when `refreshJobs()` starts.
- Increment the revision on every authoritative local `_jobs` write, including successful remove, cancel, retry, file selection, and submitted-job insertion.
- Discard a list response when the gateway generation or job-state revision no longer matches.
- Ensure loading/finalization state and polling scheduling do not get stuck when a response is discarded.
- A later fresh refresh must still converge to the server state.

Add delayed-`listJobs` regression tests for at least:

- Remove
- Cancel
- Retry
- Submission
- A later fresh refresh after the stale response is discarded

Then rerun provider, LibraryPage, details-sheet, grid, and list suites, scoped analysis, formatting, and diff checks.

After committing the fix, repeat the Task 7 spec review followed by the Task 7 quality review on the exact new head. Approval requires no Critical or Important issues.

## Task 8 after Task 7 approval

Run the full regression and analysis commands from the implementation plan, then complete the manual live smoke workflow for:

- Explicit online search from Books
- Multiple-release selection and submission
- qBittorrent progress appearing in the normal grid/list
- Downloading filter
- Details, cancel, retry, remove, and file-selection flows
- Responsive desktop/mobile and e-ink presentation

Use the verification-before-completion and final branch-finishing workflows before claiming completion.

## User-owned dirty files to preserve

These pre-existing changes are unrelated to the remaining Task 7 fix and must not be reset, overwritten, staged, or committed accidentally:

- `lib/main.dart`
- `lib/pages/acquisition_page.dart`
- `lib/providers/acquisition_availability_provider.dart`
- `lib/widgets/acquisition/acquisition_endpoint_editor.dart`
- `test/acquisition/acquisition_availability_provider_test.dart`
- `test/pages/acquisition_page_test.dart`
- `test/widgets/acquisition/acquisition_endpoint_editor_test.dart`
