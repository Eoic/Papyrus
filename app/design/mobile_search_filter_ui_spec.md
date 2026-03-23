# Mobile Search and Filter UI Design Specification

## Papyrus Book Library Application

**Version:** 1.0
**Target Platform:** Mobile (Android/iOS)
**Design System:** Material Design 3

---

## 1. Executive Summary

This specification defines a mobile-first advanced search and filtering experience for the Papyrus book library application. The design balances power-user capabilities (query language support) with intuitive visual interfaces for casual users, while maintaining WCAG 2.1 AA accessibility compliance.

### Design Philosophy

- **Progressive Disclosure:** Start simple, reveal complexity on demand
- **One-Handed Operation:** Critical actions reachable in the thumb zone
- **Visual Query Building:** Transform query syntax into tappable UI elements
- **Persistent Context:** Always show what filters are active

---

## 2. Design Tokens Reference

### Spacing System
```
xs:  4px   - Tight spacing between related elements
sm:  8px   - Standard chip/tag gaps
md:  16px  - Section padding, list item spacing
lg:  24px  - Major section separation
xl:  32px  - Screen edge margins (tablet)
xxl: 48px  - Hero spacing
```

### Touch Targets
```
Minimum:      48px x 48px (required for all interactive elements)
Recommended:  56px x 56px (preferred for primary actions)
FAB Size:     56px diameter
Chip Height:  36px (with 48px touch area via padding)
```

### Border Radius
```
sm:  4px   - Chips, small tags
md:  8px   - Buttons, inputs
lg:  12px  - Cards, sheets
xl:  16px  - Bottom sheet top corners
xxl: 28px  - Full-screen modal corners
```

### Animation Durations
```
Quick:     100ms  - Chip selection, icon changes
Standard:  200ms  - Sheet reveal, filter toggle
Emphasis:  300ms  - Full-screen transitions
Complex:   500ms  - Staggered list animations
```

---

## 3. Component Architecture

### 3.1 Overview

The mobile search/filter system consists of five interconnected components:

```
+------------------------------------------------------------------+
|                        LIBRARY PAGE                               |
+------------------------------------------------------------------+
|  +------------------------------------------------------------+  |
|  |  SEARCH APP BAR                                             |  |
|  |  [<] Search books...                    [Voice] [Filters]   |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |  ACTIVE FILTER BAR (Horizontal Scroll)                      |  |
|  |  [Reading] [x] [author:tolkien] [x] [Clear All]            |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |  QUICK FILTER CHIPS (Horizontal Scroll)                     |  |
|  |  [All] [Reading] [Favorites] [Finished] [More...]          |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |                                                              |  |
|  |                     BOOK GRID                                |  |
|  |                                                              |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|                                          [FAB: + Add Book]       |
|                                                                   |
+------------------------------------------------------------------+
```

### 3.2 Component Hierarchy

```
MobileSearchFilterSystem
|
+-- SearchAppBar
|   +-- SearchTextField
|   |   +-- PrefixIcon (search icon)
|   |   +-- InputField (with query suggestions)
|   |   +-- SuffixActions
|   |       +-- ClearButton (conditional)
|   |       +-- VoiceSearchButton (optional)
|   |       +-- FilterButton (with badge)
|   +-- BackButton (when searching)
|
+-- ActiveFilterBar
|   +-- HorizontalScrollView
|   |   +-- FilterChip[] (removable)
|   |   +-- ClearAllButton
|
+-- QuickFilterChips
|   +-- HorizontalScrollView
|   |   +-- FilterChip[] (toggleable)
|   |   +-- MoreFiltersChip (opens bottom sheet)
|
+-- FilterBottomSheet
|   +-- DragHandle
|   +-- SheetHeader
|   |   +-- Title
|   |   +-- CloseButton
|   +-- QuickFiltersSection
|   |   +-- SectionHeader
|   |   +-- FilterChipGrid
|   +-- AdvancedFiltersSection
|   |   +-- SectionHeader
|   |   +-- FilterFieldRow (Author)
|   |   +-- FilterFieldRow (Format)
|   |   +-- FilterFieldRow (Shelf)
|   |   +-- FilterFieldRow (Topic)
|   |   +-- FilterFieldRow (Status)
|   |   +-- FilterFieldRow (Progress)
|   +-- QueryPreview
|   |   +-- QueryText (shows generated query)
|   |   +-- CopyButton
|   +-- ActionBar
|       +-- ResetButton
|       +-- ApplyButton
|
+-- SearchSuggestions (Overlay)
    +-- RecentSearches
    +-- QuerySuggestions
    +-- FieldSuggestions
```

---

## 4. Detailed Component Specifications

### 4.1 Search App Bar

**Purpose:** Primary entry point for search functionality

**States:**
- Default (collapsed)
- Focused (expanded with suggestions)
- Active (showing results with query)

#### Layout Specification

```
+------------------------------------------------------------------+
|  DEFAULT STATE                                                    |
+------------------------------------------------------------------+
|  +------------------------------------------------------------+  |
|  |  [Search Icon]  "Search books..."           [Filter Badge] |  |
|  +------------------------------------------------------------+  |
|  Height: 56px                                                    |
|  Horizontal Padding: 16px                                        |
|  Icon Size: 24px                                                 |
|  Corner Radius: 28px (pill shape)                                |
+------------------------------------------------------------------+

+------------------------------------------------------------------+
|  FOCUSED STATE                                                    |
+------------------------------------------------------------------+
|  +------------------------------------------------------------+  |
|  |  [<-]  [__________________________] [X] [Voice] [Filters]  |  |
|  +------------------------------------------------------------+  |
|  |                                                              |  |
|  |  RECENT SEARCHES                                            |  |
|  |  +--------------------------------------------------------+  |
|  |  |  [Clock] "tolkien fantasy"                             |  |
|  |  |  [Clock] "author:sanderson"                            |  |
|  |  +--------------------------------------------------------+  |
|  |                                                              |  |
|  |  SUGGESTIONS                                                 |  |
|  |  +--------------------------------------------------------+  |
|  |  |  author:     [Person]                                  |  |
|  |  |  format:     [Book]                                    |  |
|  |  |  shelf:      [Folder]                                  |  |
|  |  |  status:     [Progress]                                |  |
|  |  +--------------------------------------------------------+  |
|  |                                                              |  |
+------------------------------------------------------------------+
```

#### Visual Properties

| Property | Value |
|----------|-------|
| Background | `surfaceContainerHighest` |
| Border | 1px `outline` (default), 2px `primary` (focused) |
| Text Color | `onSurface` |
| Placeholder Color | `onSurfaceVariant` @ 60% |
| Icon Color | `onSurfaceVariant` |
| Filter Badge Color | `primary` with `onPrimary` text |
| Corner Radius | `AppRadius.xxl` (28px) |
| Height | 56px |
| Inner Padding | 16px horizontal, 8px vertical |

#### Interaction Behavior

1. **Tap on Search Bar:**
   - Transitions to focused state with 200ms animation
   - Keyboard appears
   - Shows recent searches and field suggestions
   - Back button appears on the left

2. **Typing:**
   - Real-time filtering of suggestions
   - Query syntax highlighting (field names in primary color)
   - Auto-suggest completions for field:value patterns

3. **Filter Button Tap:**
   - Opens Filter Bottom Sheet
   - Shows badge with count of active filters

4. **Back Button:**
   - Clears search if empty
   - Returns to default state
   - Keyboard dismisses

### 4.2 Active Filter Bar

**Purpose:** Display currently applied filters with easy removal

**Visibility:** Only visible when filters are active

#### Layout Specification

```
+------------------------------------------------------------------+
|  ACTIVE FILTER BAR                                                |
+------------------------------------------------------------------+
|  [Reading x] [author:"tolkien" x] [format:epub x]  [Clear All]   |
+------------------------------------------------------------------+
|  Height: 48px (including padding)                                 |
|  Chip Height: 32px                                               |
|  Chip Padding: 12px horizontal                                   |
|  Chip Spacing: 8px                                               |
|  Horizontal Padding: 16px (page margins)                         |
+------------------------------------------------------------------+
```

#### Visual Properties

| Property | Value |
|----------|-------|
| Container Background | `surface` |
| Chip Background | `secondaryContainer` |
| Chip Text Color | `onSecondaryContainer` |
| Remove Icon Size | 18px |
| Remove Icon Color | `onSecondaryContainer` |
| Clear All Text Color | `primary` |
| Animation | Fade + scale on add/remove (200ms) |

#### Chip Types

1. **Quick Filter Chip:** Simple label with remove button
   ```
   +----------------+
   | Reading    [x] |
   +----------------+
   ```

2. **Query Filter Chip:** Field:value with syntax highlighting
   ```
   +------------------------+
   | author: "tolkien" [x]  |
   +------------------------+
     ^field   ^value
     Primary  onSecondaryContainer
   ```

### 4.3 Quick Filter Chips

**Purpose:** One-tap access to common filter states

#### Layout Specification

```
+------------------------------------------------------------------+
|  QUICK FILTER CHIPS                                               |
+------------------------------------------------------------------+
|  [All] [Reading] [Favorites] [Finished] [Shelves v] [Topics v]   |
+------------------------------------------------------------------+
|  Height: 48px (with touch padding)                               |
|  Chip Height: 36px                                               |
|  Chip Min Width: 64px                                            |
|  Icon Size: 18px                                                 |
|  Spacing: 8px                                                    |
+------------------------------------------------------------------+
```

#### Visual Properties

| State | Background | Text | Border |
|-------|------------|------|--------|
| Unselected | `surfaceContainerHighest` | `onSurfaceVariant` | 1px `outline` |
| Selected | `secondaryContainer` | `onSecondaryContainer` | none |
| Pressed | `secondary` @ 12% | inherit | inherit |

#### Chip Definitions

| Chip | Icon | Action |
|------|------|--------|
| All | `apps` | Clear all filters |
| Reading | `auto_stories` | Filter to reading status |
| Favorites | `favorite` | Filter to favorited books |
| Finished | `check_circle` | Filter to finished books |
| Shelves | `shelves` + chevron | Opens shelf picker |
| Topics | `topic` + chevron | Opens topic picker |

### 4.4 Filter Bottom Sheet

**Purpose:** Comprehensive filter builder with visual controls

#### Layout Specification

```
+------------------------------------------------------------------+
|  FILTER BOTTOM SHEET                                              |
+------------------------------------------------------------------+
|                         [===]                                     |
|                       Drag Handle                                 |
+------------------------------------------------------------------+
|  Filters                                          [X Close]       |
+------------------------------------------------------------------+
|                                                                   |
|  QUICK FILTERS                                                    |
|  +-------------------+  +-------------------+                     |
|  | [ ] Reading       |  | [ ] Favorites     |                     |
|  +-------------------+  +-------------------+                     |
|  +-------------------+  +-------------------+                     |
|  | [ ] Finished      |  | [ ] Unread        |                     |
|  +-------------------+  +-------------------+                     |
|                                                                   |
+------------------------------------------------------------------+
|  FILTER BY                                                        |
|  +------------------------------------------------------------+  |
|  | Author                                                      |  |
|  | [Person Icon]  Enter author name...               [Clear]  |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | Format                                                      |  |
|  | [Book Icon]    Any format                         [v]      |  |
|  +------------------------------------------------------------+  |
|  | Options: EPUB, PDF, MOBI, Physical, TXT, AZW3             |  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | Shelf                                                       |  |
|  | [Folder Icon]  Any shelf                          [v]      |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | Topic                                                       |  |
|  | [Label Icon]   Any topic                          [v]      |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | Status                                                      |  |
|  | [Schedule Icon] Any status                        [v]      |  |
|  +------------------------------------------------------------+  |
|  | Options: Currently reading, Finished, Unread               |  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | Progress                                                    |  |
|  | [Progress Icon] Any progress                               |  |
|  |     [ 0% ]================[ 100% ]                         |  |
|  |     Min: 0%              Max: 100%                         |  |
|  +------------------------------------------------------------+  |
|                                                                   |
+------------------------------------------------------------------+
|  QUERY PREVIEW                                                    |
|  +------------------------------------------------------------+  |
|  | author:"tolkien" format:epub status:reading                |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
|                                                                   |
|  [  Reset Filters  ]              [====  Apply Filters  ====]    |
|                                                                   |
+------------------------------------------------------------------+
```

#### Section Specifications

**Sheet Header:**
| Property | Value |
|----------|-------|
| Drag Handle Width | 32px |
| Drag Handle Height | 4px |
| Drag Handle Color | `outlineVariant` |
| Title Style | `titleLarge` |
| Close Button Size | 48px touch target |
| Header Padding | 16px |

**Quick Filters Section:**
| Property | Value |
|----------|-------|
| Grid Columns | 2 |
| Cell Height | 56px |
| Cell Spacing | 12px |
| Checkbox Size | 24px |
| Touch Target | Full cell (56px) |

**Filter Field Rows:**
| Property | Value |
|----------|-------|
| Row Height | 72px (min) |
| Label Style | `labelMedium` |
| Input Style | `bodyLarge` |
| Icon Size | 24px |
| Icon Color | `onSurfaceVariant` |
| Divider | `outlineVariant` 1px |

**Query Preview:**
| Property | Value |
|----------|-------|
| Background | `surfaceContainerLow` |
| Font | Monospace, `bodyMedium` |
| Padding | 12px |
| Corner Radius | 8px |
| Max Lines | 3 (scrollable) |

**Action Bar:**
| Property | Value |
|----------|-------|
| Height | 80px |
| Padding | 16px |
| Button Spacing | 16px |
| Reset Button Style | `OutlinedButton` |
| Apply Button Style | `FilledButton` |

#### Interaction Patterns

1. **Opening the Sheet:**
   - Slides up from bottom (300ms, Curves.easeOutCubic)
   - Scrim appears behind (200ms fade)
   - Initial height: 60% of screen
   - Can expand to full screen

2. **Drag Behavior:**
   - Drag handle and header area are draggable
   - Snap points: collapsed (hidden), half (60%), full (95%)
   - Velocity-based snap decisions

3. **Field Interactions:**
   - Text fields: Standard keyboard input
   - Dropdowns: Opens inline picker or separate picker sheet
   - Range slider: Dual thumb for progress range

4. **Apply/Reset:**
   - Reset: Clears all fields, haptic feedback
   - Apply: Closes sheet, applies filters, shows snackbar confirmation

### 4.5 Search Suggestions Overlay

**Purpose:** Assist users with query building and recall

#### Layout Specification

```
+------------------------------------------------------------------+
|  SEARCH SUGGESTIONS                                               |
+------------------------------------------------------------------+
|                                                                   |
|  RECENT SEARCHES                                 [Clear History]  |
|  +------------------------------------------------------------+  |
|  | [Clock] fantasy adventure                                   |  |
|  | [Clock] author:"brandon sanderson"                          |  |
|  | [Clock] format:epub shelf:"To Read"                         |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  TRY SEARCHING                                                    |
|  +------------------------------------------------------------+  |
|  | [Person] author:    Search by author name                   |  |
|  | [Book]   format:    Filter by book format                   |  |
|  | [Folder] shelf:     Search within a shelf                   |  |
|  | [Label]  topic:     Filter by topic                         |  |
|  | [Clock]  status:    Filter by reading status                |  |
|  | [Chart]  progress:  Filter by reading progress              |  |
|  +------------------------------------------------------------+  |
|                                                                   |
+------------------------------------------------------------------+
```

#### Contextual Suggestions

When typing specific field prefixes, show contextual completions:

**After typing "author:"**
```
+------------------------------------------------------------+
| [Person] J.R.R. Tolkien                                     |
| [Person] Brandon Sanderson                                  |
| [Person] Patrick Rothfuss                                   |
+------------------------------------------------------------+
```

**After typing "status:"**
```
+------------------------------------------------------------+
| [Check]  status:reading                                     |
| [Star]   status:finished                                    |
| [Book]   status:unread                                      |
+------------------------------------------------------------+
```

**After typing "format:"**
```
+------------------------------------------------------------+
| [File]   format:epub                                        |
| [File]   format:pdf                                         |
| [File]   format:mobi                                        |
| [Book]   format:physical                                    |
+------------------------------------------------------------+
```

---

## 5. Interaction Patterns

### 5.1 Search Flow

```
User Journey: Finding books by a specific author in EPUB format

1. User taps search bar
   |
   +-> Search bar expands
   +-> Recent searches appear
   +-> Keyboard opens
   |
2. User types "author:"
   |
   +-> Suggestions update to show authors from library
   +-> Query syntax highlighted
   |
3. User selects "tolkien" from suggestions
   |
   +-> Query becomes "author:tolkien"
   +-> Results update in real-time
   |
4. User taps filter button
   |
   +-> Bottom sheet opens
   +-> Author field pre-filled with "tolkien"
   |
5. User selects "EPUB" from format dropdown
   |
   +-> Query preview shows: author:"tolkien" format:epub
   |
6. User taps "Apply Filters"
   |
   +-> Sheet closes
   +-> Active filter bar shows: [author:tolkien x] [format:epub x]
   +-> Results filtered accordingly
```

### 5.2 Filter State Synchronization

The system maintains bidirectional sync between:
- Search text field
- Active filter bar
- Quick filter chips
- Filter bottom sheet
- LibraryProvider state

**State Flow:**
```
User Action -> LibraryProvider -> UI Components
                    |
                    +-> SearchQuery Parser
                    |       |
                    |       +-> Individual Filter Objects
                    |
                    +-> Notify Listeners
                            |
                            +-> Update Search Bar Text
                            +-> Update Active Filter Chips
                            +-> Update Quick Filter Selection
                            +-> Update Bottom Sheet Fields
                            +-> Trigger Book List Filter
```

### 5.3 Gesture Support

| Gesture | Location | Action |
|---------|----------|--------|
| Tap | Search bar | Expand and focus |
| Tap | Filter chip | Toggle filter |
| Tap | Active filter X | Remove filter |
| Tap | "Clear All" | Remove all filters |
| Tap | Filter button | Open bottom sheet |
| Swipe left | Active filter chip | Remove filter |
| Swipe down | Bottom sheet | Collapse/dismiss |
| Long press | Search suggestion | Preview filter result |

---

## 6. Accessibility Specifications

### 6.1 WCAG 2.1 AA Compliance

#### Touch Targets
- All interactive elements: minimum 48x48px
- Spacing between targets: minimum 8px
- Recommended touch targets: 56x56px for primary actions

#### Color Contrast
| Element | Foreground | Background | Ratio |
|---------|------------|------------|-------|
| Primary text | `onSurface` | `surface` | 14.5:1 |
| Placeholder text | `onSurfaceVariant` | `surfaceContainerHighest` | 4.6:1 |
| Chip text (selected) | `onSecondaryContainer` | `secondaryContainer` | 7.2:1 |
| Filter badge | `onPrimary` | `primary` | 4.8:1 |

#### Focus Management
- Clear focus indicators with 2px outline
- Focus trap within bottom sheet when open
- Logical tab order: Search -> Filters -> Quick chips -> Results

### 6.2 Screen Reader Support

#### Semantic Labels

```dart
// Search bar
Semantics(
  label: 'Search books',
  hint: 'Double tap to search. Use filter keywords like author: or format:',
  textField: true,
)

// Filter button with badge
Semantics(
  label: 'Filters',
  hint: '$activeFilterCount filters active. Double tap to open filter panel.',
  button: true,
)

// Active filter chip
Semantics(
  label: 'Active filter: author tolkien',
  hint: 'Double tap to remove this filter',
  button: true,
)

// Quick filter chip
Semantics(
  label: 'Reading filter',
  hint: isSelected ? 'Currently selected. Double tap to deselect' : 'Double tap to filter by reading books',
  button: true,
  selected: isSelected,
)
```

#### Announcements

| Action | Announcement |
|--------|--------------|
| Filter applied | "Filter applied. Showing X books" |
| Filter removed | "Filter removed. Showing X books" |
| All filters cleared | "All filters cleared. Showing X books" |
| No results | "No books match your filters" |
| Sheet opened | "Filter panel opened" |
| Sheet closed | "Filter panel closed. X filters applied" |

### 6.3 Reduced Motion

```dart
final animationDuration = MediaQuery.of(context).disableAnimations
    ? Duration.zero
    : AnimationDurations.standard;
```

---

## 7. Flutter Widget Implementation Guide

### 7.1 File Structure

```
lib/
+-- widgets/
|   +-- search/
|   |   +-- mobile_search_bar.dart
|   |   +-- search_suggestions.dart
|   |   +-- query_syntax_highlighter.dart
|   |
|   +-- filter/
|   |   +-- active_filter_bar.dart
|   |   +-- quick_filter_chips.dart
|   |   +-- filter_bottom_sheet.dart
|   |   +-- filter_field_row.dart
|   |   +-- range_slider_field.dart
|   |
+-- providers/
|   +-- search_filter_provider.dart  (extend LibraryProvider)
|
+-- models/
|   +-- search_filter.dart           (existing)
|   +-- active_filter.dart           (new - for UI state)
```

### 7.2 Core Widget Signatures

```dart
/// Mobile search bar with query language support
class MobileSearchBar extends StatefulWidget {
  /// Callback when search query changes
  final ValueChanged<String>? onQueryChanged;

  /// Callback when filter button is tapped
  final VoidCallback? onFilterTap;

  /// Current active filter count for badge
  final int activeFilterCount;

  /// Whether to show voice search button
  final bool showVoiceSearch;

  const MobileSearchBar({
    super.key,
    this.onQueryChanged,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.showVoiceSearch = false,
  });
}

/// Horizontal scrolling bar showing active filters
class ActiveFilterBar extends StatelessWidget {
  /// List of currently active filters
  final List<ActiveFilter> filters;

  /// Callback when a filter is removed
  final ValueChanged<ActiveFilter>? onFilterRemoved;

  /// Callback when "Clear All" is tapped
  final VoidCallback? onClearAll;

  const ActiveFilterBar({
    super.key,
    required this.filters,
    this.onFilterRemoved,
    this.onClearAll,
  });
}

/// Quick filter chips row
class QuickFilterChips extends StatelessWidget {
  /// Selected filter types
  final Set<LibraryFilterType> selectedFilters;

  /// Callback when filter selection changes
  final ValueChanged<LibraryFilterType>? onFilterToggled;

  /// Callback when "More filters" is tapped
  final VoidCallback? onMoreFilters;

  const QuickFilterChips({
    super.key,
    required this.selectedFilters,
    this.onFilterToggled,
    this.onMoreFilters,
  });
}

/// Bottom sheet for advanced filter building
class FilterBottomSheet extends StatefulWidget {
  /// Current filter state
  final SearchQuery? currentQuery;

  /// Available values for dropdowns
  final FilterOptions filterOptions;

  /// Callback when filters are applied
  final ValueChanged<SearchQuery>? onApply;

  /// Callback when reset is requested
  final VoidCallback? onReset;

  const FilterBottomSheet({
    super.key,
    this.currentQuery,
    required this.filterOptions,
    this.onApply,
    this.onReset,
  });
}
```

### 7.3 State Management Integration

```dart
/// Extended library provider with UI-specific filter state
class SearchFilterProvider extends LibraryProvider {
  // Recent searches (persisted)
  List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  // Bottom sheet visibility
  bool _isFilterSheetOpen = false;
  bool get isFilterSheetOpen => _isFilterSheetOpen;

  // Convert current state to ActiveFilter objects for UI
  List<ActiveFilter> get activeFiltersForUI {
    final filters = <ActiveFilter>[];

    // Add quick filters
    if (isFilterActive(LibraryFilterType.reading)) {
      filters.add(ActiveFilter(
        type: ActiveFilterType.quick,
        label: 'Reading',
        value: 'reading',
      ));
    }
    // ... other quick filters

    // Parse search query into individual filters
    if (searchQuery.isNotEmpty) {
      final query = SearchQueryParser.parse(searchQuery);
      for (final filter in query.filters) {
        if (filter.field != SearchField.any) {
          filters.add(ActiveFilter(
            type: ActiveFilterType.query,
            label: filter.field.name,
            value: filter.value,
            queryString: filter.toString(),
          ));
        }
      }
    }

    return filters;
  }

  void addToRecentSearches(String query) {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    notifyListeners();
  }

  void openFilterSheet() {
    _isFilterSheetOpen = true;
    notifyListeners();
  }

  void closeFilterSheet() {
    _isFilterSheetOpen = false;
    notifyListeners();
  }
}

/// Represents a filter for UI display
class ActiveFilter {
  final ActiveFilterType type;
  final String label;
  final String value;
  final String? queryString; // For query-based filters

  const ActiveFilter({
    required this.type,
    required this.label,
    required this.value,
    this.queryString,
  });
}

enum ActiveFilterType {
  quick,  // Reading, Favorites, etc.
  query,  // author:, format:, etc.
}
```

### 7.4 Key Implementation Details

#### Query Syntax Highlighting

```dart
class QuerySyntaxHighlighter {
  static TextSpan highlight(String query, TextStyle baseStyle, ColorScheme colors) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\w+):(["\w\s]+"|[\w]+)');
    int lastEnd = 0;

    for (final match in regex.allMatches(query)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: query.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Add field name in primary color
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(color: colors.primary),
      ));

      // Add colon
      spans.add(TextSpan(text: ':', style: baseStyle));

      // Add value
      spans.add(TextSpan(
        text: match.group(2),
        style: baseStyle.copyWith(fontWeight: FontWeight.w500),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < query.length) {
      spans.add(TextSpan(
        text: query.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}
```

#### Bottom Sheet Modal

```dart
void showFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: FilterBottomSheet(
          scrollController: scrollController,
          // ... other props
        ),
      ),
    ),
  );
}
```

---

## 8. Responsive Considerations

### 8.1 Breakpoint Behavior

| Width | Layout Adaptation |
|-------|-------------------|
| < 360px | Single column quick filters, stacked action buttons |
| 360-600px | Standard mobile layout as specified |
| 600-840px | Expanded search bar, 3-column quick filters |
| > 840px | Switch to desktop layout (existing AdvancedSearchBar) |

### 8.2 Orientation Handling

**Portrait:**
- Full mobile layout as specified
- Bottom sheet expands to 95% max height

**Landscape:**
- Search bar in app bar remains
- Quick filters may wrap to second row
- Bottom sheet max height: 80%
- Consider side sheet on larger phones

---

## 9. Error States and Edge Cases

### 9.1 Empty States

**No Search Results:**
```
+------------------------------------------------------------+
|                                                              |
|              [Search Icon - Large]                           |
|                                                              |
|              No books match your filters                     |
|                                                              |
|        Try adjusting your search or removing filters         |
|                                                              |
|                    [Clear Filters]                           |
|                                                              |
+------------------------------------------------------------+
```

**Empty Library:**
```
+------------------------------------------------------------+
|                                                              |
|              [Books Icon - Large]                            |
|                                                              |
|              Your library is empty                           |
|                                                              |
|           Add some books to start organizing                 |
|                                                              |
|                    [+ Add Book]                              |
|                                                              |
+------------------------------------------------------------+
```

### 9.2 Error Handling

| Scenario | Handling |
|----------|----------|
| Invalid query syntax | Show inline hint, don't prevent search |
| Network error (if applicable) | Show snackbar with retry option |
| Filter options load failure | Show cached/default options |

---

## 10. Performance Considerations

### 10.1 Optimization Strategies

1. **Debounced Search:** 300ms delay before filtering on text input
2. **Lazy Suggestions:** Load suggestions only when overlay is visible
3. **Virtualized Lists:** Use ListView.builder for large filter option lists
4. **Cached Filter Options:** Store shelf/topic lists in provider

### 10.2 Animation Performance

```dart
// Use RepaintBoundary for animated chips
RepaintBoundary(
  child: AnimatedContainer(
    duration: AnimationDurations.quick,
    // ... chip content
  ),
)

// Avoid expensive rebuilds during scroll
const ActiveFilterBar({...}); // Make stateless where possible
```

---

## 11. Testing Checklist

### 11.1 Functional Testing

- [ ] Search text filters books correctly
- [ ] Query syntax (field:value) parses correctly
- [ ] Quick filters toggle and apply
- [ ] Active filters display and can be removed
- [ ] "Clear All" removes all filters
- [ ] Bottom sheet opens and closes properly
- [ ] Filter options load and can be selected
- [ ] "Apply Filters" updates search and closes sheet
- [ ] "Reset Filters" clears all fields
- [ ] Recent searches persist and display
- [ ] Suggestions appear contextually

### 11.2 Accessibility Testing

- [ ] VoiceOver/TalkBack navigation works
- [ ] Focus order is logical
- [ ] Touch targets are 48px minimum
- [ ] Color contrast meets AA standards
- [ ] Reduced motion is respected
- [ ] Filter state announced to screen readers

### 11.3 Visual Testing

- [ ] Light theme renders correctly
- [ ] Dark theme renders correctly
- [ ] All states (default, focused, selected, error) display
- [ ] Animations are smooth
- [ ] No layout overflow on small screens
- [ ] Keyboard doesn't obscure input

---

## Appendix A: Icon Mapping

| Filter | Icon | Icon Name |
|--------|------|-----------|
| All | Grid | `Icons.apps` |
| Reading | Open book | `Icons.auto_stories` |
| Favorites | Heart | `Icons.favorite` |
| Finished | Checkmark circle | `Icons.check_circle` |
| Shelves | Bookshelf | `Icons.shelves` |
| Topics | Tag | `Icons.topic` |
| Author | Person | `Icons.person_outline` |
| Format | Book | `Icons.book_outlined` |
| Status | Clock | `Icons.schedule` |
| Progress | Chart | `Icons.show_chart` |
| Search | Magnifying glass | `Icons.search` |
| Filter | Tune | `Icons.tune` |
| Clear | X | `Icons.clear` |
| Voice | Microphone | `Icons.mic` |
| Recent | Clock | `Icons.history` |

---

## Appendix B: Color Token Usage

| Component | Light Mode | Dark Mode |
|-----------|------------|-----------|
| Search bar background | `surfaceContainerHighest` (#E4E1EC) | `surfaceContainerHighest` (#47464F) |
| Search bar border | `outline` (#787680) | `outline` (#928F9A) |
| Active chip background | `secondaryContainer` (#E3E0F9) | `secondaryContainer` (#464559) |
| Active chip text | `onSecondaryContainer` (#1A1A2C) | `onSecondaryContainer` (#E3E0F9) |
| Filter badge | `primary` (#5654A8) | `primary` (#C3C0FF) |
| Filter badge text | `onPrimary` (#FFFFFF) | `onPrimary` (#272377) |
| Query field highlight | `primary` | `primary` |
| Clear all button | `primary` | `primary` |
| Bottom sheet surface | `surface` | `surface` |
| Bottom sheet scrim | `scrim` @ 32% | `scrim` @ 32% |
