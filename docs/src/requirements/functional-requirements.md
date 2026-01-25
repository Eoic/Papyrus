# Functional requirements

This document defines the functional requirements for Papyrus, organized by feature area. Each requirement includes a priority level and references to related use cases.

## Priority levels

| Priority   | Description                       | Target |
| ---------- | ----------------                  |--------|
| **P0**     | Critical - Must have for MVP      | v1.0   |
| **P1**     | High - Should have for MVP        | v1.0   |
| **P2**     | Medium - Post-MVP planned feature | v1.x   |
| **P3**     | Low - Future consideration        | v2.x+  |

---

## 1. User management

### FR-1.1: Account registration

**Priority:** P0 | **Use case:** [UC-1.1](../use-cases.md#uc-11-create-user-account)

User can create an account using an email address and password.

**Acceptance criteria:**

- Email must be valid and unique in the system
- Password must meet minimum security requirements (8+ characters, mixed case, number)
- Email verification is sent upon registration
- Account is created in inactive state until email is verified

### FR-1.2: Email/password login

**Priority:** P0 | **Use case:** [UC-1.2](../use-cases.md#uc-12-login-with-credentials)

User can log in to the system using email and password.

**Acceptance criteria:**

- System validates credentials against stored hash
- Failed attempts are rate-limited (max 5 per minute)
- Successful login creates a secure session token
- User is redirected to their library after login

### FR-1.3: OAuth login (Google)

**Priority:** P1 | **Use case:** [UC-1.3](../use-cases.md#uc-13-login-with-google-account)

User can log in using their Google account via OAuth 2.0.

**Acceptance criteria:**

- Google OAuth flow completes securely
- New users are automatically registered on first OAuth login
- Existing users can link Google account to email account
- Google profile photo and name are imported (optional)

### FR-1.4: Offline mode

**Priority:** P0 | **Use case:** [UC-1.4](../use-cases.md#uc-14-use-application-offline)

User can use the application in offline mode without credentials or internet connection.

**Acceptance criteria:**

- All reading and library management features work offline
- Data is stored locally on device
- No account required for offline-only usage
- Offline users can later create account and migrate data

### FR-1.5: Password recovery

**Priority:** P1 | **Use case:** [UC-1.5](../use-cases.md#uc-15-recover-password)

User can reset their password via email recovery link.

**Acceptance criteria:**

- Recovery link is sent to registered email
- Link expires after 24 hours
- Link is single-use and invalidated after password change
- User must set new password meeting security requirements

### FR-1.6: Account deletion

**Priority:** P1 | **Use case:** [UC-1.6](../use-cases.md#uc-16-delete-account)

User can permanently delete their account and all associated data.

**Acceptance criteria:**

- Deletion requires password confirmation
- User is warned about data loss
- All user data is removed from server within 30 days
- Local device data remains unless explicitly deleted

---

## 2. Book management

### FR-2.1: Format conversion

**Priority:** P2 | **Use case:** [UC-2.2](../use-cases.md#uc-22-convert-book-formats)

User can convert e-book files between supported formats (EPUB, PDF, MOBI).

**Acceptance criteria:**

- Conversion preserves content and basic formatting
- Original file is retained after conversion
- Progress indicator shown for large files
- Conversion errors are reported clearly

### FR-2.2: Manual metadata editing

**Priority:** P0 | **Use case:** [UC-2.3](../use-cases.md#uc-23-edit-book-metadata)

User can manually edit book metadata (title, author, description, etc.).

**Acceptance criteria:**

- Editable fields: title, subtitle, author, co-authors, publisher, publication date, ISBN, language, description, series, series number
- Changes are saved immediately
- Cover image can be replaced from file or URL

### FR-2.3: Custom metadata fields

**Priority:** P2 | **Use case:** [UC-2.3](../use-cases.md#uc-23-edit-book-metadata)

User can add and remove custom metadata fields to books.

**Acceptance criteria:**

- Custom fields have user-defined names
- Field values can be text, number, date, or boolean
- Custom fields are searchable
- Batch editing of custom fields is supported

### FR-2.4: Book file export

**Priority:** P0 | **Use case:** [UC-2.7](../use-cases.md#uc-27-export-books-and-data)

User can export selected book files from the system.

**Acceptance criteria:**

- Single or multiple books can be selected
- Export as individual files or ZIP archive
- Original file format is preserved
- Export includes embedded metadata

### FR-2.5: Library data export

**Priority:** P1 | **Use case:** [UC-2.7](../use-cases.md#uc-27-export-books-and-data)

User can export library data in structured, human-readable formats.

**Acceptance criteria:**

- Export formats: JSON, CSV, OPML
- Includes all metadata, shelves, tags, and reading progress
- Annotations and notes can be included optionally
- Export can be filtered by shelf or tags

### FR-2.6: Book import

**Priority:** P0 | **Use case:** [UC-2.1](../use-cases.md#uc-21-import-book-files)

User can import books from files, URLs, or cloud storage.

**Acceptance criteria:**

- Supported import sources: local files, URLs, Google Drive, OneDrive, Dropbox
- Bulk import of multiple files/folders
- Metadata is automatically extracted from file
- Duplicate detection with merge options

### FR-2.7: Full-text search

**Priority:** P1 | **Use case:** [UC-2.6](../use-cases.md#uc-26-search-books)

System provides full-text search within book contents.

**Acceptance criteria:**

- Search works for EPUB, TXT formats (PDF requires OCR)
- Results show matched text with context
- Search is case-insensitive by default
- Results link directly to location in book

### FR-2.8: Advanced search

**Priority:** P0 | **Use case:** [UC-2.6](../use-cases.md#uc-26-search-books)

System supports searching by metadata, tags, categories, and content.

**Acceptance criteria:**

- Searchable fields: title, author, description, ISBN, tags, shelves
- Filters: reading status, format, date added, publication date, rating
- Search results are sortable
- Recent searches are saved

### FR-2.9: Shelf organization

**Priority:** P0 | **Use case:** [UC-2.4](../use-cases.md#uc-24-organize-books-into-shelves)

User can create shelves to group books into collections.

**Acceptance criteria:**

- Shelves have name, description, and optional color
- Books can belong to multiple shelves
- Default shelves: "Currently Reading", "Want to Read", "Finished"
- Shelves can be nested (sub-shelves)
- Drag-and-drop organization

### FR-2.10: Book tagging

**Priority:** P0 | **Use case:** [UC-2.5](../use-cases.md#uc-25-tag-books)

User can assign colored tags to books for organization and filtering.

**Acceptance criteria:**

- Tags have title and color (from palette or custom)
- Books can have 0-10 tags
- Tags are visible in library view
- Quick tag assignment via context menu
- Batch tagging supported

### FR-2.11: Query language filters

**Priority:** P2 | **Use case:** [UC-2.6](../use-cases.md#uc-26-search-books)

User can create complex filters using a query language.

**Acceptance criteria:**

- Query syntax similar to Jira/GitHub (e.g., `author:"Name" AND year:>2000`)
- Supports AND, OR, NOT operators
- Date ranges, numeric comparisons
- Filters can be saved and named
- Graphical filter builder as alternative

### FR-2.12: ISBN barcode scanning

**Priority:** P2 | **Use case:** [UC-2.8](../use-cases.md#uc-28-scan-isbn-barcode)

User can scan ISBN barcodes to add physical books with fetched metadata.

**Acceptance criteria:**

- Camera-based barcode scanning (mobile/desktop with camera)
- ISBN lookup from multiple sources
- User can edit fetched metadata before saving
- Works offline with manual ISBN entry fallback

### FR-2.13: Metadata fetching

**Priority:** P1 | **Use case:** [UC-2.3](../use-cases.md#uc-23-edit-book-metadata)

System can automatically fetch metadata from online sources.

**Acceptance criteria:**

- Sources: Open Library, Google Books (configurable)
- Fetch triggered manually or on import
- User reviews and confirms changes before applying
- Cover images can be fetched automatically

### FR-2.14: Physical book tracking

**Priority:** P1 | **Use case:** [UC-2.9](../use-cases.md#uc-29-track-physical-book)

User can add and track physical books in their library.

**Acceptance criteria:**

- Manual entry of all metadata fields
- Physical books appear in library alongside digital
- Reading status and progress tracking
- Location field (e.g., "Shelf 3", "Lent to John")

---

## 3. Integrated viewer

### FR-3.1: E-book reading

**Priority:** P0 | **Use case:** [UC-3.1](../use-cases.md#uc-31-read-books-with-integrated-viewer)

User can read e-books using the integrated viewer.

**Acceptance criteria:**

- Supports: EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ
- Responsive layout adapts to screen size
- Reading position is automatically saved
- Table of contents navigation
- Page/chapter navigation

### FR-3.2: Viewer customization

**Priority:** P0 | **Use case:** [UC-3.2](../use-cases.md#uc-32-customize-reading-experience)

User can customize the viewer appearance and behavior.

**Acceptance criteria:**

- Typography: font family, size (8-72pt), weight, line height, letter spacing, paragraph spacing
- Colors: background, text, links (presets + custom)
- Layout: margins, padding, single/dual page, pagination/scroll
- Navigation: tap zones, swipe, volume keys, on-screen buttons
- Brightness: in-app control independent of system

### FR-3.3: Reading profiles

**Priority:** P1 | **Use case:** [UC-3.3](../use-cases.md#uc-33-manage-reading-profiles)

User can create and manage named reading profiles.

**Acceptance criteria:**

- Profile contains all viewer customization settings
- Quick switch between profiles
- One profile can be set as default
- Profiles can be exported/imported
- Device-specific default profiles

### FR-3.4: Bookmarks

**Priority:** P0 | **Use case:** [UC-3.4](../use-cases.md#uc-34-manage-bookmarks)

User can create and manage bookmarks within books.

**Acceptance criteria:**

- Create bookmark at current position with optional note
- List all bookmarks for a book
- Jump to bookmark location
- Delete bookmarks
- Bookmarks sync across devices

---

## 4. Annotations and notes

### FR-4.1: Text highlighting

**Priority:** P0 | **Use case:** [UC-4.1](../use-cases.md#uc-41-create-text-annotations)

User can highlight text while reading with optional notes.

**Acceptance criteria:**

- Select text and choose highlight color
- Multiple color options (at least 5)
- Optional note attached to highlight
- Highlights visible in text
- View all highlights in dedicated panel

### FR-4.2: Book notes

**Priority:** P0 | **Use case:** [UC-4.2](../use-cases.md#uc-42-create-book-notes)

User can create free-form notes associated with books.

**Acceptance criteria:**

- Notes have title and content
- Rich text or Markdown support
- Notes are not tied to specific text location
- Multiple notes per book
- Notes are searchable

### FR-4.3: Annotation editing

**Priority:** P0 | **Use case:** [UC-4.3](../use-cases.md#uc-43-manage-annotations)

User can edit and delete existing annotations and notes.

**Acceptance criteria:**

- Edit highlight color and attached note
- Edit note title and content
- Delete with confirmation
- Undo delete within session

### FR-4.4: Annotation export

**Priority:** P1 | **Use case:** [UC-4.4](../use-cases.md#uc-44-export-annotations)

User can export annotations and notes to external formats.

**Acceptance criteria:**

- Export formats: plain text, Markdown, PDF, HTML
- Include highlighted text with context
- Group by book or export all
- Include metadata (book title, date, page)

### FR-4.5: Annotation search

**Priority:** P1 | **Use case:** [UC-4.5](../use-cases.md#uc-45-search-annotations)

User can search through all annotations and notes.

**Acceptance criteria:**

- Search across all books or specific book
- Search in highlight text and note content
- Filter by color, date, book
- Results link to source location

---

## 5. Progress tracking

### FR-5.1: Reading statistics

**Priority:** P0 | **Use case:** [UC-5.1](../use-cases.md#uc-51-track-reading-progress)

User can view comprehensive reading progress and statistics.

**Acceptance criteria:**

- Metrics: total time read, books completed, pages read, current streaks
- Per-book stats: time spent, sessions, reading velocity
- Visual charts and graphs
- Comparison to previous periods

### FR-5.2: Statistics filtering

**Priority:** P1 | **Use case:** [UC-5.2](../use-cases.md#uc-52-filter-progress-statistics)

User can filter statistics by time frame and book selection.

**Acceptance criteria:**

- Time frames: today, week, month, year, custom range
- Filter by: specific books, shelves, tags
- Export statistics data
- Save filter presets

### FR-5.3: Cross-device sync

**Priority:** P0 | **Use case:** [UC-7.3](../use-cases.md#uc-73-synchronize-data-across-devices)

System synchronizes reading progress, metadata, and annotations across all logged-in devices via the metadata server.

**Acceptance criteria:**

- Reading position syncs within 30 seconds when online
- Metadata, shelves, tags, annotations sync automatically
- Offline changes queued and sync when connection restored
- Conflict resolution: latest timestamp wins for position, merge for metadata
- Sync status indicator visible in app (synced, syncing, offline, error)
- Requires metadata server connection (self-hosted or official)

See [Server Architecture](../server-architecture.md#synchronization-architecture) for sync details.

---

## 6. Goal management

### FR-6.1: Reading goals

**Priority:** P1 | **Use case:** [UC-6.1](../use-cases.md#uc-61-create-reading-goals)

User can create time-based reading goals.

**Acceptance criteria:**

- Goal types: books per period, pages per period, time per period
- Periods: daily, weekly, monthly, yearly, custom
- Multiple active goals allowed
- Goal templates for quick creation

### FR-6.2: Manual goal updates

**Priority:** P1 | **Use case:** [UC-6.2](../use-cases.md#uc-62-manage-goal-progress)

User can manually update goal progress values.

**Acceptance criteria:**

- Increment/decrement progress
- Set exact value
- Add notes to progress updates
- History of manual updates

### FR-6.3: Automatic goal progress

**Priority:** P1 | **Use case:** [UC-6.2](../use-cases.md#uc-62-manage-goal-progress)

System automatically updates goal progress based on reading activity.

**Acceptance criteria:**

- Book completion updates book-count goals
- Reading time updates time-based goals
- Pages read updates page-count goals
- Progress is calculated in real-time

### FR-6.4: Goal notifications

**Priority:** P2 | **Use case:** [UC-6.2](../use-cases.md#uc-62-manage-goal-progress)

System sends notifications about goal progress and reminders.

**Acceptance criteria:**

- Reminder notifications (configurable frequency)
- Milestone notifications (50%, 75%, complete)
- Streak notifications
- Notifications can be disabled per goal

---

## 7. Storage and synchronization

### FR-7.1: File storage backend selection

**Priority:** P0 | **Use case:** [UC-7.1](../use-cases.md#uc-71-configure-storage-options)

User can choose where book files are stored from application settings.

**Acceptance criteria:**

- Options: device local, Google Drive, OneDrive, Dropbox, WebDAV, MinIO/S3, dedicated Papyrus server
- Multiple backends can be configured simultaneously
- One backend is designated as primary for new uploads
- Files can be migrated between backends without data loss
- Backend configuration accessible from Settings > Storage
- Connection status and storage usage displayed

See [Server Architecture](../server-architecture.md) for details.

### FR-7.1.1: Metadata server configuration

**Priority:** P0 | **Use case:** [UC-7.1](../use-cases.md#uc-71-configure-storage-options)

User can configure connection to a metadata server for cross-device synchronization.

**Acceptance criteria:**

- Default: use official hosted server (optional)
- Self-hosted option: user provides server URL
- Server URL validation and connection testing
- Login/registration on metadata server
- Clear indication when offline or disconnected
- Works without metadata server (local-only mode)

### FR-7.2: File upload

**Priority:** P0 | **Use case:** [UC-2.1](../use-cases.md#uc-21-import-book-files)

User can upload book files from their device.

**Acceptance criteria:**

- File picker with format filtering
- Drag-and-drop support (desktop/web)
- Progress indicator for large files
- Duplicate detection

### FR-7.3: OCR processing

**Priority:** P2 | **Use case:** [UC-7.2](../use-cases.md#uc-72-process-scanned-documents)

System can apply OCR to scanned documents for text extraction.

**Acceptance criteria:**

- Processes PDF files with scanned images
- Text becomes searchable after OCR
- Processing happens in background
- Quality/confidence indicator shown
- Multiple language support

### FR-7.4: Plugin system

**Priority:** P3 | **Use case:** N/A

System supports optional plugins for extended functionality.

**Acceptance criteria:**

- Plugin types: metadata sources, storage backends, reader features
- Plugins are sandboxed for security
- Enable/disable individual plugins
- Plugin marketplace/repository

### FR-7.5: OPDS catalog support

**Priority:** P2 | **Use case:** [UC-7.4](../use-cases.md#uc-74-browse-opds-catalog)

User can browse and download books from OPDS catalogs.

**Acceptance criteria:**

- Add OPDS catalog URLs
- Browse catalog hierarchy
- Search within catalogs
- Download books directly to library
- Authentication for protected catalogs

---

## Requirements traceability matrix

| Requirement | Priority | Use Cases | Actors |
|-------------|----------|-----------|--------|
| FR-1.1 | P0 | UC-1.1 | Anonymous → Registered |
| FR-1.2 | P0 | UC-1.2 | Registered |
| FR-1.3 | P1 | UC-1.3 | Registered |
| FR-1.4 | P0 | UC-1.4 | Anonymous, Registered |
| FR-1.5 | P1 | UC-1.5 | Registered |
| FR-1.6 | P1 | UC-1.6 | Registered |
| FR-2.1 | P2 | UC-2.2 | Reader |
| FR-2.2 | P0 | UC-2.3 | Reader |
| FR-2.3 | P2 | UC-2.3 | Reader |
| FR-2.4 | P0 | UC-2.7 | Reader |
| FR-2.5 | P1 | UC-2.7 | Reader |
| FR-2.6 | P0 | UC-2.1 | Reader |
| FR-2.7 | P1 | UC-2.6 | Reader |
| FR-2.8 | P0 | UC-2.6 | Reader |
| FR-2.9 | P0 | UC-2.4 | Reader |
| FR-2.10 | P0 | UC-2.5 | Reader |
| FR-2.11 | P2 | UC-2.6 | Reader |
| FR-2.12 | P2 | UC-2.8 | Reader |
| FR-2.13 | P1 | UC-2.3 | Reader |
| FR-2.14 | P1 | UC-2.9 | Reader |
| FR-3.1 | P0 | UC-3.1 | Reader, E-ink Reader |
| FR-3.2 | P0 | UC-3.2 | Reader, E-ink Reader |
| FR-3.3 | P1 | UC-3.3 | Reader, E-ink Reader |
| FR-3.4 | P0 | UC-3.4 | Reader |
| FR-4.1 | P0 | UC-4.1 | Reader |
| FR-4.2 | P0 | UC-4.2 | Reader |
| FR-4.3 | P0 | UC-4.3 | Reader |
| FR-4.4 | P1 | UC-4.4 | Reader |
| FR-4.5 | P1 | UC-4.5 | Reader |
| FR-5.1 | P0 | UC-5.1 | Reader |
| FR-5.2 | P1 | UC-5.2 | Reader |
| FR-5.3 | P0 | UC-7.3 | Registered |
| FR-6.1 | P1 | UC-6.1 | Reader |
| FR-6.2 | P1 | UC-6.2 | Reader |
| FR-6.3 | P1 | UC-6.2 | Reader |
| FR-6.4 | P2 | UC-6.2 | Reader |
| FR-7.1 | P0 | UC-7.1 | Registered, Admin |
| FR-7.1.1 | P0 | UC-7.1 | Registered |
| FR-7.2 | P0 | UC-2.1 | Reader |
| FR-7.3 | P2 | UC-7.2 | Reader |
| FR-7.4 | P3 | N/A | Developer |
| FR-7.5 | P2 | UC-7.4 | Reader |
