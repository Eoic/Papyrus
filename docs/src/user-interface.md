# User interface

This section outlines the user interface design principles, layout patterns, and key screen specifications for the Papyrus cross-platform book management system. The design follows Material 3 guidelines while maintaining consistency across all supported platforms, with special considerations for e-ink devices.

## Design principles

### Material 3 foundation

- Modern, clean design based on Material 3 design system
- Adaptive color schemes with dynamic theming support
- Consistent typography and spacing throughout the application
- Platform-specific adaptations while maintaining core design language

### Cross-platform consistency

- Unified experience across Android, iOS, Web, Desktop, and E-ink platforms
- Responsive layouts that adapt to different screen sizes and orientations
- Consistent navigation patterns and interaction behaviors
- Platform-appropriate UI elements while maintaining brand identity

### E-ink first design

For e-ink devices, the design prioritizes:

- **High contrast**: Pure black on white (or inverse) for maximum readability
- **No animations**: Static UI transitions to avoid ghosting artifacts
- **Reduced refresh**: Minimize screen updates to improve battery life and reduce flicker
- **Larger touch targets**: Accommodate slower touch response on e-ink screens
- **Hardware button support**: Navigation via physical buttons when available

### Accessibility

- High contrast color options for better readability
- Scalable text and UI elements
- Keyboard navigation support for desktop platforms
- Screen reader compatibility
- Color-blind friendly design choices
- E-ink optimized modes with maximum contrast

### User-centric design

- Intuitive navigation with minimal learning curve
- Contextual actions and smart defaults
- Customizable interface elements based on user preferences
- Efficient workflows for common tasks

## Information architecture

### Primary navigation structure

```
Home / Library
├── All Books
├── Shelves
│   ├── Currently Reading
│   ├── Planning to Read
│   ├── Completed
│   └── Custom Shelves
├── Series
├── Tags
├── Search & Filters
└── Recently Added

Reader
├── Book Content
├── Table of Contents
├── Annotations & Notes
├── Bookmarks
├── Reading Settings
└── Progress Information

Progress & Goals
├── Reading Statistics
├── Active Goals
├── Progress Charts
└── Reading History

Settings
├── Account Management
├── Reading Preferences
├── Storage Configuration
├── Synchronization
├── Import / Export
├── E-ink Mode Settings
└── About
```

## Key screen specifications

### 1. Library/home screen

**Purpose:** Primary entry point showing user's book collection

**Layout components:**

- **Header bar:** App logo, search icon, user profile menu
- **Navigation tabs:** All Books, Shelves, Series, Tags, Search
- **Filter bar:** Quick filters (reading status, format, recently added)
- **Book grid/list:** Configurable view with cover thumbnails
- **Floating action button:** Add new book
- **Bottom navigation:** Library, Reader, Progress, Settings (mobile)

**Responsive behavior:**

- Desktop: Sidebar navigation with main content area
- Tablet: Adaptive grid layout with 3-4 columns
- Mobile: Single column list with compact view option
- E-ink: High-contrast list view with larger text and touch targets

**Key interactions:**

- Tap book cover to open in reader
- Long press for context menu (add to shelf, edit, delete)
- Swipe gestures for quick actions (mark as read, favorite) - disabled on e-ink
- Search with auto-complete and recent searches

### 2. Book reader screen

**Purpose:** Immersive reading experience with customization options

**Layout components:**

- **Reading area:** Full-screen book content with minimal UI
- **Top toolbar:** Back button, book title, reading settings (auto-hide)
- **Bottom toolbar:** Progress bar, page indicators, navigation controls
- **Side panels:** Table of contents, annotations, notes, bookmarks (collapsible)
- **Reading settings overlay:** Font, spacing, colors, theme options
- **Annotation tools:** Highlight colors, note creation, bookmark

**Adaptive features:**

- Automatic day/night theme switching (disabled on e-ink)
- Reading profiles for different contexts (indoor/outdoor, device type)
- Gesture-based navigation (tap zones, swipe for pages)
- Adjustable UI element visibility and timing
- E-ink mode with page-turn only refresh

**Customization options:**

- Font family, size, weight selection
- Line height and letter spacing adjustments
- Margin and padding controls
- Background and text color customization
- Reading mode (paginated vs. continuous scroll)
- Column layout for wide screens
- E-ink refresh mode (full page, partial, fast)

**E-ink reader optimizations:**

- Full page refresh option to clear ghosting
- Hardware button mapping for page turns
- Reduced UI chrome for maximum reading area
- High contrast text rendering
- Optional inverted mode (white text on black)

### 3. Book details screen

**Purpose:** Comprehensive book information and management

**Layout components:**

- **Header:** Book cover, title, author, rating
- **Metadata section:** Publication info, ISBN, page count, format
- **Description:** Expandable book summary
- **Action buttons:** Read, add to shelf, mark as favorite, edit
- **Progress section:** Reading status, current position, time spent
- **Notes and annotations:** Quick access to user content
- **Series information:** Series name, book number, other books in series
- **Related information:** Author's other works, similar books

**Management features:**

- Metadata editing with form validation
- Tag assignment with color coding
- Shelf management with multiple selection
- Series assignment and ordering
- Export options (book file, metadata, notes)
- Delete confirmation with data preservation options

### 4. Search and discovery screen

**Purpose:** Advanced book finding and filtering capabilities

**Layout components:**

- **Search bar:** Text input with voice search option (voice disabled on e-ink)
- **Filter chips:** Quick access to common filters
- **Advanced filters panel:** Detailed filtering options
- **Results area:** Filtered book grid with sort options
- **Search suggestions:** Recent searches, popular tags, saved filters

**Search capabilities:**

- Full-text search across book content (where supported)
- Metadata search (title, author, ISBN, description)
- Tag and shelf filtering
- Series filtering
- Complex query language support
- Saved search patterns
- Search history and suggestions

**Filter options:**

- Reading status (not started, in progress, completed)
- Book format (EPUB, PDF, physical, etc.)
- Date added ranges
- Publication date ranges
- Rating and favorite status
- File size and page count ranges
- Series membership
- Custom metadata fields

### 5. Progress and statistics screen

**Purpose:** Reading analytics and goal tracking

**Layout components:**

- **Summary cards:** Books read, time spent, current streak
- **Charts area:** Reading progress visualizations
- **Goals section:** Active goals with progress indicators
- **Time filters:** Week, month, year, custom range selectors
- **Achievement badges:** Reading milestones and accomplishments
- **Detailed statistics:** Books by genre, reading speed, completion rates

**Visualization types:**

- Reading time trends (line charts)
- Books completed over time (bar charts)
- Reading distribution by day/hour (heat maps)
- Genre preferences (pie charts)
- Goal progress indicators (progress bars, circular indicators)

**E-ink adaptations:**

- Static, high-contrast charts without animations
- Simplified visualizations with clear labels
- Text-based statistics as primary, charts as secondary
- Manual refresh button for updated data

### 6. Settings and preferences screen

**Purpose:** Application configuration and user account management

**Layout organization:**

- **Account section:** Profile info, authentication, data sync
- **Reading preferences:** Default reader settings, profiles
- **Storage configuration:** File storage backends, sync settings
- **Display settings:** Theme, font size, e-ink mode toggle
- **Import/Export:** Data migration and backup options
- **Notifications:** Goal reminders, sync status, updates
- **About:** Version info, licenses, support contact

**Key configuration areas:**

- Reading profile management with import/export
- Storage backend selection and configuration
- Synchronization preferences and conflict resolution
- Data export formats and destinations
- Privacy settings and data retention policies
- E-ink mode settings and optimizations

## Platform-specific adaptations

### Desktop (Windows, macOS, Linux)

- **Window management:** Resizable windows with minimum size constraints
- **Keyboard shortcuts:** Full keyboard navigation and shortcuts
- **Menu bar:** Native menu integration with platform conventions
- **File management:** Drag-and-drop support for book imports
- **Multi-window:** Optional separate reader windows

### Mobile (Android, iOS)

- **Touch optimization:** Large touch targets, gesture navigation
- **Status bar integration:** Adaptive status bar colors
- **Notification support:** Reading reminders, sync status
- **Share integration:** Share books and notes with other apps
- **Background sync:** Offline reading with background synchronization

### Web browser

- **Responsive design:** Adaptive layouts for various screen sizes
- **Progressive web app:** Offline functionality and app-like experience
- **File upload:** Web-based book import with drag-and-drop
- **Cross-browser compatibility:** Support for modern browsers
- **Bookmark integration:** Browser bookmark sync for reading positions

### E-ink devices

E-ink devices require special UI considerations due to their unique display characteristics:

**Display optimizations:**

- **No animations:** All transitions are instant cuts, no fades or slides
- **Minimal refresh:** UI updates batched to reduce screen flicker
- **Full page refresh:** Optional periodic full refresh to clear ghosting
- **High contrast:** Pure black (#000000) and white (#FFFFFF) only
- **Sharp edges:** No anti-aliasing on UI elements for crisp rendering

**Navigation:**

- **Hardware buttons:** Page turn buttons mapped to forward/back navigation
- **Larger touch targets:** Minimum 56px touch areas (vs 44px on other platforms)
- **Simplified menus:** Reduced nesting, more items per screen
- **Confirmation dialogs:** Extra confirmation for destructive actions (slower to undo)

**Reader specific:**

- **Page-based reading:** Pagination preferred over scrolling
- **Refresh modes:**
  - Full refresh: Complete screen update, clearest but slowest
  - Partial refresh: Updates changed areas only, faster but may ghost
  - Fast refresh: Optimized for page turns, some quality trade-off
- **Contrast adjustment:** Fine-tune text darkness for different e-ink panels
- **Font optimization:** Use fonts optimized for e-ink (e.g., Bookerly, Literata)

**Performance:**

- **Lazy loading:** Load content only when needed
- **Reduced imagery:** Downscale or hide decorative images
- **Battery optimization:** Minimize background activity
- **Offline first:** Assume intermittent connectivity

## Color scheme and theming

The application uses Material 3 design system with custom color schemes optimized for reading applications.

### Light theme (default)

Based on Material 3 light color scheme with purple primary colors:

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary | Purple | #5654A8 | Main brand color for buttons, links, key UI elements |
| Primary Container | Light Purple | #E2DFFF | Backgrounds for primary actions |
| Secondary | Dark Purple-Gray | #5D5C71 | Secondary buttons and text |
| Secondary Container | Light Gray-Purple | #E3E0F9 | Secondary backgrounds |
| Surface | Pure White | #FFFBFF | Main content backgrounds |
| Surface Container | Light Gray | #E4E1EC | Card and container backgrounds |
| On Surface | Dark Gray | #1C1B1F | Primary text color |
| On Surface Variant | Medium Gray | #47464F | Secondary text color |
| Outline | Medium Gray | #787680 | Borders and dividers |

### Dark theme

Optimized dark color scheme for comfortable night reading:

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary | Light Purple | #C3C0FF | Adjusted for dark backgrounds |
| Primary Container | Dark Purple | #3E3C8F | Primary action backgrounds |
| Secondary | Light Purple-Gray | #C7C4DD | Secondary elements |
| Secondary Container | Dark Gray | #464559 | Secondary backgrounds |
| Surface | Very Dark Gray | #1C1B1F | Main content backgrounds |
| Surface Container | Medium Dark Gray | #47464F | Card backgrounds |
| On Surface | Light Gray | #E5E1E6 | Primary text color |
| On Surface Variant | Medium Light Gray | #C8C5D0 | Secondary text color |
| Outline | Gray | #928F9A | Borders and dividers |

### E-ink theme

Maximum contrast theme optimized for e-ink displays:

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary | Black | #000000 | All interactive elements |
| Primary Container | Light Gray | #E0E0E0 | Button backgrounds |
| Secondary | Dark Gray | #404040 | Secondary text |
| Secondary Container | Light Gray | #F0F0F0 | Card backgrounds |
| Surface | White | #FFFFFF | Main backgrounds |
| Surface Container | Off White | #F5F5F5 | Elevated surfaces |
| On Surface | Black | #000000 | Primary text |
| On Surface Variant | Dark Gray | #606060 | Secondary text |
| Outline | Black | #000000 | Borders (2px minimum) |
| Inverse Surface | Black | #000000 | Inverted mode background |
| Inverse On Surface | White | #FFFFFF | Inverted mode text |

**E-ink Theme Characteristics:**

- No gradients or shadows
- 2px minimum border width for visibility
- Bold font weights preferred
- No transparency or alpha blending
- Icons use solid fills, not outlines

### Sepia theme (reading)

Warm-toned theme for extended reading sessions:

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Surface | Cream | #FDF6E3 | Reading background |
| On Surface | Dark Brown | #5C4A32 | Text color |
| Primary | Brown | #8B7355 | Links and accents |

### Reading-specific color considerations

- **Error colors:** Red tones (#BA1A1A light, #FFB4AB dark) for validation and warnings
- **Tertiary colors:** Pink-purple accent (#7A5368 light, #EAB9D2 dark) for special highlights
- **Shadow and scrim:** Pure black (#000000) for depth and overlays
- **Inverse colors:** Automatically calculated contrasting colors for accessibility

### Dynamic theming features

- **System integration:** Automatic theme switching based on system preferences
- **Material You support:** Dynamic color generation from wallpaper (Android 12+)
- **Time-based switching:** Optional automatic day/night theme changes
- **Reading profiles:** Theme preferences saved per reading profile
- **Custom accent colors:** User-customizable accent colors while maintaining accessibility
- **E-ink auto-detection:** Automatic switch to e-ink theme on compatible devices

## Responsive design breakpoints

### Breakpoint definitions

| Breakpoint | Width | Layout | Navigation |
|------------|-------|--------|------------|
| Mobile | 0-599px | Single column | Bottom tabs |
| Tablet | 600-839px | Adaptive grid | Side navigation option |
| Desktop Small | 840-1199px | Sidebar + multi-column | Sidebar navigation |
| Desktop Large | 1200px+ | Multiple panels | Sidebar navigation |
| E-ink | Any | Simplified single column | Tab bar or hardware buttons |

### Layout adaptations

| Element | Mobile | Tablet | Desktop | E-ink |
|---------|--------|--------|---------|-------|
| Navigation | Bottom tabs | Side nav | Sidebar | Top tabs + buttons |
| Content Grid | 1 column | 2-3 columns | 4+ columns | 1-2 columns |
| Reader | Full screen | Centered | Centered + margins | Full screen |
| Panels | Overlay | Side panels | Side panels | Full screen overlay |
| Touch Targets | 44px | 44px | 36px | 56px |
| Font Size | 16px base | 16px base | 14px base | 18px base |

### E-ink specific layout rules

- Maximum content width: 600px (typical e-reader width)
- Minimum touch target: 56px × 56px
- Line height: 1.5 minimum for readability
- Paragraph spacing: 1em minimum
- Button padding: 16px minimum
- Border width: 2px minimum for visibility

## Accessibility features

### Visual accessibility

- **High contrast modes:** Enhanced contrast ratios for better visibility
- **Font scaling:** Support for system font size preferences (up to 200%)
- **Color indicators:** Non-color-dependent status indicators
- **Focus indicators:** Clear focus states for keyboard navigation
- **E-ink compatibility:** Full functionality in grayscale

### Motor accessibility

- **Touch targets:** Minimum 44px touch targets (56px on e-ink)
- **Gesture alternatives:** Tap alternatives for all swipe gestures
- **Keyboard navigation:** Full keyboard accessibility for desktop
- **Voice control:** Voice command support where available
- **Hardware button support:** Physical button navigation on supported devices

### Cognitive accessibility

- **Simple navigation:** Clear, consistent navigation patterns
- **Help tooltips:** Contextual help for complex features
- **Undo actions:** Easy reversal of accidental actions
- **Progress indicators:** Clear feedback for long-running operations
- **Confirmation dialogs:** Explicit confirmation for destructive actions

### E-ink accessibility considerations

- **Slow refresh accommodation:** Extra time for users to read before screen updates
- **Clear state indication:** Obvious visual feedback for selected/active states
- **Reduced cognitive load:** Simplified screens with essential information only
- **Consistent layout:** Predictable element positioning across screens
- **Text-first design:** Information conveyed through text, not color or icons alone

## Component library

### Button variants

| Variant | Standard | E-ink |
|---------|----------|-------|
| Primary | Filled with brand color | Black fill, white text |
| Secondary | Outlined | 2px black border |
| Tertiary | Text only | Underlined text |
| Disabled | 50% opacity | Gray fill, no interaction |

### Form elements

| Element | Standard | E-ink |
|---------|----------|-------|
| Text Input | 1px border, focus ring | 2px border, bold on focus |
| Checkbox | Filled square | 2px border checkbox, X mark |
| Radio | Filled circle | 2px border circle, filled dot |
| Toggle | Animated switch | Static on/off states |
| Dropdown | Animated expand | Full screen picker |

### Feedback components

| Component | Standard | E-ink |
|-----------|----------|-------|
| Loading | Spinner animation | "Loading..." text |
| Progress | Animated bar | Segmented bar (static) |
| Toast | Fade in/out | Full width banner |
| Dialog | Fade + scale | Instant overlay |
| Snackbar | Slide up | Top banner |

---

This user interface specification provides a comprehensive framework for developing a modern, accessible, and user-friendly book management application that works seamlessly across all target platforms—including e-ink devices—while maintaining the clean, Material 3-inspired design aesthetic.
