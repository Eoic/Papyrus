# Progress Screens - E-ink

Self-contained design prompt for Goals and Statistics screens on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Text, borders, filled elements |
| White | `#FFFFFF` | Background |
| Dark Gray | `#404040` | Secondary text |
| Light Gray | `#C0C0C0` | Empty progress, dividers |
| Container | `#F5F5F5` | Cards |

---

## Screen 1: Goals Page

### Layout (1072 x 1448 viewport)

```
┌───────────────────────────────────────────────────────────────────┐
│  GOALS                                                      [+]   │  Header: 72px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ACTIVE GOALS                                                     │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  12 BOOKS THIS YEAR                                         │  │
│  │                                                             │  │
│  │  Progress: 8 of 12 books (67%)                              │  │
│  │  ████████████████████████░░░░░░░░░░░░                      │  │
│  │                                                             │  │
│  │  4 books remaining • On track                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  30 MINUTES DAILY                                           │  │
│  │                                                             │  │
│  │  Today: 45 minutes (COMPLETED)                              │  │
│  │  ████████████████████████████████████░░░░░░░░░░░░  150%    │  │
│  │                                                             │  │
│  │  Current streak: 5 days                                     │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  50 PAGES PER WEEK                                          │  │
│  │                                                             │  │
│  │  This week: 35 of 50 pages (70%)                            │  │
│  │  ██████████████████████░░░░░░░░░░░░░░░░                    │  │
│  │                                                             │  │
│  │  15 pages remaining                                         │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  COMPLETED GOALS                                                  │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  [X] 6 books - Q1 2024                                      │  │
│  │  [X] 100 hours reading - 2023                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  DASHBOARD  │  LIBRARY  │  GOALS  │  SETTINGS                    │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Goal Card:**
```
┌─────────────────────────────────────────────────────────────────┐
│  GOAL TITLE                                                     │
│  Progress: X of Y (Z%)                                          │
│  ████████████████████████░░░░░░░░░░░░                          │
│  Status message                                                 │
└─────────────────────────────────────────────────────────────────┘
```
- Border: 2px solid Black
- Padding: 16px
- Title: 18px, bold, uppercase
- Progress text: 16px
- Progress bar: 16px height, segmented
- Status: 16px
- No circular progress (too complex for e-ink)

**Segmented Progress Bar:**
```
████████████████████████░░░░░░░░░░░░  67%
```
- Height: 16px
- Filled: Black
- Empty: Light Gray with 1px border
- 20 segments for visibility
- Percentage label right of bar

**Completed Goals List:**
- Simple list format
- Checkmark prefix: [X]
- Goal description + time period

**Add Goal Button:**
- Header: + icon
- Touch target: 56px

### Add Goal Screen (Full-screen)

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  NEW GOAL                                                    │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  GOAL TYPE                                                        │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ○ BOOKS TO READ                                            │  │
│  │  ○ READING TIME                                             │  │
│  │  ○ PAGES TO READ                                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  TARGET AMOUNT                                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  12                                                         │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  TIME PERIOD                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ○ DAILY                                                    │  │
│  │  ● YEARLY                                                   │  │
│  │  ○ WEEKLY                                                   │  │
│  │  ○ MONTHLY                                                  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                      CREATE GOAL                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Screen 2: Statistics Page

### Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  STATISTICS                              [WEEK] [MONTH] [YEAR]    │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  SUMMARY                                                          │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Total books:           135                                 │  │
│  │  Goals completed:        12                                 │  │
│  │  Total reading time:    45 hours                            │  │
│  │  Pages read:          4,230                                 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  READING TIME THIS WEEK                                           │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  │  Mon  ████████████████  45 min                              │  │
│  │  Tue  ████████████████████████████  90 min                  │  │
│  │  Wed  ████████████████████  60 min                          │  │
│  │  Thu  ░░░░░░░░░░░░░░░░  0 min                               │  │
│  │  Fri  ░░░░░░░░░░░░░░░░  0 min                               │  │
│  │  Sat  ████████████  35 min                                  │  │
│  │  Sun  ░░░░░░░░░░░░░░░░  0 min                               │  │
│  │                                                             │  │
│  │  Total: 3h 50min   Average: 33 min/day                      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  BOOKS BY GENRE                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Fiction        ████████████████████████████████████  45%   │  │
│  │  Non-fiction    ████████████████████████  30%               │  │
│  │  History        ████████████  15%                           │  │
│  │  Other          ████████  10%                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  READING STREAK                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Current streak:    5 days                                  │  │
│  │  Best streak:      21 days                                  │  │
│  │  Days this month:  18 of 26                                 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  DASHBOARD  │  LIBRARY  │  GOALS  │  SETTINGS                    │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Time Period Toggle:**
- Segmented buttons in header
- Selected: Inverted (black bg, white text)
- Unselected: White bg, black text, border

**Summary Card:**
- Simple label-value pairs
- Label: Left-aligned
- Value: Right-aligned, bold
- 2px border

**Horizontal Bar Chart (Reading Time):**
```
Mon  ████████████████  45 min
Tue  ████████████████████████████  90 min
```
- Text-based horizontal bars
- Day label: 16px, left
- Bar: Block characters, proportional width
- Time label: 16px, right of bar

**Genre Distribution (Horizontal Bars):**
```
Fiction      ████████████████████████████████████  45%
Non-fiction  ████████████████████████  30%
```
- Horizontal percentage bars
- No pie charts (poor on e-ink)
- Label + bar + percentage

**Streak Stats:**
- Simple label-value format
- Current, Best, This month

---

## Figma Generation Instructions

```
CREATE E-INK PROGRESS SCREENS

GLOBAL RULES:
- Background: #FFFFFF
- Borders: 2px solid #000000
- No shadows or gradients
- Border radius: 0px
- Progress bars: Segmented style

Frame 1: Goals Page (1072 x 1448)
- Header: "GOALS" title, add icon
- Active Goals section:
  - Goal cards with title, text progress, segmented bar, status
  - Dividers between cards
- Completed Goals: Simple list with checkmarks
- Bottom nav: GOALS active

Frame 2: Add Goal (1072 x 1448)
- Header: Back button, "NEW GOAL" title
- Radio groups: Goal Type, Time Period
- Number input: Target Amount
- Create Goal button

Frame 3: Statistics Page (1072 x 1448)
- Header: "STATISTICS" title, period toggles
- Summary: Label-value pairs in card
- Reading Time: Horizontal bar chart (text-based)
- Genre: Horizontal percentage bars
- Streak: Label-value pairs
- Bottom nav: (no Stats nav item - use SETTINGS or combine)

CHARTS (E-ink optimized):
- Use text-based horizontal bars only
- No circular or pie charts
- Segmented progress bars
- Clear labels with values

STATES:
- Toggle selected: Inverted colors
- Radio selected: Filled circle
- Progress bar filled: Black segments
- Progress bar empty: Light gray with border
```
