# Book Reader - E-ink

Self-contained design prompt for the immersive book reading experience on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Text |
| White | `#FFFFFF` | Background |
| Dark Gray | `#404040` | Secondary UI |
| Light Gray | `#C0C0C0` | Progress track |

**E-ink Reader Rules:**
- NO animations during reading
- Full page refresh on page turns
- Minimal UI chrome
- Large touch targets for page navigation
- Hardware button support

---

## Main Reader View

### Purpose
Clean, distraction-free reading optimized for e-ink displays.

### Layout (1072 x 1448 viewport)

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  Chapter 1                                    12 / 180  [≡] │  Header: 56px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│                                                                   │
│                                                                   │
│        In my younger and more vulnerable years my                 │
│     father gave me some advice that I've been                    │
│     turning over in my mind ever since.                          │
│                                                                   │
│        "Whenever you feel like criticizing                       │
│     anyone," he told me, "just remember that all                 │
│     the people in this world haven't had the                     │
│     advantages that you've had."                                 │
│                                                                   │
│        He didn't say any more, but we've always                  │
│     been unusually communicative in a reserved                   │
│     way, and I understood that he meant a great                  │
│     deal more than that. In consequence, I'm                     │
│     inclined to reserve all judgments, a habit                   │
│     that has opened up many curious natures to                   │
│     me and also made me the victim of not a few                  │
│     veteran bores.                                                │
│                                                                   │
│                                                                   │
│                                                                   │
│                                                                   │
│  [TAP LEFT                                       TAP RIGHT]       │  Tap zones
│  [PREVIOUS]                                      [NEXT PAGE]      │  (invisible)
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  ████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  7%   │  Progress: 24px
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Header (Minimal):**
- Height: 56px
- Border bottom: 2px solid Black
- Leading: Back button (56x56px touch)
- Center: Chapter name
- Right: Page indicator (current / total)
- Far right: Menu icon

**Reading Area:**
- Full screen minus header and progress
- Font: Literata or Bookerly (e-ink optimized)
- Size: 20px (adjustable 16-28px)
- Line height: 1.8 (generous for e-ink)
- Margins: 48px horizontal (larger for comfort)
- Paragraph indent: 24px
- No hyphenation (cleaner rendering)

**Tap Zones:**
- Left 40%: Previous page
- Right 40%: Next page
- Center 20%: Show menu (optional)
- Invisible zones, no visual indicator

**Hardware Button Mapping:**
- Page forward button: Next page
- Page back button: Previous page
- Center/OK button: Open menu

**Progress Bar:**
- Height: 24px (larger for visibility)
- Track: Light Gray
- Fill: Black
- Segmented style (20 segments)
- Percentage text: Right side
- Border: 2px solid Black

---

## Reader Menu (Full Screen Overlay)

```
┌───────────────────────────────────────────────────────────────────┐
│  [×]  MENU                                                        │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  TABLE OF CONTENTS                                      [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  BOOKMARKS                                              [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ANNOTATIONS                                            [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  READING SETTINGS                                       [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  GO TO PAGE...                                          [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ADD BOOKMARK                                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  EXIT READER                                                │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

**Menu Item:**
- Height: 72px (larger touch target)
- Text: 18px, uppercase
- Chevron for navigation items
- 2px dividers between items

---

## Reading Settings Screen

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  READING SETTINGS                                            │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  FONT                                                             │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ○ LITERATA                                                 │  │
│  │  ● BOOKERLY                                                 │  │
│  │  ○ GEORGIA                                                  │  │
│  │  ○ OPEN DYSLEXIC                                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  FONT SIZE                                                        │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  │  [ - ]     ████████████████     20px     [ + ]             │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  LINE SPACING                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  │  [ - ]     ████████████████     1.8      [ + ]             │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  MARGINS                                                          │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  [NARROW]     [NORMAL]     [WIDE]                          │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  REFRESH MODE                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ○ FULL (every page)                                        │  │
│  │  ● PARTIAL (every 5 pages)                                  │  │
│  │  ○ FAST (more ghosting)                                     │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Settings Components

**Font Radio Group:**
- Full-width radio buttons
- 56px row height
- 24px radio circles
- Selected: Filled dot

**Size/Spacing Stepper:**
- Decrease button: 64x64px, "−"
- Progress bar: Visual indicator
- Value: Current setting
- Increase button: 64x64px, "+"
- All in bordered container

**Margin Selector:**
- Segmented buttons
- 3 options
- Selected: Inverted (black bg, white text)

**Refresh Mode:**
- E-ink specific setting
- Full: Best quality, slower
- Partial: Balanced
- Fast: More ghosting, faster

---

## Table of Contents

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  TABLE OF CONTENTS                                           │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ● CHAPTER 1                                             1  │  │  Current
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │    CHAPTER 2                                            15  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │    CHAPTER 3                                            28  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │    CHAPTER 4                                            45  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ...                                                              │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

**TOC Item:**
- Height: 64px
- Current chapter: ● marker, bold
- Chapter name: 18px
- Page number: Right-aligned
- Dividers between items

---

## Go To Page

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  GO TO PAGE                                                  │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Current: Page 12 of 180                                          │
│                                                                   │
│  ENTER PAGE NUMBER                                                │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  12                                                         │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                        GO TO PAGE                           │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  OR SELECT LOCATION                                               │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  BEGINNING                                                  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  25%                                                     45 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  50%                                                     90 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  75%                                                    135 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  END                                                    180 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Figma Generation Instructions

```
CREATE E-INK READER SCREENS

GLOBAL RULES:
- Background: #FFFFFF
- Text: #000000
- No shadows or gradients
- Large touch targets (64px minimum)
- Clear, high-contrast UI

Frame 1: Reader - Reading View (1072 x 1448)
- Minimal header: 56px, back, chapter, pages, menu
- Reading area: Literata 20px, 48px margins
- Large tap zones for navigation (invisible)
- Progress bar: 24px, segmented style

Frame 2: Reader Menu (1072 x 1448)
- Full screen overlay
- Menu items: 72px height, uppercase
- Options: TOC, Bookmarks, Annotations, Settings, Go To, Add Bookmark, Exit

Frame 3: Reading Settings (1072 x 1448)
- Header: Back button, title
- Font: Radio group
- Size: Stepper control (−/+)
- Line spacing: Stepper control
- Margins: Segmented selector
- Refresh mode: Radio group

Frame 4: Table of Contents (1072 x 1448)
- Header: Back button, title
- Chapter list with page numbers
- Current chapter marked with ●

Frame 5: Go To Page (1072 x 1448)
- Header: Back button, title
- Page number input
- Quick jump buttons (25%, 50%, 75%, Beginning, End)

INTERACTIONS:
- Tap left: Previous page
- Tap right: Next page
- Tap center or menu button: Show menu
- Hardware buttons: Page navigation
- Full page refresh on page turns
```
