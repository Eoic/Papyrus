# E-ink Platform Context

Platform-specific design guidelines for e-ink/e-paper devices (Kindle, Kobo, reMarkable, etc.).

---

## Critical E-ink Constraints

### Display Limitations

E-ink displays have fundamental differences from LCD/OLED:

| Characteristic | E-ink | Standard Display |
|----------------|-------|------------------|
| Refresh rate | 0.1-1 Hz | 60-120 Hz |
| Color depth | 16 grayscale | 16M colors |
| Ghosting | Yes | No |
| Animations | Not supported | Full support |
| Touch response | 100-300ms | <50ms |

### Absolute Rules

1. **NO gradients** - Use solid fills only
2. **NO shadows** - Use borders instead
3. **NO transparency** - All colors must be solid
4. **NO animations** - Instant state changes only
5. **NO anti-aliasing concerns** - Use clean, sharp edges
6. **NO color reliance** - Information must be conveyed without color

---

## Screen Specifications

### Common E-ink Devices

| Device | Resolution | Size | PPI |
|--------|------------|------|-----|
| Kindle Paperwhite | 1236 x 1648 | 6.8" | 300 |
| Kobo Clara 2E | 1072 x 1448 | 6" | 300 |
| reMarkable 2 | 1404 x 1872 | 10.3" | 226 |
| Design target | **1072 x 1448** | 6" | 300 |

### Design Viewport

Design for the most common 6" e-reader:
- Width: 1072px
- Height: 1448px
- Safe area: 24px margins all sides
- Content width: 1024px

---

## Color Palette (Strict)

Only use these colors. No exceptions.

| Name | Hex | Usage |
|------|-----|-------|
| **Black** | `#000000` | Primary text, borders, icons, filled buttons |
| **White** | `#FFFFFF` | Background, button text on black |
| **Dark Gray** | `#404040` | Secondary text, less prominent elements |
| **Medium Gray** | `#808080` | Disabled states, dividers |
| **Light Gray** | `#C0C0C0` | Subtle borders, inactive elements |
| **Container Gray** | `#F5F5F5` | Card backgrounds, input fields |

### Color Usage Guidelines

```
Background:     #FFFFFF (always)
Primary text:   #000000
Secondary text: #404040
Borders:        #000000 (2px minimum)
Disabled:       #808080
Cards/inputs:   #F5F5F5 background, #000000 border
```

---

## Typography

### Font Requirements

- **Primary font:** High-contrast, well-hinted fonts
- **Recommended:** Bookerly, Literata, Charter, Georgia
- **Fallback:** System serif

### Size Scale (E-ink Adjusted)

| Style | Size | Weight | Line Height |
|-------|------|--------|-------------|
| Page Title | 32px | 700 | 40px |
| Section Title | 24px | 600 | 32px |
| Card Title | 20px | 600 | 28px |
| Body | 18px | 400 | 28px |
| Secondary | 16px | 400 | 24px |
| Caption | 14px | 400 | 20px |

**Minimum font size: 14px** (smaller text becomes illegible)

### Weight Guidelines

- Prefer **500-700 weight** for better visibility
- Thin/light weights (100-300) should be avoided
- Bold renders more clearly on e-ink

---

## Touch Targets

E-ink touch panels have lower precision and slower response:

| Element | Minimum | Recommended | Spacing |
|---------|---------|-------------|---------|
| Buttons | 56x56px | 64x64px | 16px |
| List items | 64px height | 72px | 8px |
| Icons | 48x48px | 56x56px | 16px |
| Checkboxes | 32x32px | 40x40px | 24px |

### Touch Feedback

Since visual feedback is slow:
- Use clear selected/pressed states with color inversion
- Consider haptic feedback where available
- Avoid double-tap interactions

---

## Navigation Structure

### Tab Bar Navigation

```
┌───────────────────────────────────────────────────────────────────┐
│   Library    │    Goals     │    Stats     │   Settings          │
└───────────────────────────────────────────────────────────────────┘
Height: 72px, Border: 2px bottom
```

**Specifications:**
- Height: 72px
- Border: 2px solid black (bottom)
- Text: 18px, weight 500
- Active tab: Black background, white text
- Inactive tab: White background, black text

### Page Header

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  Page Title                                           [⋮]   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
Height: 72px, Border: 2px bottom
```

### Hardware Button Support

Many e-readers have physical buttons:
- Page forward/back buttons for navigation
- Map to: Next page, Previous page, Confirm, Back

---

## Component Specifications

### Buttons

**Primary Button (Filled):**
```
┌─────────────────────────────────────┐
│           Button Label              │  Height: 56px
└─────────────────────────────────────┘  No radius
```
- Background: `#000000`
- Text: `#FFFFFF`, 18px, weight 600
- Padding: 24px horizontal
- Border: none (solid fill)

**Secondary Button (Outlined):**
```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│           Button Label              │  Height: 56px
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  Border: 2px
```
- Background: `#FFFFFF`
- Text: `#000000`, 18px, weight 600
- Border: 2px solid `#000000`
- Padding: 24px horizontal

**Disabled Button:**
- Background: `#FFFFFF`
- Text: `#808080`
- Border: 2px solid `#808080`

### Cards

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Card content here                                  │  Border: 2px
│                                                     │  Padding: 16px
│                                                     │
└─────────────────────────────────────────────────────┘
```
- Background: `#FFFFFF` or `#F5F5F5`
- Border: 2px solid `#000000`
- Border radius: 0px (sharp corners)
- Padding: 16px

### Text Input

```
Label
┌─────────────────────────────────────────────────────┐
│  Input text here                                    │  Height: 56px
└─────────────────────────────────────────────────────┘  Border: 2px
```
- Label: Always visible above field
- Background: `#F5F5F5`
- Border: 2px solid `#000000`
- Text: 18px
- Padding: 16px
- Border radius: 0px

**Focused state:**
- Border: 4px solid `#000000`
- Background: `#FFFFFF`

### Checkboxes and Radio Buttons

```
Unchecked:     Checked:
┌───────┐      ┌───────┐
│       │      │   ✓   │
└───────┘      └───────┘
```
- Size: 32x32px
- Border: 2px solid `#000000`
- Checked fill: `#000000`
- Checkmark: `#FFFFFF`
- Touch target: 56x56px

### Lists

```
┌─────────────────────────────────────────────────────────────────┐
│  [icon]  List item text                                    [>] │
├─────────────────────────────────────────────────────────────────┤
│  [icon]  List item text                                    [>] │
├─────────────────────────────────────────────────────────────────┤
│  [icon]  List item text                                    [>] │
└─────────────────────────────────────────────────────────────────┘
```
- Item height: 72px
- Divider: 1px solid `#C0C0C0`
- Padding: 16px horizontal
- Icon: 24px, left-aligned
- Chevron: 24px, right-aligned

### Progress Indicators

**Static Progress Bar:**
```
Progress: 75%
████████████████████████░░░░░░░░
```
- Height: 16px
- Track: 2px border, `#FFFFFF` fill
- Progress: `#000000` fill
- Segments recommended for clarity

**Text-based Loading:**
```
Loading...
```
- No spinners or animations
- Use text indication only

### Dialogs/Modals

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                   Dialog Title                      │
│                                                     │
│  Dialog message text explaining the situation.     │
│                                                     │
│  ┌─────────────┐      ┌─────────────┐              │
│  │   Cancel    │      │   Confirm   │              │
│  └─────────────┘      └─────────────┘              │
│                                                     │
└─────────────────────────────────────────────────────┘
```
- Full width minus 48px margins (or full screen)
- Border: 2px solid `#000000`
- Background: `#FFFFFF`
- Padding: 24px
- Buttons: Full width or side-by-side

---

## Layout Patterns

### Full Page Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                         Header (72px)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                                                                 │
│                         Content                                 │
│                       (scrollable)                              │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                       Tab Bar (72px)                            │
└─────────────────────────────────────────────────────────────────┘
```

### Book Grid Layout

```
┌─────────┬─────────┬─────────┐
│         │         │         │
│  Book   │  Book   │  Book   │  2-3 columns
│         │         │         │  depending on screen
├─────────┼─────────┼─────────┤
│         │         │         │
│  Book   │  Book   │  Book   │
│         │         │         │
└─────────┴─────────┴─────────┘
Gap: 16px
```

- 6" screen: 2 columns (cover ~300px wide)
- 10" screen: 3-4 columns

---

## Refresh Strategies

### Full Refresh

Use full page refresh (flash black/white) for:
- Page navigation
- Major content changes
- Every 5-10 partial refreshes

### Partial Refresh

Use partial refresh for:
- Scrolling (if supported)
- Button state changes
- Small UI updates

### Refresh Indicators

```
┌─────────────────────────────────────┐
│         ⟳ Refreshing...             │
└─────────────────────────────────────┘
```

Show "Refreshing..." text during full refresh operations.

---

## Accessibility Considerations

### High Contrast by Default

E-ink is naturally high contrast. Maintain this:
- Never use gray text on gray backgrounds
- Ensure 7:1+ contrast ratio for all text
- Use pattern fills if distinction needed (not color)

### Large Text Support

- Support system font size scaling
- Minimum: 14px
- Default: 18px
- Large: 24px

### Screen Reader Support

- All elements must have accessible labels
- Use semantic structure
- Support TalkBack/VoiceOver where available

---

## Figma Frame Setup

For e-ink designs:

```
Frame: E-ink 6"
Width: 1072px
Height: 1448px
Background: #FFFFFF (pure white)
```

Also create:
- 1404 x 1872 (10" tablet-style e-reader)

**Export settings:**
- Grayscale only
- No effects or shadows
- Sharp edges (no anti-aliasing on icons)
