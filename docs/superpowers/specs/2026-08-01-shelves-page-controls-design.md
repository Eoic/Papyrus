# Shelves Page Controls

## Goal

Give the Shelves page the same persistent search-and-chip control pattern as the Books page. Users can filter, sort, and change shelf density without controls moving between mobile and desktop layouts.

## Interaction Model

The search field remains the primary header control. A fixed-height, horizontally scrollable chip row sits immediately below it on every breakpoint.

The chip order is:

1. Contents
2. Sort
3. Type
4. View

Active chips move before inactive chips while preserving their relative order, matching the Books page. An external `Clear all` action appears when any filter, non-default sort, or non-default view is active. Clearing restores Contents: All, Type: All, Sort: Name A–Z, and View: Small grid. Text search remains independent and is cleared only from the search field.

The existing header sort button and view toggle are removed. The New shelf action keeps its current breakpoint-specific placement.

## Controls

### Contents

- All
- With books
- Empty

Book occupancy is calculated from the current `DataStore` shelf membership rather than cached display values.

### Type

- All
- Regular
- Smart

Regular shelves match `isSmart == false`; Smart shelves match `isSmart == true`.

### Sort

- Name A–Z
- Name Z–A
- Book count: highest first
- Book count: lowest first
- Date created: newest first
- Date created: oldest first
- Date modified: newest first
- Date modified: oldest first

The provider may retain its existing sort field plus ascending flag internally. The chip presents each field-direction combination as a single explicit option so selecting the current option never silently reverses it.

### View

- Small grid
- Large grid
- List

Small grid preserves the current responsive density: 2 columns on phones, 4 on tablets, 5 on small desktops, and 6 on large desktops. Large grid uses 2 columns on phones, 3 on tablets and small desktops, and 4 on large desktops, following the Books grid pattern. List keeps the existing shelf list presentation.

## State and Data Flow

`ShelvesProvider` owns shelf search, contents filter, type filter, sort field and direction, and view mode. Its `shelves` getter applies operations in this order:

1. Plain case-insensitive search over name and description.
2. Contents and type filters using AND logic.
3. Sorting.

The page reads the resulting list once per build and passes it to the grid, list, count, and empty-state decisions. Chip selections notify once and immediately update the visible shelves.

## Components

Add a shelf-specific `ShelvesFilterChips` widget rather than generalizing the larger Books filter component. It uses the same visual language and modal selection-sheet interaction but exposes only shelf-specific options. This avoids coupling unrelated filter models and keeps the page focused.

`ShelvesPage` uses one shared control structure across breakpoints: search row, chip row, then results. Mobile retains the navigation menu and floating New shelf action. Desktop retains its New shelf button.

## Empty States

When the complete shelf collection is empty, retain the existing creation-focused `No shelves yet` state and Create shelf action.

When shelves exist but search or filters produce no results, show `No shelves found` with guidance to change search or filters. Do not present the Create shelf action as the primary resolution for a filtered result.

## Accessibility

- Chips expose category-specific semantic labels and selection state.
- Selection sheets have descriptive titles and indicate the selected option.
- Search clear, Clear all, New shelf, and view choices retain tooltips or semantic labels.
- The horizontally scrolling row remains keyboard and pointer accessible.
- Selected state is communicated by more than color.

## Scope

- These controls apply to the main Shelves page only.
- Shelf contents retain their existing book controls.
- Advanced shelf filtering and saved presets are out of scope.
- No new automated test files are required.

## Verification

- Run targeted `flutter analyze` for the provider, page, and new chip widget.
- Build the debug web application.
- Verify the same control order and spacing on mobile and desktop.
- Verify every search, filter, sort, and view combination.
- Verify Small grid, Large grid, and List at each responsive breakpoint.
- Verify Clear all resets structured controls without clearing text search.
- Verify empty-library and no-results states remain distinct.
- Verify active chips move first without changing the chip-row height.
