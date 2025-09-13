---
description: User interface designs.
---

# User interface

This section outlines the user interface design principles, layout patterns, and key screen specifications for the Papyrus cross-platform book management system. The design follows Material 3 guidelines while maintaining consistency across all supported platforms.

## Design principles

### Material 3 foundation

* Modern, clean design based on Material 3 design system
* Adaptive color schemes with dynamic theming support
* Consistent typography and spacing throughout the application
* Platform-specific adaptations while maintaining core design language

### Cross-platform consistency

* Unified experience across Android, iOS, Web, and Desktop platforms
* Responsive layouts that adapt to different screen sizes and orientations
* Consistent navigation patterns and interaction behaviors
* Platform-appropriate UI elements while maintaining brand identity

### Accessibility

* High contrast color options for better readability
* Scalable text and UI elements
* Keyboard navigation support for desktop platforms
* Screen reader compatibility
* Color-blind friendly design choices

### User-centric design

* Intuitive navigation with minimal learning curve
* Contextual actions and smart defaults
* Customizable interface elements based on user preferences
* Efficient workflows for common tasks

## Information architecture

### Primary navigation structure

```
Home / library
├── All books
├── Shelves
│   ├── Currently reading
│   ├── Planning to read
│   ├── Completed
│   └── Custom shelves
├── Tags
├── Search & filters
└── Recently added

Reader
├── Book content
├── Table of contents
├── Annotations & notes
├── Reading settings
└── Progress information

Progress & goals
├── Reading statistics
├── Active goals
├── Progress charts
└── Reading history

Settings
├── Account management
├── Reading preferences
├── Storage configuration
├── Synchronization
├── Import / export
└── About
```

## Key screen specifications

### 1. Library/Home screen

**Purpose:** Primary entry point showing user's book collection

**Layout components:**

* **Header bar:** App logo, search icon, user profile menu
* **Navigation tabs:** All Books, Shelves, Tags, Search
* **Filter bar:** Quick filters (reading status, format, recently added)
* **Book grid/list:** Configurable view with cover thumbnails
* **Floating action button:** Add new book
* **Bottom navigation:** Library, Reader, Progress, Settings (mobile)

**Responsive behavior:**

* Desktop: Sidebar navigation with main content area
* Tablet: Adaptive grid layout with 3-4 columns
* Mobile: Single column list with compact view option

**Key interactions:**

* Tap book cover to open in reader
* Long press for context menu (add to shelf, edit, delete)
* Swipe gestures for quick actions (mark as read, favorite)
* Search with auto-complete and recent searches

### 2. Book reader screen

**Purpose:** Immersive reading experience with customization options

**Layout components:**

* **Reading area:** Full-screen book content with minimal UI
* **Top toolbar:** Back button, book title, reading settings (auto-hide)
* **Bottom toolbar:** Progress bar, page indicators, navigation controls
* **Side panels:** Table of contents, annotations, notes (collapsible)
* **Reading settings overlay:** Font, spacing, colors, theme options
* **Annotation tools:** Highlight colors, note creation, bookmark

**Adaptive features:**

* Automatic day/night theme switching
* Reading profiles for different contexts (indoor/outdoor, device type)
* Gesture-based navigation (tap zones, swipe for pages)
* Adjustable UI element visibility and timing

**Customization options:**

* Font family, size, weight selection
* Line height and letter spacing adjustments
* Margin and padding controls
* Background and text color customization
* Reading mode (paginated vs. continuous scroll)
* Column layout for wide screens

### 3. Book details screen

**Purpose:** Comprehensive book information and management

**Layout components:**

* **Header:** Book cover, title, author, rating
* **Metadata section:** Publication info, ISBN, page count, format
* **Description:** Expandable book summary
* **Action buttons:** Read, add to shelf, mark as favorite, edit
* **Progress section:** Reading status, current position, time spent
* **Notes and annotations:** Quick access to user content
* **Related information:** Series, author's other works, similar books

**Management features:**

* Metadata editing with form validation
* Tag assignment with color coding
* Shelf management with multiple selection
* Export options (book file, metadata, notes)
* Delete confirmation with data preservation options

### 4. Search and discovery screen

**Purpose:** Advanced book finding and filtering capabilities

**Layout components:**

* **Search bar:** Text input with voice search option
* **Filter chips:** Quick access to common filters
* **Advanced filters panel:** Detailed filtering options
* **Results area:** Filtered book grid with sort options
* **Search suggestions:** Recent searches, popular tags, saved filters

**Search capabilities:**

* Full-text search across book content (where supported)
* Metadata search (title, author, ISBN, description)
* Tag and shelf filtering
* Complex query language support
* Saved search patterns
* Search history and suggestions

**Filter options:**

* Reading status (not started, in progress, completed)
* Book format (EPUB, PDF, physical, etc.)
* Date added ranges
* Publication date ranges
* Rating and favorite status
* File size and page count ranges
* Custom metadata fields

### 5. Progress and statistics screen

**Purpose:** Reading analytics and goal tracking

**Layout components:**

* **Summary cards:** Books read, time spent, current streak
* **Charts area:** Reading progress visualizations
* **Goals section:** Active goals with progress indicators
* **Time filters:** Week, month, year, custom range selectors
* **Achievement badges:** Reading milestones and accomplishments
* **Detailed statistics:** Books by genre, reading speed, completion rates

**Visualization types:**

* Reading time trends (line charts)
* Books completed over time (bar charts)
* Reading distribution by day/hour (heat maps)
* Genre preferences (pie charts)
* Goal progress indicators (progress bars, circular indicators)

### 6. Settings and preferences screen

**Purpose:** Application configuration and user account management

**Layout organization:**

* **Account section:** Profile info, authentication, data sync
* **Reading preferences:** Default reader settings, profiles
* **Storage configuration:** File storage backends, sync settings
* **Import/Export:** Data migration and backup options
* **Notifications:** Goal reminders, sync status, updates
* **About:** Version info, licenses, support contact

**Key configuration areas:**

* Reading profile management with import/export
* Storage backend selection and configuration
* Synchronization preferences and conflict resolution
* Data export formats and destinations
* Privacy settings and data retention policies

## Platform-specific adaptations

### Desktop (Windows, macOS, Linux)

* **Window management:** Resizable windows with minimum size constraints
* **Keyboard shortcuts:** Full keyboard navigation and shortcuts
* **Menu bar:** Native menu integration with platform conventions
* **File management:** Drag-and-drop support for book imports
* **Multi-window:** Optional separate reader windows

### Mobile (Android, iOS)

* **Touch optimization:** Large touch targets, gesture navigation
* **Status bar integration:** Adaptive status bar colors
* **Notification support:** Reading reminders, sync status
* **Share integration:** Share books and notes with other apps
* **Background sync:** Offline reading with background synchronization

### Web browser

* **Responsive design:** Adaptive layouts for various screen sizes
* **Progressive web app:** Offline functionality and app-like experience
* **File upload:** Web-based book import with drag-and-drop
* **Cross-browser compatibility:** Support for modern browsers
* **Bookmark integration:** Browser bookmark sync for reading positions

## Color scheme and theming

The application uses Material 3 design system with custom color schemes optimized for reading applications. The color values are defined in the Flutter client and ensure accessibility and readability across all themes.

### Light theme (default)

Based on Material 3 light color scheme with purple primary colors:

* **Primary:** Purple (#5654A8) - Main brand color for buttons, links, and key UI elements
* **Primary container:** Light purple (#E2DFFF) - Backgrounds for primary actions
* **Secondary:** Dark purple-gray (#5D5C71) - Secondary buttons and text
* **Secondary container:** Light gray-purple (#E3E0F9) - Secondary backgrounds
* **Surface:** Pure white (#FFFBFF) - Main content backgrounds
* **Surface container:** Light gray (#E4E1EC) - Card and container backgrounds
* **On surface:** Dark gray (#1C1B1F) - Primary text color
* **On surface variant:** Medium gray (#47464F) - Secondary text color
* **Outline:** Medium gray (#787680) - Borders and dividers

### Dark theme

Optimized dark color scheme for comfortable night reading:

* **Primary:** Light purple (#C3C0FF) - Adjusted for dark backgrounds
* **Primary container:** Dark purple (#3E3C8F) - Primary action backgrounds
* **Secondary:** Light purple-gray (#C7C4DD) - Secondary elements
* **Secondary container:** Dark gray (#464559) - Secondary backgrounds
* **Surface:** Very dark gray (#1C1B1F) - Main content backgrounds
* **Surface container:** Medium dark gray (#47464F) - Card backgrounds
* **On surface:** Light gray (#E5E1E6) - Primary text color
* **On surface variant:** Medium light gray (#C8C5D0) - Secondary text color
* **Outline:** Gray (#928F9A) - Borders and dividers

### Reading-specific color considerations

* **Error colors:** Red tones (#BA1A1A light, #FFB4AB dark) for validation and warnings
* **Tertiary colors:** Pink-purple accent (#7A5368 light, #EAB9D2 dark) for special highlights
* **Shadow and scrim:** Pure black (#000000) for depth and overlays
* **Inverse colors:** Automatically calculated contrasting colors for accessibility

### Dynamic theming features

* **System integration:** Automatic theme switching based on system preferences
* **Material You support:** Dynamic color generation from wallpaper (Android 12+)
* **Time-based switching:** Optional automatic day/night theme changes
* **Reading profiles:** Theme preferences saved per reading profile
* **Custom accent colors:** User-customizable accent colors while maintaining accessibility

## Responsive design breakpoints

### Breakpoint definitions

* **Mobile:** 0-599px (single column, bottom navigation)
* **Tablet:** 600-839px (adaptive grid, side navigation option)
* **Desktop small:** 840-1199px (sidebar navigation, multi-column grid)
* **Desktop large:** 1200px+ (optimized for large screens, multiple panels)

### Layout adaptations

* **Navigation:** Bottom tabs (mobile) → Side navigation (tablet+)
* **Content grid:** 1 column (mobile) → 2-3 columns (tablet) → 4+ columns (desktop)
* **Reader:** Full screen (mobile) → Centered with margins (desktop)
* **Panels:** Overlay (mobile) → Side panels (tablet+)

## Accessibility features

### Visual accessibility

* **High contrast modes:** Enhanced contrast ratios for better visibility
* **Font scaling:** Support for system font size preferences
* **Color indicators:** Non-color-dependent status indicators
* **Focus indicators:** Clear focus states for keyboard navigation

### Motor accessibility

* **Touch targets:** Minimum 44px touch targets for mobile
* **Gesture alternatives:** Tap alternatives for swipe gestures
* **Keyboard navigation:** Full keyboard accessibility for desktop
* **Voice control:** Voice command support where available

### Cognitive accessibility

* **Simple navigation:** Clear, consistent navigation patterns
* **Help tooltips:** Contextual help for complex features
* **Undo actions:** Easy reversal of accidental actions
* **Progress indicators:** Clear feedback for long-running operations

This user interface specification provides a comprehensive framework for developing a modern, accessible, and user-friendly book management application that works seamlessly across all target platforms while maintaining the clean, Material 3-inspired design aesthetic.
