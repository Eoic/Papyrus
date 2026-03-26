# EPUB Web Import — Design Spec

## Problem

The "Import digital books" button in `AddBookChoiceSheet` is unimplemented. On web, processing EPUB files (ZIP decompression, XML parsing, image extraction) on the main thread blocks rendering and freezes the UI. Dart isolates are not available on web, so an alternative is needed.

## Solution

A JavaScript Web Worker handles all EPUB processing and OPFS storage off the main thread. A Dart service class communicates with the worker via `package:web` typed bindings, exposing a clean async API to the rest of the app.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Flutter/Dart (main thread)                         │
│                                                     │
│  ImportBookSheet ──► BookImportService               │
│       (UI)            │                             │
│                       │ package:web Worker API      │
│                       ▼                             │
│  ─ ─ ─ ─ ─ ─ ─ ─ postMessage ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│                       │                             │
│  ┌────────────────────▼────────────────────────┐    │
│  │  Web Worker (book_worker.js)                │    │
│  │                                             │    │
│  │  EpubProcessor                              │    │
│  │    ├─ unzip (zip.js or manual ZIP parsing)  │    │
│  │    ├─ parse container.xml → find OPF        │    │
│  │    ├─ parse OPF → metadata + cover ref      │    │
│  │    ├─ extract cover image bytes             │    │
│  │    └─ compute SHA-256 hash                  │    │
│  │                                             │    │
│  │  OpfsStorage                                │    │
│  │    ├─ write(bookId, blob)                   │    │
│  │    ├─ read(bookId) → blob                   │    │
│  │    └─ delete(bookId)                        │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Extensibility

The worker dispatches on a `format` field in the incoming message. Adding a new format (PDF, MOBI) means adding a new processor function in the worker — the Dart service interface and UI remain unchanged.

```js
// Worker message dispatch
switch (msg.format) {
  case 'epub': result = await processEpub(msg.fileData); break;
  case 'pdf':  result = await processPdf(msg.fileData);  break; // future
}
```

## Components

### 1. JS Web Worker — `web/book_worker.js`

Runs off the main thread. Handles three message types:

**Messages (Dart → Worker):**

| type | fields | description |
|------|--------|-------------|
| `process` | `format`, `bookId`, `fileData` (ArrayBuffer) | Extract metadata, store file in OPFS |
| `delete` | `bookId` | Remove file from OPFS |
| `getFile` | `bookId` | Retrieve file bytes from OPFS |

**Responses (Worker → Dart):**

| type | fields | description |
|------|--------|-------------|
| `success` | `action`, `bookId`, `metadata`, `coverData`, `fileSize`, `fileHash` | Processing complete |
| `error` | `message` | Processing failed |

**EPUB processing steps:**
1. Read ZIP central directory from ArrayBuffer
2. Find `META-INF/container.xml` → extract rootfile path
3. Parse OPF (`.opf`) file → extract `<dc:title>`, `<dc:creator>`, `<dc:publisher>`, `<dc:description>`, `<dc:language>`, `<dc:identifier>` (ISBN), `<dc:date>`
4. Find cover image: check `<meta name="cover" content="...">` → resolve from manifest, or fall back to first `<item media-type="image/...">` with `properties="cover-image"`
5. Extract cover image bytes from ZIP
6. Compute SHA-256 of the full file using Web Crypto API
7. Estimate page count: sum uncompressed sizes of all `application/xhtml+xml` items, divide by ~2000 bytes/page
8. Store original EPUB blob in OPFS at `books/<bookId>.epub`
9. Return metadata + cover bytes to Dart via `postMessage` (transfer ArrayBuffers for zero-copy)

**ZIP parsing:** Implement minimal ZIP central directory parsing in JS (no external library needed — EPUB ZIPs are standard and unencrypted). If this proves insufficient, add `zip.js` as a vendored dependency.

### 2. Dart Service — `lib/services/book_import_service.dart`

```dart
class BookImportResult {
  final String bookId;
  final String title;
  final String? subtitle;
  final String author;
  final List<String> coAuthors;
  final String? publisher;
  final String? description;
  final String? language;
  final String? isbn;
  final int? pageCount;
  final Uint8List? coverImage;
  final String? coverMimeType;
  final int fileSize;
  final String fileHash;
}

class BookImportService {
  Worker? _worker;

  /// Lazily creates and returns the Web Worker.
  Worker _getWorker();

  /// Import a book file: extract metadata, store in OPFS.
  /// Format is inferred from filename extension.
  /// Currently supports: .epub
  Future<BookImportResult> importBook(Uint8List bytes, String filename);

  /// Delete a book's stored file from OPFS.
  Future<void> deleteBookFile(String bookId);

  /// Retrieve a book's file from OPFS.
  Future<Uint8List?> getBookFile(String bookId);

  /// Clean up the worker when no longer needed.
  void dispose();
}
```

**Implementation details:**
- Uses `package:web` for typed `Worker` construction and `MessageEvent` handling
- Uses `dart:js_interop` for `JSObject`/`JSArrayBuffer` conversions
- Each call creates a `Completer`, sends a message, and completes on the matching response
- Worker is created lazily on first call and reused
- Book ID generated Dart-side before sending to worker: `'book-${DateTime.now().millisecondsSinceEpoch}'`

**Platform branching:** On web (`kIsWeb`), uses the Web Worker. On native (future), can delegate to `Isolate.run()` with `FileMetadataService` + local file storage. For now, native is not implemented and the service throws `UnsupportedError` on non-web platforms.

### 3. Import UI — `lib/widgets/add_book/import_book_sheet.dart`

Bottom sheet on mobile, dialog on desktop (same pattern as `AddBookChoiceSheet`).

**States:**
1. **Idle** — "Select an EPUB file" button
2. **Processing** — Circular progress indicator + filename
3. **Success** — Shows extracted metadata (cover, title, author) with "Add to library" button
4. **Error** — Error message with "Try again" button

**On success:** Creates a `Book` object from `BookImportResult`, calls `dataStore.addBook(book)`, closes the sheet.

**File picking:** Uses `file_picker` package with `allowedExtensions: ['epub']` and `type: FileType.custom`.

### 4. Wiring — `lib/widgets/add_book/add_book_choice_sheet.dart`

Change the "Import digital books" `onTap` from `() {}` to opening `ImportBookSheet`.

## OPFS Storage Structure

```
opfs-root/
  books/
    book-1711234567890.epub
    book-1711234567891.epub
```

Flat directory. One file per book. File name matches the book ID.

## Error Cases

| Error | Source | User-facing message |
|-------|--------|---------------------|
| Not a ZIP file | Worker | "This file doesn't appear to be a valid EPUB" |
| No OPF found | Worker | "Could not read EPUB metadata" |
| Missing title | Worker | Falls back to filename as title |
| OPFS write failure | Worker | "Could not save the book file" |
| Worker crash | Dart service | "Something went wrong. Please try again" |
| File picker cancelled | UI | No action (return to idle) |

## Files to Create

| File | Type |
|------|------|
| `web/book_worker.js` | New — Web Worker script |
| `lib/services/book_import_service.dart` | New — Dart service |
| `lib/widgets/add_book/import_book_sheet.dart` | New — Import UI |

## Files to Modify

| File | Change |
|------|--------|
| `lib/widgets/add_book/add_book_choice_sheet.dart` | Wire "Import digital books" to `ImportBookSheet` |

## Verification

1. `dart analyze` — no errors on new/modified Dart files
2. `flutter test` — existing tests still pass
3. Manual test on web: `flutter run -d chrome`, click "+ Add book" → "Import digital books" → select an EPUB → verify metadata is extracted, cover is shown, book appears in library
4. Verify OPFS storage: use Chrome DevTools Application tab → Storage → OPFS to confirm the file is stored
5. Verify main thread is not blocked: interact with the UI (scroll, navigate) while the worker processes a file
