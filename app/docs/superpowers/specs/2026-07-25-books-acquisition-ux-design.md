# Books Acquisition UX Design

Date: 2026-07-25

## Objective

Integrate online book discovery and managed downloads into the existing Books page without introducing a parallel visual system or disrupting ordinary library use.

The normal Books experience remains local-first. Online discovery is an explicit secondary action, and active downloads appear as temporary books in the same grid until they are imported.

## Design Principles

- Preserve the existing Books page for ordinary library browsing.
- Reuse Papyrus typography, spacing, filters, selection headers, dialogs, bottom sheets, and card dimensions.
- Show task language rather than infrastructure language.
- Keep local and online search modes visually and behaviorally distinct.
- Put loading, empty, and error feedback in the content area.
- Make download progress visible without requiring a separate management page.

## Entry and Local Search

The normal Books page retains its current header, local search, filter chips, sort control, view toggle, and Add book action. It does not show an acquisition toolbar, download button, or additional row below the search field.

Typing in the Books search field continues to filter only the local library.

When a non-empty local search has no matches and online acquisition is available, the existing empty state shows:

- Title: `No books found`
- Query-aware supporting text
- Primary action: `Search online for “<query>”`

When acquisition is unavailable, both online entry actions are omitted. The empty state does not expose integration setup, endpoint names, or backend failures.

The existing Add book bottom sheet gains a third option:

- Title: `Find books online`
- Subtitle: `Search connected book sources`

This option uses the same choice-card component, spacing, icon treatment, and navigation behavior as Import digital books and Add physical book.

Choosing the empty-state action enters online mode with the current query. Choosing Find books online enters online mode with an empty query and focuses the online search field.

## Online Results Mode

Online discovery is an in-place mode of the Books page. The application shell and Books destination remain unchanged, while the Books header and content become contextual.

The online header contains:

- A Back action that returns to the previous local Books state
- The title `Online results`
- A search field containing the current online query

Library filters, local sort, grid/list view toggle, and Add book are hidden while online mode is active because they do not apply to release results.

Remote search runs only when the user explicitly submits the query. Editing the field does not issue requests on every keystroke.

### Results

Results use a full-width list because release title, format, size, seeders, and source must be compared directly. They do not imitate library book cards.

Each row uses existing Papyrus list conventions:

- Checkbox at the leading edge
- Release title using the existing title style
- One secondary metadata line
- Existing divider and selected-row treatment
- Whole-row selection target

The metadata line contains, when available:

- Format
- File size
- Seeders
- Source

Raw release tokens, endpoint IDs, client hashes, and implementation terminology are never displayed.

### Selection

Selecting a result replaces the online header with the existing contextual selection-header pattern:

- Close selection
- Selected count
- Select all or Deselect all
- Download action

Closing selection clears selection but remains in online results. Back returns to the local Books state.

## Submission

If exactly one enabled download client is available, Download submits the selected releases immediately.

If multiple clients are available, Papyrus opens a standard choice bottom sheet using the same handle, shape, padding, typography, and choice rows as existing Papyrus sheets.

The client choice is described by its user-defined name. Internal endpoint details are not shown unless they are necessary to distinguish identically named clients.

When every selected release is submitted successfully:

- Successful items become placeholder books in the local grid.
- The page returns to the local Books view.
- Result selection is cleared.

When submission is partially or completely unsuccessful:

- Successful items still become placeholder books.
- The page remains in online mode.
- Failed items remain visible with a concise reason and selected for retry.
- Successfully submitted items are removed from the result selection.

## Download Placeholders

Each accepted download creates a placeholder card in the ordinary Books grid immediately.

Placeholder cards use the same dimensions, shape, spacing, and title placement as existing book cards. Their cover area uses a neutral Papyrus treatment rather than release artwork or a visually unrelated status panel.

The card presents:

- Book or release title
- Current download state
- Progress bar when progress is known
- Download speed and ETA when available
- `Needs attention` when user action is required

Placeholder cards participate in the All view and local text search.

When one or more managed download jobs exist, a temporary `Downloading` filter appears alongside the existing Books filters. It shows active, queued, failed, and attention-required placeholders. It disappears when no managed jobs remain.

When import completes, the placeholder is replaced by the imported book through the normal synchronized data flow. No manual refresh is required.

## Download Details and Actions

Opening a placeholder displays a standard Papyrus bottom sheet with:

- Title and current status
- Progress, downloaded size, total size, speed, and ETA when available
- Selected file when known
- Contextual actions such as Cancel, Retry import, or Select file

Jobs requiring file selection present the file choices within this sheet flow.

Download selection is separate from ordinary book selection so the action set is never ambiguous. Selecting placeholder cards uses the existing selection-header appearance with only actions valid for the selected jobs.

Available bulk actions:

- Cancel for active or queued jobs
- Retry for retryable failed imports
- Remove for cancelled or failed jobs

Cancel and Remove use the same confirmation-dialog appearance and destructive-action treatment as deleting a shelf. Confirmation is not presented as a bottom sheet.

## Language and Errors

User-facing language describes tasks and outcomes:

- `Search online`
- `Online results`
- `Downloading`
- `Needs attention`
- `Download failed`
- `Try again`

Names such as Prowlarr and qBittorrent appear only in integration settings or when a user-defined client name is needed for client selection.

Error placement follows the active task:

- Search errors replace the result content with a concise error state, Retry, and Back.
- Empty searches show an instructional empty state.
- No results show `No online results` and invite a different title, author, or ISBN.
- Submission errors stay attached to the failed result rows.
- Download and import errors appear on the placeholder and in its details sheet.

Raw backend exception text is logged for diagnostics but mapped to stable user-facing messages.

## State and Data Flow

The Books page has two mutually exclusive presentation modes:

1. Local library
2. Online results

Online-result selection and placeholder-download selection are contextual substates of those modes. They reuse the established selection-header appearance but keep independent selections and actions.

Online query and result selection are acquisition state. Local query, filters, sort, view mode, and book selection remain library state. Entering or leaving online mode does not discard the local state.

Server acquisition jobs remain the source of truth for download status. The client refreshes jobs while the Books page is visible and when the application resumes. Active jobs restore after reload, restart, or another device update.

Imported books continue to come from the existing synchronized book repository. The UI does not fabricate a completed book from the acquisition job response.

## Responsive Behavior

Mobile and desktop use the same state model and language.

On desktop, the online contextual header occupies the existing Books header region and results use the standard page width and padding.

On mobile, Back, title, and search wrap into the existing compact header structure. Selection actions use the existing mobile bottom action treatment when they cannot fit safely in the header.

No control depends on hover, and every row and card action has an accessible label and keyboard focus behavior.

## Testing

Widget tests cover:

- Local search remains local-only.
- The online action appears only for a non-empty, unmatched query when acquisition is ready.
- Add book exposes Find books online only when acquisition is available.
- Local state survives entering and leaving online mode.
- Remote requests run only on explicit submission.
- Loading, empty, success, and error result states.
- Result selection, select all, client choice, successful submission, complete failure, and partial failure.
- Placeholder rendering for each job state.
- Downloading filter visibility and filtering.
- Placeholder selection and valid bulk actions.
- Cancel and Remove confirmation dialogs.
- Completed import replacement.
- Mobile and desktop layouts under the real application theme.

Provider and gateway tests cover state transitions, polling lifecycle, error mapping, retry behavior, and restoration from server jobs.

## Non-Goals

- Automatic remote search on every local keystroke
- Mixing local books and online releases in one result collection
- A separate download-management destination
- Redesigning integration settings
- OPDS, OPFS, or other future source types
- Changing the server acquisition contract unless implementation reveals a blocking contract defect
