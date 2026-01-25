# Book Details - E-ink

Self-contained design prompt for Book Details and Search Options screens on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Text, borders, icons |
| White | `#FFFFFF` | Background |
| Dark Gray | `#404040` | Secondary text |
| Medium Gray | `#808080` | Disabled |
| Light Gray | `#C0C0C0` | Dividers |
| Container | `#F5F5F5` | Cards, inputs |

---

## Screen 1: Book Details Page

### Purpose
Display book information optimized for e-ink readability with minimal UI chrome.

### Layout (1072 x 1448 viewport)

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  BOOK DETAILS                                                │  Header: 72px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│       ┌─────────────────┐                                         │
│       │                 │                                         │
│       │    [Cover]      │    THE GREAT GATSBY                     │
│       │    160x240      │                                         │
│       │                 │    F. Scott Fitzgerald                  │
│       │                 │                                         │
│       └─────────────────┘    ★★★★☆  4.2                          │
│                                                                   │
│       Progress: 75%                                               │
│       ████████████████████████░░░░░░░░                           │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    CONTINUE READING                         │  │  Primary: 64px
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────┐  ┌───────────────────────────┐    │
│  │      ADD TO SHELF         │  │          EDIT             │    │  Secondary: 56px
│  └───────────────────────────┘  └───────────────────────────┘    │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  [DETAILS]  │  [ANNOTATIONS]  │  [NOTES]                         │  Tabs: 56px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  DESCRIPTION                                                      │
│  ─────────────────────────────────────────────────────────────── │
│  Set in the Jazz Age on Long Island, the novel                   │
│  depicts narrator Nick Carraway's interactions                   │
│  with mysterious millionaire Jay Gatsby and                      │
│  Gatsby's obsession with his former lover...                     │
│                                                                   │
│  INFORMATION                                                      │
│  ─────────────────────────────────────────────────────────────── │
│  Publisher      Scribner                                          │
│  Published      April 10, 1925                                    │
│  ISBN           978-0743273565                                    │
│  Format         EPUB                                              │
│  Pages          289                                               │
│                                                                   │
│  SHELVES                                                          │
│  ─────────────────────────────────────────────────────────────── │
│  Currently Reading, Favorites                                     │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Header:**
- Height: 72px
- Back button: 56x56px touch area
- Title: "BOOK DETAILS", 24px, bold
- Border bottom: 2px solid Black

**Cover Section:**
- Layout: Cover left, info right
- Cover: 160 x 240px, 2px black border
- Title: 24px, bold, uppercase
- Author: 18px
- Rating: 5 stars (text-based for e-ink: "★★★★☆")

**Progress Section:**
- Label: "Progress: 75%", 16px
- Bar: 16px height, segmented (20 segments)
- Filled: Black, Empty: Light Gray with border

**Action Buttons:**

Primary (Continue Reading):
- Width: Full width - 96px margins
- Height: 64px
- Background: Black
- Text: "CONTINUE READING", white, 18px, bold

Secondary (Add to Shelf, Edit):
- Width: 50% - gaps
- Height: 56px
- Background: White
- Border: 2px solid Black
- Text: 16px, bold

**Tab Bar:**
- Height: 56px
- Tabs: DETAILS, ANNOTATIONS, NOTES
- Selected: Black background, white text
- Border: 2px bottom

**Content Sections:**
- Section title: 16px, bold, uppercase
- Divider: 2px solid Black below title
- Body text: 18px, line height 28px
- Info grid: Label left (Dark Gray), value right (Black)

### Tab: Annotations

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  ANNOTATIONS (12)                                            │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  "The loneliest moment in someone's life is when           │  │
│  │  they are watching their whole world fall apart..."        │  │
│  │                                                             │  │
│  │  Chapter 3, Page 45                                         │  │
│  │  Highlighted Jan 15, 2024                                   │  │
│  │                                                             │  │
│  │  NOTE: This quote resonates with the theme of              │  │
│  │  isolation in modern society.                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  "So we beat on, boats against the current, borne          │  │
│  │  back ceaselessly into the past."                          │  │
│  │                                                             │  │
│  │  Chapter 9, Page 180                                        │  │
│  │  Highlighted Jan 18, 2024                                   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

**Annotation Card:**
- Border: 2px solid Black
- Padding: 16px
- Quote: 18px, italic
- Location: 14px, Dark Gray
- Date: 14px, Dark Gray
- Note (if present): 16px, prefixed with "NOTE:"
- Margin bottom: 16px

### Tab: Notes

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  NOTES (3)                                          [+ ADD]  │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  CHAPTER 1 SUMMARY                                          │  │
│  │  ───────────────────────────────────────────────────────── │  │
│  │  Nick Carraway introduces himself as the narrator          │  │
│  │  and describes his move to West Egg, Long Island.          │  │
│  │  He rents a small house next to Gatsby's mansion...        │  │
│  │                                                             │  │
│  │  Created Jan 14, 2024                                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  THEMES TO EXPLORE                                          │  │
│  │  ───────────────────────────────────────────────────────── │  │
│  │  - The American Dream and its corruption                   │  │
│  │  - Old money vs new money                                  │  │
│  │  - The green light symbolism...                            │  │
│  │                                                             │  │
│  │  Created Jan 16, 2024                                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

**Note Card:**
- Border: 2px solid Black
- Title: 18px, bold, uppercase
- Divider: 1px below title
- Content: 18px
- Date: 14px, Dark Gray

---

## Screen 2: Search/Filter Screen

### Full-screen filter interface

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  SEARCH & FILTER                                    [CLEAR]  │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  SEARCH                                                           │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Enter search term...                                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  READING STATUS                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ○ ALL                                                      │  │
│  │  ○ NOT STARTED                                              │  │
│  │  ● READING                                                  │  │
│  │  ○ FINISHED                                                 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  FORMAT                                                           │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ☑ EPUB                                                     │  │
│  │  ☑ PDF                                                      │  │
│  │  ☐ MOBI                                                     │  │
│  │  ☐ PHYSICAL                                                 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  MINIMUM RATING                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  [★] [★★] [★★★] [★★★★] [★★★★★] [ANY]                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    APPLY FILTERS                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Filter Components

**Search Input:**
- Height: 64px
- Border: 2px solid Black
- Background: Container (#F5F5F5)
- Text: 18px

**Radio Group (Reading Status):**
- Container: 2px border
- Row height: 56px (touch target)
- Radio: 24px circle, 2px border
- Selected: Filled black dot
- Text: 18px

**Checkbox Group (Format):**
- Container: 2px border
- Row height: 56px
- Checkbox: 24px square, 2px border
- Checked: Black fill with white checkmark
- Text: 18px

**Rating Selector:**
- Segmented buttons
- Each segment: Star count
- Selected: Black background, white text
- Unselected: White background, black text

**Apply Button:**
- Full width - margins
- Height: 64px
- Black background, white text

---

## Figma Generation Instructions

```
CREATE E-INK BOOK DETAILS SCREENS

GLOBAL RULES:
- All backgrounds: #FFFFFF
- All primary elements: #000000
- Borders: 2px minimum
- Border radius: 0px
- Touch targets: 56px minimum
- Font minimum: 14px

Frame 1: Book Details - Main (1072 x 1448)
- Header: 72px, back button, "BOOK DETAILS" title
- Cover section: Cover left (160x240, 2px border), info right
- Title: 24px bold uppercase
- Author: 18px
- Rating: Text stars "★★★★☆"
- Progress: Text label + segmented 16px bar
- Buttons: Primary full-width 64px, two secondary 56px
- Tab bar: 56px, selected inverted
- Details content: Description, Information grid, Shelves list

Frame 2: Book Details - Annotations (1072 x 1448)
- Header with count "(12)"
- Annotation cards: 2px border, quote italic, location, date, optional note
- Dividers between cards

Frame 3: Book Details - Notes (1072 x 1448)
- Header with count and ADD button
- Note cards: 2px border, title bold, content, date

Frame 4: Search/Filter (1072 x 1448)
- Header: "SEARCH & FILTER", CLEAR button
- Search input: 64px
- Radio group: Reading Status in bordered container
- Checkbox group: Format in bordered container
- Rating: Segmented button selector
- Apply button: 64px, black fill

STATES:
- Tab selected: Inverted colors
- Radio selected: Filled dot
- Checkbox checked: Black fill, white check
- Button pressed: Inverted colors
- Input focused: 4px border
```
