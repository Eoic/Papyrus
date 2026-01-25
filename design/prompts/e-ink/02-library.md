# Library Screens - E-ink

Self-contained design prompt for Books, Shelves, and Topics screens on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Text, borders, icons |
| White | `#FFFFFF` | Background |
| Dark Gray | `#404040` | Secondary text |
| Medium Gray | `#808080` | Disabled |
| Light Gray | `#C0C0C0` | Dividers |
| Container | `#F5F5F5` | Cards |

**Rules:**
- NO gradients, shadows, transparency
- All borders: 2px minimum
- Border radius: 0px
- Touch targets: 56px minimum

---

## Screen 1: Books Page (Library Home)

### Purpose
Simple, high-contrast book list optimized for e-ink display.

### Layout (1072 x 1448 viewport)

```
┌───────────────────────────────────────────────────────────────────┐
│  LIBRARY                                            [+] [Search]  │  Header: 72px
├───────────────────────────────────────────────────────────────────┤
│  [ALL] [SHELVES] [TOPICS] [FAVORITES]                            │  Tab bar: 56px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ ┌───────────┐                                               │  │
│  │ │           │  BOOK TITLE                                   │  │  Row: 96px
│  │ │  [Cover]  │  Author Name                                  │  │
│  │ │  64x96px  │  ████████████░░░░░░░░░░░░  45%                │  │  Progress
│  │ └───────────┘                                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│  Divider: 1px
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ ┌───────────┐                                               │  │
│  │ │           │  ANOTHER BOOK TITLE                           │  │
│  │ │  [Cover]  │  Another Author                               │  │
│  │ │           │                                               │  │
│  │ └───────────┘                                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ ┌───────────┐                                               │  │
│  │ │           │  THIRD BOOK TITLE                             │  │
│  │ │  [Cover]  │  Third Author                                 │  │
│  │ │           │                                               │  │
│  │ └───────────┘                                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  LIBRARY  │  GOALS  │  STATS  │  SETTINGS                        │  Bottom nav: 72px
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Header:**
- Height: 72px
- Background: White
- Border bottom: 2px solid Black
- Title: "LIBRARY", 24px, bold, left
- Actions: Add (+) and Search icons, 48px touch targets

**Tab Bar:**
- Height: 56px
- Tabs: "ALL", "SHELVES", "TOPICS", "FAVORITES"
- Selected: Black background, white text
- Unselected: White background, black text, 2px bottom border
- Touch target: Full tab width, 56px height

**Book Row:**
```
┌─────────────────────────────────────────────────────────────────┐
│ ┌───────────┐                                                   │
│ │           │  BOOK TITLE                                       │
│ │  [Cover]  │  Author Name                                      │  Height: 96px
│ │  64x96px  │  ████████████░░░░░░░░░░░░  45%                    │
│ └───────────┘                                                   │
└─────────────────────────────────────────────────────────────────┘
```
- Height: 96px
- Padding: 16px
- Cover: 64x96px, 2px black border
- Title: 20px, bold, uppercase
- Author: 16px, Dark Gray
- Progress bar: 8px height, segmented (10 segments)
- Divider: 1px Light Gray

**Progress Bar (E-ink optimized):**
```
████████████░░░░░░░░░░░░  45%
```
- Height: 8px
- Filled segments: Black
- Empty segments: Light Gray with 1px border
- Percentage text: 14px, right of bar

**Bottom Navigation:**
- Height: 72px
- Border top: 2px solid Black
- Items: LIBRARY, GOALS, STATS, SETTINGS
- Active: Black background, white text
- Text: 14px, uppercase

### Empty State

```
┌───────────────────────────────────────────────────────────────────┐
│                                                                   │
│                         NO BOOKS YET                              │  24px, bold
│                                                                   │
│           Add your first book to start reading                    │  18px
│                                                                   │
│              ┌─────────────────────────────┐                      │
│              │        ADD BOOK             │                      │  64px button
│              └─────────────────────────────┘                      │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Screen 2: Shelves Page

### Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  SHELVES                                                    [+]   │  Header
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  DEFAULT SHELVES                                                  │  Section: 16px
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  CURRENTLY READING                                      12  │  │  Row: 72px
│  │  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  WANT TO READ                                           34  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  FINISHED                                               89  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  FAVORITES                                              15  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  CUSTOM SHELVES                                                   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SCIENCE FICTION                                         8  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  LIBRARY  │  GOALS  │  STATS  │  SETTINGS                        │
└───────────────────────────────────────────────────────────────────┘
```

### Shelf Row

```
┌─────────────────────────────────────────────────────────────────┐
│  SHELF NAME                                                 12  │
│  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░  (optional)            │
└─────────────────────────────────────────────────────────────────┘
```
- Height: 72px (without progress), 96px (with progress)
- Padding: 16px
- Name: 18px, bold, uppercase
- Count: 18px, right-aligned
- Progress: For "Currently Reading" only
- Touch target: Full width

### Section Header

- Text: "DEFAULT SHELVES", "CUSTOM SHELVES"
- Size: 14px, bold
- Color: Dark Gray
- Padding: 24px top, 8px bottom

---

## Screen 3: Topics Page

### Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  TOPICS                                                     [+]   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  FICTION                                                45  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  NON-FICTION                                            32  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  HISTORY                                                18  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SCIENCE FICTION                                        12  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  BIOGRAPHY                                              15  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  LIBRARY  │  GOALS  │  STATS  │  SETTINGS                        │
└───────────────────────────────────────────────────────────────────┘
```

### Topic Row

```
┌─────────────────────────────────────────────────────────────────┐
│  TOPIC NAME                                                 45  │
└─────────────────────────────────────────────────────────────────┘
```
- Height: 64px
- Padding: 16px
- Name: 18px, bold, uppercase
- Count: 18px, right-aligned
- No colored dots (e-ink limitation)

---

## Search Screen

When search is tapped:

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  SEARCH                                                      │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Search books...                                            │  │  Input: 64px
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  RECENT SEARCHES                                                  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  "science fiction"                                     [x]  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  "asimov"                                              [x]  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Add Book Bottom Sheet (Full Screen on E-ink)

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  ADD BOOK                                                    │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  IMPORT FROM FILE                                       [>] │  │  Option: 72px
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ADD MANUALLY                                           [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SCAN BARCODE                                           [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Figma Generation Instructions

```
CREATE E-INK LIBRARY SCREENS

GLOBAL RULES:
- Background: #FFFFFF
- Text/borders: #000000
- No shadows, gradients, or transparency
- All borders: 2px solid black
- Border radius: 0px
- Minimum touch target: 56px

Frame 1: Books Page - List (1072 x 1448)
- Header: 72px, "LIBRARY" title, add and search icons
- Tab bar: 56px, 4 tabs, selected = inverted colors
- Book list: Full width rows, 96px each
  - Cover thumbnail: 64x96px with 2px border
  - Title: 20px bold uppercase
  - Author: 16px gray
  - Progress bar: 8px, segmented
- Dividers: 1px light gray between rows
- Bottom nav: 72px, 4 items

Frame 2: Books Page - Empty (1072 x 1448)
- Same header and tabs
- Centered empty state with message and button

Frame 3: Shelves Page (1072 x 1448)
- Header: "SHELVES" title, add icon
- Section headers: "DEFAULT SHELVES", "CUSTOM SHELVES"
- Shelf rows: 72px height, name + count
- Progress bar for "Currently Reading"

Frame 4: Topics Page (1072 x 1448)
- Header: "TOPICS" title, add icon
- Topic rows: 64px height, name + count
- No colored indicators (grayscale only)

Frame 5: Search Screen (1072 x 1448)
- Back button + "SEARCH" title
- Search input: 64px, 2px border
- Recent searches list

Frame 6: Add Book Modal (1072 x 1448)
- Full screen (not bottom sheet)
- Back button + "ADD BOOK" title
- Option rows: 72px each with chevron

STATES:
- Tab selected: Inverted (black bg, white text)
- Row pressed: Light gray background (#F5F5F5)
- Button pressed: Inverted colors
```
