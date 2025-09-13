---
description: >-
  List of use cases created from the defined requirements. Each table of the use
  case is linked to system actors and one or more functional or non-functional
  requirements.
---

# Use cases

This section presents the main use cases derived from the functional requirements, organized by functional areas. Each use case includes the involved actors and references to the corresponding requirements.

## Requirements traceability

This document maintains bi-directional traceability between use cases and requirements:

- **Functional Requirements**: [Functional Requirements](requirements/functional-requirements.md)
- **Non-Functional Requirements**: [Non-Functional Requirements](requirements/non-functional-requirements.md)
- **System Actors**: [Actors](actors.md)

## Use case notation

- **UC-X.Y**: Use case identifier (section X, item Y)
- **Actors**: User types involved in the use case
- **Requirements**: Links to related functional (FR) and non-functional (NFR) requirements
- **Description**: Brief summary of the use case purpose
- **Main flow**: Step-by-step description of the normal execution path

## 1. User management use cases

### UC-1.1: Create user account
**Actors:** Anonymous user → Registered user  
**Requirements:** [FR-1.1](requirements/functional-requirements.md#1-user-management)  
**Description:** User creates a new account using email and password to access synchronization features.

**Main flow:**
1. User accesses registration form
2. User provides email address and password
3. System validates input and creates account
4. User receives confirmation
5. User can now access registered user features

### UC-1.2: Login with credentials
**Actors:** Registered user  
**Requirements:** [FR-1.2](requirements/functional-requirements.md#1-user-management)  
**Description:** User authenticates using email and password to access their account.

**Main flow:**
1. User accesses login form
2. User enters email and password
3. System validates credentials
4. User gains access to personal library and settings

### UC-1.3: Login with Google account
**Actors:** Registered user  
**Requirements:** [FR-1.3](requirements/functional-requirements.md#1-user-management)  
**Description:** User authenticates using their Google account for quick access.

**Main flow:**
1. User selects Google login option
2. User authorizes application via Google OAuth
3. System creates or links account
4. User gains access to personal library and settings

### UC-1.4: Use application offline
**Actors:** Anonymous user, Registered user  
**Requirements:** [FR-1.4](requirements/functional-requirements.md#1-user-management), [NFR-2.1](requirements/non-functional-requirements.md#2-synchronization)  
**Description:** User accesses core functionality without internet connection.

**Main flow:**
1. User opens application without internet
2. System loads local data and libraries
3. User can read, annotate, and manage local books
4. Changes are stored locally for later synchronization

### UC-1.5: Recover password
**Actors:** Registered user  
**Requirements:** [FR-1.5](requirements/functional-requirements.md#1-user-management)  
**Description:** User resets forgotten password via email recovery.

**Main flow:**
1. User requests password recovery
2. System sends recovery link to registered email
3. User follows link and creates new password
4. User can login with new credentials

## 2. Book management use cases

### UC-2.1: Import book files
**Actors:** Reader  
**Requirements:** [FR-2.6](requirements/functional-requirements.md#2-book-management), [FR-7.2](requirements/functional-requirements.md#7-storage-and-synchronization)  
**Description:** User adds new books to their library from local files.

**Main flow:**
1. User selects import option
2. User chooses book files from device storage
3. System processes and extracts metadata
4. Books are added to user's library

### UC-2.2: Convert book formats
**Actors:** Reader  
**Requirements:** [FR-2.1](requirements/functional-requirements.md#2-book-management)  
**Description:** User converts existing book to different format.

**Main flow:**
1. User selects book for conversion
2. User chooses target format (EPUB, PDF, MOBI)
3. System processes conversion
4. Converted file is available for download or use

### UC-2.3: Edit book metadata
**Actors:** Reader  
**Requirements:** [FR-2.2](requirements/functional-requirements.md#2-book-management), [FR-2.3](requirements/functional-requirements.md#2-book-management)  
**Description:** User modifies book information and metadata fields.

**Main flow:**
1. User opens book details
2. User edits metadata fields (title, author, tags, etc.)
3. User can add or remove custom metadata fields
4. Changes are saved to library

### UC-2.4: Organize books into shelves
**Actors:** Reader  
**Requirements:** [FR-2.9](requirements/functional-requirements.md#2-book-management)  
**Description:** User creates and manages book collections using shelves.

**Main flow:**
1. User creates new shelf with name and description
2. User assigns books to shelves
3. User can view and manage shelf contents
4. Books can belong to multiple shelves

### UC-2.5: Tag books
**Actors:** Reader  
**Requirements:** [FR-2.10](requirements/functional-requirements.md#2-book-management)  
**Description:** User assigns visual tags to books for organization.

**Main flow:**
1. User selects book for tagging
2. User creates or selects tags (title and color)
3. User can assign up to 10 unique tags per book
4. Tags are visible in library and search results

### UC-2.6: Search books
**Actors:** Reader  
**Requirements:** [FR-2.7](requirements/functional-requirements.md#2-book-management), [FR-2.8](requirements/functional-requirements.md#2-book-management), [FR-2.11](requirements/functional-requirements.md#2-book-management)  
**Description:** User finds books using various search criteria and filters.

**Main flow:**
1. User enters search query or creates filter
2. System searches metadata, tags, categories, and content
3. User can use complex filters and query language
4. Results are displayed with relevant matches highlighted

### UC-2.7: Export books and data
**Actors:** Reader  
**Requirements:** [FR-2.4](requirements/functional-requirements.md#2-book-management), [FR-2.5](requirements/functional-requirements.md#2-book-management)  
**Description:** User exports book files and metadata for backup or migration.

**Main flow:**
1. User selects books or entire library for export
2. User chooses export format and options
3. System creates structured export file
4. User downloads or saves export data

## 3. Reading and viewer use cases

### UC-3.1: Read books with integrated viewer
**Actors:** Reader  
**Requirements:** [FR-3.1](requirements/functional-requirements.md#3-integrated-viewer), [NFR-3.1](requirements/non-functional-requirements.md#3-platforms), [NFR-3.3](requirements/non-functional-requirements.md#3-platforms)  
**Description:** User reads books using the built-in e-book viewer.

**Main flow:**
1. User opens book from library
2. System loads book in integrated viewer
3. User navigates through pages and chapters
4. Reading progress is automatically tracked

### UC-3.2: Customize reading experience
**Actors:** Reader  
**Requirements:** [FR-3.2](requirements/functional-requirements.md#3-integrated-viewer)  
**Description:** User personalizes viewer appearance and layout.

**Main flow:**
1. User accesses viewer settings
2. User adjusts font, size, spacing, colors, layout
3. User previews changes in real-time
4. Settings are saved and applied to reading session

### UC-3.3: Manage reading profiles
**Actors:** Reader  
**Requirements:** [FR-3.3](requirements/functional-requirements.md#3-integrated-viewer)  
**Description:** User creates and manages custom reading profiles.

**Main flow:**
1. User creates new reading profile
2. User configures all visual and layout preferences
3. User saves profile with descriptive name
4. User can switch between profiles during reading

## 4. Annotations and notes use cases

### UC-4.1: Create text annotations
**Actors:** Reader  
**Requirements:** [FR-4.1](requirements/functional-requirements.md#4-annotations-and-notes)  
**Description:** User highlights and annotates text while reading.

**Main flow:**
1. User selects text in book viewer
2. User chooses highlight color and adds optional note
3. Annotation is saved and visible in text
4. User can review annotations in dedicated panel

### UC-4.2: Create book notes
**Actors:** Reader  
**Requirements:** [FR-4.2](requirements/functional-requirements.md#4-annotations-and-notes)  
**Description:** User creates free-form notes for books.

**Main flow:**
1. User opens notes panel for book
2. User creates new note with title and content
3. Note is saved and associated with book
4. User can organize and search through notes

## 5. Progress tracking use cases

### UC-5.1: Track reading progress
**Actors:** Reader  
**Requirements:** [FR-5.1](requirements/functional-requirements.md#5-progress-tracking), [FR-5.3](requirements/functional-requirements.md#5-progress-tracking)  
**Description:** System automatically tracks and displays reading statistics.

**Main flow:**
1. System monitors reading time and progress
2. System calculates statistics (books read, pages, velocity)
3. Progress is synchronized across devices
4. User can view detailed progress reports

### UC-5.2: Filter progress statistics
**Actors:** Reader  
**Requirements:** [FR-5.2](requirements/functional-requirements.md#5-progress-tracking)  
**Description:** User customizes progress views with filters and time ranges.

**Main flow:**
1. User accesses progress dashboard
2. User selects time frame (week, month, year, custom)
3. User filters by specific books or all books
4. System displays filtered statistics and charts

## 6. Goal management use cases

### UC-6.1: Create reading goals
**Actors:** Reader  
**Requirements:** [FR-6.1](requirements/functional-requirements.md#6-goal-management)  
**Description:** User sets time-based reading objectives.

**Main flow:**
1. User accesses goal creation interface
2. User selects goal template (read N books in M months)
3. User customizes goal parameters
4. System begins tracking progress toward goal

### UC-6.2: Manage goal progress
**Actors:** Reader  
**Requirements:** [FR-6.2](requirements/functional-requirements.md#6-goal-management), [FR-6.3](requirements/functional-requirements.md#6-goal-management)  
**Description:** User and system update goal progress and status.

**Main flow:**
1. System automatically updates goal progress based on reading activity
2. User can manually adjust progress if needed
3. System displays completion status and remaining time
4. User receives notifications about goal progress

## 7. Storage and synchronization use cases

### UC-7.1: Configure storage options
**Actors:** Registered user, System administrator  
**Requirements:** [FR-7.1](requirements/functional-requirements.md#7-storage-and-synchronization), [NFR-1.2](requirements/non-functional-requirements.md#1-storage)  
**Description:** User selects and configures preferred storage backend.

**Main flow:**
1. User accesses storage settings
2. User chooses between local, self-hosted, or cloud storage
3. User provides necessary credentials and configuration
4. System validates and activates storage connection

### UC-7.2: Process scanned documents
**Actors:** Reader  
**Requirements:** [FR-7.3](requirements/functional-requirements.md#7-storage-and-synchronization)  
**Description:** System applies OCR to scanned book files for text extraction.

**Main flow:**
1. User uploads scanned document (PDF, images)
2. System detects that OCR processing is needed
3. System applies OCR to extract text content
4. Processed book becomes searchable and accessible

### UC-7.3: Synchronize data across devices
**Actors:** Registered user  
**Requirements:** [FR-5.3](requirements/functional-requirements.md#5-progress-tracking), [NFR-2.1](requirements/non-functional-requirements.md#2-synchronization), [NFR-2.2](requirements/non-functional-requirements.md#2-synchronization)  
**Description:** System keeps user data consistent across multiple devices.

**Main flow:**
1. User makes changes on one device
2. System queues changes for synchronization
3. When online, system syncs changes to server
4. Other devices receive and apply synchronized changes
5. Offline changes are marked with appropriate indicators
