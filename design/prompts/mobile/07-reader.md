# Book Reader - Mobile

Self-contained design prompt for the immersive book reading experience on mobile.

---

## Color Reference (Light/Sepia/Dark Themes)

**Light Reading Theme:**
| Token | Value | Usage |
|-------|-------|-------|
| Background | `#FFFBFF` | Page background |
| Text | `#1C1B1F` | Body text |
| Primary | `#5654A8` | Highlights, controls |

**Sepia Theme:**
| Token | Value | Usage |
|-------|-------|-------|
| Background | `#FDF6E3` | Page background |
| Text | `#5C4A32` | Body text |
| Primary | `#8B7355` | Highlights |

**Dark Theme:**
| Token | Value | Usage |
|-------|-------|-------|
| Background | `#1C1B1F` | Page background |
| Text | `#E5E1E6` | Body text |
| Primary | `#C3C0FF` | Highlights |

---

## Main Reader View

### Purpose
Immersive, distraction-free reading experience with minimal UI chrome.

### Layout (390 x 844 viewport)

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │  Auto-hide with UI
├─────────────────────────────────────────┤
│  [←]  The Great Gatsby         [Aa][⋮] │  Top bar (auto-hide)
├─────────────────────────────────────────┤  64px
│                                         │
│                                         │
│     In my younger and more              │
│  vulnerable years my father gave        │
│  me some advice that I've been          │
│  turning over in my mind ever           │
│  since.                                 │
│                                         │  Reading area
│     "Whenever you feel like             │  (tap zones for nav)
│  criticizing anyone," he told me,       │
│  "just remember that all the            │
│  people in this world haven't had       │
│  the advantages that you've had."       │
│                                         │
│     He didn't say any more, but         │
│  we've always been unusually            │
│  communicative in a reserved way,       │
│  and I understood that he meant a       │
│  great deal more than that.             │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  Chapter 1                    12 of 180 │  Bottom bar (auto-hide)
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░ │  48px
└─────────────────────────────────────────┘
```

### Component Specifications

**Top Bar (Auto-hide):**
- Height: 64px
- Background: Semi-transparent surface (when visible)
- Leading: Back arrow
- Center: Book title (truncated)
- Trailing: Text settings (Aa), overflow menu
- Shows on tap, hides after 3 seconds

**Reading Area:**
- Full screen content
- Tap zones:
  - Left 1/3: Previous page
  - Center 1/3: Show/hide UI
  - Right 1/3: Next page
- Long press: Create highlight

**Text Styling (Default):**
- Font: Georgia or user preference
- Size: 18px (adjustable 12-32px)
- Line height: 1.6
- Paragraph spacing: 1em
- Margins: 24px horizontal

**Bottom Bar (Auto-hide):**
- Height: 48px
- Chapter name: Left
- Page indicator: Right (current / total)
- Progress bar: Full width, 4px
- Progress: Primary color

**Progress Bar:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░
```
- Draggable for navigation
- Shows tooltip with page number while dragging

---

## Reader Settings Panel

### Triggered by "Aa" button

```
┌─────────────────────────────────────────┐
│            ─────────────                │  Handle
│                                         │
│  Reading Settings                       │
│                                         │
│  Font                                   │
│  ┌────┐ ┌────────┐ ┌────────┐ ┌──────┐ │
│  │ Aa │ │ Aa     │ │  Aa    │ │ Aa   │ │  Font options
│  │Sys │ │Georgia │ │Literata│ │OpenDys│ │
│  └────┘ └────────┘ └────────┘ └──────┘ │
│                                         │
│  Size                                   │
│  A  [━━━━━━━━━●━━━━━━━━━]  A           │  Size slider
│                            18px         │
│                                         │
│  Line Spacing                           │
│  [━━━━━━━━━━━●━━━━━━━━━━━]             │
│                            1.6          │
│                                         │
│  Theme                                  │
│  ┌──────┐ ┌──────┐ ┌──────┐            │
│  │  ○   │ │  ○   │ │  ○   │            │  Theme options
│  │Light │ │Sepia │ │ Dark │            │
│  └──────┘ └──────┘ └──────┘            │
│                                         │
│  Margins                                │
│  [Narrow] [Normal] [Wide]               │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  Save as Profile              [Save]    │
│                                         │
└─────────────────────────────────────────┘
Height: ~450px (bottom sheet)
```

### Settings Components

**Font Selector:**
- 4 options in row
- Selected: Primary border
- Preview of font in each

**Size Slider:**
- Small "A" left, Large "A" right
- Range: 12-32px
- Current value displayed

**Line Spacing Slider:**
- Range: 1.0-2.5
- Current value displayed

**Theme Selector:**
- 3 theme swatches
- Circle with theme colors
- Label below
- Selected: Primary border

**Margin Selector:**
- Segmented button
- 3 options: Narrow, Normal, Wide

---

## Highlight & Annotation

### Text Selection

```
┌─────────────────────────────────────────┐
│                                         │
│     "Whenever you feel like             │
│  ████████████████████████████████       │  Selected text
│  ████████████████████████████████       │  (highlighted)
│  ████████████████████████████████"      │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ ● ● ● ●  │  Note  │  Copy  │ ✕ │    │  Selection toolbar
│  └─────────────────────────────────┘    │  (4 colors, note, copy)
│                                         │
└─────────────────────────────────────────┘
```

**Selection Toolbar:**
- Height: 48px
- Background: Surface Container
- Shadow: Level 2
- Colors: 4 highlight colors (Yellow, Green, Blue, Pink)
- Actions: Add note, Copy, Close

**Highlight Colors:**
| Color | Hex |
|-------|-----|
| Yellow | `#FFF59D` |
| Green | `#A5D6A7` |
| Blue | `#90CAF9` |
| Pink | `#F48FB1` |

### Add Note Dialog

```
┌─────────────────────────────────────────┐
│            ─────────────                │
│                                         │
│  Add Note                               │
│                                         │
│  "Whenever you feel like criticizing    │
│  anyone..."                             │  Quote preview
│                                         │
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │ Write your note here...             ││  Text area
│  │                                     ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │           Save Note                 ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

---

## Table of Contents Panel

```
┌─────────────────────────────────────────┐
│  [←]  Table of Contents                 │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  Chapter 1                     • 1  ││  Current chapter
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 2                      15  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 3                      28  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 4                      45  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 5                      62  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 6                      79  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 7                      98  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 8                     121  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  Chapter 9                     156  ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

**TOC Item:**
- Height: 56px
- Chapter name: Left
- Page number: Right
- Current chapter: Primary color dot, bold text

---

## Figma Generation Instructions

```
CREATE MOBILE READER SCREENS

Frame 1: Reader - Reading View (390 x 844)
- Full screen with reading content
- Top bar: Back, title, settings (Aa), menu - auto-hide
- Reading area: Georgia 18px, 24px margins
- Bottom bar: Chapter name, page indicator, progress bar
- Show in Light theme

Frame 2: Reader - UI Visible (390 x 844)
- Same as above but with UI bars visible
- Semi-transparent backgrounds

Frame 3: Reader - Dark Theme (390 x 844)
- Dark background (#1C1B1F)
- Light text (#E5E1E6)
- Adjusted UI colors

Frame 4: Reader - Sepia Theme (390 x 844)
- Cream background (#FDF6E3)
- Brown text (#5C4A32)

Frame 5: Settings Panel (390 x 450)
- Bottom sheet with handle
- Font selector row
- Size slider with preview
- Line spacing slider
- Theme selector (3 swatches)
- Margin selector

Frame 6: Text Selection (390 x 844)
- Reading view with selected text highlighted
- Selection toolbar below text

Frame 7: Add Note Dialog (390 x 350)
- Bottom sheet
- Quote preview
- Text area for note
- Save button

Frame 8: Table of Contents (390 x 844)
- Full screen drawer/sheet
- Chapter list with page numbers
- Current chapter highlighted

COMPONENTS:
- Auto-hide toolbar
- Reading text styles
- Progress bar (draggable)
- Selection toolbar
- Theme swatch
- Font preview card
- TOC item

INTERACTIONS:
- Tap zones for navigation
- Long press for selection
- Swipe for pages (optional)
- Drag progress bar
```
