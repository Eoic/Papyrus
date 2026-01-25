# Papyrus Design System Context

This document provides the foundational context for all Figma AI design generation prompts.

---

## Application Overview

**Papyrus** is a cross-platform book management application for readers who want to organize, track, and enjoy their book collections.

**Target Users:**
- Avid readers managing large book collections
- Students and researchers organizing academic materials
- E-book enthusiasts with multiple file formats
- Users who read across multiple devices

**Core Value Proposition:**
- Unified library for physical and digital books
- Cross-device synchronization
- Comprehensive reading progress tracking
- Support for multiple e-book formats (EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ)

**Supported Platforms:**
- Mobile: Android, iOS
- Desktop: Windows, macOS, Linux
- Web: Progressive Web App
- E-ink: Dedicated e-reader devices

---

## Brand Identity

**Brand Name:** Papyrus

**Tagline:** "Your ultimate digital library"

**Logo:** Stylized scroll/book icon in primary purple color
- File: `assets/images/logo.png`
- Size: 150x150px for splash/welcome screens
- Size: 40x40px for app bars

**Brand Colors:**
- Primary Purple: `#5654A8` - Represents wisdom, creativity, and literature
- Light variant: `#C3C0FF` (dark theme)
- Container: `#E2DFFF` (light backgrounds)

**Brand Voice:**
- Calm and focused
- Supportive of reading flow
- Minimal distractions
- Clean and organized

---

## Design System Foundation

### Material Design 3 Adherence

Follow Material Design 3 (Material You) guidelines with these specifications:

1. **Component Library:** Use MD3 components (FilledButton, OutlinedButton, Card, etc.)
2. **Color System:** Dynamic color based on purple seed color (`#5654A8`)
3. **Typography:** MD3 type scale with system fonts
4. **Shape:** Rounded corners following MD3 shape scale
5. **Elevation:** MD3 tonal elevation system
6. **Motion:** MD3 motion patterns (disabled on e-ink)

### Core Design Principles

1. **Reading-First:** Prioritize content consumption over UI chrome
2. **Minimal Distraction:** Clean interfaces that don't compete with book content
3. **Accessibility:** WCAG 2.1 AA compliance, high contrast options
4. **Cross-Platform Consistency:** Same visual language, platform-appropriate interactions
5. **Progressive Disclosure:** Show essential features first, advanced features on demand

---

## Navigation Paradigm

### Mobile Navigation (Bottom Tab Bar)

```
[Dashboard] [Library] [Goals] [Statistics] [Profile]
     |          |         |        |           |
   home    books/shelves  reading   charts    settings
                          goals
```

**Tab Icons (Material Symbols Rounded):**
- Dashboard: `dashboard`
- Library: `library_books`
- Goals: `emoji_events`
- Statistics: `stacked_line_chart`
- Profile: `person`

### Library Sub-Navigation (Drawer)

When in Library tab, a drawer provides access to:
- All Books (`stacked_bar_chart`)
- Shelves (`shelves`)
- Topics/Tags (`topic`)
- Bookmarks (`bookmark`)
- Annotations (`border_color`)
- Notes (`notes`)

### Desktop Navigation (Sidebar)

Permanent sidebar with:
- Logo + app name at top
- Main navigation items (vertical list)
- Library sub-items expandable
- User profile at bottom

### E-ink Navigation (Tab Bar + Buttons)

- Simplified tab bar with text labels
- Hardware button support for page navigation
- No gestures (tap only)

---

## Common UI Patterns

### App Bar

**Mobile:**
- Height: 64px
- Title: centered or left-aligned
- Leading: back arrow or menu icon
- Actions: up to 2 icons

**Desktop:**
- Height: 64px
- Title: left-aligned after sidebar
- Actions: right-aligned

### Floating Action Button (FAB)

- Position: bottom-right, 16px margin
- Size: 56x56px
- Icon: 24px
- Primary action: Add new book
- E-ink: Use outlined button at bottom instead

### Cards

- Padding: 16px all sides
- Border radius: 12px
- Elevation: Level 1 (light), tonal (dark)
- E-ink: 2px black border, no shadow

### Lists

- Item height: 56-72px (single/two-line)
- Leading: 40px avatar or 24px icon
- Trailing: icon or text
- Dividers: full-width or inset

### Bottom Sheets

- Border radius: 16px top corners
- Handle: 4px x 32px, centered, 8px from top
- Max height: 90% of screen
- E-ink: Full-screen modal instead

### Dialogs

- Min width: 280px
- Max width: 560px
- Border radius: 28px
- Padding: 24px
- E-ink: Full-screen with 2px border

---

## Content Guidelines

### Book Display

**Grid View:**
- Cover aspect ratio: 2:3 (width:height)
- Cover size: 120x180px (mobile), 150x225px (desktop)
- Title: max 2 lines, ellipsis
- Author: max 1 line, ellipsis

**List View:**
- Cover size: 60x90px
- Title + Author visible
- Progress indicator optional

### Empty States

Always provide:
1. Illustration or icon (optional on e-ink)
2. Headline explaining the state
3. Body text with guidance
4. Action button to resolve

Example:
- Icon: `menu_book` (48px)
- Headline: "No books yet"
- Body: "Add your first book to start building your library"
- Action: "Add Book" button

### Loading States

- Use circular progress indicator (standard)
- Use "Loading..." text (e-ink)
- Skeleton screens for content loading
- Never show empty content without explanation

### Error States

- Error icon: `error` in Error color
- Clear error message
- Recovery action when possible
- "Try Again" button

---

## Accessibility Requirements

### Color Contrast

- Normal text: 4.5:1 minimum
- Large text (18px+): 3:1 minimum
- UI components: 3:1 minimum
- E-ink: Maximum contrast (black on white)

### Touch Targets

- Minimum: 44x44px (mobile), 56x56px (e-ink)
- Spacing: 8px between targets

### Focus Indicators

- Visible focus ring on all interactive elements
- 2px outline in Primary color
- 2px offset from element

### Screen Reader Support

- All images have alt text
- Interactive elements have labels
- Form fields have visible labels
- Status changes announced

---

## File Naming Convention

Design files should follow:
```
papyrus-[platform]-[page]-[state]-[theme].fig

Examples:
papyrus-mobile-library-populated-light.fig
papyrus-desktop-reader-settings-dark.fig
papyrus-eink-dashboard-empty.fig
```

---

## Reference Files

- **Design Tokens:** `design/tokens/design-tokens.md`
- **Flutter Colors:** `client/lib/themes/color_schemes.g.dart`
- **UI Specification:** `docs/src/user-interface.md`
- **Router/Pages:** `client/lib/config/app_router.dart`
