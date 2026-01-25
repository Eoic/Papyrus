# Desktop Platform Context

Platform-specific design guidelines for Windows, macOS, and Linux desktop applications.

---

## Screen Specifications

### Viewport Sizes

| Category | Width | Height | Use Case |
|----------|-------|--------|----------|
| Minimum | 1024px | 768px | Small laptops |
| Standard | 1280px | 800px | Common laptops |
| Large | 1440px | 900px | Desktop monitors |
| Design target | **1440px** | **900px** | Primary design size |
| Wide | 1920px | 1080px | Full HD monitors |

### Grid System

| Breakpoint | Columns | Margins | Gutter |
|------------|---------|---------|--------|
| 840-1199px | 12 | 24px | 24px |
| 1200px+ | 12 | 32px | 24px |

**Sidebar considerations:**
- Sidebar width: 280px (collapsed: 72px)
- Content area: Viewport - Sidebar - Margins

---

## Navigation Structure

### Permanent Sidebar

```
┌──────────────────────────────────────────────────────────────────┐
│ ┌──────────┐                                                     │
│ │          │                                                     │
│ │  [Logo]  │                                                     │
│ │ Papyrus  │               Main Content Area                    │
│ │          │                                                     │
│ ├──────────┤                                                     │
│ │ □ Dash   │                                                     │
│ │ □ Library│                                                     │
│ │ □ Goals  │                                                     │
│ │ □ Stats  │                                                     │
│ ├──────────┤                                                     │
│ │          │                                                     │
│ │ (spacer) │                                                     │
│ │          │                                                     │
│ ├──────────┤                                                     │
│ │ □ Profile│                                                     │
│ │ □ Settings│                                                    │
│ └──────────┘                                                     │
└──────────────────────────────────────────────────────────────────┘
```

**Sidebar Specifications:**
- Width: 280px (expanded), 72px (collapsed)
- Background: Surface
- Border: 1px Outline Variant on right edge
- Logo section height: 80px
- Nav item height: 48px
- Padding: 16px

**Nav Item:**
```
┌────────────────────────────────┐
│ [icon]  Label                  │  Height: 48px
└────────────────────────────────┘  Padding: 12px 16px
```

**Selected state:**
- Background: Primary Container
- Icon + Text: On Primary Container
- Left indicator: 4px wide, Primary, 24px height

### Top App Bar (Content Area)

```
┌─────────────────────────────────────────────────────────────────┐
│ Page Title              [Search...]           [?] [bell] [user]│
└─────────────────────────────────────────────────────────────────┘
Height: 64px
```

**Specifications:**
- Height: 64px
- Title: Headline Medium (28px), left-aligned
- Search: Optional, 320px width
- Actions: Right-aligned, 24px icons, 8px spacing
- Background: Surface
- Border: 1px Outline Variant on bottom

---

## Mouse & Keyboard Interactions

### Click Targets

| Element | Minimum Size | Recommended |
|---------|--------------|-------------|
| Buttons | 36x36px | 40x40px |
| Icons | 32x32px | 40x40px |
| List items | 36px height | 48px |
| Spacing between targets | 4px | 8px |

### Hover States

All interactive elements must have visible hover states:
- Buttons: Background color shift
- Cards: Elevation increase (Level 1 → Level 2)
- List items: Background tint
- Links: Underline or color change

### Keyboard Navigation

| Key | Action |
|-----|--------|
| Tab | Move focus forward |
| Shift+Tab | Move focus backward |
| Enter/Space | Activate focused element |
| Escape | Close modal/dropdown |
| Arrow keys | Navigate within lists/grids |

**Focus Indicators:**
- 2px outline in Primary color
- 2px offset from element
- Visible on all focusable elements

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl/Cmd + N | Add new book |
| Ctrl/Cmd + F | Open search |
| Ctrl/Cmd + , | Open settings |
| Ctrl/Cmd + 1-5 | Switch nav tabs |
| Escape | Close modal/go back |

---

## Layout Patterns

### Two-Panel Layout (Master-Detail)

```
┌───────────┬────────────────────────────────────────────┐
│           │                                            │
│  Sidebar  │              Content Area                  │
│   280px   │              (flexible)                    │
│           │                                            │
└───────────┴────────────────────────────────────────────┘
```

### Three-Panel Layout (Library with Detail)

```
┌───────────┬─────────────────────┬──────────────────────┐
│           │                     │                      │
│  Sidebar  │     Book Grid       │    Book Details      │
│   280px   │       400px+        │       360px          │
│           │                     │                      │
└───────────┴─────────────────────┴──────────────────────┘
```

### Grid Layout (Books)

At 1440px with 280px sidebar:
- Content width: 1160px - 64px margins = 1096px
- 4-5 columns recommended
- Book card: 200x300px (cover) + 48px (text area)

```
┌───────┬───────┬───────┬───────┬───────┐
│       │       │       │       │       │
│ Book  │ Book  │ Book  │ Book  │ Book  │
│       │       │       │       │       │
├───────┼───────┼───────┼───────┼───────┤
│       │       │       │       │       │
│ Book  │ Book  │ Book  │ Book  │ Book  │
│       │       │       │       │       │
└───────┴───────┴───────┴───────┴───────┘
Gap: 24px
Card width: ~200px
```

---

## Window Behavior

### Resizing

- Minimum window size: 1024x768px
- Sidebar: Fixed 280px (can collapse to 72px)
- Content: Responsive, uses available space
- Breakpoints trigger layout changes

### Collapsed Sidebar

At narrow widths (< 1200px), sidebar can collapse:

```
┌────┬────────────────────────────────────────────────────┐
│[□] │                                                    │
│[□] │                                                    │
│[□] │            Content Area (expanded)                 │
│[□] │                                                    │
│[□] │                                                    │
└────┴────────────────────────────────────────────────────┘
Width: 72px (icons only)
```

- Show icons only, tooltips on hover
- Click to expand temporarily
- Toggle button at top

---

## Dialog & Modal Positioning

### Centered Dialog

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│              ┌─────────────────────┐                   │
│              │      Dialog         │                   │
│              │                     │  Max: 560px       │
│              │                     │                   │
│              └─────────────────────┘                   │
│                                                        │
└────────────────────────────────────────────────────────┘
```

- Center of viewport (not sidebar)
- Scrim: 50% black overlay
- Animation: Fade + slight scale

### Dropdown Menus

- Position: Below trigger, aligned left
- Max height: 320px (scrollable)
- Width: Min 200px, max 320px

### Context Menus

- Position: At cursor
- Min width: 200px
- Avoid screen edges

---

## Typography Scaling

Desktop uses standard MD3 type scale:

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display Medium | 45px | 400 | Hero sections |
| Headline Large | 32px | 400 | Page titles |
| Headline Medium | 28px | 400 | Section titles |
| Title Large | 22px | 400 | Card titles |
| Title Medium | 16px | 500 | Buttons, tabs |
| Body Large | 16px | 400 | Primary text |
| Body Medium | 14px | 400 | Secondary text |

---

## Color Theme Application

### Light Theme

```
Sidebar: Surface background
Content: Surface background
Cards: Surface Container High
Dialogs: Surface Container Highest
```

### Dark Theme

```
Sidebar: Surface background (#1C1B1F)
Content: Surface background
Cards: Surface Container (#2B2930)
Dialogs: Surface Container Highest (#47464F)
```

---

## Platform-Specific Notes

### Windows

- Title bar: Custom or system (your choice)
- Window controls: Right side (minimize, maximize, close)
- System font: Segoe UI (falls back to Roboto)
- DPI awareness: Support 100%, 125%, 150%, 200%

### macOS

- Title bar: Native with traffic lights (left side)
- Window controls: Left side (close, minimize, maximize)
- System font: SF Pro (falls back to system)
- Respect system appearance (light/dark)

### Linux

- Title bar: System or custom
- Window controls: Varies by DE (usually right)
- System font: System default (varies)
- Support GTK/Qt themes where possible

---

## Figma Frame Setup

For desktop designs:

```
Frame: Desktop
Width: 1440px
Height: 900px
Background: Surface color
```

Also create:
- 1280x800 (laptop)
- 1920x1080 (full HD)

For responsive testing.
