# Papyrus

**A cross-platform e-book reading and management application**

## Overview

Papyrus is an open-source application for reading and managing both physical and digital books. It provides a versatile, user-friendly system that makes reading comfortable and fun across Android, iOS, Web, Desktop (Windows, macOS, Linux), and e-ink devices. Papyrus features an intuitive, modern UI with extensive customization options, unifying book organization, reading, note-taking, progress tracking, and personalized settings in a single application.

## Why Papyrus?

Existing solutions often fall short in one or more areas:

| Problem                              | How Papyrus Solves It                        |
| ------------------------------------ | -------------------------------------------- |
| Fragmented ecosystems (Kindle, Kobo) | Single app works everywhere with your books  |
| Complex desktop-only tools (Calibre) | Simple, intuitive interface on all platforms |
| Subscription-based cloud services    | Self-hostable, no mandatory subscriptions    |
| Privacy concerns with analytics      | No analytics by default, opt-in telemetry    |
| Poor e-ink device support            | Optimized UI for e-ink displays              |
| No offline functionality             | Offline-first design with optional sync      |

## Goals

1. **Cross-platform** - Manage books seamlessly across all devices without relearning the UI
2. **Integrated reader** - Read e-books with extensive customization options
3. **Flexible management** - Organize books into shelves, categories, and tags with powerful filtering
4. **Progress tracking** - Track reading time, books read, and achieve reading goals
5. **Storage flexibility** - Choose between local, self-hosted, or cloud storage
6. **Data ownership** - Export everything in open formats; your data is yours
7. **Privacy first** - No default analytics; optional self-hosted synchronization
8. **Extensible** - Plugin system for metadata sources, storage, and reader features
9. **Developer friendly** - Public REST API and easy self-hosting

## Target Audience

- **Regular readers** who consume digital and/or physical books and need a centralized library management solution
- **Habit builders** who want to track reading statistics and build reading habits through goals
- **Privacy-conscious users** who prefer local control over their data
- **Multi-device users** who read on phones, tablets, e-readers, and computers
- **E-ink device owners** who want a dedicated reading experience optimized for their hardware

## Supported Platforms

| Platform                            | Status    | Notes                                      |
| ----------------------------------- | --------- | ------------------------------------------ |
| Android (8.0+)                      | Primary   | Full feature support                       |
| iOS (12.0+)                         | Primary   | Full feature support                       |
| Web (Chrome, Firefox, Safari, Edge) | Primary   | PWA with offline support                   |
| Windows (10+)                       | Primary   | Native desktop experience                  |
| macOS (10.15+)                      | Primary   | Native desktop experience                  |
| Linux                               | Primary   | Native desktop experience                  |
| E-ink devices                       | Secondary | Optimized grayscale UI, reduced animations |

## Supported E-book Formats

| Format  | Read    | Convert To | Notes                                |
| ------- | ------- | ---------- | ------------------------------------ |
| EPUB    | Yes     | Yes        | Primary format, full feature support |
| PDF     | Yes     | Yes        | Fixed layout support                 |
| MOBI    | Yes     | Yes        | Kindle format                        |
| AZW3    | Yes     | No         | Kindle format (read-only)            |
| TXT     | Yes     | Yes        | Plain text                           |
| CBR/CBZ | Yes     | No         | Comic book archives                  |
| FB2     | Planned | Planned    | Future support                       |
| DOCX    | Planned | Planned    | Future support                       |

---

## Feature Overview

### Core Features (MVP)

These features define the minimum viable product and are prioritized for initial release:

#### 1. Book Management

- **Import books** from local storage, URL, or cloud services (Google Drive, OneDrive, Dropbox)
- **Organize with shelves** - user-defined collections (e.g., "Currently Reading", "Sci-Fi")
- **Tag books** with color-coded labels (0-10 tags per book)
- **Edit metadata** manually or fetch from online sources (Open Library, Google Books)
- **Search and filter** by title, author, tags, shelves, reading status, and more
- **Physical book tracking** - manually add and track physical books in your library

#### 2. Integrated E-book Reader

**Typography controls:**

- Font family selection (built-in and custom fonts)
- Font size, weight, line spacing, paragraph spacing
- Text alignment (left, right, center, justified)
- RTL language support

**Appearance:**

- Background color themes (light, dark, sepia, custom)
- Text and link color customization
- Adjustable margins and padding
- Brightness control (in-app)

**Navigation:**

- Single-page and two-page layouts
- Paginated and continuous scroll modes
- Table of contents navigation
- Go-to-page/percentage jump
- Progress bar with position indicator
- Touch zones, swipe gestures, volume key navigation

**Reading profiles:**

- Save named presets of all reader settings
- Quick profile switching
- Default profile per device
- Profile import/export

#### 3. Annotations and Notes

- **Highlight text** with multiple colors
- **Add notes** to highlights or create standalone book notes
- **Bookmarks** for quick navigation
- **Export annotations** to text, PDF, or Markdown
- **Search** across all annotations and notes

#### 4. Reading Progress and Goals

**Automatic tracking:**

- Reading time per book and total
- Pages/percentage read
- Books started, in progress, completed
- Reading velocity statistics

**Goals:**

- Time-based goals (e.g., "Read 30 minutes daily")
- Book count goals (e.g., "Read 12 books this year")
- Custom goals with manual progress updates
- Visual progress indicators and charts

**Synchronization:**

- Reading position synced across devices
- Progress and statistics synchronized

#### 5. Storage and Sync

**Storage options:**

- Device local storage (default, no account required)
- Self-hosted server (for privacy-focused users)
- Cloud storage (Google Drive, OneDrive, Dropbox)
- Network storage (NAS, shared folders)

**Offline support:**

- Full offline functionality without account
- Automatic sync when online
- Conflict resolution options

### Advanced Features (Post-MVP)

These features are planned for future releases:

- **Format conversion** between EPUB, PDF, and MOBI
- **OPDS catalog browsing** - download from online catalogs
- **OCR processing** - extract text from scanned documents
- **Audiobook support** - manage and play audiobooks with synchronized progress
- **Text-to-speech** - read books aloud
- **Social features** - share progress, reviews, and recommendations
- **AI-powered features** - summaries, recommendations, smart categorization
- **ISBN barcode scanning** - add physical books by scanning
- **Plugin system** - extend functionality with community plugins

---

## Documentation

This specification provides comprehensive documentation for development and maintenance:

### Requirements

- **[Requirements Overview](requirements/README.md)** - Structure and traceability
- **[Functional Requirements](requirements/functional-requirements.md)** - What the system does
- **[Non-Functional Requirements](requirements/non-functional-requirements.md)** - How the system performs

### System Design

- **[Actors](actors.md)** - User types and their interactions
- **[Use Cases](use-cases.md)** - Detailed workflows and scenarios
- **[Entities](entities.md)** - Data model and relationships
- **[Database Model](database-model.md)** - Database schema and design

### Implementation

- **[Technologies](technologies.md)** - Technology stack and architecture
- **[User Interface](user-interface.md)** - Design guidelines and UI specifications
- **[Market Analysis](market-analysis.md)** - Competitive landscape and positioning

---

## Quick Reference

### Requirement Notation

| Prefix  | Meaning                    | Example                  |
| ------- | -------------------------- | ------------------------ |
| FR-X.Y  | Functional Requirement     | FR-2.1 (Book conversion) |
| NFR-X.Y | Non-Functional Requirement | NFR-4.1 (Startup time)   |
| UC-X.Y  | Use Case                   | UC-2.1 (Import books)    |

### Feature Priority Levels

| Level         | Description                              |
| ------------- | ---------------------------------------- |
| P0 - Critical | Must have for MVP launch                 |
| P1 - High     | Should have for MVP, can defer if needed |
| P2 - Medium   | Nice to have, planned for post-MVP       |
| P3 - Low      | Future consideration, not planned        |
