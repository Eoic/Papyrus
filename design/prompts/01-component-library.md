# Papyrus Component Library

Detailed specifications for common UI components used across all platforms.

---

## Buttons

### Filled Button (Primary Action)

**Standard (Light Theme):**
```
┌─────────────────────────────────┐
│         Button Label            │  Height: 50px
└─────────────────────────────────┘  Radius: 8px
```
- Background: Primary (`#5654A8`)
- Text: On Primary (`#FFFFFF`)
- Font: Title Medium (16px, weight 500)
- Padding: 24px horizontal, 12px vertical
- Min width: 64px
- Elevation: Level 1

**States:**
| State | Background | Text | Border |
|-------|------------|------|--------|
| Default | `#5654A8` | `#FFFFFF` | none |
| Hovered | `#4A489C` | `#FFFFFF` | none |
| Pressed | `#3E3C8F` | `#FFFFFF` | none |
| Focused | `#5654A8` | `#FFFFFF` | 2px `#C3C0FF` |
| Disabled | `#E4E1EC` | `#787680` | none |

**Dark Theme:**
- Background: Primary (`#C3C0FF`)
- Text: On Primary (`#272377`)

**E-ink:**
```
┌─────────────────────────────────┐
│         Button Label            │  Height: 56px
└─────────────────────────────────┘  Border: 2px solid #000
```
- Background: `#000000`
- Text: `#FFFFFF`
- Border: none (filled style)
- Radius: 0px

### Outlined Button (Secondary Action)

**Standard (Light Theme):**
```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│         Button Label            │  Height: 50px
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  Radius: 8px
```
- Background: transparent
- Text: Primary (`#5654A8`)
- Border: 1px Outline (`#787680`)
- Padding: 24px horizontal, 12px vertical

**States:**
| State | Background | Text | Border |
|-------|------------|------|--------|
| Default | transparent | `#5654A8` | 1px `#787680` |
| Hovered | `#E2DFFF` | `#5654A8` | 1px `#5654A8` |
| Pressed | `#C3C0FF` | `#5654A8` | 1px `#5654A8` |
| Focused | transparent | `#5654A8` | 2px `#5654A8` |
| Disabled | transparent | `#787680` | 1px `#C8C5D0` |

**E-ink:**
- Background: `#FFFFFF`
- Text: `#000000`
- Border: 2px solid `#000000`
- Radius: 0px

### Text Button (Tertiary Action)

**Standard:**
- Background: transparent
- Text: Primary (`#5654A8`)
- Padding: 12px horizontal, 8px vertical
- No border

**E-ink:**
- Text: `#000000`
- Underline: 1px solid `#000000`

### Icon Button

**Standard:**
- Size: 48x48px touch target
- Icon: 24px
- Background: transparent (ripple on press)

**States:**
| State | Background | Icon Color |
|-------|------------|------------|
| Default | transparent | On Surface Variant (`#47464F`) |
| Hovered | Surface Container Highest (`#E4E1EC`) | On Surface (`#1C1B1F`) |
| Pressed | Outline Variant (`#C8C5D0`) | On Surface (`#1C1B1F`) |
| Disabled | transparent | Outline (`#787680`) at 38% |

**E-ink:**
- Size: 56x56px
- Border: 2px solid `#000000` (optional)
- Icon: 24px, `#000000`

---

## Text Inputs

### Outlined Text Field

**Standard (Light Theme):**
```
┌─────────────────────────────────┐
│ Label                           │
├─────────────────────────────────┤
│ Placeholder text           [?] │  Height: 56px
└─────────────────────────────────┘  Radius: 4px
  Helper text
```

- Border: 1px Outline (`#787680`)
- Background: transparent
- Label: Body Small (12px), On Surface Variant
- Input text: Body Large (16px), On Surface
- Padding: 16px horizontal

**States:**
| State | Border | Label Color |
|-------|--------|-------------|
| Default | 1px `#787680` | `#47464F` |
| Focused | 2px `#5654A8` | `#5654A8` |
| Error | 2px `#BA1A1A` | `#BA1A1A` |
| Disabled | 1px `#C8C5D0` | `#787680` |

**E-ink:**
- Border: 2px solid `#000000`
- No floating label animation
- Label above field always
- Radius: 0px

### Password Field

Same as Outlined Text Field with:
- Trailing icon: `visibility` / `visibility_off`
- Input obscured by default

### Search Field

```
┌─────────────────────────────────────┐
│ [search] Search books...     [tune]│  Height: 56px
└─────────────────────────────────────┘  Radius: 28px (pill)
```

- Background: Surface Container Highest (`#E4E1EC`)
- Leading icon: `search` (24px)
- Trailing icon: `tune` (filter options)
- Placeholder: Body Large, On Surface Variant

---

## Cards

### Book Card (Grid View)

```
┌───────────────────────┐
│                       │
│    [Book Cover]       │  Aspect: 2:3
│      120x180px        │
│                       │
├───────────────────────┤
│ Book Title            │  Title Small (14px)
│ Author Name           │  Label Small (11px)
└───────────────────────┘  Total: ~230px height
```

**Light Theme:**
- Background: Surface (`#FFFBFF`)
- Border radius: 8px (cover), 0px (text area)
- Shadow: Level 1
- Cover: `object-fit: cover`

**States:**
| State | Effect |
|-------|--------|
| Default | Level 1 shadow |
| Hovered | Level 2 shadow |
| Pressed | Scale 0.98 |
| Selected | 2px Primary border |

**E-ink:**
- Border: 2px solid `#000000`
- No shadow
- No hover states

### Book Card (List View)

```
┌─────────────────────────────────────────────────┐
│ ┌───────┐                                       │
│ │ Cover │  Book Title                    [>]   │  Height: 72px
│ │ 48x72 │  Author Name                         │
│ └───────┘                                       │
└─────────────────────────────────────────────────┘
```

### Info Card

```
┌─────────────────────────────────────┐
│ [icon]  Card Title            [>]  │
│                                     │
│ Card description text that can     │  Padding: 16px
│ wrap to multiple lines.            │
└─────────────────────────────────────┘
```

- Background: Surface Container (`#E4E1EC`)
- Border radius: 12px
- Icon: 24px, Primary color
- Title: Title Medium
- Description: Body Medium

---

## Navigation Components

### Bottom Navigation Bar

```
┌─────────────────────────────────────────────────────────┐
│  [icon]    [icon]    [icon]    [icon]    [icon]        │
│  Label     Label     Label     Label     Label         │  Height: 80px
└─────────────────────────────────────────────────────────┘
```

- Background: Surface (`#FFFBFF`)
- Height: 80px (includes safe area)
- Item width: equal distribution
- Icon: 24px
- Label: Label Medium (12px)
- Active: Primary color, indicator pill
- Inactive: On Surface Variant

**Active Indicator:**
- Background: Primary Container (`#E2DFFF`)
- Size: 64x32px pill
- Border radius: 16px

### Navigation Drawer

```
┌────────────────────────┐
│ ┌──────────────────┐   │
│ │      Header      │   │  Header: 64px
│ └──────────────────┘   │
├────────────────────────┤
│ [icon] Menu Item 1     │
│ [icon] Menu Item 2  *  │  Selected item
│ [icon] Menu Item 3     │  Item height: 56px
│ ────────────────────── │  Divider
│ [icon] Menu Item 4     │
└────────────────────────┘
```

- Width: 280px (mobile), 360px (desktop)
- Background: Surface
- Item padding: 16px horizontal, 12px vertical
- Selected: Primary Container background

### Tab Bar

```
┌──────────┬──────────┬──────────┐
│   Tab 1  │   Tab 2  │   Tab 3  │  Height: 48px
├──────────┴──────────┴──────────┤
│ ════════                       │  Indicator: 3px
└────────────────────────────────┘
```

- Background: Surface
- Text: Title Small (14px)
- Active: Primary, with indicator
- Inactive: On Surface Variant
- Indicator: 3px height, Primary color, 16px radius ends

---

## Feedback Components

### Snackbar

```
┌─────────────────────────────────────────────────┐
│  Message text                        [Action]  │  Height: 48px
└─────────────────────────────────────────────────┘
```

- Background: Inverse Surface (`#313034`)
- Text: On Inverse Surface (`#F3EFF4`)
- Action: Inverse Primary (`#C3C0FF`)
- Border radius: 4px
- Margin: 16px from edges
- Position: bottom, above bottom nav

### Dialog

```
┌─────────────────────────────────────┐
│              [icon]                 │
│                                     │
│          Dialog Title               │  Title: Headline Small
│                                     │
│ Dialog body text explaining the    │  Body: Body Medium
│ action or information.             │
│                                     │
│              [Cancel]  [Confirm]   │  Buttons: right-aligned
└─────────────────────────────────────┘
```

- Min width: 280px
- Max width: 560px
- Background: Surface Container Highest
- Border radius: 28px
- Padding: 24px
- Icon: 24px, Primary (optional)

**E-ink:**
- Full screen overlay
- Border: 2px solid `#000000`
- Radius: 0px

### Progress Indicators

**Circular (Loading):**
- Size: 48px
- Stroke: 4px
- Color: Primary

**Linear (Progress):**
- Height: 4px
- Track: Surface Container Highest
- Indicator: Primary
- Border radius: 2px

**E-ink:**
- Text: "Loading..." or percentage
- Segmented bar for progress (static)

---

## Form Elements

### Checkbox

```
Default:    Selected:    Indeterminate:
┌───┐       ┌───┐        ┌───┐
│   │       │ ✓ │        │ ─ │
└───┘       └───┘        └───┘
```

- Size: 18x18px
- Touch target: 48x48px
- Border: 2px Outline
- Selected fill: Primary
- Checkmark: On Primary

**E-ink:**
- Border: 2px solid `#000000`
- Fill: `#000000` when selected

### Radio Button

```
Default:    Selected:
 ○           ●
```

- Outer size: 20px
- Inner dot: 10px
- Touch target: 48x48px
- Border: 2px
- Selected: Primary fill

### Switch / Toggle

```
Off:                On:
┌──────────○       ○──────────┐
└──────────┘       └──────────┘
```

- Track: 52x32px
- Thumb: 24px
- Track off: Surface Container Highest
- Track on: Primary
- Thumb: Surface (off), On Primary (on)

**E-ink:**
- Replace with checkbox + label
- Or use clear ON/OFF text indicators

### Dropdown / Select

```
┌─────────────────────────────────┐
│ Selected value               [▼]│  Height: 56px
└─────────────────────────────────┘
```

- Same styling as outlined text field
- Trailing icon: `arrow_drop_down`
- Menu: elevation Level 2

**E-ink:**
- Full screen picker modal

---

## Specialized Components

### Reading Progress Bar

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░
                                    75%
```

- Height: 4px (thin) or 8px (prominent)
- Track: Surface Container Highest
- Progress: Primary
- Label: Body Small, centered or right-aligned

### Book Cover Placeholder

```
┌─────────────────────┐
│                     │
│     [book icon]     │  Icon: 48px
│                     │  Color: On Surface Variant
│     No Cover        │  Text: Body Small
│                     │
└─────────────────────┘
```

- Background: Surface Container
- Border: 1px dashed Outline

### Star Rating

```
★ ★ ★ ★ ☆
```

- Star size: 24px
- Filled: Primary or Tertiary
- Empty: Outline Variant
- Touch target: 48px per star
- Spacing: 4px between stars

### Chip / Tag

```
┌─────────────┐
│ [x] Label   │  Height: 32px
└─────────────┘  Radius: 16px (pill)
```

- Background: Surface Container Highest
- Text: Label Large, On Surface
- Leading icon: optional, 18px
- Trailing icon: `close` for removable
- Padding: 8px horizontal

**Selected state:**
- Background: Primary Container
- Text: On Primary Container

---

## Animation Specifications

### Standard Durations

| Animation | Duration | Easing |
|-----------|----------|--------|
| Button press | 100ms | ease-out |
| Page transition | 300ms | ease-in-out |
| Dialog open | 200ms | ease-out |
| Drawer slide | 250ms | ease-in-out |
| Fade in/out | 150ms | linear |
| Expand/collapse | 200ms | ease-in-out |

### E-ink Override

All durations: 0ms (instant state changes)
