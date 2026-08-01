# Reusable Shelf Books Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render direct shelf members through the Books page implementation with shelf-local controls, shelf-scoped filter options, an editable shelf identity header, and a no-op `Add to shelf` action.

**Architecture:** `ShelfContentsPage` becomes a route adapter that owns a local `LibraryProvider` and passes the current `Shelf` into a configurable `LibraryPage`. `LibraryPage` chooses either all library books or direct shelf members as its stable source collection, then reuses the existing filter, sort, selection, grid, list, and responsive presentation pipeline. Quick-filter and advanced-filter options are derived from that unfiltered source collection.

**Tech Stack:** Flutter, Dart, Provider, GoRouter, existing Papyrus `DataStore`, `LibraryProvider`, and Material bottom sheets.

**Repository note:** Preserve the existing uncommitted change in `app/lib/widgets/shelves/shelves_filter_chips.dart`. Stage only the files named by each task. Per the approved design, do not add or modernize automated tests.

---

### Task 1: Derive Filter Options from a Supplied Book Collection

**Files:**
- Modify: `app/lib/models/library_filter_options.dart`

- [ ] **Step 1: Add the book model dependency and scoped source parameter**

Import `Book` and `LibraryReadingStatus`, add scoped reading option fields, and change the factory to accept an optional source while preserving main-library behavior:

```dart
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';

final List<LibraryFilterOption<LibraryReadingStatus>> readingStatuses;
final List<int> ratings;
final bool hasUnrated;

factory LibraryFilterOptions.fromDataStore(
  DataStore dataStore, {
  Iterable<Book>? books,
}) {
  final isScoped = books != null;
  final sourceBooks = books ?? dataStore.books;
```

Add the three fields to the const constructor.

- [ ] **Step 2: Collect organization membership from source books**

Alongside the existing normalized metadata maps, collect stable IDs while iterating the source:

```dart
final topicIds = <String>{};
final shelfIds = <String>{};
final readingStatuses = <LibraryReadingStatus>{};
final ratings = <int>{};
var hasUnrated = false;

for (final book in sourceBooks) {
  for (final author in [book.author, ...book.coAuthors]) {
    _addNormalized(authors, author);
  }

  final language = book.language;
  final normalizedLanguage = normalizeBookLanguage(language);
  if (language != null && normalizedLanguage != null) {
    languages.putIfAbsent(normalizedLanguage, () => bookLanguageLabel(language));
  }

  _addNormalized(formats, book.formatLabel);
  _addNormalized(publishers, book.publisher);
  _addNormalized(series, book.seriesName);
  topicIds.addAll(dataStore.getTagIdsForBook(book.id));
  shelfIds.addAll(dataStore.getShelfIdsForBook(book.id));
  readingStatuses.add(book.readingStatus);
  final rating = book.rating;
  if (rating == null) {
    hasUnrated = true;
  } else {
    ratings.add(rating);
  }
}
```

Build topic and shelf options only from matching IDs, retaining the existing alphabetical sort:

```dart
topics: _sortedOptions(
  dataStore.tags
      .where((topic) => topicIds.contains(topic.id))
      .map((topic) => LibraryFilterOption(value: topic.id, label: topic.name)),
),
shelves: _sortedOptions(
  dataStore.shelves
      .where((shelf) => shelfIds.contains(shelf.id))
      .map((shelf) => LibraryFilterOption(value: shelf.id, label: shelf.name)),
),
```

Populate reading choices from the source only when a scoped collection was supplied; retain the main Books page's current complete choice set otherwise:

```dart
readingStatuses: [
  for (final status in LibraryReadingStatus.values)
    if (!isScoped || readingStatuses.contains(status))
      LibraryFilterOption(value: status, label: status.label),
],
ratings: isScoped ? (ratings.toList()..sort()) : const [1, 2, 3, 4, 5],
hasUnrated: isScoped ? hasUnrated : true,
```

- [ ] **Step 3: Format and analyze the model**

Run:

```bash
cd app
dart format lib/models/library_filter_options.dart
flutter analyze lib/models/library_filter_options.dart
```

Expected: formatting succeeds and analysis reports no issues.

- [ ] **Step 4: Commit the scoped option model**

```bash
git add app/lib/models/library_filter_options.dart
git commit -m "PPR-25: Scope library filter options"
```

### Task 2: Pass Scoped Options and Books into Both Filter Surfaces

**Files:**
- Modify: `app/lib/widgets/library/library_filter_chips.dart`
- Modify: `app/lib/widgets/library/library_advanced_filter_sheet.dart`

- [ ] **Step 1: Allow quick-filter options to be supplied explicitly**

Add an optional `LibraryFilterOptions filterOptions` field to `LibraryFilterChips` so the existing call sites remain valid until the page supplies the scoped value:

```dart
final LibraryFilterOptions? filterOptions;

const LibraryFilterChips({
  super.key,
  this.filterOptions,
  this.horizontalPadding,
  this.showDownloading = false,
  this.isDownloadingSelected = false,
  this.onDownloadingTapped,
  this.onLibraryFilterTapped,
});
```

In `build`, retain the `DataStore` watch for the compatibility fallback and replace the locally created options with:

```dart
final filterOptions = this.filterOptions ?? LibraryFilterOptions.fromDataStore(dataStore);
```

Replace the static status option list at use time with options derived from `filterOptions.readingStatuses`:

```dart
final statusOptions = [
  for (final option in filterOptions.readingStatuses)
    _SelectionOption<LibraryReadingStatus>(
      value: option.value,
      label: option.label,
      icon: option.value.icon,
    ),
];
```

Use `statusOptions` for the status chip label and selection sheet. The main page still receives all status values through the fallback.

- [ ] **Step 2: Add source books and options to the advanced sheet API**

Add optional immutable inputs so the main page remains valid before Task 5 wires its explicit collection:

```dart
final List<Book>? sourceBooks;
final LibraryFilterOptions? filterOptions;
```

Accept them in both `LibraryAdvancedFilterSheet.show` and its constructor, and pass them through the `DraggableScrollableSheet` builder.

- [ ] **Step 3: Use the scoped inputs for facets and preview count**

Replace the state initializer and preview source:

```dart
late final List<Book> _sourceBooks = widget.sourceBooks ?? widget.dataStore.books;
late final LibraryFilterOptions _options =
    widget.filterOptions ?? LibraryFilterOptions.fromDataStore(widget.dataStore, books: _sourceBooks);

int get _matchingBookCount {
  return widget.libraryProvider
      .filterBooks(_sourceBooks, dataStore: widget.dataStore, filters: _draft)
      .length;
}
```

Use `_options.readingStatuses` in the Reading status `_SmallFacet`. Extend `_RatingFilterField` with explicit availability:

```dart
final List<int> availableRatings;
final bool showUnrated;

const _RatingFilterField({
  required this.ratings,
  required this.includeUnrated,
  required this.availableRatings,
  required this.showUnrated,
  required this.onChanged,
});
```

Render the Unrated chip only when `showUnrated`, and iterate `availableRatings` instead of the hard-coded 1–5 loop. Only add the status and rating controls when their scoped option collections are non-empty; the main-library fallback keeps the existing controls unchanged.

This keeps options stable while the local draft changes.

- [ ] **Step 4: Format and analyze both filter surfaces**

Run:

```bash
cd app
dart format lib/widgets/library/library_filter_chips.dart lib/widgets/library/library_advanced_filter_sheet.dart
flutter analyze lib/widgets/library/library_filter_chips.dart lib/widgets/library/library_advanced_filter_sheet.dart
```

Expected: no analysis issues and the existing main-library call sites remain valid.

- [ ] **Step 5: Commit the filter-surface interfaces**

```bash
git add app/lib/widgets/library/library_filter_chips.dart app/lib/widgets/library/library_advanced_filter_sheet.dart
git commit -m "PPR-25: Add scoped library filter inputs"
```

### Task 3: Keep Favorite Data Shared While Shelf Controls Stay Local

**Files:**
- Modify: `app/lib/providers/library_provider.dart`

- [ ] **Step 1: Add an optional favorite-state delegate**

Give a shelf-local provider access to the session's existing favorite overrides without sharing its filters, sort, view, search, or selection state:

```dart
class LibraryProvider extends ChangeNotifier {
  final LibraryProvider? _favoriteDelegate;

  LibraryProvider({LibraryProvider? favoriteDelegate})
      : _favoriteDelegate = favoriteDelegate {
    _favoriteDelegate?.addListener(_onFavoriteDelegateChanged);
  }

  void _onFavoriteDelegateChanged() {
    notifyListeners();
  }
```

- [ ] **Step 2: Route favorite reads and writes through the delegate**

Update only the favorite API:

```dart
bool isBookFavorite(String bookId, bool originalFavorite) {
  return _favoriteDelegate?.isBookFavorite(bookId, originalFavorite) ??
      _favoriteOverrides[bookId] ??
      originalFavorite;
}

void toggleFavorite(String bookId, bool currentFavorite) {
  final delegate = _favoriteDelegate;
  if (delegate != null) {
    delegate.toggleFavorite(bookId, currentFavorite);
    return;
  }

  _favoriteOverrides[bookId] = !currentFavorite;
  notifyListeners();
}

bool? getFavoriteOverride(String bookId) {
  return _favoriteDelegate?.getFavoriteOverride(bookId) ?? _favoriteOverrides[bookId];
}
```

- [ ] **Step 3: Remove the delegate listener during disposal**

```dart
@override
void dispose() {
  _favoriteDelegate?.removeListener(_onFavoriteDelegateChanged);
  super.dispose();
}
```

- [ ] **Step 4: Format, analyze, and commit**

```bash
cd app
dart format lib/providers/library_provider.dart
flutter analyze lib/providers/library_provider.dart
cd ..
git add app/lib/providers/library_provider.dart
git commit -m "PPR-25: Share favorite state with shelf views"
```

### Task 4: Support Clearing Shelf Descriptions

**Files:**
- Modify: `app/lib/models/shelf.dart`
- Modify: `app/lib/providers/shelves_provider.dart`

- [ ] **Step 1: Add explicit nullable-field clearing to `Shelf.copyWith`**

Add a focused flag without changing the behavior of omitted fields:

```dart
Shelf copyWith({
  String? id,
  String? name,
  String? description,
  bool clearDescription = false,
  String? colorHex,
  IconData? icon,
  String? parentShelfId,
  bool? isSmart,
  String? smartQuery,
  int? sortOrder,
  DateTime? createdAt,
  DateTime? updatedAt,
  int? bookCount,
  List<CoverPreview>? coverPreviews,
}) {
  return Shelf(
    id: id ?? this.id,
    name: name ?? this.name,
    description: clearDescription ? null : description ?? this.description,
    colorHex: colorHex ?? this.colorHex,
    icon: icon ?? this.icon,
    parentShelfId: parentShelfId ?? this.parentShelfId,
    isSmart: isSmart ?? this.isSmart,
    smartQuery: smartQuery ?? this.smartQuery,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    bookCount: bookCount ?? this.bookCount,
    coverPreviews: coverPreviews ?? this.coverPreviews,
  );
}
```

- [ ] **Step 2: Make the existing full edit flow clear an empty description**

The current `AddShelfSheet` already returns `null` for an empty description. Update `ShelvesProvider.updateShelf`:

```dart
final updatedShelf = shelf.copyWith(
  name: name,
  description: description,
  clearDescription: description == null,
  colorHex: colorHex,
  icon: icon,
  updatedAt: DateTime.now(),
);
```

- [ ] **Step 3: Format and analyze the update path**

Run:

```bash
cd app
dart format lib/models/shelf.dart lib/providers/shelves_provider.dart
flutter analyze lib/models/shelf.dart lib/providers/shelves_provider.dart lib/widgets/shelves/add_shelf_sheet.dart
```

Expected: no analysis issues.

- [ ] **Step 4: Commit nullable description support**

```bash
git add app/lib/models/shelf.dart app/lib/providers/shelves_provider.dart
git commit -m "PPR-25: Allow clearing shelf descriptions"
```

### Task 5: Configure `LibraryPage` for a Shelf Collection

**Files:**
- Modify: `app/lib/pages/library_page.dart`

- [ ] **Step 1: Add shelf presentation inputs without changing the default route**

Import `LibraryFilterOptions` and `Shelf`, then extend the widget:

```dart
class LibraryPage extends StatefulWidget {
  final Shelf? shelf;
  final VoidCallback? onBack;
  final VoidCallback? onEditShelf;

  const LibraryPage({
    super.key,
    this.shelf,
    this.onBack,
    this.onEditShelf,
  });

  bool get isShelfView => shelf != null;
```

The existing `const LibraryPage()` construction remains the main Books page.

- [ ] **Step 2: Disable library-wide acquisition state in shelf mode**

In `didChangeDependencies`, treat the downloads provider as unavailable when `widget.isShelfView`. Do the same in `build` so shelf mode cannot enter online presentation, register library visibility, expose orphan acquisition jobs, or show the downloading filter.

Use the scoped source in `build`:

```dart
List<Book> _sourceBooks(DataStore dataStore) {
  final shelf = widget.shelf;
  return shelf == null ? dataStore.books : dataStore.getBooksInShelf(shelf.id);
}

final sourceBooks = _sourceBooks(dataStore);
final filterOptions = LibraryFilterOptions.fromDataStore(
  dataStore,
  books: sourceBooks,
);
final books = _getFilteredBooks(libraryProvider, dataStore, sourceBooks);
```

Update `_getFilteredBooks` to filter and sort the supplied source instead of reading `dataStore.books` internally:

```dart
List<Book> _getFilteredBooks(
  LibraryProvider provider,
  DataStore dataStore,
  List<Book> sourceBooks,
) {
  final books = provider.filterBooks(sourceBooks, dataStore: dataStore);
  return provider.sortBooks(books);
}
```

Pass `sourceBooks` and `filterOptions` into both responsive layout methods. Use `sourceBooks` when building acquisition-library items; in shelf mode the downloads provider is null, so no linked or orphan acquisition jobs are introduced.

- [ ] **Step 3: Feed one scoped source into chips and advanced filters**

Pass `filterOptions` into both `LibraryFilterChips` instances. Update `_showAdvancedFilters` to recompute the unfiltered current source and call:

```dart
final dataStore = context.read<DataStore>();
final sourceBooks = _sourceBooks(dataStore);

LibraryAdvancedFilterSheet.show(
  context,
  libraryProvider: libraryProvider,
  dataStore: dataStore,
  sourceBooks: sourceBooks,
  filterOptions: LibraryFilterOptions.fromDataStore(dataStore, books: sourceBooks),
);
```

The main page supplies all books through the same path.

- [ ] **Step 4: Build the flat shelf identity header**

Add a private helper that uses the shelf's icon and color without a card or shadow:

```dart
Widget _buildShelfIdentity(BuildContext context, {required bool showBack}) {
  final shelf = widget.shelf!;
  final colorScheme = Theme.of(context).colorScheme;
  final description = shelf.description?.trim();

  return Row(
    children: [
      if (showBack)
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to shelves',
        ),
      Icon(shelf.displayIcon, color: shelf.color ?? colorScheme.primary),
      const SizedBox(width: Spacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shelf.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              description == null || description.isEmpty ? 'Add a description' : description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: widget.onEditShelf,
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Edit shelf',
      ),
    ],
  );
}
```

Apply the existing typography and `onSurfaceVariant` color to the description/placeholder. On mobile render this row above a full-width search field; on desktop render it above the existing search/action row.

- [ ] **Step 5: Replace the primary action in shelf mode**

Keep main-library callbacks unchanged. In shelf mode:

- desktop label: `Add to shelf`;
- mobile FAB: plus icon with tooltip `Add to shelf`;
- callback: `() {}` so the controls remain enabled and intentionally do nothing.

Do not expose `AddBookChoiceSheet` or online search from shelf mode.

- [ ] **Step 6: Scope the drawer, downloads chip, content, and empty states**

- Keep `LibraryDrawer` only for the main mobile Books page; shelf mode uses its Back action.
- Build acquisition items from the scoped source only on the main page.
- Hide the downloading chip in shelf mode.
- Keep normal selection and bulk book actions for shelf books.
- If the unfiltered shelf source is empty, show `No books in this shelf`, explanatory shelf copy, and the no-op `Add to shelf` action.
- If the source is non-empty but filtering produces no books, use the normal no-results state without `Search online`.

Carry `sourceBooks.length` through `_buildMobileLayout` / `_buildDesktopLayout` into `_buildBookContent`, and then into `_buildEmptyState`, so the empty-state decision uses the unfiltered collection count rather than the filtered result count.

- [ ] **Step 7: Format and run targeted page analysis**

Run:

```bash
cd app
dart format lib/pages/library_page.dart
flutter analyze \
  lib/pages/library_page.dart \
  lib/models/library_filter_options.dart \
  lib/widgets/library/library_filter_chips.dart \
  lib/widgets/library/library_advanced_filter_sheet.dart
```

Expected: no analysis issues.

- [ ] **Step 8: Commit the reusable Books page**

```bash
git add \
  app/lib/pages/library_page.dart \
  app/lib/models/library_filter_options.dart \
  app/lib/widgets/library/library_filter_chips.dart \
  app/lib/widgets/library/library_advanced_filter_sheet.dart
git commit -m "PPR-25: Reuse books page for collections"
```

### Task 6: Replace `ShelfContentsPage` with a Thin Adapter

**Files:**
- Modify: `app/lib/pages/shelf_contents_page.dart`

- [ ] **Step 1: Replace the shelf-specific presentation with a stateless route adapter**

Delete the separate `ShelvesProvider`, scaffold key, responsive layouts, search/sort/view controls, mixed child-shelf content, and duplicated grid/list builders. The route only retains its nullable `shelfId`:

```dart
class ShelfContentsPage extends StatelessWidget {
  final String? shelfId;

  const ShelfContentsPage({super.key, required this.shelfId});
}
```

- [ ] **Step 2: Preserve the missing-shelf state**

Watch `DataStore`, resolve `getShelf(shelfId ?? '')`, and return the existing `Shelf not found` scaffold when null. Keep its Back-to-shelves action.

- [ ] **Step 3: Open the shared edit sheet and persist all fields**

Add:

```dart
void _editShelf(BuildContext context, DataStore dataStore, Shelf shelf) {
  AddShelfSheet.show(
    context,
    shelf: shelf,
    onSave: (name, description, colorHex, icon) {
      dataStore.updateShelf(
        shelf.copyWith(
          name: name,
          description: description,
          clearDescription: description == null,
          colorHex: colorHex,
          icon: icon,
          updatedAt: DateTime.now(),
        ),
      );
    },
  );
}
```

- [ ] **Step 4: Delegate the valid shelf route to `LibraryPage`**

Read the global `LibraryProvider` before introducing the local override. Key the local provider by shelf ID so navigating between shelf routes cannot retain controls from the previous shelf. Use `create` so Provider owns disposal:

```dart
final favoriteState = context.read<LibraryProvider>();

return ChangeNotifierProvider(
  key: ValueKey('shelf-library-${shelf.id}'),
  create: (_) => LibraryProvider(favoriteDelegate: favoriteState),
  child: LibraryPage(
    shelf: shelf,
    onBack: () => context.go('/library/shelves'),
    onEditShelf: () => _editShelf(context, dataStore, shelf),
  ),
);
```

Do not query `getChildShelves`; hierarchy remains available elsewhere but is absent from this page.

- [ ] **Step 5: Format and analyze the adapter**

Run:

```bash
cd app
dart format lib/pages/shelf_contents_page.dart
flutter analyze lib/pages/shelf_contents_page.dart lib/pages/library_page.dart lib/models/shelf.dart
```

Expected: no analysis issues.

- [ ] **Step 6: Commit the route adapter**

```bash
git add app/lib/pages/shelf_contents_page.dart
git commit -m "PPR-25: Delegate shelf books to library page"
```

### Task 7: Remove Obsolete Shelf-Book State

**Files:**
- Modify: `app/lib/providers/shelves_provider.dart`

- [ ] **Step 1: Confirm the legacy symbols have no remaining consumers**

Run:

```bash
rg -n "BookSortOption|BookFilterType|bookSearchQuery|isBookGridView|isBookListView|setBookViewMode|getFilteredBooksForShelf|getBooksForShelf|sortBooks\(" app/lib --glob '*.dart'
```

Expected: matches occur only in `shelves_provider.dart`.

- [ ] **Step 2: Remove the duplicated shelf-book presentation model**

Delete:

- `BookSortOption` and `BookFilterType`;
- `_isBookGridView`, `_bookSortOption`, `_bookSortAscending`, `_bookSearchQuery`, and `_activeBookFilters`;
- their getters and `isBookFilterActive`;
- `setBookViewMode`, `setBookSortOption`, `sortBooks`, `setBookSearchQuery`, `clearBookSearch`, filter mutation/reset methods, `getFilteredBooksForShelf`, and `getBooksForShelf`.

Keep shelf collection controls, CRUD, `getChildShelves`, book membership mutations, count helpers, and cover previews. Remove unused `Book` and `LibraryReadingStatus` imports.

- [ ] **Step 3: Format, analyze, and re-run the usage search**

Run:

```bash
cd app
dart format lib/providers/shelves_provider.dart
flutter analyze lib/providers/shelves_provider.dart lib/pages/shelves_page.dart lib/pages/shelf_contents_page.dart
cd ..
rg -n "BookSortOption|BookFilterType|bookSearchQuery|isBookGridView|isBookListView|setBookViewMode|getFilteredBooksForShelf|getBooksForShelf" app/lib --glob '*.dart'
```

Expected: analysis reports no issues and the search returns no matches.

- [ ] **Step 4: Commit provider cleanup**

```bash
git add app/lib/providers/shelves_provider.dart
git commit -m "PPR-25: Remove legacy shelf book controls"
```

### Task 8: Verify the Integrated Experience

**Files:**
- Verify only; do not add test files.

- [ ] **Step 1: Run the complete targeted analyzer**

```bash
cd app
flutter analyze \
  lib/models/library_filter_options.dart \
  lib/models/shelf.dart \
  lib/providers/library_provider.dart \
  lib/providers/shelves_provider.dart \
  lib/pages/library_page.dart \
  lib/pages/shelf_contents_page.dart \
  lib/pages/shelves_page.dart \
  lib/widgets/library/library_filter_chips.dart \
  lib/widgets/library/library_advanced_filter_sheet.dart \
  lib/widgets/shelves/add_shelf_sheet.dart
```

Expected: `No issues found!`.

- [ ] **Step 2: Build the web client**

```bash
flutter build web --debug
```

Expected: exit code 0 and a completed debug web build.

- [ ] **Step 3: Check patch hygiene and preservation of prior work**

```bash
cd ..
git diff --check
git status --short
```

Expected: no whitespace errors. The pre-existing `app/lib/widgets/shelves/shelves_filter_chips.dart` modification remains visible unless separately committed by the user.

- [ ] **Step 4: Perform manual behavior verification**

Verify:

- Books filters do not carry into a shelf and shelf filters do not carry back.
- Only direct shelf members appear; child shelves never render.
- Quick and advanced option lists contain only metadata and memberships present in the unfiltered shelf.
- Advanced preview counts match applied results.
- Search, all structured filters, sorting, small grid, large grid, list, selection, bulk actions, and book navigation match Books behavior.
- Mobile and desktop identity headers show the selected colored icon, name, description, placeholder, and Edit action without tinted containers.
- Editing name, description, color, and icon refreshes immediately; clearing a description persists.
- `Add to shelf` remains visually enabled but changes no data.
- Empty shelf, filtered no-results, deleted shelf, and Back navigation states are correct.

- [ ] **Step 5: Review final commit and worktree scope**

```bash
git log --oneline -8
git status --short
```

Do not stage or commit unrelated user changes.
