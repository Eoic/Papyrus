# Dashboard - Mobile

Self-contained design prompt for the Dashboard/Home screen on mobile.

---

## Color Reference (Light Theme)

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#5654A8` | Accents, progress |
| Surface | `#FFFBFF` | Background |
| On Surface | `#1C1B1F` | Primary text |
| On Surface Variant | `#47464F` | Secondary text |
| Primary Container | `#E2DFFF` | Card accents |
| Surface Container | `#E4E1EC` | Cards |
| Tertiary | `#7A5368` | Goals |

---

## Dashboard Page

### Purpose
Main landing page after login showing reading activity, current books, and quick actions.

### Layout (390 x 844 viewport)

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  Dashboard                 [🔔] [user]  │  App Bar: 64px
├─────────────────────────────────────────┤
│                                         │
│  Good morning, User!                    │  Greeting: 24px
│  You've read 45 minutes today           │  Subtext: 14px
│                                         │
├─────────────────────────────────────────┤
│  Continue Reading                       │  Section
│  ┌─────────────────────────────────────┐│
│  │ ┌───────┐                           ││
│  │ │ Cover │  The Great Gatsby         ││  Currently reading
│  │ │ 80x120│  F. Scott Fitzgerald      ││  card
│  │ │       │  ████████░░░░░  75%       ││
│  │ └───────┘                    [▶]    ││
│  └─────────────────────────────────────┘│
│                                         │
├─────────────────────────────────────────┤
│  Reading Goal                           │
│  ┌─────────────────────────────────────┐│
│  │  📚 12 books this year              ││
│  │                                     ││
│  │  ████████████████░░░░░  8/12 books  ││  Goal progress
│  │                                     ││
│  │  4 books to go • 67% complete       ││
│  └─────────────────────────────────────┘│
│                                         │
├─────────────────────────────────────────┤
│  This Week                              │
│  ┌───────┬───────┬───────┬───────┬────┐│
│  │  M   │  T   │  W   │  T   │ F  ││  Activity
│  │ ░░░  │ ███  │ ██░  │ ░░░  │    ││  heatmap
│  │ 15m  │ 45m  │ 30m  │  0m  │ -- ││
│  └───────┴───────┴───────┴───────┴────┘│
│                                         │
├─────────────────────────────────────────┤
│  Recently Added                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ [Cover] │ │ [Cover] │ │ [Cover] │   │  Horizontal
│  │  80x120 │ │  80x120 │ │  80x120 │   │  scroll
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
├─────────────────────────────────────────┤
│ [■] [□] [□] [□] [□]                     │  Bottom Nav
│ Dash Lib Goals Stats Prof               │
└─────────────────────────────────────────┘
```

### Component Specifications

**App Bar:**
- Height: 64px
- Title: "Dashboard", Title Large (22px)
- Trailing icons: Notification bell, user avatar (32px)
- Avatar: Circular, 32px

**Greeting Section:**
- Greeting: "Good morning/afternoon/evening, [Name]!"
- Style: Headline Medium (28px)
- Subtext: "You've read X minutes today"
- Style: Body Medium, On Surface Variant
- Padding: 16px horizontal, 24px vertical

**Continue Reading Card:**
```
┌───────────────────────────────────────────────────┐
│ ┌───────┐                                         │
│ │       │  Book Title                             │
│ │ Cover │  Author Name                            │
│ │ 80x120│  ████████░░░░░ 75%                     │
│ │       │                                   [▶]  │
│ └───────┘                                         │
└───────────────────────────────────────────────────┘
```
- Background: Surface Container
- Border radius: 16px
- Padding: 16px
- Cover: 80 x 120px
- Play button: 48x48px, Primary background, centered play icon
- Progress: 4px bar below title/author

**Reading Goal Card:**
```
┌─────────────────────────────────────────┐
│  📚 12 books this year                  │
│                                         │
│  ████████████████░░░░░░  8/12 books    │
│                                         │
│  4 books to go • 67% complete           │
└─────────────────────────────────────────┘
```
- Background: Primary Container (light)
- Border radius: 16px
- Padding: 16px
- Icon: 24px book emoji/icon
- Goal text: Title Medium
- Progress bar: 8px height, Primary color
- Status: Body Small, On Surface Variant

**Weekly Activity:**
```
┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐
│  Mon  │  Tue  │  Wed  │  Thu  │  Fri  │  Sat  │  Sun  │
│  ░░░  │  ███  │  ██░  │  ░░░  │  ░░░  │  ██░  │  ░░░  │
│  15m  │  45m  │  30m  │   0m  │   0m  │  25m  │   0m  │
└───────┴───────┴───────┴───────┴───────┴───────┴───────┘
```
- 7 columns, equal width
- Day label: Label Small, centered
- Bar: Height varies by reading time (max 40px)
- Time label: Label Small, centered
- Today highlighted with Primary color
- Background: Surface Container, 12px radius

**Recently Added (Horizontal Scroll):**
- Title: "Recently Added" + "See all" link
- Cards: 80x120px covers in horizontal scroll
- Gap: 12px
- Padding: 16px horizontal
- Max 5 visible, scroll for more

### Section Header Pattern

```
Recently Added                    See all →
```
- Title: Title Small (14px), bold
- Link: Body Small, Primary color
- Flex row, space-between

### States to Design

1. **First Time User (Empty):**
   - No continue reading section
   - Goal card: "Set your first reading goal" CTA
   - Recently added: "Add your first book" CTA

2. **Active Reader:**
   - All sections populated
   - Continue reading shows most recent

3. **Goal Completed:**
   - Goal card shows celebration state
   - Confetti animation (optional)

4. **No Reading Today:**
   - Activity shows 0m for today
   - Motivational message

---

## Figma Generation Instructions

```
CREATE MOBILE DASHBOARD SCREEN

Frame 1: Dashboard - Active User (390 x 844)
- Status bar: 47px
- App bar: 64px, "Dashboard", notification + avatar icons
- Greeting: "Good morning, User!", subtext below
- Continue Reading card: Cover + title + progress + play button
- Reading Goal card: Primary Container bg, icon + text + progress bar
- Weekly Activity: 7-day bar chart with time labels
- Recently Added: Horizontal scroll of book covers
- Bottom nav: Dashboard active

Frame 2: Dashboard - New User (390 x 844)
- Same layout but with empty states:
- No Continue Reading section
- Goal card: "Set your first reading goal" button
- Recently Added: "Add your first book" placeholder

Frame 3: Dashboard - Goal Completed (390 x 844)
- Goal card shows completed state with checkmark
- "You did it! 12 books read" message

COMPONENTS:
- Continue Reading card
- Goal Progress card
- Activity Bar chart
- Recent Books carousel
- Section header with "See all" link

STATES:
- Activity bars: Today (Primary), past (Surface Container)
- Goal: In progress, completed
- Card: Default, pressed
```
