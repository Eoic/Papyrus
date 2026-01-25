# Use Cases

This section presents the main use cases derived from the functional requirements. Each use case includes actors, requirements traceability, detailed flows, and alternative scenarios.

## Use Case Notation

| Element | Description |
|---------|-------------|
| **UC-X.Y** | Use case identifier (section X, item Y) |
| **Actors** | User types involved |
| **Priority** | P0-P3 (matches requirement priority) |
| **Requirements** | Links to FR and NFR |
| **Preconditions** | State required before use case |
| **Main Flow** | Primary success scenario |
| **Alternative Flows** | Variations and edge cases |
| **Postconditions** | State after successful completion |

---

## 1. User Management Use Cases

### UC-1.1: Create User Account

**Actors:** Anonymous User → Registered User
**Priority:** P0
**Requirements:** [FR-1.1](requirements/functional-requirements.md#fr-11-account-registration)

**Description:** User creates a new account to access synchronization and cloud features.

**Preconditions:**

- User is not logged in
- User has valid email address

**Main Flow:**

1. User navigates to registration screen
2. User enters email address and password
3. System validates email format and uniqueness
4. System validates password strength (8+ chars, mixed case, number)
5. System creates account in inactive state
6. System sends verification email
7. User clicks verification link
8. System activates account
9. User is redirected to login screen

**Alternative Flows:**

*A1: Email already registered*

- At step 3, if email exists:
  - System displays "Email already registered" error
  - User can choose to log in or recover password

*A2: Weak password*

- At step 4, if password is too weak:
  - System displays password requirements
  - User must enter a stronger password

*A3: Verification link expired*

- At step 7, if link expired (24 hours):
  - System displays expiration message
  - User can request new verification email

**Postconditions:**

- New user account exists
- User can log in with credentials

---

### UC-1.2: Login with Credentials

**Actors:** Registered User
**Priority:** P0
**Requirements:** [FR-1.2](requirements/functional-requirements.md#fr-12-emailpassword-login)

**Description:** User authenticates using email and password.

**Preconditions:**

- User has registered account
- Account is verified and active

**Main Flow:**

1. User navigates to login screen
2. User enters email and password
3. System validates credentials
4. System creates session token
5. User is redirected to library

**Alternative Flows:**

*A1: Invalid credentials*

- At step 3, if credentials invalid:
  - System displays "Invalid email or password"
  - Failed attempt is logged
  - After 5 failures, temporary lockout (15 minutes)

*A2: Account not verified*

- At step 3, if account not verified:
  - System prompts to resend verification email

*A3: Account disabled*

- At step 3, if account disabled:
  - System displays account disabled message
  - User is directed to support contact

**Postconditions:**

- User is authenticated
- Session token is stored on device
- User has access to their library

---

### UC-1.3: Login with Google Account

**Actors:** Registered User
**Priority:** P1
**Requirements:** [FR-1.3](requirements/functional-requirements.md#fr-13-oauth-login-google)

**Description:** User authenticates via Google OAuth 2.0.

**Preconditions:**

- User has Google account
- Device has internet connection

**Main Flow:**

1. User selects "Sign in with Google"
2. System redirects to Google OAuth
3. User authorizes application
4. Google returns authorization code
5. System exchanges code for user info
6. If new user, system creates account
7. System creates session token
8. User is redirected to library

**Alternative Flows:**

*A1: User denies authorization*

- At step 3, if user denies:
  - System returns to login screen
  - Message: "Google sign-in cancelled"

*A2: Link to existing account*

- At step 6, if email matches existing account:
  - System prompts to link accounts
  - User confirms linking

**Postconditions:**

- User is authenticated
- Google account linked to Papyrus account

---

### UC-1.4: Use Application Offline

**Actors:** Anonymous User, Registered User
**Priority:** P0
**Requirements:** [FR-1.4](requirements/functional-requirements.md#fr-14-offline-mode), [NFR-2.1](requirements/non-functional-requirements.md#nfr-21-onlineoffline-parity)

**Description:** User accesses application without internet connection.

**Preconditions:**

- Application is installed on device
- For registered users: at least one previous online session

**Main Flow:**

1. User opens application without internet
2. System detects offline state
3. System loads local data
4. User accesses library and books
5. User can read, annotate, organize
6. Changes are stored locally
7. Offline indicator is displayed

**Alternative Flows:**

*A1: First launch (Anonymous)*

- User can immediately use all local features
- No account required

*A2: First launch (Registered, never synced)*

- System shows "Connect to sync your data"
- User can continue with empty library

*A3: Sync when online*

- When internet restored:
  - System begins background sync
  - Pending changes indicator updates

**Postconditions:**

- User can use reading and management features
- Changes are queued for sync

---

### UC-1.5: Recover Password

**Actors:** Registered User
**Priority:** P1
**Requirements:** [FR-1.5](requirements/functional-requirements.md#fr-15-password-recovery)

**Description:** User resets forgotten password via email.

**Preconditions:**

- User has registered account
- User has access to registered email

**Main Flow:**

1. User clicks "Forgot password"
2. User enters registered email
3. System sends recovery email with link
4. User clicks link (valid 24 hours)
5. User enters new password
6. System validates password strength
7. System updates password
8. All existing sessions are invalidated
9. User is redirected to login

**Alternative Flows:**

*A1: Email not found*

- At step 3, system still shows success message (security)
- No email sent if account doesn't exist

*A2: Link expired*

- At step 4, if link expired:
  - System displays expiration message
  - User can request new link

**Postconditions:**

- Password is updated
- User must log in with new password

---

### UC-1.6: Delete Account

**Actors:** Registered User
**Priority:** P1
**Requirements:** [FR-1.6](requirements/functional-requirements.md#fr-16-account-deletion)

**Description:** User permanently deletes their account and all data.

**Preconditions:**

- User is logged in
- User understands consequences

**Main Flow:**

1. User navigates to account settings
2. User selects "Delete account"
3. System displays warning about data loss
4. User confirms by entering password
5. System marks account for deletion
6. System logs user out
7. Account and data deleted within 30 days

**Alternative Flows:**

*A1: Export data first*

- Before step 4, user can export all data
- See UC-2.7 for export process

*A2: Cancel deletion*

- Within 7 days, user can log in to cancel
- Account is restored to active state

**Postconditions:**

- Account is deleted
- User data removed from server
- Local data remains on device

---

## 2. Book Management Use Cases

### UC-2.1: Import Book Files

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-2.6](requirements/functional-requirements.md#fr-26-book-import), [FR-7.2](requirements/functional-requirements.md#fr-72-file-upload)

**Description:** User adds books to library from files.

**Preconditions:**

- User has book files in supported format

**Main Flow:**

1. User selects "Add books"
2. User chooses import source (device, cloud, URL)
3. User selects files
4. System uploads/imports files
5. System extracts metadata from files
6. System checks for duplicates
7. Books are added to library
8. User receives confirmation

**Alternative Flows:**

*A1: Unsupported format*

- System displays format error
- Lists supported formats

*A2: Duplicate detected*

- System shows existing book
- User can: skip, replace, keep both

*A3: Bulk import*

- User selects folder
- System imports all supported files
- Progress shown for large imports

*A4: Import from URL*

- User enters URL
- System downloads and imports

**Postconditions:**

- Books are in user's library
- Metadata is populated

---

### UC-2.2: Convert Book Formats

**Actors:** Reader
**Priority:** P2
**Requirements:** [FR-2.1](requirements/functional-requirements.md#fr-21-format-conversion)

**Description:** User converts book to different format.

**Preconditions:**

- Book exists in library
- Source format supports conversion

**Main Flow:**

1. User opens book details
2. User selects "Convert format"
3. User chooses target format
4. User sets conversion options (optional)
5. System processes conversion
6. Converted file is added to library
7. Original file is preserved

**Alternative Flows:**

*A1: Conversion fails*

- System shows error details
- User can retry with different options

*A2: Large file*

- Progress indicator shown
- Conversion runs in background
- Notification when complete

**Postconditions:**

- New file in target format exists
- Original file unchanged

---

### UC-2.3: Edit Book Metadata

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-2.2](requirements/functional-requirements.md#fr-22-manual-metadata-editing), [FR-2.13](requirements/functional-requirements.md#fr-213-metadata-fetching)

**Description:** User modifies book information.

**Preconditions:**

- Book exists in library

**Main Flow:**

1. User opens book details
2. User selects "Edit"
3. User modifies metadata fields
4. User saves changes
5. System validates and stores changes

**Alternative Flows:**

*A1: Fetch metadata online*

- User clicks "Fetch metadata"
- System searches online sources
- User reviews and selects matches
- Selected metadata is applied

*A2: Edit cover image*

- User can upload new cover
- User can crop/adjust cover
- User can fetch cover online

**Postconditions:**

- Book metadata is updated

---

### UC-2.4: Organize Books into Shelves

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-2.9](requirements/functional-requirements.md#fr-29-shelf-organization)

**Description:** User creates and manages book collections.

**Preconditions:**

- User has books in library

**Main Flow:**

1. User navigates to Shelves
2. User creates new shelf (name, description, color)
3. User adds books to shelf
4. Shelf is saved

**Alternative Flows:**

*A1: Add from library view*

- User long-presses book
- User selects "Add to shelf"
- User chooses shelf(s)

*A2: Create nested shelf*

- User creates shelf within existing shelf
- Hierarchy is maintained

*A3: Drag and drop*

- User drags book to shelf
- Book is added to shelf

**Postconditions:**

- Books are organized in shelves

---

### UC-2.5: Tag Books

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-2.10](requirements/functional-requirements.md#fr-210-book-tagging)

**Description:** User assigns colored labels to books.

**Preconditions:**

- User has books in library

**Main Flow:**

1. User opens book details or context menu
2. User selects "Tags"
3. User creates or selects tags
4. Tags are applied to book

**Alternative Flows:**

*A1: Create new tag*

- User enters tag name
- User selects color
- Tag is created and applied

*A2: Batch tagging*

- User selects multiple books
- User applies tags to all

**Postconditions:**

- Books have assigned tags
- Tags visible in library view

---

### UC-2.6: Search Books

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-2.7](requirements/functional-requirements.md#fr-27-full-text-search), [FR-2.8](requirements/functional-requirements.md#fr-28-advanced-search), [FR-2.11](requirements/functional-requirements.md#fr-211-query-language-filters)

**Description:** User finds books using search and filters.

**Preconditions:**

- User has books in library

**Main Flow:**

1. User opens search
2. User enters query
3. System searches metadata
4. Results are displayed
5. User can filter/sort results

**Alternative Flows:**

*A1: Full-text search*

- User searches book contents
- Results show matched text with context

*A2: Advanced filters*

- User uses filter panel
- Multiple criteria combined

*A3: Query language*

- User types query like `author:"Name" AND year:>2000`
- System parses and executes

*A4: Save search*

- User saves search as filter
- Filter available for reuse

**Postconditions:**

- Matching books are displayed

---

### UC-2.7: Export Books and Data

**Actors:** Reader
**Priority:** P0/P1
**Requirements:** [FR-2.4](requirements/functional-requirements.md#fr-24-book-file-export), [FR-2.5](requirements/functional-requirements.md#fr-25-library-data-export)

**Description:** User exports library data for backup or migration.

**Preconditions:**

- User has books in library

**Main Flow:**

1. User navigates to Export
2. User selects what to export (books, metadata, annotations)
3. User chooses format (ZIP, JSON, CSV)
4. System creates export file
5. User downloads export

**Alternative Flows:**

*A1: Selective export*

- User selects specific books
- Only selected items exported

*A2: Export to cloud*

- User chooses cloud destination
- File uploaded directly

**Postconditions:**

- Export file is created
- User has backup of data

---

### UC-2.8: Scan ISBN Barcode

**Actors:** Reader
**Priority:** P2
**Requirements:** [FR-2.12](requirements/functional-requirements.md#fr-212-isbn-barcode-scanning)

**Description:** User adds physical book by scanning barcode.

**Preconditions:**

- Device has camera
- Physical book has ISBN barcode

**Main Flow:**

1. User selects "Scan ISBN"
2. Camera opens
3. User scans barcode
4. System decodes ISBN
5. System fetches metadata
6. User reviews and confirms
7. Book is added as physical

**Alternative Flows:**

*A1: Manual ISBN entry*

- If scan fails, user types ISBN
- System fetches metadata

*A2: No metadata found*

- System shows "Not found"
- User can enter details manually

**Postconditions:**

- Physical book added to library

---

### UC-2.9: Track Physical Book

**Actors:** Reader
**Priority:** P1
**Requirements:** [FR-2.14](requirements/functional-requirements.md#fr-214-physical-book-tracking)

**Description:** User manages physical books in library.

**Preconditions:**

- None

**Main Flow:**

1. User selects "Add physical book"
2. User enters book details
3. User sets reading status
4. User can add location (e.g., "Shelf 3")
5. Book is added to library

**Alternative Flows:**

*A1: Mark as lent*

- User marks book as lent
- User enters borrower info
- Reminder can be set

**Postconditions:**

- Physical book tracked in library

---

## 3. Reading and Viewer Use Cases

### UC-3.1: Read Books with Integrated Viewer

**Actors:** Reader, E-ink Reader
**Priority:** P0
**Requirements:** [FR-3.1](requirements/functional-requirements.md#fr-31-e-book-reading)

**Description:** User reads e-books in the viewer.

**Preconditions:**

- Book exists in library
- Book format is supported

**Main Flow:**

1. User opens book from library
2. System loads book in viewer
3. System restores last position
4. User reads and navigates
5. System saves progress automatically

**Alternative Flows:**

*A1: Navigate via TOC*

- User opens table of contents
- User selects chapter

*A2: Go to page/position*

- User enters page number or percentage
- System jumps to position

*A3: E-ink mode*

- System detects e-ink display
- UI adapts (no animations, high contrast)

**Postconditions:**

- Reading position is saved
- Time tracked for statistics

---

### UC-3.2: Customize Reading Experience

**Actors:** Reader, E-ink Reader
**Priority:** P0
**Requirements:** [FR-3.2](requirements/functional-requirements.md#fr-32-viewer-customization)

**Description:** User personalizes viewer appearance.

**Preconditions:**

- Book is open in viewer

**Main Flow:**

1. User opens reader settings
2. User adjusts typography (font, size, spacing)
3. User sets colors (background, text)
4. User configures layout (margins, mode)
5. Changes apply immediately
6. Settings are saved

**Alternative Flows:**

*A1: Quick theme switch*

- User taps theme button
- Cycles through presets

*A2: E-ink optimized*

- User enables e-ink mode
- High contrast, no animations

**Postconditions:**

- Reader customized to preference

---

### UC-3.3: Manage Reading Profiles

**Actors:** Reader, E-ink Reader
**Priority:** P1
**Requirements:** [FR-3.3](requirements/functional-requirements.md#fr-33-reading-profiles)

**Description:** User saves and switches reader configurations.

**Preconditions:**

- Reader settings have been customized

**Main Flow:**

1. User opens profile management
2. User creates new profile
3. User names profile (e.g., "Night reading")
4. Current settings saved to profile
5. User can switch between profiles

**Alternative Flows:**

*A1: Set default profile*

- User marks profile as default
- Applied to new books

*A2: Export/import profiles*

- User exports profile to file
- Can import on other devices

**Postconditions:**

- Profiles saved for quick switching

---

### UC-3.4: Manage Bookmarks

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-3.4](requirements/functional-requirements.md#fr-34-bookmarks)

**Description:** User creates and uses bookmarks.

**Preconditions:**

- Book is open in viewer

**Main Flow:**

1. User taps bookmark button
2. Bookmark created at current position
3. User can add note (optional)
4. Bookmark saved

**Alternative Flows:**

*A1: View all bookmarks*

- User opens bookmark panel
- Sees list with positions
- Taps to navigate

*A2: Delete bookmark*

- User swipes or long-press
- Confirms deletion

**Postconditions:**

- Bookmark saved and accessible

---

## 4. Annotations and Notes Use Cases

### UC-4.1: Create Text Annotations

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-4.1](requirements/functional-requirements.md#fr-41-text-highlighting)

**Description:** User highlights text while reading.

**Preconditions:**

- Book is open in viewer

**Main Flow:**

1. User selects text
2. Context menu appears
3. User chooses highlight color
4. User adds note (optional)
5. Annotation saved

**Alternative Flows:**

*A1: Quick highlight*

- User selects and taps color
- Instant highlight without menu

**Postconditions:**

- Text is highlighted
- Annotation appears in panel

---

### UC-4.2: Create Book Notes

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-4.2](requirements/functional-requirements.md#fr-42-book-notes)

**Description:** User creates free-form notes for books.

**Preconditions:**

- Book exists in library

**Main Flow:**

1. User opens book notes
2. User creates new note
3. User enters title and content
4. Note saved

**Alternative Flows:**

*A1: Rich text editing*

- User uses formatting (bold, lists)
- Markdown syntax supported

**Postconditions:**

- Note attached to book

---

### UC-4.3: Manage Annotations

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-4.3](requirements/functional-requirements.md#fr-43-annotation-editing)

**Description:** User edits or deletes annotations.

**Preconditions:**

- Annotations exist for book

**Main Flow:**

1. User opens annotation panel
2. User selects annotation
3. User edits (color, note) or deletes
4. Changes saved

**Postconditions:**

- Annotations updated

---

### UC-4.4: Export Annotations

**Actors:** Reader
**Priority:** P1
**Requirements:** [FR-4.4](requirements/functional-requirements.md#fr-44-annotation-export)

**Description:** User exports annotations to file.

**Preconditions:**

- Book has annotations

**Main Flow:**

1. User opens export options
2. User selects format (Markdown, PDF, TXT)
3. User configures options (include context, metadata)
4. System generates export
5. User downloads file

**Postconditions:**

- Annotations exported to file

---

### UC-4.5: Search Annotations

**Actors:** Reader
**Priority:** P1
**Requirements:** [FR-4.5](requirements/functional-requirements.md#fr-45-annotation-search)

**Description:** User searches through annotations.

**Preconditions:**

- User has annotations

**Main Flow:**

1. User opens annotation search
2. User enters search query
3. Results from all books shown
4. User can filter by book, color, date

**Postconditions:**

- Matching annotations displayed

---

## 5. Progress Tracking Use Cases

### UC-5.1: Track Reading Progress

**Actors:** Reader
**Priority:** P0
**Requirements:** [FR-5.1](requirements/functional-requirements.md#fr-51-reading-statistics)

**Description:** System tracks and displays reading activity.

**Preconditions:**

- User reads books in viewer

**Main Flow:**

1. System monitors reading sessions
2. System records time and pages
3. User views progress dashboard
4. Statistics displayed (charts, metrics)

**Postconditions:**

- Reading activity is tracked
- Statistics available

---

### UC-5.2: Filter Progress Statistics

**Actors:** Reader
**Priority:** P1
**Requirements:** [FR-5.2](requirements/functional-requirements.md#fr-52-statistics-filtering)

**Description:** User customizes statistics view.

**Preconditions:**

- Reading data exists

**Main Flow:**

1. User opens statistics
2. User selects time range
3. User filters by books/shelves
4. Filtered results displayed

**Postconditions:**

- Statistics filtered to selection

---

## 6. Goal Management Use Cases

### UC-6.1: Create Reading Goals

**Actors:** Reader
**Priority:** P1
**Requirements:** [FR-6.1](requirements/functional-requirements.md#fr-61-reading-goals)

**Description:** User sets reading objectives.

**Preconditions:**

- User wants to track goals

**Main Flow:**

1. User opens Goals
2. User creates new goal
3. User selects type (books, pages, time)
4. User sets target and period
5. Goal is saved and tracking begins

**Postconditions:**

- Goal is active
- Progress tracked automatically

---

### UC-6.2: Manage Goal Progress

**Actors:** Reader
**Priority:** P1
**Requirements:** [FR-6.2](requirements/functional-requirements.md#fr-62-manual-goal-updates), [FR-6.3](requirements/functional-requirements.md#fr-63-automatic-goal-progress)

**Description:** User and system update goal progress.

**Preconditions:**

- Active goal exists

**Main Flow:**

1. System updates progress automatically
2. User can manually adjust if needed
3. Progress displayed with visualizations
4. Notifications sent at milestones

**Postconditions:**

- Goal progress is current

---

## 7. Storage and Synchronization Use Cases

### UC-7.1: Configure Storage Options

**Actors:** Registered User, System Administrator
**Priority:** P0
**Requirements:** [FR-7.1](requirements/functional-requirements.md#fr-71-file-storage-backend-selection), [FR-7.1.1](requirements/functional-requirements.md#fr-711-metadata-server-configuration)

**Description:** User configures metadata server connection and file storage backend(s) for synchronization and book storage.

**Preconditions:**

- Application is installed
- Internet connection available (for server configuration)

**Main Flow (Metadata Server):**

1. User opens Settings > Sync & Storage
2. User selects metadata server option:
   - Official hosted server (default)
   - Self-hosted server (enter URL)
3. User logs in or registers on metadata server
4. System validates connection
5. Sync capabilities are enabled

**Main Flow (File Storage Backend):**

1. User opens Settings > Storage > File Storage
2. User clicks "Add Storage Backend"
3. User selects backend type (Google Drive, WebDAV, MinIO, etc.)
4. User configures credentials:
   - OAuth flow for Google/OneDrive/Dropbox
   - URL + credentials for WebDAV/MinIO
5. System validates connection and shows storage info
6. User sets backend as primary (optional)
7. Backend is available for file storage

**Alternative Flows:**

*A1: Cloud storage OAuth (Google Drive, OneDrive, Dropbox)*

1. User clicks "Connect with [Provider]"
2. OAuth popup opens
3. User authorizes Papyrus access
4. System stores tokens securely
5. Storage folder is created automatically

*A2: Self-hosted metadata server*

1. User enters server URL (e.g., <https://papyrus.home.local>)
2. System tests connection and retrieves server info
3. User registers or logs in on self-hosted server
4. Connection is established

*A3: WebDAV server (Nextcloud, etc.)*

1. User enters WebDAV URL
2. User enters username and password
3. System tests connection
4. User specifies folder path

*A4: MinIO/S3-compatible storage*

1. User enters endpoint URL
2. User enters bucket name
3. User enters access key and secret key
4. System tests connection

*A5: Local-only mode (no sync)*

1. User skips metadata server setup
2. User uses only local storage
3. All data stored on device only
4. No cross-device sync available

*A6: Dedicated Papyrus server for files*

1. User selects "Papyrus Server" as file storage
2. Files stored on same server as metadata
3. Single server handles everything

**Postconditions:**

- Metadata server connected (optional)
- File storage backend(s) configured
- Cross-device sync enabled (if metadata server connected)
- Books can be uploaded to selected storage

See [Server Architecture](server-architecture.md) for technical details.

---

### UC-7.2: Process Scanned Documents

**Actors:** Reader
**Priority:** P2
**Requirements:** [FR-7.3](requirements/functional-requirements.md#fr-73-ocr-processing)

**Description:** System applies OCR to scanned books.

**Preconditions:**

- PDF with scanned images uploaded

**Main Flow:**

1. System detects scanned content
2. System queues OCR processing
3. OCR runs in background
4. Text extracted and indexed
5. User notified of completion

**Postconditions:**

- Book content is searchable

---

### UC-7.3: Synchronize Data Across Devices

**Actors:** Registered User
**Priority:** P0
**Requirements:** [FR-5.3](requirements/functional-requirements.md#fr-53-cross-device-sync), [NFR-2.1](requirements/non-functional-requirements.md#nfr-21-onlineoffline-parity)

**Description:** System keeps metadata, reading progress, and annotations consistent across devices via the metadata server.

**Preconditions:**

- User logged into metadata server on multiple devices
- At least one device has internet connection

**Main Flow:**

1. User makes changes on device A (e.g., reads pages, adds annotation)
2. Changes are saved locally immediately
3. Changes are queued in sync queue
4. When online, client pushes changes to metadata server
5. Metadata server records changes with timestamps
6. Device B polls or receives push notification
7. Device B fetches changes from metadata server
8. Device B applies changes to local storage
9. UI updates to reflect synchronized state

**Synchronized Data:**

- Reading position (page, chapter, percentage)
- Annotations (highlights, notes)
- Bookmarks
- Book metadata edits
- Shelf and tag assignments
- Reading goals and progress
- Reading session statistics

**Alternative Flows:**

*A1: Conflict detected (same book, both devices)*

1. System compares timestamps
2. For reading position: latest timestamp wins
3. For metadata: merge non-conflicting fields, latest wins for conflicts
4. For annotations: keep both (no conflict, additive)
5. User notified of resolved conflicts (optional)

*A2: Offline changes accumulated*

1. User works offline on device A
2. Multiple changes queued locally
3. When device comes online, all queued changes sync
4. Server processes changes in timestamp order

*A3: Book file sync*

1. If book exists on server but not locally
2. User can download for offline access
3. File downloaded from configured storage backend
4. Local reading position preserved after download

*A4: Metadata server unavailable*

1. Client detects connection failure
2. UI shows "Offline" or "Sync unavailable" indicator
3. All changes continue to be saved locally
4. Sync resumes automatically when server available

**Postconditions:**

- All devices have consistent metadata
- Reading position synchronized
- Annotations available on all devices

See [Server Architecture](server-architecture.md#synchronization-architecture) for sync details.

---

### UC-7.4: Browse OPDS Catalog

**Actors:** Reader
**Priority:** P2
**Requirements:** [FR-7.5](requirements/functional-requirements.md#fr-75-opds-catalog-support)

**Description:** User downloads books from online catalogs.

**Preconditions:**

- OPDS catalog URL known
- Internet connection available

**Main Flow:**

1. User adds OPDS catalog URL
2. System loads catalog
3. User browses or searches
4. User selects book to download
5. Book added to library

**Alternative Flows:**

*A1: Protected catalog*

- User enters credentials
- System authenticates

**Postconditions:**

- Book downloaded to library

---

## Use Case Summary

### By Priority

| Priority | Use Cases | Description |
|----------|-----------|-------------|
| **P0** | UC-1.1, UC-1.2, UC-1.4, UC-2.1, UC-2.3, UC-2.4, UC-2.5, UC-2.6, UC-2.7, UC-3.1, UC-3.2, UC-3.4, UC-4.1, UC-4.2, UC-4.3, UC-5.1, UC-7.1, UC-7.3 | MVP critical |
| **P1** | UC-1.3, UC-1.5, UC-1.6, UC-2.9, UC-3.3, UC-4.4, UC-4.5, UC-5.2, UC-6.1, UC-6.2 | MVP high priority |
| **P2** | UC-2.2, UC-2.8, UC-7.2, UC-7.4 | Post-MVP |

### By Actor

| Actor | Primary Use Cases |
|-------|-------------------|
| Anonymous User | UC-1.4 |
| Registered User | UC-1.1, UC-1.2, UC-1.3, UC-1.5, UC-1.6, UC-7.1, UC-7.3 |
| Reader | UC-2.x, UC-3.x, UC-4.x, UC-5.x, UC-6.x |
| E-ink Reader | UC-3.1, UC-3.2, UC-3.3 |
| System Administrator | UC-7.1 |
