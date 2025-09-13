---
description: A short overview of the project.
icon: books
cover: >-
  https://images.unsplash.com/photo-1604866830893-c13cafa515d5?crop=entropy&cs=srgb&fm=jpg&ixid=M3wxOTcwMjR8MHwxfHNlYXJjaHwxfHxib29rc3xlbnwwfHx8fDE3MzU3NzEzODh8MA&ixlib=rb-4.0.3&q=85
coverY: 0
layout:
  cover:
    visible: true
    size: full
  title:
    visible: true
  description:
    visible: true
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# What is Papyrus?

### About

Papyrus is a cross-platform application for reading and managing both physical and digital books. It aims to provide a versatile, user-friendly system that makes reading comfortable and fun, all while being accessible on Android, iOS, Web, and Desktop platforms. Papyrus features an intuitive, modern UI with extensive customization options, unifying book organization, reading, note taking, progress tracking, and personalized settings.

### Rationale

Nowadays, many solutions exist that offer some reading functionalities but often fall short on a subset of essential features or user experience. Papyrus aims to deliver a comprehensive solution that balances functionality with good user experience, covering all reading needs in a single application.

### Goals

* **Cross-platform** - manage physical and electronic books seamlessly across devices, whether it's a desktop PC, smartphone or an e-reader. No need to relearn the UI or use third-party apps.
* **Integrated reader** - read added books and customize reading experience with various look-and-feel options.
* **Flexible management** - organize physical and digital books into shelves, assign categories, attach tags, create custom filters and more.
* **Progress tracking and goals** - track reading time and books read, plan and create custom reading goals.
* **Storage flexibility** - choose between local and cloud storage options for saving digital book files, notes and annotations.
* **Data ownership** - export book lists, book files, and annotations to files in popular formats or sync to services like Google Docs, Zotero, etc.
* **Privacy first** - no default analytics and optional self-hosted synchronization.
* **Extensible** - plugin system for metadata sources, storage and reader features.
* **Developer friendly** - allow easy hosting and setting up local storage server, have a public REST API to allow for building front-ends.

### Target audience

* Readers who regularly consume digital and/or physical books and are looking for a centralized solution that allows them to manage their libraries.
* Users who want to track statistics of their reading habits and assess their progress over time.
* Users who are looking to build or reinforce their reading habits through goals and gamification.

### Core features

#### **1. Cross-platform compatibility**

* **Platforms:**
  * Android (Mobile).
  * iOS (Mobile).
  * Web (Firefox, Chrome and Safari).
  * Desktop (Windows, macOS, Linux).
* **Data synchronization:**
  * Synchronization of library data across all logged-in devices:
    * Book metadata and files (if any).
    * Categories, shelves and tags.
    * Reading progress (current page).
    * Notes and highlights.
    * Reading profiles (customized reader settings).
    * Reading goals.
    * Statistics (reading time, books read).

#### **2. Integrated book viewer**

* **Supported formats:**
  * Primary formats: EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ.
  * Potential future formats: DOCX, FB2, HTML.
* **Customization options:**
  * **Typography:**
    * Font selection - include a selection of common fonts (e.g., Arial, Times New Roman, Open Sans, Roboto) and allow users to add custom fonts from their device or via a web link.
    * Font size - adjustable with a slider or discrete steps.
    * Font weight - support for bold, regular, and potentially light/extra-bold weights.
    * Line spacing - adjustable spacing between lines, expressed as a multiplier or in pixels.
    * Paragraph spacing - adjustable spacing before and after paragraphs.
    * Text alignment - left, right, center, justified.
    * Text direction - support for left-to-right (LTR) and right-to-left (RTL) text.
  * **Colors and appearance:**
    * Background color - predefined themes (light, dark, sepia, etc.) and a color picker for custom colors.
    * Text color - customizable text color.
    * Link color - customizable color for hyperlinks.
    * Margins - adjustable top, bottom, left, and right margins.
    * Padding - adjustable padding.
  * **Layout and navigation:**
    * Page layout - single-page and two-page (landscape) views.
    * Scrolling mode - paginated and continuous scrolling modes.
    * Screen orientation - support for portrait and landscape modes on mobile devices.
    * Brightness control - in-app brightness adjustment.
    * Page turning - tap zones, swipe gestures, volume key navigation, and on-screen controls.
    * Table of contents - navigation via an interactive table of contents.
    * Go to page - ability to jump to a specific page number or percentage.
    * Progress bar - visual indicator of reading progress within the book.
  * **Advanced:**
    * Character spacing - adjustable spacing between individual characters.
    * Word spacing - adjustable spacing between words.
    * Text scaling - ability to scale the text horizontally.
    * Initial column count - for multi-column layouts, usually relevant for larger displays.
* **Reading profiles:**
  * Users can save and manage multiple named reading profiles, each containing a complete set of viewer customization settings.
  * Quick switching between profiles.
  * Option to set a default profile.
  * Profile import and export.

#### **3. Flexible book management**

* **Library organization:**
  * **Shelves:**
    * User-defined virtual shelves for grouping books (e.g., "Software engineering", "Non-fiction", "Sci-fi").
    * Shelves can have sub-shelves (nested shelves) for more fine grained categorization.
  * **Categories:**
    * Dynamic categorization of books based on metadata.
    * Predefined categories (e.g., author, genre, publisher, language, series).
    * User-defined categories.
    * Category conditions:
      * Define categories using rules or conditions (e.g., "Release Date > 2000," "Rating >= 4," "Tags contains 'Sci-Fi'").
      * Support for logical operators (AND, OR, NOT).
      * Graphical interface for defining conditions (e.g., dropdown menus, date pickers) in addition to a text-based query language.
  * **Tags:**
    * User-defined labels for books.
    * Books can have multiple tags.
    * Tags are color coded.
  * **Custom filters:**
    * Create complex filters using combinations of metadata fields, categories, tags, and reading progress.
    * Save and name custom filters for reuse.
    * Example filters: "Books by author X published after 1990 with the tag 'History' that I haven't started reading."
    * Filters are created with a query language (DSL, like in Jira) or through a graphical user interface.
    * Filters can be saved to reuse later.
* **Metadata management:**
  * **Metadata editing:**
    * Manual editing of book metadata (title, author, publisher, publication date, ISBN, description, cover image, series, etc.).
    * Batch editing of metadata for multiple books.
  * **Metadata retrieval:**
    * Automatically fetch metadata from online sources (e.g., Open Library, Google Books, Goodreads).
    * User-configurable metadata sources (manual entry).
    * Option to prioritize metadata sources (e.g., manual over online, Open Library over Goodreads).
  * **Cover image management:**
    * Automatic downloading of cover images from online sources.
    * Manual selection of cover images from local files.
    * Ability to edit and crop cover images.
* **Search:**
  * **Basic search -** search across title, author, and series.
  * **Advanced search - u**se filters, categories, and tags to narrow down search results.
  * **Full-text Search - s**earch within the content of digital books (where supported by the format).
* **Sorting:**
  * Sort books by title, author, date added, publication date, rating, etc.
  * Ascending / descending order.

#### **4. Reading goals and progress tracking**

* **Goal setting:**
  * **Time-based goals:**
    * Set goals for daily, weekly, or monthly reading time (e.g., "Read 30 minutes per day").
    * Option to set goals for specific days of the week.
  * **Book-based Goals:**
    * Set goals for the number of books to read within a specified period (e.g., "Read 12 books in 6 months").
    * Option to specify which books or categories count towards the goal.
  * **Custom goals:**
    * Allow users to define goals with flexible criteria (e.g., "Read all books by Author X by the end of the year") and allow updating goal status manually (e.g., checkbox, numeric input).
* **Progress tracking:**
  * Automatic tracking of reading time for each book.
  * Recording of pages read and current reading position.
  * Tracking of completed books (user can set this status to a book manually).
  * Visualizations of reading progress:
    * Progress bars.
    * Charts (e.g., daily/weekly reading time).
    * Statistics (e.g., average reading time per day, books read per month).
  * Tracking reading progress across devices.
* **Reminders and notifications:**
  * Optional reminders to meet reading goals.
  * Customizable notification settings.

#### **5. Storage and book import and export**

* **E-book imports:**
  * Import from local storage (files and folders) or via URL.
  * Import from cloud storage services (Google Drive, Dropbox, OneDrive, etc.).
  * Bulk import of multiple files / folders.
* **E-book export:**
  * Export entire library or selected books to local storage as an archive (e.g., ZIP).
  * Export metadata along with book files.
* **E-book conversion:**
  * Convert e-books between supported formats.
  * Batch conversion of multiple books.
  * Conversion options (e.g., font size, margins).
* **Storage options:**
  * **Local storage** - store e-book files on the user's device or in a self-hosted server.
  * **Cloud Storage** - integration with cloud storage providers.
    * Users can link their cloud storage accounts.
    * Option to store e-books in the cloud and download them for offline reading.
    * Synchronization of e-books and metadata with the cloud.
  * **Network Storage** - support for connecting to network storage locations (e.g., NAS, shared folders).
* **Physical book tracking:**
  * Manual entry of physical book details, like title, author, ISBN, edition, etc.
  * Ability to categorize and tag physical books.
  * Option to mark physical books as "Read" with a completion date.
  * Include physical books in search and filtering.
  * Option to add personal notes for physical books.

#### **6. Notes and annotations**

* **Highlighting:**
  * Highlight text with multiple colors (pre-selected or through a color picker).
  * Option to add notes to highlights.
  * Highlight styling (e.g., underline, bold).
* **Note-taking:**
  * Create notes associated with specific text selections, pages, or the entire book.
  * Support for rich text formatting in notes (bold, italics, lists) through rich-text editor or Markdown syntax.
  * Organization of notes (e.g., folders, labels).
* **Bookmarks** - create and manage bookmarks within digital books.
* **Annotation Management:**
  * View and manage all highlights, notes, and bookmarks for a book in a dedicated panel.
  * Search and filter annotations.
  * Export annotations:
    * Export to plain text, RTF, HTML, Markdown.
    * Option to include context around highlights.

#### **7. Advanced features**

* Socialization:
  * Sharing thoughts, reading progress and reviews with friends.
  * Sharing book recommendations.
* Audiobook Support:
  * Manage and play audiobooks.
  * Synchronize audiobook progress across devices.
  * Text-to-speech support.
* OPDS Support:
  * Browse and download books from online catalogs.
* AI-Powered Features:
  * Book summaries through LLMs.
  * Personalized recommendations according to library content.
  * "Smart" categorization.
* Optical character recognition (OCR):
  * For importing text from scanned documents or images.

---

## Specification overview

This specification provides comprehensive documentation for the Papyrus book management system, covering all aspects from requirements to implementation details:

### [Requirements](requirements/README.md)
- **[Functional requirements](requirements/functional-requirements.md)**: Core features and capabilities
- **[Non-functional requirements](requirements/non-functional-requirements.md)**: Performance, security, and quality attributes

### [System design](actors.md)
- **[Actors](actors.md)**: User types and their interactions with the system
- **[Use cases](use-cases.md)**: Detailed scenarios and workflows
- **[Entities](entities.md)**: Data model and relationships
- **[Database model](database-model.md)**: Complete database schema and design

### [Implementation](technologies.md)
- **[Technologies](technologies.md)**: Technology stack and architecture decisions
- **[User interface](user-interface.md)**: Design guidelines and UI specifications

This specification serves as the definitive guide for understanding, developing, and maintaining the Papyrus system.
