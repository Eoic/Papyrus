# Shelves Page Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Books-style chip row to the main Shelves page for contents filtering, type filtering, explicit sorting, and Small grid/Large grid/List display modes.

**Architecture:** Keep all shelf collection state and list transformation in `ShelvesProvider`. Add a shelf-specific chip widget with single-selection bottom sheets, then simplify `ShelvesPage` so mobile and desktop share the same search → chips → results structure. Separate the main shelf-collection view mode from the existing shelf-contents book view mode so this feature does not change the controls inside a shelf.

**Tech Stack:** Flutter, Dart, Provider, Material 3, Papyrus design tokens

---

### Task 1: Separate Shelf Collection State from Shelf-Contents State

**Files:**
- Modify: `app/lib/providers/shelves_provider.dart:7-205`
- Modify: `app/lib/pages/shelf_contents_page.dart:300-355`

- [ ] **Step 1: Define the shelf collection enums and defaults**

Replace the ambiguous two-state main-page view model with:

```dart
enum ShelvesViewMode { smallGrid, largeGrid, list }

enum ShelfContentsFilter { all, withBooks, empty }

enum ShelfTypeFilter { all, regular, smart }
```

Keep `ShelfSortOption { name, bookCount, dateCreated, dateModified }` and its ascending flag. Add a separate private boolean for the existing shelf-contents grid/list control:

```dart
ShelvesViewMode _viewMode = ShelvesViewMode.smallGrid;
bool _isBookGridView = true;
ShelfContentsFilter _contentsFilter = ShelfContentsFilter.all;
ShelfTypeFilter _typeFilter = ShelfTypeFilter.all;
```

- [ ] **Step 2: Add collection-control getters and setters**

Expose `contentsFilter`, `typeFilter`, `viewMode`, `isSmallGridView`, `isLargeGridView`, and collection `isListView`. Add idempotent setters for contents, type, sort field plus explicit direction, and view mode. Add:

```dart
bool get hasActiveShelfControls =>
    _contentsFilter != ShelfContentsFilter.all ||
    _typeFilter != ShelfTypeFilter.all ||
    _shelfSortOption != ShelfSortOption.name ||
    !_shelfSortAscending ||
    _viewMode != ShelvesViewMode.smallGrid;

void clearShelfControls() {
  _contentsFilter = ShelfContentsFilter.all;
  _typeFilter = ShelfTypeFilter.all;
  _shelfSortOption = ShelfSortOption.name;
  _shelfSortAscending = true;
  _viewMode = ShelvesViewMode.smallGrid;
  notifyListeners();
}
```

Do not clear `_searchQuery` here.

- [ ] **Step 3: Apply shelf filters before sorting**

Update `shelves` to apply name/description search, then:

```dart
switch (_contentsFilter) {
  case ShelfContentsFilter.all:
    break;
  case ShelfContentsFilter.withBooks:
    list = list.where((shelf) => _dataStore!.getBookCountForShelf(shelf.id) > 0).toList();
  case ShelfContentsFilter.empty:
    list = list.where((shelf) => _dataStore!.getBookCountForShelf(shelf.id) == 0).toList();
}

switch (_typeFilter) {
  case ShelfTypeFilter.all:
    break;
  case ShelfTypeFilter.regular:
    list = list.where((shelf) => !shelf.isSmart).toList();
  case ShelfTypeFilter.smart:
    list = list.where((shelf) => shelf.isSmart).toList();
}
```

Call `_applySorting` last. Add a `hasAnyShelves` getter based on the unfiltered `DataStore` collection so the page can distinguish no data from no matches.

- [ ] **Step 4: Preserve shelf-contents grid/list behavior**

Add `isBookGridView`, `isBookListView`, and `setBookViewMode(bool isGrid)` around `_isBookGridView`. Update `shelf_contents_page.dart` to use those APIs instead of the main collection `viewMode`, `isGridView`, and `isListView`. Do not change shelf-contents layout or chip behavior.

- [ ] **Step 5: Verify the provider layer**

Run:

```bash
flutter analyze lib/providers/shelves_provider.dart lib/pages/shelf_contents_page.dart
```

Expected: no issues.

### Task 2: Build the Shelf Filter Chip Row

**Files:**
- Create: `app/lib/widgets/shelves/shelves_filter_chips.dart`

- [ ] **Step 1: Add focused presentation types**

Create private `_ChipEntry`, `_SelectionOption<T>`, `_DropdownFilterChip`, and `_SingleSelectionSheet<T>` types modeled on `library_filter_chips.dart`. Keep them local to the shelf widget; do not expose or refactor the Books filter implementation.

Use `ActionChip` with:

- category-specific semantics and selected state;
- an 18 px leading icon and trailing arrow;
- `secondaryContainer` for active controls;
- compact visual density and `AppRadius.full` shape;
- a transparent border in the selected state when needed to keep intrinsic height stable.

Present selections with `showModalBottomSheet(useRootNavigator: true)` and a list whose selected row has a trailing check.

- [ ] **Step 2: Define explicit options**

Contents options: All, With books, Empty.

Type options: All, Regular, Smart.

Sort options use a private value record containing both `ShelfSortOption` and `ascending`:

```dart
typedef _ShelfSortSelection = ({ShelfSortOption option, bool ascending});
```

Define all eight approved sort labels. View options are Small grid, Large grid, and List.

- [ ] **Step 3: Build active-first ordering and Clear all**

Construct entries in default order Contents, Sort, Type, View. Treat defaults as inactive. Stable-sort entries so active controls render first, then show them in a fixed-height horizontal `ListView.separated` matching the Books chip-row padding and spacing.

When `provider.hasActiveShelfControls` is true, append a compact `Clear all` text action that calls `provider.clearShelfControls`. Text search remains unchanged.

- [ ] **Step 4: Verify the chip widget**

Run:

```bash
flutter analyze lib/widgets/shelves/shelves_filter_chips.dart
```

Expected: no issues.

### Task 3: Integrate One Shared Control Pattern into ShelvesPage

**Files:**
- Modify: `app/lib/pages/shelves_page.dart:88-330`

- [ ] **Step 1: Remove legacy header controls**

Delete `_buildSortButton`, `_buildSortMenuItem`, and `_buildViewToggle`. Remove the shared `ViewModeToggle` import. Add the `ShelvesFilterChips` import.

Keep `_buildSearchField`, the mobile menu button, the mobile floating New shelf action, and the desktop New shelf button.

- [ ] **Step 2: Place the chip row below search on mobile**

Build the mobile control stack as:

1. Menu plus expanded search field.
2. `Spacing.sm` vertical gap.
3. `ShelvesFilterChips`.
4. Results.

Remove the shelf-count/view-toggle row so the chip row occupies a stable position equivalent to Books.

- [ ] **Step 3: Place the chip row below search on desktop**

Keep Search and New shelf in the desktop header row, including compact-width wrapping if required. Put `ShelvesFilterChips` on the next line with `Spacing.sm` separation. Do not move sort or view back into the search row at wide widths.

- [ ] **Step 4: Render from one visible list per build**

Capture `final shelves = provider.shelves` once in each layout and pass it into `_buildShelfGrid` or `_buildShelfList`. Update those helpers to accept `List<Shelf>` rather than repeatedly reading the provider getter.

Select the result widget as follows:

```dart
if (!provider.hasAnyShelves) {
  return _buildEmptyState(context);
}
if (shelves.isEmpty) {
  return _buildNoResultsState(context);
}
if (provider.viewMode == ShelvesViewMode.list) {
  return _buildShelfList(context, shelves);
}
return _buildShelfGrid(context, shelves, provider.viewMode);
```

- [ ] **Step 5: Implement responsive Small and Large grid density**

Keep existing aspect ratios and spacing. Resolve columns from the selected mode:

| Breakpoint | Small grid | Large grid |
|---|---:|---:|
| Phone | 2 | 2 |
| Tablet | 4 | 3 |
| Small desktop | 5 | 3 |
| Large desktop | 6 | 4 |

- [ ] **Step 6: Add the filtered no-results state**

Add `_buildNoResultsState` using `EmptyState` with title `No shelves found` and guidance to change search or filters. Do not include the Create shelf action. Retain the existing creation-focused empty state when `hasAnyShelves` is false.

- [ ] **Step 7: Verify page integration**

Run:

```bash
flutter analyze lib/providers/shelves_provider.dart lib/pages/shelves_page.dart lib/pages/shelf_contents_page.dart lib/widgets/shelves/shelves_filter_chips.dart
```

Expected: no issues.

### Task 4: Final Verification

**Files:**
- Verify: `app/lib/providers/shelves_provider.dart`
- Verify: `app/lib/pages/shelves_page.dart`
- Verify: `app/lib/pages/shelf_contents_page.dart`
- Verify: `app/lib/widgets/shelves/shelves_filter_chips.dart`

- [ ] **Step 1: Format and validate the diff**

Run:

```bash
dart format app/lib/providers/shelves_provider.dart app/lib/pages/shelves_page.dart app/lib/pages/shelf_contents_page.dart app/lib/widgets/shelves/shelves_filter_chips.dart
git diff --check
```

- [ ] **Step 2: Run final static analysis**

Run the four-file targeted `flutter analyze` command from Task 3.

- [ ] **Step 3: Build the web application**

Run:

```bash
flutter build web --debug
```

Expected: build succeeds.

- [ ] **Step 4: Manually verify behavior**

- Confirm search matches shelf names and descriptions.
- Confirm Contents and Type combine with AND logic.
- Confirm every explicit sort direction.
- Confirm Small grid, Large grid, and List on phone, tablet, and desktop widths.
- Confirm active chips move first without moving the results vertically.
- Confirm Clear all preserves text search.
- Confirm `No shelves yet` and `No shelves found` appear in the correct states.
- Confirm shelf contents still switch between their existing grid and list views.

- [ ] **Step 5: Commit the implementation**

```bash
git add app/lib/providers/shelves_provider.dart app/lib/pages/shelves_page.dart app/lib/pages/shelf_contents_page.dart app/lib/widgets/shelves/shelves_filter_chips.dart docs/superpowers/plans/2026-08-01-shelves-page-controls.md
git commit -m "PPR-25: Add shelves page controls"
```
