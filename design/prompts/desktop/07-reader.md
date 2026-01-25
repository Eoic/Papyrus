# Book Reader - Desktop

Self-contained design prompt for the immersive book reading experience on desktop.

---

## Color Reference (Light/Sepia/Dark Themes)

**Light Theme:**
| Token | Value | Usage |
|-------|-------|-------|
| Background | `#FFFBFF` | Page |
| Text | `#1C1B1F` | Body text |
| Primary | `#5654A8` | Highlights |

**Sepia Theme:**
| Token | Value | Usage |
|-------|-------|-------|
| Background | `#FDF6E3` | Page |
| Text | `#5C4A32` | Body text |
| Primary | `#8B7355` | Highlights |

**Dark Theme:**
| Token | Value | Usage |
|-------|-------|-------|
| Background | `#1C1B1F` | Page |
| Text | `#E5E1E6` | Body text |
| Primary | `#C3C0FF` | Highlights |

---

## Main Reader View

### Purpose
Full-screen reading experience with optional side panels.

### Layout (1440 x 900 viewport)

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│  [←]  The Great Gatsby                                    [TOC] [🔖] [Aa] [⋮]   │
├───────────────────────────────────────────────────────────────────────────────────┤
│                                                                                   │
│                                                                                   │
│                                                                                   │
│                                                                                   │
│               In my younger and more vulnerable years my                          │
│            father gave me some advice that I've been turning                      │
│            over in my mind ever since.                                            │
│                                                                                   │
│               "Whenever you feel like criticizing anyone,"                        │
│            he told me, "just remember that all the people in                     │
│            this world haven't had the advantages that you've                     │
│            had."                                                                  │
│                                                                                   │
│               He didn't say any more, but we've always been                      │
│            unusually communicative in a reserved way, and I                      │
│            understood that he meant a great deal more than that.                 │
│            In consequence, I'm inclined to reserve all judgments,                │
│            a habit that has opened up many curious natures to me                 │
│            and also made me the victim of not a few veteran bores.               │
│                                                                                   │
│                                                                                   │
│                                                                                   │
│                                           12                                      │
├───────────────────────────────────────────────────────────────────────────────────┤
│  Chapter 1                    ━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░     12 of 180    │
└───────────────────────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Top Bar:**
- Height: 64px
- Always visible (or auto-hide option)
- Leading: Back button
- Center: Book title
- Trailing: TOC, Bookmarks, Settings (Aa), Menu
- Background: Surface

**Reading Area:**
- Centered column
- Max width: 720px (optimal reading width)
- Font: Georgia (default)
- Size: 20px
- Line height: 1.7
- Margins: Auto (centered)

**Page Navigation:**
- Click left edge: Previous page
- Click right edge: Next page
- Or use arrow keys
- Show page turn indicator on hover

**Bottom Bar:**
- Height: 48px
- Chapter name: Left
- Progress bar: Center (draggable)
- Page indicator: Right

---

## Reader with Side Panel

### TOC Panel Open

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│  [←]  The Great Gatsby                                    [TOC] [🔖] [Aa] [⋮]   │
├──────────────────────┬────────────────────────────────────────────────────────────┤
│                      │                                                            │
│  Table of Contents   │                                                            │
│                      │                                                            │
│  • Chapter 1      1  │        In my younger and more vulnerable                  │
│    Chapter 2     15  │     years my father gave me some advice                   │
│    Chapter 3     28  │     that I've been turning over in my                     │
│    Chapter 4     45  │     mind ever since.                                      │
│    Chapter 5     62  │                                                            │
│    Chapter 6     79  │        "Whenever you feel like criticizing                │
│    Chapter 7     98  │     anyone," he told me, "just remember                   │
│    Chapter 8    121  │     that all the people in this world                     │
│    Chapter 9    156  │     haven't had the advantages that                       │
│                      │     you've had."                                          │
│                      │                                                            │
│                      │                                                            │
│  Width: 280px        │                                                            │
├──────────────────────┴────────────────────────────────────────────────────────────┤
│  Chapter 1                    ━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░     12 of 180    │
└───────────────────────────────────────────────────────────────────────────────────┘
```

### Annotations Panel Open

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│  [←]  The Great Gatsby                                    [TOC] [🔖] [Aa] [⋮]   │
├────────────────────────────────────────────────────────────┬──────────────────────┤
│                                                            │                      │
│                                                            │  Annotations         │
│        In my younger and more vulnerable                  │                      │
│     years my father gave me some advice                   │  ┌────────────────┐  │
│     that I've been turning over in my                     │  │ ● "Whenever... │  │
│     mind ever since.                                      │  │ Page 12        │  │
│                                                            │  └────────────────┘  │
│        "Whenever you feel like criticizing                │                      │
│     anyone," he told me, "just remember                   │  ┌────────────────┐  │
│     that all the people in this world                     │  │ ● "In my..."   │  │
│     haven't had the advantages that                       │  │ Page 1         │  │
│     you've had."                                          │  └────────────────┘  │
│                                                            │                      │
│                                                            │  ┌────────────────┐  │
│                                                            │  │ + Add Note     │  │
│                                                            │  └────────────────┘  │
│                                                            │                      │
│                                                            │  Width: 320px        │
├────────────────────────────────────────────────────────────┴──────────────────────┤
│  Chapter 1                    ━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░     12 of 180    │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## Settings Panel

### Appears as right-side drawer or modal

```
┌─────────────────────────────────────┐
│  Reading Settings              [×]  │
├─────────────────────────────────────┤
│                                     │
│  Font Family                        │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ Aa │ │ Aa │ │ Aa │ │ Aa │       │
│  │Sys │ │Geo │ │Lit │ │O.D.│       │
│  └────┘ └────┘ └────┘ └────┘       │
│                                     │
│  Font Size                          │
│  A [━━━━━━━━●━━━━━] A    20px      │
│                                     │
│  Line Height                        │
│  [━━━━━━━━●━━━━━━━━]     1.7       │
│                                     │
│  Column Width                       │
│  [Narrow] [Normal] [Wide]           │
│                                     │
│  Theme                              │
│  ┌─────────┐ ┌─────────┐ ┌────────┐│
│  │ ○ Light │ │ ○ Sepia │ │ ○ Dark ││
│  └─────────┘ └─────────┘ └────────┘│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Reading Profiles                   │
│  ┌───────────────────────────────┐  │
│  │ Default Profile           [▼] │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Save Profile]                     │
│                                     │
└─────────────────────────────────────┘
Width: 360px
```

---

## Text Selection & Annotation

### Selection on Desktop

```
     "Whenever you feel like criticizing anyone," he told me,
  ████████████████████████████████████████████████████████████
  ████████████████████████████████████████████████████████████

     ┌────────────────────────────────────────────────────┐
     │ [●] [●] [●] [●]  │  📝 Note  │  📋 Copy  │  🔍 Search │
     └────────────────────────────────────────────────────┘
```

**Selection Toolbar:**
- Appears above or below selection
- 4 highlight colors
- Note, Copy, Search web actions
- Keyboard shortcut hints

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ← / → | Previous / Next page |
| Space | Next page |
| Home / End | Beginning / End |
| T | Toggle TOC |
| B | Toggle bookmarks |
| S | Open settings |
| F | Toggle fullscreen |
| Esc | Close panels / Exit |

---

## Figma Generation Instructions

```
CREATE DESKTOP READER SCREENS

Frame 1: Reader - Standard View (1440 x 900)
- Top bar: 64px, back, title, action icons
- Reading area: 720px centered, Georgia 20px
- Bottom bar: Chapter, progress, pages
- Light theme

Frame 2: Reader - TOC Panel (1440 x 900)
- Left panel: 280px TOC list
- Reading area: Adjusted width
- Current chapter highlighted in TOC

Frame 3: Reader - Annotations Panel (1440 x 900)
- Right panel: 320px annotations list
- Reading area: Adjusted width
- Annotation cards with color indicators

Frame 4: Reader - Settings Panel (1440 x 900)
- Right drawer: 360px settings
- Or centered modal

Frame 5: Reader - Dark Theme (1440 x 900)
- Full dark theme applied
- Adjusted UI colors

Frame 6: Reader - Text Selection (1440 x 900)
- Selected text highlighted
- Floating toolbar with actions

Frame 7: Reader - Fullscreen (1920 x 1080)
- No top/bottom bars
- Minimal UI on hover
- Centered reading column

COMPONENTS:
- Reading toolbar
- Side panel (TOC/Annotations)
- Settings drawer
- Selection toolbar
- Progress bar
- Page navigation zones

INTERACTIONS:
- Hover edges: Show page navigation
- Keyboard navigation
- Panel toggles
- Selection and highlighting
```
