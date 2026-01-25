# Mobile Platform Context

Platform-specific design guidelines for iOS and Android mobile devices.

---

## Screen Specifications

### Viewport Sizes

| Device Category | Width | Height | Scale |
|-----------------|-------|--------|-------|
| Small phone | 360px | 640px | 1x |
| Standard phone | 360px | 800px | 1x |
| Large phone | 428px | 926px | 1x |
| Design target | **390px** | **844px** | 1x |

**Safe Areas (iPhone 14 reference):**
- Top: 47px (status bar + notch)
- Bottom: 34px (home indicator)

**Android adjustments:**
- Top: 24px (status bar only)
- Bottom: 0px (gesture nav) or 48px (button nav)

### Grid System

- Columns: 4
- Margins: 16px left/right
- Gutter: 16px
- Content width: 358px (390 - 32)

---

## Navigation Structure

### Bottom Navigation Bar

```
┌─────────────────────────────────────────────────────────┐
│ Dashboard │ Library │  Goals  │  Stats  │ Profile      │
│    [□]    │   [□]   │   [□]   │   [□]   │   [□]        │
└─────────────────────────────────────────────────────────┘
Height: 80px (including 34px safe area)
```

**Specifications:**
- Always visible on main screens
- 5 items, equal width
- Active indicator: 64x32px pill, Primary Container
- Icon: 24px, centered above label
- Label: 12px, Label Medium weight

**Icons (Material Symbols Rounded):**
| Tab | Icon | Active |
|-----|------|--------|
| Dashboard | `dashboard` | `dashboard` (filled) |
| Library | `library_books` | `library_books` (filled) |
| Goals | `emoji_events` | `emoji_events` (filled) |
| Statistics | `stacked_line_chart` | `stacked_line_chart` (filled) |
| Profile | `person` | `person` (filled) |

### App Bar

```
┌─────────────────────────────────────────────────────────┐
│ [<] Page Title                              [?] [+]    │
└─────────────────────────────────────────────────────────┘
Height: 64px
```

**Specifications:**
- Height: 64px
- Leading: Back arrow (24px) or menu hamburger
- Title: Title Large (22px), left-aligned or centered
- Actions: Max 2 icons, 24px each
- Background: Surface
- Elevation: 0 (scrolled: Level 1)

### Navigation Drawer (Library Section)

```
┌────────────────────────────────┐
│ ┌────────────────────────────┐ │
│ │        Library             │ │  Header
│ └────────────────────────────┘ │
├────────────────────────────────┤
│ [□] All Books                  │ ← Selected
│ [□] Shelves                    │
│ [□] Topics                     │
│ [□] Bookmarks                  │
│ [□] Annotations                │
│ [□] Notes                      │
└────────────────────────────────┘
Width: 280px
```

---

## Touch Interactions

### Touch Targets

| Element | Minimum Size | Recommended |
|---------|--------------|-------------|
| Buttons | 44x44px | 48x48px |
| Icons | 44x44px | 48x48px |
| List items | 44px height | 56-72px |
| Spacing between targets | 8px | 8px |

### Gestures

| Gesture | Action |
|---------|--------|
| Tap | Primary action |
| Long press | Context menu |
| Swipe right | Go back (iOS) |
| Swipe left on item | Quick actions |
| Pull down | Refresh |
| Pinch | Zoom (reader) |

### Haptic Feedback

- Light: Selection changes
- Medium: Successful actions
- Heavy: Destructive actions (before confirmation)

---

## Layout Patterns

### Full-Screen Page

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │ ← Safe area
├─────────────────────────────────────────┤
│              App Bar (64px)             │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│           Scrollable Content            │
│              (Flexible)                 │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│         Bottom Nav Bar (80px)           │ ← Includes safe area
└─────────────────────────────────────────┘
Total: 844px (iPhone 14)
Content: 653px scrollable
```

### Modal Bottom Sheet

```
┌─────────────────────────────────────────┐
│                                         │
│          (Dimmed background)            │
│                                         │
├─────────────────────────────────────────┤
│              ────────                   │ ← Handle (32x4px)
│                                         │
│           Sheet Content                 │ ← Max 90% height
│                                         │
│                                         │
└─────────────────────────────────────────┘
Border radius: 16px (top corners only)
```

### Grid Layout (Books)

```
┌─────┬─────┬─────┐
│     │     │     │
│Book │Book │Book │  2-3 columns
│     │     │     │  depending on width
├─────┼─────┼─────┤
│     │     │     │
│Book │Book │Book │
│     │     │     │
└─────┴─────┴─────┘
```

- 360px width: 2 columns (162px each + 16px gap + 16px margins)
- 428px width: 3 columns (120px each + 16px gaps + 16px margins)
- Item spacing: 16px

---

## Typography Scaling

Mobile uses slightly smaller type for compact screens:

| Style | Desktop | Mobile |
|-------|---------|--------|
| Headline Large | 32px | 28px |
| Headline Medium | 28px | 24px |
| Title Large | 22px | 20px |
| Body Large | 16px | 16px |
| Body Medium | 14px | 14px |

---

## Common Mobile Components

### FAB (Floating Action Button)

```
                        ┌───────┐
                        │  [+]  │  56x56px
                        └───────┘
Position: bottom-right
Margin: 16px from edges, 16px above bottom nav
```

### Pull-to-Refresh

```
       ↓ Pull to refresh
    ┌─────────────────┐
    │   (○) Loading   │  Height: 64px
    └─────────────────┘
```

### Swipe Actions

```
┌─────────────────────────────────────────┐
│ ← Swipe                                 │
├─────────────────────────────────────────┤
│ [Edit]  Item Content            [Delete]│
└─────────────────────────────────────────┘
```

- Left action (reveal right): Primary actions (edit, share)
- Right action (reveal left): Destructive actions (delete, archive)
- Action button width: 80px each

---

## Color Theme Application

### Light Theme (Default)

```
Status bar: Light content on Surface
App bar: Surface background
Content: Surface background
Bottom nav: Surface background
FAB: Primary background
```

### Dark Theme

```
Status bar: Light content on Surface
App bar: Surface background (#1C1B1F)
Content: Surface background
Bottom nav: Surface background
FAB: Primary background (#C3C0FF)
```

---

## Platform-Specific Notes

### iOS

- Use SF Pro font (system default)
- Support Dynamic Type
- Swipe-from-edge for back navigation
- Status bar: 47px with notch
- Home indicator: 34px

### Android

- Use Roboto font (system default)
- Support system back button/gesture
- Material You dynamic colors (optional)
- Status bar: 24px
- Navigation bar: 48px (buttons) or gesture area

---

## Figma Frame Setup

For mobile designs, use these frame settings:

```
Frame: iPhone 14 Pro
Width: 393px
Height: 852px
Background: Surface color

Or standard:
Width: 390px
Height: 844px
```

Export at 1x, 2x, and 3x for assets.
