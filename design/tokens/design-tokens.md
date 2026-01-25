# Papyrus Design Tokens

Design tokens for the Papyrus book management application. These tokens define the visual language across all platforms and themes.

---

## Color Palettes

### Light Theme

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Primary** | `#5654A8` | rgb(86, 84, 168) | Main brand color, primary buttons, active states |
| **On Primary** | `#FFFFFF` | rgb(255, 255, 255) | Text/icons on primary color |
| **Primary Container** | `#E2DFFF` | rgb(226, 223, 255) | Primary button backgrounds (less emphasis) |
| **On Primary Container** | `#100563` | rgb(16, 5, 99) | Text on primary container |
| **Secondary** | `#5D5C71` | rgb(93, 92, 113) | Secondary actions, less prominent elements |
| **On Secondary** | `#FFFFFF` | rgb(255, 255, 255) | Text/icons on secondary color |
| **Secondary Container** | `#E3E0F9` | rgb(227, 224, 249) | Secondary backgrounds |
| **On Secondary Container** | `#1A1A2C` | rgb(26, 26, 44) | Text on secondary container |
| **Tertiary** | `#7A5368` | rgb(122, 83, 104) | Accent color, highlights |
| **On Tertiary** | `#FFFFFF` | rgb(255, 255, 255) | Text/icons on tertiary |
| **Tertiary Container** | `#FFD8EA` | rgb(255, 216, 234) | Tertiary backgrounds |
| **On Tertiary Container** | `#2F1124` | rgb(47, 17, 36) | Text on tertiary container |
| **Error** | `#BA1A1A` | rgb(186, 26, 26) | Error states, destructive actions |
| **Error Container** | `#FFDAD6` | rgb(255, 218, 214) | Error message backgrounds |
| **On Error** | `#FFFFFF` | rgb(255, 255, 255) | Text on error color |
| **On Error Container** | `#410002` | rgb(65, 0, 2) | Text on error container |
| **Surface** | `#FFFBFF` | rgb(255, 251, 255) | Main background color |
| **On Surface** | `#1C1B1F` | rgb(28, 27, 31) | Primary text color |
| **Surface Container Highest** | `#E4E1EC` | rgb(228, 225, 236) | Elevated surfaces, cards |
| **On Surface Variant** | `#47464F` | rgb(71, 70, 79) | Secondary text color |
| **Outline** | `#787680` | rgb(120, 118, 128) | Borders, dividers |
| **Outline Variant** | `#C8C5D0` | rgb(200, 197, 208) | Subtle borders |
| **Inverse Surface** | `#313034` | rgb(49, 48, 52) | Snackbars, tooltips |
| **On Inverse Surface** | `#F3EFF4` | rgb(243, 239, 244) | Text on inverse surface |
| **Inverse Primary** | `#C3C0FF` | rgb(195, 192, 255) | Primary on inverse surface |
| **Shadow** | `#000000` | rgb(0, 0, 0) | Drop shadows |
| **Scrim** | `#000000` | rgb(0, 0, 0) | Modal overlays (with opacity) |

### Dark Theme

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Primary** | `#C3C0FF` | rgb(195, 192, 255) | Main brand color |
| **On Primary** | `#272377` | rgb(39, 35, 119) | Text/icons on primary |
| **Primary Container** | `#3E3C8F` | rgb(62, 60, 143) | Primary backgrounds |
| **On Primary Container** | `#E2DFFF` | rgb(226, 223, 255) | Text on primary container |
| **Secondary** | `#C7C4DD` | rgb(199, 196, 221) | Secondary elements |
| **On Secondary** | `#2F2F42` | rgb(47, 47, 66) | Text on secondary |
| **Secondary Container** | `#464559` | rgb(70, 69, 89) | Secondary backgrounds |
| **On Secondary Container** | `#E3E0F9` | rgb(227, 224, 249) | Text on secondary container |
| **Tertiary** | `#EAB9D2` | rgb(234, 185, 210) | Accent color |
| **On Tertiary** | `#472639` | rgb(71, 38, 57) | Text on tertiary |
| **Tertiary Container** | `#603C50` | rgb(96, 60, 80) | Tertiary backgrounds |
| **On Tertiary Container** | `#FFD8EA` | rgb(255, 216, 234) | Text on tertiary container |
| **Error** | `#FFB4AB` | rgb(255, 180, 171) | Error states |
| **Error Container** | `#93000A` | rgb(147, 0, 10) | Error backgrounds |
| **On Error** | `#690005` | rgb(105, 0, 5) | Text on error |
| **On Error Container** | `#FFDAD6` | rgb(255, 218, 214) | Text on error container |
| **Surface** | `#1C1B1F` | rgb(28, 27, 31) | Main background |
| **On Surface** | `#E5E1E6` | rgb(229, 225, 230) | Primary text |
| **Surface Container Highest** | `#47464F` | rgb(71, 70, 79) | Elevated surfaces |
| **On Surface Variant** | `#C8C5D0` | rgb(200, 197, 208) | Secondary text |
| **Outline** | `#928F9A` | rgb(146, 143, 154) | Borders |
| **Outline Variant** | `#47464F` | rgb(71, 70, 79) | Subtle borders |
| **Inverse Surface** | `#E5E1E6` | rgb(229, 225, 230) | Inverse backgrounds |
| **On Inverse Surface** | `#1C1B1F` | rgb(28, 27, 31) | Text on inverse |
| **Inverse Primary** | `#5654A8` | rgb(86, 84, 168) | Primary on inverse |
| **Shadow** | `#000000` | rgb(0, 0, 0) | Drop shadows |
| **Scrim** | `#000000` | rgb(0, 0, 0) | Modal overlays |

### E-ink Theme

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Primary** | `#000000` | rgb(0, 0, 0) | Primary elements, text, borders |
| **On Primary** | `#FFFFFF` | rgb(255, 255, 255) | Text on primary |
| **Surface** | `#FFFFFF` | rgb(255, 255, 255) | Main background |
| **On Surface** | `#000000` | rgb(0, 0, 0) | Primary text |
| **Secondary** | `#404040` | rgb(64, 64, 64) | Secondary elements (dark gray) |
| **Container** | `#F5F5F5` | rgb(245, 245, 245) | Card backgrounds (light gray) |
| **Disabled** | `#808080` | rgb(128, 128, 128) | Disabled states (medium gray) |
| **Outline** | `#000000` | rgb(0, 0, 0) | All borders (2px minimum) |

**E-ink Constraints:**
- NO gradients - use solid fills only
- NO shadows - use 2px black borders instead
- NO transparency/opacity - all colors must be solid
- NO anti-aliasing on icons - use pixel-perfect rendering
- Maximum 5 grayscale values for optimal e-ink rendering

---

## Typography Scale

Based on Material Design 3 type scale. Default font: System (Roboto/SF Pro).

| Style | Size | Line Height | Weight | Letter Spacing | Usage |
|-------|------|-------------|--------|----------------|-------|
| **Display Large** | 57px | 64px | 400 | -0.25px | Hero text (rare) |
| **Display Medium** | 45px | 52px | 400 | 0px | Large headlines |
| **Display Small** | 36px | 44px | 400 | 0px | Section headers |
| **Headline Large** | 32px | 40px | 400 | 0px | Page titles |
| **Headline Medium** | 28px | 36px | 400 | 0px | Card titles |
| **Headline Small** | 24px | 32px | 400 | 0px | Subsection titles |
| **Title Large** | 22px | 28px | 400 | 0px | Large list items |
| **Title Medium** | 16px | 24px | 500 | 0.15px | Button text, tabs |
| **Title Small** | 14px | 20px | 500 | 0.1px | Small titles |
| **Body Large** | 16px | 24px | 400 | 0.5px | Primary body text |
| **Body Medium** | 14px | 20px | 400 | 0.25px | Secondary body text |
| **Body Small** | 12px | 16px | 400 | 0.4px | Captions |
| **Label Large** | 14px | 20px | 500 | 0.1px | Prominent labels |
| **Label Medium** | 12px | 16px | 500 | 0.5px | Standard labels |
| **Label Small** | 11px | 16px | 500 | 0.5px | Small labels |

**E-ink Typography Adjustments:**
- Minimum font size: 18px (use Body Large as minimum)
- Prefer weight 500+ for better readability
- Line height: 1.5x minimum for clarity

---

## Spacing System

Based on 8px grid system.

| Token | Value | Usage |
|-------|-------|-------|
| **xs** | 4px | Tight spacing, icon gaps |
| **sm** | 8px | Compact spacing, inline elements |
| **md** | 16px | Standard spacing, form gaps |
| **lg** | 24px | Section spacing |
| **xl** | 32px | Large section gaps |
| **xxl** | 48px | Page-level spacing |

**Common Combinations:**
- Button padding: 16px horizontal, 12px vertical
- Card padding: 16px all sides
- List item padding: 16px horizontal, 12px vertical
- Page margins: 16px (mobile), 24px (tablet), 32px (desktop)
- Form field spacing: 16px between fields

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| **none** | 0px | Sharp corners, e-ink buttons |
| **sm** | 4px | Small elements, chips |
| **md** | 8px | Buttons, inputs, small cards |
| **lg** | 12px | Cards, dialogs |
| **xl** | 16px | Large containers, bottom sheets |
| **xxl** | 28px | FABs, pills |
| **full** | 9999px | Circular elements, avatars |

**E-ink Adjustments:**
- Use `none` (0px) or `sm` (4px) only
- Sharp corners render better on e-ink displays

---

## Elevation / Shadows

| Level | Shadow | Usage |
|-------|--------|-------|
| **Level 0** | none | Flat elements |
| **Level 1** | `0 1px 2px rgba(0,0,0,0.3), 0 1px 3px 1px rgba(0,0,0,0.15)` | Cards, buttons |
| **Level 2** | `0 1px 2px rgba(0,0,0,0.3), 0 2px 6px 2px rgba(0,0,0,0.15)` | Floating elements |
| **Level 3** | `0 4px 8px 3px rgba(0,0,0,0.15), 0 1px 3px rgba(0,0,0,0.3)` | Dialogs, modals |
| **Level 4** | `0 6px 10px 4px rgba(0,0,0,0.15), 0 2px 3px rgba(0,0,0,0.3)` | Navigation drawers |
| **Level 5** | `0 8px 12px 6px rgba(0,0,0,0.15), 0 4px 4px rgba(0,0,0,0.3)` | Highest elevation |

**E-ink Alternative:**
- Replace all shadows with 2px solid black borders
- Use container background (#F5F5F5) for visual separation

---

## Touch Targets

| Platform | Minimum Size | Recommended | Spacing Between |
|----------|--------------|-------------|-----------------|
| **Mobile** | 44x44px | 48x48px | 8px |
| **Desktop** | 36x36px | 40x40px | 4px |
| **E-ink** | 56x56px | 64x64px | 16px |

---

## Responsive Breakpoints

| Breakpoint | Width | Columns | Margins | Gutter |
|------------|-------|---------|---------|--------|
| **Mobile** | 0-599px | 4 | 16px | 16px |
| **Tablet** | 600-839px | 8 | 24px | 24px |
| **Desktop Small** | 840-1199px | 12 | 24px | 24px |
| **Desktop Large** | 1200px+ | 12 | 32px | 24px |

---

## Icon Specifications

| Context | Size | Style |
|---------|------|-------|
| **Navigation** | 24px | Material Symbols Rounded, weight 400 |
| **Action buttons** | 24px | Material Symbols Rounded, weight 400 |
| **List items** | 24px | Material Symbols Rounded, weight 400 |
| **Small indicators** | 18px | Material Symbols Rounded, weight 400 |
| **Large displays** | 48px | Material Symbols Rounded, weight 300 |

**E-ink Icons:**
- Use filled variants for better visibility
- Minimum size: 24px
- Weight: 500+ for better contrast

---

## Animation Durations

| Type | Duration | Easing | E-ink |
|------|----------|--------|-------|
| **Quick** | 100ms | ease-out | 0ms |
| **Standard** | 200ms | ease-in-out | 0ms |
| **Emphasis** | 300ms | ease-in-out | 0ms |
| **Complex** | 500ms | cubic-bezier | 0ms |

**Note:** All animations are disabled on e-ink devices. Use instant state changes.
