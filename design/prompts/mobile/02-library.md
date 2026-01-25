# Library Screens - Mobile

Self-contained design prompt for Books, Shelves, and Topics screens on mobile.

---

## Color Reference (Light Theme)

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#5654A8` | Active states, FAB |
| On Primary | `#FFFFFF` | Text on primary |
| Surface | `#FFFBFF` | Background |
| On Surface | `#1C1B1F` | Primary text |
| On Surface Variant | `#47464F` | Secondary text |
| Outline | `#787680` | Borders |
| Primary Container | `#E2DFFF` | Selected states |
| Surface Container | `#E4E1EC` | Cards, inputs |

---

## Screen 1: Books Page (Library Home)

### Purpose
Main library view displaying user's book collection in a grid or list format.

### User Entry Points
- Bottom navigation "Library" tab
- App launch (authenticated user)
- Back from book details

### Layout (390 x 844 viewport)

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [≡]  Library                    [🔍]  │  App Bar: 64px
├─────────────────────────────────────────┤
│  ┌─────┬─────┬─────┬─────┬─────┬─────┐ │
│  │ All │Shelf│Topic│ ★  │ New │ ... │ │  Filter chips (scrollable)
│  └─────┴─────┴─────┴─────┴─────┴─────┘ │  Height: 48px
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────┐  ┌─────────┐               │
│  │         │  │         │               │
│  │ [Cover] │  │ [Cover] │               │  Book Grid
│  │         │  │         │               │  2 columns
│  ├─────────┤  ├─────────┤               │  Cover: 165x247px
│  │ Title   │  │ Title   │               │
│  │ Author  │  │ Author  │               │
│  └─────────┘  └─────────┘               │
│                                         │
│  ┌─────────┐  ┌─────────┐               │
│  │         │  │         │               │
│  │ [Cover] │  │ [Cover] │               │
│  │         │  │         │               │
│  ├─────────┤  ├─────────┤               │
│  │ Title   │  │ Title   │               │
│  │ Author  │  │ Author  │               │
│  └─────────┘  └─────────┘               │
│                                         │
│                              ┌─────┐    │
│                              │ [+] │    │  FAB: 56px
│                              └─────┘    │
├─────────────────────────────────────────┤
│ [□] [■] [□] [□] [□]                     │  Bottom Nav: 80px
│ Dash Lib Goals Stats Prof               │
└─────────────────────────────────────────┘
```

### Component Specifications

**App Bar:**
- Height: 64px
- Leading: Drawer menu icon (24px)
- Title: "Library", Title Large (22px)
- Trailing: Search icon (24px)
- Background: Surface

**Filter Chips (Horizontal Scroll):**
- Height: 32px each
- Padding: 12px horizontal
- Background: Surface Container (unselected), Primary Container (selected)
- Text: Label Large (14px)
- Border radius: 16px
- Chips: "All", "Shelves", "Topics", "Favorites", "Recently Added", "Reading"
- Container padding: 16px horizontal, 8px vertical
- Gap between chips: 8px

**Book Grid:**
- Columns: 2
- Column gap: 16px
- Row gap: 16px
- Padding: 16px horizontal
- Card width: (390 - 48) / 2 = 171px

**Book Card:**
```
┌─────────────────┐
│                 │
│   [Cover]       │  Aspect: 2:3
│   171 x 256px   │  Border radius: 8px
│                 │
├─────────────────┤
│ Book Title      │  14px, Title Small, max 2 lines
│ Author Name     │  11px, Label Small, 1 line
└─────────────────┘  Total height: ~310px
```
- Cover: `object-fit: cover`, border radius 8px
- Placeholder: Surface Container with book icon
- Title: 14px, Title Small, weight 500, max 2 lines, ellipsis
- Author: 11px, Label Small, On Surface Variant, 1 line, ellipsis
- Card shadow: Level 1

**FAB (Floating Action Button):**
- Size: 56x56px
- Background: Primary (`#5654A8`)
- Icon: `add` (24px, white)
- Position: Bottom right, 16px from edges, 16px above bottom nav
- Border radius: 16px
- Shadow: Level 3

**Bottom Navigation:**
- Height: 80px (including safe area)
- Items: Dashboard, Library (active), Goals, Statistics, Profile
- Active: Primary color with indicator pill

### States to Design

1. **Empty State:**
```
┌─────────────────────────────────────────┐
│                                         │
│              [book icon]                │  48px icon
│                                         │
│          No books yet                   │  Headline Small
│                                         │
│   Add your first book to start          │  Body Medium
│   building your library                 │
│                                         │
│         ┌──────────────┐                │
│         │  Add Book    │                │  Primary button
│         └──────────────┘                │
│                                         │
└─────────────────────────────────────────┘
```

2. **Loading State:**
- Skeleton cards (gray rectangles)
- No FAB until loaded

3. **Populated State:**
- Grid with books
- FAB visible

4. **Filtered State:**
- Selected chip highlighted
- Grid shows filtered results

### Interactions

- Tap book: Navigate to book details
- Long press book: Show context menu (Edit, Add to shelf, Delete)
- Tap FAB: Open "Add book" bottom sheet
- Tap drawer icon: Open library drawer
- Pull down: Refresh library

---

## Screen 2: Shelves Page

### Purpose
Manage and browse book collections organized into shelves.

### Layout

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [≡]  Shelves                    [+]   │  App Bar
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ [📚]  Currently Reading         12 ││  Shelf Card
│  │       ──────────────────────────   ││  Height: 72px
│  │       ████████████░░░░░░░░░░░░░    ││  Progress bar
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ [📖]  Want to Read              34 ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ [✓]   Finished                  89 ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ [♥]   Favorites                 15 ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  Custom Shelves                         │  Section header
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ [📁]  Science Fiction            8 ││
│  └─────────────────────────────────────┘│
│                                         │
├─────────────────────────────────────────┤
│ [□] [■] [□] [□] [□]                     │
└─────────────────────────────────────────┘
```

### Component Specifications

**Shelf Card:**
```
┌─────────────────────────────────────────────────┐
│ [icon]  Shelf Name                        [12] │
│         ████████████░░░░░░░░░░░░░   (optional) │
└─────────────────────────────────────────────────┘
```
- Height: 72px (with progress) or 64px (without)
- Padding: 16px
- Icon: 24px, circle background (Surface Container)
- Name: Title Medium (16px)
- Count: Body Medium, On Surface Variant
- Progress bar: 4px height, Primary color (optional)
- Divider: 1px at bottom

**Section Header:**
- Text: "Custom Shelves"
- Style: Title Small (14px)
- Color: On Surface Variant
- Padding: 16px horizontal, 24px top, 8px bottom

**Add Button (App Bar):**
- Icon: `add` (24px)
- Touch target: 48x48px

### Empty State

```
No custom shelves yet

Create shelves to organize your books

[Create Shelf]
```

---

## Screen 3: Topics/Tags Page

### Purpose
View and manage book tags/topics for organization.

### Layout

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [≡]  Topics                     [+]   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │  ┌────────┐ ┌──────────┐ ┌───────┐ ││  Tag cloud
│  │  │Fiction │ │Non-fiction│ │History│ ││  or list view
│  │  └────────┘ └──────────┘ └───────┘ ││
│  │                                     ││
│  │  ┌─────────┐ ┌───────┐ ┌─────────┐ ││
│  │  │Biography│ │Science│ │Self-help│ ││
│  │  └─────────┘ └───────┘ └─────────┘ ││
│  │                                     ││
│  │  ┌────────┐ ┌────────┐ ┌─────────┐ ││
│  │  │Fantasy │ │Mystery │ │ Romance │ ││
│  │  └────────┘ └────────┘ └─────────┘ ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
├─────────────────────────────────────────┤
│ [□] [■] [□] [□] [□]                     │
└─────────────────────────────────────────┘
```

### Component Specifications

**Topic Chip:**
```
┌─────────────────┐
│ ● Topic Name 12 │  Height: 36px
└─────────────────┘  Border radius: 18px
```
- Height: 36px
- Padding: 12px horizontal
- Background: Surface Container
- Leading: Color dot (8px circle)
- Text: Label Large (14px)
- Count: Label Medium, On Surface Variant
- Border radius: 18px (pill)

**Chip Colors (predefined):**
| Topic Type | Dot Color |
|------------|-----------|
| Fiction | `#5654A8` (Primary) |
| Non-fiction | `#7A5368` (Tertiary) |
| Custom | User-selected |

**Layout:**
- Wrap flow layout
- Gap: 8px
- Padding: 16px

### Interactions

- Tap topic: Navigate to filtered books view
- Long press: Edit or delete topic
- Tap +: Create new topic

---

## Navigation Drawer (Library Sub-nav)

When drawer icon is tapped:

```
┌────────────────────────────┐
│                            │
│  ┌────────────────────────┐│
│  │      [Logo]            ││  72px header
│  │      Papyrus           ││
│  └────────────────────────┘│
├────────────────────────────┤
│  [■] All Books          ←  │  Selected
│  [□] Shelves               │
│  [□] Topics                │
│  [□] Bookmarks             │
│  [□] Annotations           │
│  [□] Notes                 │
├────────────────────────────┤
│                            │
└────────────────────────────┘
Width: 280px
```

---

## Figma Generation Instructions

```
CREATE MOBILE LIBRARY SCREENS

Frame 1: Books Page - Empty (390 x 844)
- Status bar: 47px
- App bar: 64px, drawer icon left, "Library" title, search icon right
- Filter chips: Horizontal scroll, 48px container height
- Empty state: Centered icon (48px), headline, body text, primary button
- Bottom nav: 80px, Library tab active

Frame 2: Books Page - Populated (390 x 844)
- Same header as empty
- Book grid: 2 columns, 16px gaps
- Book cards: 171px wide, 2:3 cover + text area
- FAB: 56px, bottom right, #5654A8 fill
- Bottom nav: Library active

Frame 3: Shelves Page (390 x 844)
- App bar: "Shelves" title, add icon
- Shelf cards: Full width, 72px height, icon + name + count
- Default shelves: Currently Reading, Want to Read, Finished, Favorites
- Section header: "Custom Shelves"
- Bottom nav

Frame 4: Topics Page (390 x 844)
- App bar: "Topics" title, add icon
- Topic chips: Wrap layout, colored dots, name + count
- Bottom nav

Frame 5: Navigation Drawer
- Width: 280px
- Header with logo
- Menu items with icons

COMPONENT VARIANTS:
- Book card: default, selected (primary border), loading (skeleton)
- Filter chip: unselected, selected
- Shelf card: default, with progress bar
- Topic chip: various colors

STATES:
- Empty states for all screens
- Loading skeletons
- Context menu on long-press
```
