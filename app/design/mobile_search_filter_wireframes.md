# Mobile Search and Filter UI Wireframes

## Papyrus Book Library Application

This document provides visual wireframe representations of the mobile search and filter interface.

---

## 1. Default Library View (No Filters Active)

```
+------------------------------------------+
|  [=]  Library                    [Search]|
+------------------------------------------+
|                                          |
| [All] [Reading] [Favorites] [Finished]   |
|       [Shelves v] [Topics v]             |
|                                          |
+------------------------------------------+
|                                          |
|  +--------+  +--------+  +--------+      |
|  |        |  |        |  |        |      |
|  |  Book  |  |  Book  |  |  Book  |      |
|  |  Cover |  |  Cover |  |  Cover |      |
|  |        |  |        |  |        |      |
|  +--------+  +--------+  +--------+      |
|  Title...    Title...    Title...        |
|  Author      Author      Author          |
|                                          |
|  +--------+  +--------+  +--------+      |
|  |        |  |        |  |        |      |
|  |  Book  |  |  Book  |  |  Book  |      |
|  |  Cover |  |  Cover |  |  Cover |      |
|  |        |  |        |  |        |      |
|  +--------+  +--------+  +--------+      |
|  Title...    Title...    Title...        |
|  Author      Author      Author          |
|                                          |
|                                  +-----+ |
|                                  | [+] | |
|                                  +-----+ |
+------------------------------------------+
```

---

## 2. Search Activated (Expanded State)

```
+------------------------------------------+
|  [<-] [________________________] [X] [#] |
|        Search books...                   |
+------------------------------------------+
|                                          |
|  RECENT SEARCHES                         |
|  +--------------------------------------+|
|  | [o] tolkien fantasy                  ||
|  +--------------------------------------+|
|  | [o] author:sanderson                 ||
|  +--------------------------------------+|
|  | [o] format:epub shelf:"To Read"      ||
|  +--------------------------------------+|
|                                          |
|  TRY SEARCHING                           |
|  +--------------------------------------+|
|  | [P] author:   Search by author       ||
|  +--------------------------------------+|
|  | [B] format:   Filter by format       ||
|  +--------------------------------------+|
|  | [F] shelf:    Search within shelf    ||
|  +--------------------------------------+|
|  | [T] topic:    Filter by topic        ||
|  +--------------------------------------+|
|  | [C] status:   Reading status         ||
|  +--------------------------------------+|
|  | [%] progress: Filter by progress     ||
|  +--------------------------------------+|
|                                          |
+------------------------------------------+

Legend:
[o] = History/clock icon
[P] = Person icon
[B] = Book icon
[F] = Folder icon
[T] = Tag icon
[C] = Clock icon
[%] = Progress icon
[#] = Filter/tune icon
```

---

## 3. Search with Active Query

```
+------------------------------------------+
|  [<-] [author:tolkien format:e] [X] [#]  |
+------------------------------------------+
|                                          |
|  SUGGESTIONS                             |
|  +--------------------------------------+|
|  | format:epub                          ||
|  +--------------------------------------+|
|  | format:ebook (any digital)           ||
|  +--------------------------------------+|
|                                          |
+------------------------------------------+
|                                          |
| Active: [author:tolkien x] [format:epub x]|
|                                          |
+------------------------------------------+
|                                          |
|  +--------+  +--------+                  |
|  |        |  |        |                  |
|  |  Book  |  |  Book  |                  |
|  |  Cover |  |  Cover |                  |
|  |        |  |        |                  |
|  +--------+  +--------+                  |
|  The Hobbit  Fellowship                  |
|  Tolkien     Tolkien                     |
|                                          |
|            4 books found                 |
|                                          |
+------------------------------------------+
```

---

## 4. Filter Bottom Sheet (Collapsed - 60%)

```
+------------------------------------------+
|  [<-] Library                    [Search]|
+------------------------------------------+
|                                          |
| [All] [Reading] [Favorites] [Finished]   |
|                                          |
+------------------------------------------+
|         (Scrim/Overlay - 32% opacity)    |
|                                          |
+==========================================+
|                  [===]                   |
|              Drag Handle                 |
+------------------------------------------+
|  Filters                           [X]   |
+------------------------------------------+
|                                          |
|  QUICK FILTERS                           |
|  +------------------+ +------------------+|
|  | [ ] Reading      | | [ ] Favorites   ||
|  +------------------+ +------------------+|
|  +------------------+ +------------------+|
|  | [ ] Finished     | | [ ] Unread      ||
|  +------------------+ +------------------+|
|                                          |
+------------------------------------------+
|  FILTER BY                               |
|  +--------------------------------------+|
|  | Author                                |
|  | [P] Enter author name...      [Clear]||
|  +--------------------------------------+|
|                                          |
|  +--------------------------------------+|
|  | Format                                |
|  | [B] Any format                    [v]||
|  +--------------------------------------+|
|                                          |
+------------------------------------------+
|  [  Reset  ]        [ Apply Filters ]    |
+------------------------------------------+
```

---

## 5. Filter Bottom Sheet (Expanded - 95%)

```
+------------------------------------------+
|                  [===]                   |
|              Drag Handle                 |
+------------------------------------------+
|  Filters                           [X]   |
+------------------------------------------+
|                                          |
|  QUICK FILTERS                           |
|  +------------------+ +------------------+|
|  | [*] Reading      | | [ ] Favorites   ||
|  +------------------+ +------------------+|
|  +------------------+ +------------------+|
|  | [ ] Finished     | | [ ] Unread      ||
|  +------------------+ +------------------+|
|                                          |
+------------------------------------------+
|  FILTER BY                               |
|  +--------------------------------------+|
|  | Author                                |
|  | [P] tolkien                   [Clear]||
|  +--------------------------------------+|
|                                          |
|  +--------------------------------------+|
|  | Format                                |
|  | [B] EPUB                          [v]||
|  +--------------------------------------+|
|                                          |
|  +--------------------------------------+|
|  | Shelf                                 |
|  | [F] Any shelf                     [v]||
|  +--------------------------------------+|
|                                          |
|  +--------------------------------------+|
|  | Topic                                 |
|  | [T] Fantasy                       [v]||
|  +--------------------------------------+|
|                                          |
|  +--------------------------------------+|
|  | Status                                |
|  | [C] Currently reading             [v]||
|  +--------------------------------------+|
|                                          |
|  +--------------------------------------+|
|  | Progress                              |
|  | [%] 25% - 100%                        |
|  |     [o====|=================o]        |
|  |     Min: 25%          Max: 100%       |
|  +--------------------------------------+|
|                                          |
+------------------------------------------+
|  QUERY PREVIEW                           |
|  +--------------------------------------+|
|  | author:"tolkien" format:epub         ||
|  | topic:"Fantasy" status:reading       ||
|  | progress:>25                         ||
|  +--------------------------------------+|
|                                          |
+------------------------------------------+
|                                          |
|  [  Reset Filters  ]  [ Apply Filters ]  |
|                                          |
+------------------------------------------+
```

---

## 6. Format Dropdown Expanded

```
+------------------------------------------+
|  +--------------------------------------+|
|  | Format                                |
|  | [B] EPUB                          [^]||
|  +--------------------------------------+|
|  | +----------------------------------+ ||
|  | |   Any format                     | ||
|  | +----------------------------------+ ||
|  | | * EPUB                           | ||
|  | +----------------------------------+ ||
|  | |   PDF                            | ||
|  | +----------------------------------+ ||
|  | |   MOBI                           | ||
|  | +----------------------------------+ ||
|  | |   Physical                       | ||
|  | +----------------------------------+ ||
|  | |   TXT                            | ||
|  | +----------------------------------+ ||
|  | |   AZW3                           | ||
|  | +----------------------------------+ ||
|  +--------------------------------------+|
```

---

## 7. Active Filter Bar with Multiple Filters

```
+------------------------------------------+
|  [<-] Library                    [Search]|
+------------------------------------------+
|                                          |
| <- [Reading x] [author:tolkien x]        |
|    [format:epub x] [topic:Fantasy x]     |
|                          [Clear All] ->  |
|                                          |
+------------------------------------------+
|                                          |
| [All] [Reading*] [Favorites] [Finished]  |
|       [Shelves v] [Topics v]             |
|                                          |
+------------------------------------------+

Note: Horizontal scroll enabled for filter bar
* indicates selected quick filter
```

---

## 8. Empty Search Results

```
+------------------------------------------+
|  [<-] [author:nonexistent___] [X] [#]    |
+------------------------------------------+
|                                          |
| Active: [author:nonexistent x]           |
|                                          |
+------------------------------------------+
|                                          |
|                                          |
|                                          |
|              +--------+                  |
|              |   [Q]  |                  |
|              +--------+                  |
|                                          |
|         No books match your filters      |
|                                          |
|   Try adjusting your search or removing  |
|                  filters                 |
|                                          |
|            [ Clear Filters ]             |
|                                          |
|                                          |
|                                          |
+------------------------------------------+

[Q] = Search/magnifying glass icon
```

---

## 9. Shelf Picker (Full Screen Overlay)

```
+------------------------------------------+
|  [<-]  Select Shelf                      |
+------------------------------------------+
|  [_____________________________] [X]     |
|  Search shelves...                       |
+------------------------------------------+
|                                          |
|  YOUR SHELVES                            |
|  +--------------------------------------+|
|  | [F] To Read                      (12)||
|  +--------------------------------------+|
|  | [F] Currently Reading             (3)||
|  +--------------------------------------+|
|  | [F] Favorites                     (8)||
|  +--------------------------------------+|
|  | [F] Science Fiction              (15)||
|  +--------------------------------------+|
|  | [F] Fantasy                      (23)||
|  +--------------------------------------+|
|  | [F] Non-Fiction                   (7)||
|  +--------------------------------------+|
|  | [F] Technical                    (11)||
|  +--------------------------------------+|
|                                          |
|                                          |
+------------------------------------------+

[F] = Folder icon
(n) = Book count in shelf
```

---

## 10. Topic Multi-Select Chips

```
+------------------------------------------+
|  +--------------------------------------+|
|  | Topic                                 |
|  |                                       |
|  | [Fantasy*] [Sci-Fi] [Adventure*]      |
|  | [Mystery] [Romance] [Historical]      |
|  | [Thriller] [Biography] [Self-Help]    |
|  |                                       |
|  | Selected: Fantasy, Adventure          |
|  +--------------------------------------+|

* = Selected topic chip
```

---

## 11. Search with Voice Input (Optional Feature)

```
+------------------------------------------+
|  [<-] [________________________] [X] [M] |
|                                          |
+------------------------------------------+
|                                          |
|  +--------------------------------------+|
|  |                                      ||
|  |              ((( O )))               ||
|  |                                      ||
|  |           Listening...               ||
|  |                                      ||
|  |      "fantasy adventure books"       ||
|  |                                      ||
|  |              [Cancel]                ||
|  |                                      ||
|  +--------------------------------------+|
|                                          |
+------------------------------------------+

[M] = Microphone icon
((( O ))) = Animated listening indicator
```

---

## 12. Filter Badge States

```
No filters active:
+------+
| [#]  |    Plain filter icon
+------+

1-9 filters active:
+------+
| [#]  |    Badge with number
|  (3) |
+------+

10+ filters active:
+------+
| [#]  |    Badge with "9+"
| (9+) |
+------+
```

---

## 13. Quick Filter Interaction States

```
UNSELECTED:
+------------------+
|  [o] Reading     |   Outline border
+------------------+   Light background

SELECTED:
+------------------+
|  [*] Reading     |   Filled background
+------------------+   Checkmark or filled icon

PRESSED:
+------------------+
|  [o] Reading     |   Ripple effect
+------------------+   Slightly darker

DISABLED:
+------------------+
|  [o] Reading     |   50% opacity
+------------------+   No interaction
```

---

## 14. Responsive Layout - Tablet (600-840px)

```
+----------------------------------------------------------+
|  [=]  Library                                     [Search]|
+----------------------------------------------------------+
|                                                           |
| [All] [Reading] [Favorites] [Finished] [Shelves v] [More] |
|                                                           |
+----------------------------------------------------------+
|                                                           |
|  +--------+  +--------+  +--------+  +--------+           |
|  |        |  |        |  |        |  |        |           |
|  |  Book  |  |  Book  |  |  Book  |  |  Book  |           |
|  |  Cover |  |  Cover |  |  Cover |  |  Cover |           |
|  |        |  |        |  |        |  |        |           |
|  +--------+  +--------+  +--------+  +--------+           |
|  Title       Title       Title       Title                |
|  Author      Author      Author      Author               |
|                                                           |
|  +--------+  +--------+  +--------+  +--------+           |
|  |        |  |        |  |        |  |        |           |
|  |  Book  |  |  Book  |  |  Book  |  |  Book  |           |
|  |  Cover |  |  Cover |  |  Cover |  |  Cover |           |
|  |        |  |        |  |        |  |        |           |
|  +--------+  +--------+  +--------+  +--------+           |
|  Title       Title       Title       Title                |
|  Author      Author      Author      Author               |
|                                                  +------+ |
|                                                  | [+]  | |
|                                                  +------+ |
+----------------------------------------------------------+

Note: 4 columns instead of 2, expanded search bar
```

---

## 15. Accessibility Focus Order

```
Focus order indicated by numbers:

+------------------------------------------+
|  [1]  Library                    [2]     |  1: Menu/Back
+------------------------------------------+  2: Search
|                                          |
| [3] [4] [5] [6] [7] [8]                  |  3-8: Quick filters
|                                          |
+------------------------------------------+
|                                          |
|  [9]        [10]       [11]              |  9-11: First row books
|                                          |
|  [12]       [13]       [14]              |  12-14: Second row books
|                                          |
|                                  [15]    |  15: FAB
+------------------------------------------+

Screen reader will announce:
1. "Menu button"
2. "Search button. Double tap to search books"
3. "All filter, selected"
4. "Reading filter, not selected"
...and so on
```

---

## Component Measurements

### Search Bar
```
+--------------------------------------------------+
|  16px  [24px]  8px  [__________]  8px  [48px]    |  16px
|        icon         input            button       |
+--------------------------------------------------+
         ^                              ^
     Touch: 48px                    Touch: 48px

Total Height: 56px
Corner Radius: 28px (pill)
```

### Filter Chip
```
+------------------------+
|  12px  [18px]  4px  Text  4px  [18px]  12px  |
|        icon              optional X           |
+------------------------+

Height: 36px
Touch Target: 48px (with 6px vertical padding)
Corner Radius: 18px (pill)
Min Width: 64px
```

### Active Filter Chip
```
+----------------------------+
|  12px  Text  8px  [X]  8px |
|                   18px     |
+----------------------------+

Height: 32px
Touch Target: Full chip
Corner Radius: 16px
```

### Bottom Sheet
```
+------------------------------------------+
|                  32px                     |  Drag handle width
|                  4px                      |  Drag handle height
|                  16px                     |  Top padding
+------------------------------------------+
|  16px                            16px    |  Horizontal padding
|        Title           [48px]            |  Close button
|  16px                                    |  Below header
+------------------------------------------+
|  16px                                    |  Section padding
|        Section content                   |
|  24px                                    |  Between sections
+------------------------------------------+
|  16px                                    |
|  [   Button   ]  16px  [   Button   ]    |  Action bar
|  16px                                    |
+------------------------------------------+

Min Height: 30% of screen
Default Height: 60% of screen
Max Height: 95% of screen
Corner Radius (top): 16px
```
