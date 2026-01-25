# Book Details - Mobile

Self-contained design prompt for Book Details and Search Options screens on mobile.

---

## Color Reference (Light Theme)

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#5654A8` | Actions, progress |
| On Primary | `#FFFFFF` | Text on primary |
| Surface | `#FFFBFF` | Background |
| On Surface | `#1C1B1F` | Primary text |
| On Surface Variant | `#47464F` | Secondary text |
| Outline | `#787680` | Borders |
| Primary Container | `#E2DFFF` | Tabs, chips |
| Tertiary | `#7A5368` | Ratings |
| Surface Container | `#E4E1EC` | Cards |

---

## Screen 1: Book Details Page

### Purpose
Display comprehensive book information with tabs for details, annotations, and notes.

### User Entry Points
- Tap book from library grid
- Search result selection
- Notification about book

### Layout (390 x 844 viewport)

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [←]  Book Title...              [⋮]   │  App Bar: 64px
├─────────────────────────────────────────┤
│                                         │
│         ┌─────────────────┐             │
│         │                 │             │
│         │    [Cover]      │             │  Cover: 180x270px
│         │    180x270      │             │
│         │                 │             │
│         └─────────────────┘             │
│                                         │
│    The Great Gatsby                     │  Title: 24px
│    F. Scott Fitzgerald                  │  Author: 16px
│                                         │
│    ★★★★☆  4.2  •  EPUB  •  289 pages   │  Meta row
│                                         │
│    ━━━━━━━━━━━━━━━━━━░░░░░  75%        │  Progress: 4px
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌────────┐  │
│  │   Read   │ │ Add to   │ │  Edit  │  │  Action buttons
│  │    ▶     │ │  Shelf   │ │   ✎    │  │
│  └──────────┘ └──────────┘ └────────┘  │
│                                         │
├─────────────────────────────────────────┤
│  [Details]  [Annotations]  [Notes]      │  Tabs: 48px
├─────────────────────────────────────────┤
│                                         │
│  Description                            │  Tab content
│  ─────────────────────────────────────  │  (scrollable)
│  Set in the Jazz Age on Long Island... │
│  the novel depicts narrator Nick...     │
│                             [Read more] │
│                                         │
│  Information                            │
│  ─────────────────────────────────────  │
│  Publisher    Scribner                  │
│  Published    April 10, 1925            │
│  ISBN         978-0743273565            │
│  Language     English                   │
│  Format       EPUB                      │
│  File size    2.4 MB                    │
│                                         │
│  Shelves                                │
│  ─────────────────────────────────────  │
│  [Currently Reading] [Favorites]        │
│                                         │
│  Topics                                 │
│  ─────────────────────────────────────  │
│  [● Fiction] [● Classics] [● American] │
│                                         │
└─────────────────────────────────────────┘
```

### Component Specifications

**App Bar:**
- Height: 64px
- Leading: Back arrow (24px)
- Title: Book title, truncated with ellipsis
- Trailing: Overflow menu (24px)

**Cover Section:**
- Cover size: 180 x 270px
- Border radius: 12px
- Shadow: Level 2
- Centered horizontally
- Margin: 24px top

**Book Title:**
- Text: Book title
- Style: Headline Medium (28px)
- Alignment: Center
- Margin: 16px top

**Author:**
- Text: Author name
- Style: Title Medium (16px)
- Color: On Surface Variant
- Alignment: Center
- Margin: 4px top

**Meta Row:**
- Rating: 5 stars (16px each), filled/empty, Tertiary color
- Rating number: Body Medium
- Format badge: EPUB/PDF/MOBI
- Page count: "289 pages"
- Separator: "•" in On Surface Variant
- Centered, flex row with gaps

**Progress Bar:**
- Height: 4px
- Width: Full width minus 48px padding
- Track: Surface Container
- Fill: Primary
- Border radius: 2px
- Percentage: Body Small, right-aligned

**Action Buttons:**
```
┌──────────────────┐
│      Read        │
│       ▶          │  Primary filled
└──────────────────┘
```
- Layout: 3 buttons in row
- Primary "Read": Filled, Primary background
- "Add to Shelf": Outlined
- "Edit": Outlined, icon only (48x48)
- Height: 48px
- Gap: 12px
- Margin: 24px horizontal

**Tab Bar:**
- Height: 48px
- Tabs: Details, Annotations, Notes
- Active tab: Primary color text, 3px indicator
- Inactive: On Surface Variant

### Tab Content: Details

**Section Headers:**
- Text: "Description", "Information", "Shelves", "Topics"
- Style: Title Small (14px), bold
- Color: On Surface
- Underline: 1px Outline Variant
- Margin: 16px bottom

**Description:**
- Text: Body Large (16px)
- Line height: 24px
- Max lines: 4 (collapsed)
- "Read more" link: Primary color

**Information Grid:**
```
Publisher    Scribner
Published    April 10, 1925
ISBN         978-0743273565
```
- Left column: Body Medium, On Surface Variant
- Right column: Body Medium, On Surface
- Row height: 32px
- Padding: 16px horizontal

**Shelf Chips:**
- Same as library filter chips
- Removable (x icon on tap)

**Topic Chips:**
- With color dots
- Tappable to filter library

### Tab Content: Annotations

```
┌─────────────────────────────────────────┐
│  "The loneliest moment in someone's    │
│  life is when they are watching..."    │
│                                         │
│  ● Chapter 3, Page 45                   │  Yellow highlight dot
│  Added Jan 15, 2024                     │
├─────────────────────────────────────────┤
│  Note: This quote resonates with the   │
│  theme of isolation in modern society. │
└─────────────────────────────────────────┘
```

- Highlight card with color indicator
- Quote text: Body Large, italic
- Location: Body Small, On Surface Variant
- Note (if any): Body Medium, Surface Container background

### Tab Content: Notes

```
┌─────────────────────────────────────────┐
│  Chapter 1 Summary                      │
│  ─────────────────────────────────────  │
│  Nick Carraway introduces himself as   │
│  the narrator and describes his move...│
│                                         │
│  Created Jan 14, 2024                   │
└─────────────────────────────────────────┘
```

- Note title: Title Medium
- Note content: Body Medium, max 3 lines
- Date: Body Small, On Surface Variant
- FAB: Add note (bottom right)

---

## Screen 2: Search Options Page

### Purpose
Advanced search and filtering interface.

### Layout

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [←]  Search Options                    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ 🔍 Search books...                  ││  Search input
│  └─────────────────────────────────────┘│
│                                         │
│  FILTERS                                │
│                                         │
│  Reading Status                         │
│  ┌────────┐ ┌────────┐ ┌────────────┐  │
│  │  All   │ │Reading │ │ Finished   │  │  Chips
│  └────────┘ └────────┘ └────────────┘  │
│                                         │
│  Format                                 │
│  ┌──────┐ ┌─────┐ ┌──────┐ ┌────────┐  │
│  │ All  │ │EPUB │ │ PDF  │ │Physical│  │
│  └──────┘ └─────┘ └──────┘ └────────┘  │
│                                         │
│  Rating                                 │
│  ★ ★ ★ ★ ★  Any rating                 │
│                                         │
│  Date Added                             │
│  ┌─────────────────────────────────────┐│
│  │ Any time                        [▼] ││  Dropdown
│  └─────────────────────────────────────┘│
│                                         │
│  Shelves                                │
│  ┌──────────────┐ ┌─────────────────┐  │
│  │ All shelves  │ │ Currently Read. │  │
│  └──────────────┘ └─────────────────┘  │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │          Apply Filters              ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │          Clear All                  ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

### Component Specifications

**Filter Section:**
- Header: Title Small, bold
- Margin: 24px top, 8px bottom

**Filter Chips:**
- Multi-select capable
- Selected: Primary Container, check icon
- Unselected: Surface Container

**Rating Filter:**
- 5 tappable stars
- Tap to set minimum rating
- "Any rating" text when none selected

**Date Dropdown:**
- Options: Any time, Last 7 days, Last 30 days, Last year, Custom
- Custom opens date picker

**Apply Button:**
- Full width
- Primary filled
- Text: "Apply Filters"

**Clear Button:**
- Full width
- Text button
- Text: "Clear All"

---

## Figma Generation Instructions

```
CREATE MOBILE BOOK DETAILS SCREENS

Frame 1: Book Details - Details Tab (390 x 844)
- App bar: Back button, book title truncated, overflow menu
- Cover: 180x270px, centered, rounded corners, shadow
- Title: 28px centered below cover
- Author: 16px gray, centered
- Meta row: Stars, rating number, format, pages
- Progress bar: 4px, full width - 48px
- Action buttons: Read (primary), Add to Shelf (outlined), Edit (icon)
- Tab bar: Details active
- Details content: Description, Information grid, Shelves, Topics

Frame 2: Book Details - Annotations Tab (390 x 844)
- Same header and cover section
- Tab bar: Annotations active
- Annotation cards with highlight color, quote, location, optional note

Frame 3: Book Details - Notes Tab (390 x 844)
- Same header and cover section
- Tab bar: Notes active
- Note cards with title, preview, date
- FAB for adding notes

Frame 4: Book Details - Empty Annotations (390 x 844)
- Empty state: "No annotations yet"

Frame 5: Search Options (390 x 844)
- App bar: Back, "Search Options"
- Search input field
- Filter sections: Reading Status, Format, Rating, Date, Shelves
- Filter chips (multi-select)
- Apply and Clear buttons

COMPONENT STATES:
- Rating stars: empty, filled, interactive
- Filter chips: unselected, selected
- Action buttons: default, pressed
- Tab: active, inactive
```
