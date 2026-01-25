# Dashboard - E-ink

Self-contained design prompt for the Dashboard/Home screen on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Text, borders |
| White | `#FFFFFF` | Background |
| Dark Gray | `#404040` | Secondary text |
| Light Gray | `#C0C0C0` | Dividers |
| Container | `#F5F5F5` | Cards |

---

## Dashboard Page

### Purpose
Simplified dashboard showing essential reading information optimized for e-ink.

### Layout (1072 x 1448 viewport)

```
┌───────────────────────────────────────────────────────────────────┐
│  DASHBOARD                                                        │  Header: 72px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Good morning, User!                                              │  Greeting: 28px
│  Read 45 minutes today                                            │  Status: 18px
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  CONTINUE READING                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ┌───────────┐                                              │  │
│  │  │           │  THE GREAT GATSBY                            │  │  Card: 120px
│  │  │  [Cover]  │  F. Scott Fitzgerald                         │  │
│  │  │  80x120   │  ██████████████████░░░░░░  75%               │  │
│  │  └───────────┘                                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     CONTINUE READING                        │  │  Button: 64px
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  READING GOAL                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  │  12 books this year                                         │  │
│  │                                                             │  │
│  │  ██████████████████████░░░░░░░░░░  8 of 12 books           │  │
│  │                                                             │  │
│  │  4 books remaining • 67% complete                           │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  THIS WEEK                                                        │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Mon    Tue    Wed    Thu    Fri    Sat    Sun              │  │
│  │                                                             │  │
│  │  ░░░    ███    ██░    ░░░    ░░░    ██░    ░░░              │  │  Activity
│  │                                                             │  │
│  │  15m    45m    30m     0m     0m    25m     0m              │  │
│  │                                                             │  │
│  │  Total: 1h 55m                                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  QUICK STATS                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Books in library:     135                                  │  │
│  │  Shelves:               12                                  │  │
│  │  Total reading time:   45h                                  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  DASHBOARD  │  LIBRARY  │  GOALS  │  SETTINGS                    │  Nav: 72px
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Header:**
- Height: 72px
- Title: "DASHBOARD", 24px, bold
- Border bottom: 2px solid Black

**Greeting Section:**
- Name: 28px, bold
- Status: 18px
- Padding: 24px

**Continue Reading Section:**

Card:
```
┌─────────────────────────────────────────────────────────────────┐
│  ┌───────────┐                                                  │
│  │           │  BOOK TITLE                                      │
│  │  [Cover]  │  Author Name                                     │
│  │  80x120   │  ████████████████████░░░░░░  75%                │
│  └───────────┘                                                  │
└─────────────────────────────────────────────────────────────────┘
```
- Border: 2px solid Black
- Padding: 16px
- Cover: 80 x 120px, 2px border
- Title: 20px, bold, uppercase
- Author: 16px
- Progress: 12px segmented bar

Button:
- Full width - margins
- Height: 64px
- Black background, white text
- "CONTINUE READING"

**Reading Goal Section:**
```
┌─────────────────────────────────────────────────────────────────┐
│  12 books this year                                             │
│  ██████████████████████░░░░░░░░░░  8 of 12 books               │
│  4 books remaining • 67% complete                               │
└─────────────────────────────────────────────────────────────────┘
```
- Border: 2px solid Black
- Goal text: 18px, bold
- Progress: 16px segmented bar (12 segments for 12 books)
- Status: 16px

**Weekly Activity:**
```
┌─────────────────────────────────────────────────────────────────┐
│  Mon    Tue    Wed    Thu    Fri    Sat    Sun                  │
│  ░░░    ███    ██░    ░░░    ░░░    ██░    ░░░                  │
│  15m    45m    30m     0m     0m    25m     0m                  │
│  Total: 1h 55m                                                  │
└─────────────────────────────────────────────────────────────────┘
```
- Border: 2px solid Black
- Day labels: 14px
- Bars: ASCII-style using block characters
- Full bar (███): Black fill
- Partial (██░): Mixed
- Empty (░░░): Light gray
- Time labels: 14px
- Total: 16px, bold

**Quick Stats:**
```
Books in library:     135
Shelves:               12
Total reading time:   45h
```
- Simple label-value pairs
- Label: 16px, left-aligned
- Value: 16px, bold, right-aligned
- Row height: 40px

**Bottom Navigation:**
- Height: 72px
- Border top: 2px solid Black
- 4 items: DASHBOARD, LIBRARY, GOALS, SETTINGS
- Active: Black background, white text

---

## Empty States

**No Current Book:**
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│               You're not reading anything                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    GO TO LIBRARY                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**No Goal Set:**
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    No reading goal set                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    SET A GOAL                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Figma Generation Instructions

```
CREATE E-INK DASHBOARD SCREEN

GLOBAL RULES:
- Background: #FFFFFF
- All text/borders: #000000
- Borders: 2px solid
- Border radius: 0px
- Touch targets: 56px minimum

Frame 1: Dashboard - Active (1072 x 1448)
- Header: 72px, "DASHBOARD" title, 2px bottom border
- Greeting: Name (28px bold), reading time (18px)
- Continue Reading: Card with cover, title, progress bar
- Continue button: 64px, black fill
- Reading Goal: Goal text + segmented progress bar + status
- Weekly Activity: 7-day text-based bar chart
- Quick Stats: Label-value pairs
- Bottom nav: 4 items, Dashboard active (inverted)

Frame 2: Dashboard - Empty (1072 x 1448)
- Same header and greeting
- "No current book" placeholder with "GO TO LIBRARY" button
- "No goal set" placeholder with "SET A GOAL" button
- Empty activity chart
- Quick stats with zeros

COMPONENTS:
- Continue Reading card
- Reading Goal card
- Activity chart (text-based)
- Stats list
- Empty state cards

STATES:
- Button pressed: Inverted colors
- Nav item active: Inverted colors
```
