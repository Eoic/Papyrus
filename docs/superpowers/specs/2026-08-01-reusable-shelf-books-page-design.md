# Reusable Shelf Books Page Design

- Status: Approved
- Date: 2026-08-01
- Audience: Papyrus client engineers

## Overview

Replace the dedicated shelf-contents presentation with the Books page presentation configured for a shelf-scoped book collection. The shelf route must reuse the Books page search, filters, sorting, view modes, selection behavior, grids, lists, and responsive layout instead of maintaining parallel implementations.

## Problem

`ShelfContentsPage` currently owns separate search, filtering, sorting, grid/list rendering, selection headers, and responsive layouts. That implementation has already diverged from `LibraryPage` and requires every Books page improvement to be implemented twice. It also mixes child shelves with books, which conflicts with the faceted book-filtering model.

## Goals

- Use one Books page implementation for both the complete library and an individual shelf.
- Give every shelf page independent search, structured filters, sorting, view mode, and selection state.
- Restrict a shelf page to books assigned directly to that shelf.
- Derive quick-filter and advanced-filter choices from the shelf's complete, unfiltered book collection.
- Show the shelf name and replace the primary action with `Add to shelf`.
- Preserve the existing invalid-shelf experience.
- Remove obsolete shelf-book presentation state and logic from `ShelvesProvider`.

## Non-goals

- Implement adding books to a shelf. The `Add to shelf` action is intentionally an enabled no-op.
- Remove shelf hierarchy from models, persistence, shelf-management screens, or `DataStore`.
- Render child shelves on a shelf books page.
- Change the main Books page's behavior or filter-option population.
- Add or modernize automated tests.

## Constraints

- The existing uncommitted Shelves chip-alignment work must remain separate from this change.
- The shelf page must use a distinct `LibraryProvider`; filters from the main Books page must not carry into a shelf or back out of it.
- Values within one structured filter category retain OR behavior, and active categories retain AND behavior.
- Filter choices must remain stable while filters are applied. They are derived from the unfiltered shelf collection, not the current result set.
- Shelf membership remains the outer collection constraint and is applied before text search, structured filters, and sorting.

## Proposed Design

### Reusable Books Page

Make `LibraryPage` accept an optional shelf collection configuration. With no shelf configuration, it retains its current main-library behavior. With shelf configuration, it receives the shelf identity, shelf name, scoped source books, primary-action presentation, and back-navigation behavior.

The reusable page continues to own the responsive header, search bar, filter chips, advanced-filter sheet, result presentation, selection mode, bulk actions, and book navigation. Shelf mode changes only context-specific inputs and excludes library-wide acquisition controls.

### Shelf Route Adapter

Reduce `ShelfContentsPage` to a thin route adapter that:

1. Resolves the route's shelf ID through `DataStore`.
2. Shows the current `Shelf not found` state when the record is absent.
3. Owns and disposes a shelf-local `LibraryProvider`.
4. Obtains direct members through `DataStore.getBooksInShelf(shelf.id)`.
5. Renders `LibraryPage` with the shelf configuration and local provider.

It must not instantiate `ShelvesProvider`, query child shelves, or render `ShelfCard` items.

### Scoped Filter Options

Extend `LibraryFilterOptions` so callers may provide an unfiltered source collection. The main Books page supplies all library books; shelf mode supplies direct shelf members.

Metadata options are derived from those source books:

- primary authors and co-authors;
- normalized languages;
- formats;
- publishers;
- series.

Organization options are restricted to records attached to at least one source book:

- topic IDs from each source book's tag relations;
- shelf IDs from each source book's shelf relations.

Quick chips and the advanced sheet receive the same scoped options. Advanced-filter preview counts run `LibraryProvider.filterBooks` against the same source collection. Applied filters do not change the source used to construct options.

### Shelf Collection Pipeline

Shelf mode resolves visible books in this order:

1. Read all books assigned directly to the shelf.
2. Apply plain-text search and the shelf-local `LibraryFilters` through `LibraryProvider.filterBooks`.
3. Apply the shelf-local sort through `LibraryProvider.sortBooks`.
4. Render using the shelf-local `LibraryViewMode`.

The current library-wide acquisition placeholders, downloading-only chip, online results mode, and online-search empty-state action are omitted in shelf mode. Normal book selection and bulk book actions remain available.

### Responsive Header and Actions

On mobile, shelf mode shows Back and the shelf name before the normal Books search and filter rows. On desktop, the shelf name appears above the normal search/action row.

The desktop `Add book` button becomes `Add to shelf`. The mobile FAB retains the Books page shape and plus icon with an `Add to shelf` tooltip and semantic label. Both controls use an empty callback so they remain visually enabled without changing data.

### Empty and Missing States

- An invalid or deleted shelf shows the existing `Shelf not found` state and Back-to-shelves action.
- A valid shelf with no direct books shows shelf-specific empty copy and the no-op `Add to shelf` action.
- A non-empty shelf reduced to zero results by search or filters shows the Books page no-results treatment without offering online search.

## Interfaces and Dependencies

- `LibraryPage` gains optional shelf-collection configuration while preserving its default constructor behavior for the main Books route.
- `LibraryFilterOptions.fromDataStore` gains an optional source-book collection.
- `LibraryFilterChips` gains scoped filter options or source books supplied by `LibraryPage`.
- `LibraryAdvancedFilterSheet.show` gains the source collection used for its options and preview count.
- `ShelfContentsPage` owns a local `LibraryProvider` and delegates rendering to `LibraryPage`.
- `DataStore.getBooksInShelf`, `getShelfIdsForBook`, and `getTagIdsForBook` remain the membership sources of truth.

## Risks and Mitigations

- **Main Books regressions from page parameterization:** keep all new configuration optional and preserve existing defaults; run targeted analysis and a web build.
- **Filters showing irrelevant values:** construct both quick and advanced options from the unfiltered shelf source.
- **Preview counts disagreeing with visible results:** pass the identical source collection to the advanced sheet and the page filtering pipeline.
- **State leaking between pages:** create and dispose a dedicated `LibraryProvider` in the shelf route adapter.
- **Stale shelf data after store updates:** resolve the shelf and its direct books from the watched `DataStore` on rebuild.
- **Existing selected values disappear after membership changes:** the scoped provider is page-local, and the UI must tolerate selected values that are temporarily absent from refreshed options until filters are cleared.

## Rollout and Rollback

This is a client-only presentation refactor with no persisted-data migration. Roll out by replacing the shelf route implementation and removing only shelf-book-specific state from `ShelvesProvider`. Roll back by restoring the previous `ShelfContentsPage` and provider members; shelf models and stored relations remain compatible throughout.

## Verification

- Run targeted `flutter analyze` over the reusable page, shelf adapter, filter-option model, chips, advanced sheet, and providers.
- Run `flutter build web --debug`.
- Manually verify independent state between Books and shelf routes.
- Verify direct shelf membership only; child shelves never appear.
- Verify shelf-scoped option lists, preview counts, filtering, sorting, and all three view modes.
- Verify mobile and desktop shelf headers and the enabled no-op `Add to shelf` actions.
- Verify empty, no-results, missing-shelf, selection, bulk-action, and book-navigation states.

## Accepted Decisions

- Shelf pages use separate state from the main Books page.
- Filter choices are shelf-specific and derived from unfiltered direct shelf members.
- Child shelves are omitted only from the contents route; hierarchy remains elsewhere.
- The reusable configurable `LibraryPage` approach is preferred over a second composed page or a larger shared-page extraction.
- No automated tests are added in this task.

## Open Questions

None.
