# EPUB Web Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable importing EPUB files on the web without blocking the render thread, storing files offline in OPFS.

**Architecture:** A JS Web Worker (`web/book_worker.js`) handles EPUB ZIP parsing, metadata extraction, cover extraction, SHA-256 hashing, and OPFS file storage. A Dart service (`BookImportService`) communicates with the worker via `package:web` typed bindings. An import UI sheet lets users pick a file, shows progress, previews extracted metadata, and adds the book to the library.

**Tech Stack:** JavaScript (Web Worker, ZIP parsing, OPFS API, Web Crypto), Dart (`package:web`, `dart:js_interop`, `file_picker`), Flutter (Material 3 widgets)

**Design spec:** `docs/superpowers/specs/2026-03-27-epub-web-import-design.md`

---

## File Structure

| File | Responsibility |
|------|---------------|
| `web/book_worker.js` | **New.** Web Worker: ZIP parsing, EPUB metadata/cover extraction, SHA-256 hashing, OPFS read/write/delete |
| `lib/services/book_import_service.dart` | **New.** Dart service: Worker lifecycle, postMessage/onMessage bridging, `BookImportResult` model |
| `lib/widgets/add_book/import_book_sheet.dart` | **New.** Import UI: file picker, progress, metadata preview, add-to-library action |
| `lib/widgets/add_book/add_book_choice_sheet.dart` | **Modify.** Wire "Import digital books" button to `ImportBookSheet` |

---

### Task 1: Web Worker — ZIP parsing and EPUB metadata extraction

**Files:**
- Create: `app/web/book_worker.js`

This task builds the complete Web Worker script. The worker is structured as a message handler that dispatches on `type` and `format` fields. The EPUB processor does minimal ZIP central directory parsing (no external library) and XML parsing via DOMParser.

- [ ] **Step 1: Create the Web Worker file with message handler skeleton**

Create `app/web/book_worker.js`:

```js
// book_worker.js — Runs off the main thread.
// Handles EPUB processing, OPFS storage, and file retrieval.

self.onmessage = async function (e) {
  const msg = e.data;
  try {
    switch (msg.type) {
      case 'process':
        await handleProcess(msg);
        break;
      case 'delete':
        await handleDelete(msg);
        break;
      case 'getFile':
        await handleGetFile(msg);
        break;
      default:
        throw new Error(`Unknown message type: ${msg.type}`);
    }
  } catch (err) {
    self.postMessage({ type: 'error', message: err.message || String(err) });
  }
};

// ============================================================================
// Message handlers
// ============================================================================

async function handleProcess(msg) {
  const { format, bookId, fileData } = msg;
  let result;
  switch (format) {
    case 'epub':
      result = await processEpub(fileData, bookId);
      break;
    default:
      throw new Error(`Unsupported format: ${format}`);
  }

  // Store the original file in OPFS
  await opfsWrite(bookId, format, new Uint8Array(fileData));

  // Compute file hash
  const hashBuffer = await crypto.subtle.digest('SHA-256', fileData);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const fileHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

  const response = {
    type: 'success',
    action: 'process',
    bookId,
    metadata: result.metadata,
    fileSize: fileData.byteLength,
    fileHash,
  };

  // Transfer cover ArrayBuffer for zero-copy if present
  const transferables = [];
  if (result.coverData) {
    response.coverData = result.coverData;
    response.coverMimeType = result.coverMimeType;
    transferables.push(result.coverData);
  }

  self.postMessage(response, transferables);
}

async function handleDelete(msg) {
  await opfsDelete(msg.bookId);
  self.postMessage({ type: 'success', action: 'delete', bookId: msg.bookId });
}

async function handleGetFile(msg) {
  const fileData = await opfsRead(msg.bookId);
  const response = { type: 'success', action: 'getFile', bookId: msg.bookId };
  const transferables = [];
  if (fileData) {
    response.fileData = fileData.buffer;
    transferables.push(fileData.buffer);
  } else {
    response.fileData = null;
  }
  self.postMessage(response, transferables);
}

// ============================================================================
// OPFS storage
// ============================================================================

async function getOpfsBookDir() {
  const root = await navigator.storage.getDirectory();
  return root.getDirectoryHandle('books', { create: true });
}

async function opfsWrite(bookId, format, uint8Array) {
  const dir = await getOpfsBookDir();
  const fileHandle = await dir.getFileHandle(`${bookId}.${format}`, { create: true });
  const writable = await fileHandle.createWritable();
  await writable.write(uint8Array);
  await writable.close();
}

async function opfsRead(bookId) {
  const dir = await getOpfsBookDir();
  // Try known extensions
  const extensions = ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];
  for (const ext of extensions) {
    try {
      const fileHandle = await dir.getFileHandle(`${bookId}.${ext}`);
      const file = await fileHandle.getFile();
      const buffer = await file.arrayBuffer();
      return new Uint8Array(buffer);
    } catch (_) {
      // File not found with this extension, try next
    }
  }
  return null;
}

async function opfsDelete(bookId) {
  const dir = await getOpfsBookDir();
  const extensions = ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];
  for (const ext of extensions) {
    try {
      await dir.removeEntry(`${bookId}.${ext}`);
      return;
    } catch (_) {
      // File not found with this extension, try next
    }
  }
}

// ============================================================================
// ZIP parsing (minimal, for standard unencrypted ZIPs like EPUBs)
// ============================================================================

function parseZipEntries(buffer) {
  const view = new DataView(buffer);
  const bytes = new Uint8Array(buffer);

  // Find End of Central Directory record (search backwards for signature 0x06054b50)
  let eocdOffset = -1;
  for (let i = bytes.length - 22; i >= 0; i--) {
    if (view.getUint32(i, true) === 0x06054b50) {
      eocdOffset = i;
      break;
    }
  }
  if (eocdOffset === -1) throw new Error('Not a valid ZIP file');

  const cdOffset = view.getUint32(eocdOffset + 16, true);
  const cdEntryCount = view.getUint16(eocdOffset + 10, true);

  const entries = {};
  let offset = cdOffset;
  const decoder = new TextDecoder();

  for (let i = 0; i < cdEntryCount; i++) {
    if (view.getUint32(offset, true) !== 0x02014b50) break;

    const compressedSize = view.getUint32(offset + 20, true);
    const uncompressedSize = view.getUint32(offset + 24, true);
    const nameLen = view.getUint16(offset + 28, true);
    const extraLen = view.getUint16(offset + 30, true);
    const commentLen = view.getUint16(offset + 32, true);
    const localHeaderOffset = view.getUint32(offset + 42, true);
    const compressionMethod = view.getUint16(offset + 10, true);

    const name = decoder.decode(bytes.subarray(offset + 46, offset + 46 + nameLen));

    entries[name] = {
      name,
      compressedSize,
      uncompressedSize,
      localHeaderOffset,
      compressionMethod,
    };

    offset += 46 + nameLen + extraLen + commentLen;
  }

  return { entries, buffer };
}

async function readZipEntry(zip, entryName) {
  const entry = zip.entries[entryName];
  if (!entry) return null;

  const view = new DataView(zip.buffer);
  const nameLen = view.getUint16(entry.localHeaderOffset + 26, true);
  const extraLen = view.getUint16(entry.localHeaderOffset + 28, true);
  const dataStart = entry.localHeaderOffset + 30 + nameLen + extraLen;

  const compressed = new Uint8Array(zip.buffer, dataStart, entry.compressedSize);

  if (entry.compressionMethod === 0) {
    // Stored (no compression)
    return compressed;
  } else if (entry.compressionMethod === 8) {
    // Deflate — use DecompressionStream
    const blob = new Blob([compressed]);
    const ds = new DecompressionStream('raw-deflate');
    const stream = blob.stream().pipeThrough(ds);
    const decompressed = await new Response(stream).arrayBuffer();
    return new Uint8Array(decompressed);
  } else {
    throw new Error(`Unsupported compression method: ${entry.compressionMethod}`);
  }
}

// ============================================================================
// EPUB processor
// ============================================================================

async function processEpub(fileData, bookId) {
  const zip = parseZipEntries(fileData);

  // 1. Find the OPF file path from META-INF/container.xml
  const containerBytes = await readZipEntry(zip, 'META-INF/container.xml');
  if (!containerBytes) throw new Error('Could not read EPUB metadata');
  const containerXml = new TextDecoder().decode(containerBytes);
  const containerDoc = new DOMParser().parseFromString(containerXml, 'application/xml');
  const rootfileEl = containerDoc.querySelector('rootfile');
  if (!rootfileEl) throw new Error('Could not read EPUB metadata');
  const opfPath = rootfileEl.getAttribute('full-path');
  if (!opfPath) throw new Error('Could not read EPUB metadata');

  // 2. Parse OPF for metadata
  const opfBytes = await readZipEntry(zip, opfPath);
  if (!opfBytes) throw new Error('Could not read EPUB metadata');
  const opfXml = new TextDecoder().decode(opfBytes);
  const opfDoc = new DOMParser().parseFromString(opfXml, 'application/xml');

  // OPF base directory (for resolving relative paths in manifest)
  const opfDir = opfPath.includes('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';

  // Extract Dublin Core metadata
  const dcNs = 'http://purl.org/dc/elements/1.1/';
  const getText = (tag) => {
    const el = opfDoc.getElementsByTagNameNS(dcNs, tag)[0];
    return el ? el.textContent.trim() : null;
  };

  const title = getText('title') || bookId;
  const description = getText('description');
  const publisher = getText('publisher');
  const language = getText('language');

  // Authors — all <dc:creator> elements
  const creatorEls = opfDoc.getElementsByTagNameNS(dcNs, 'creator');
  const authors = [];
  for (let i = 0; i < creatorEls.length; i++) {
    const text = creatorEls[i].textContent.trim();
    if (text) authors.push(text);
  }
  const author = authors.length > 0 ? authors[0] : 'Unknown';
  const coAuthors = authors.slice(1);

  // ISBN — look through <dc:identifier> elements
  let isbn = null;
  const identifiers = opfDoc.getElementsByTagNameNS(dcNs, 'identifier');
  for (let i = 0; i < identifiers.length; i++) {
    const text = identifiers[i].textContent.trim().replace(/[^0-9X]/gi, '');
    if (text.length === 13 || text.length === 10) {
      isbn = text;
      break;
    }
  }

  // 3. Find cover image from manifest
  let coverData = null;
  let coverMimeType = null;
  const manifest = opfDoc.querySelector('manifest');
  const metaEls = opfDoc.querySelectorAll('metadata meta, meta');

  // Strategy A: <meta name="cover" content="item-id" />
  let coverItemId = null;
  for (let i = 0; i < metaEls.length; i++) {
    if (metaEls[i].getAttribute('name') === 'cover') {
      coverItemId = metaEls[i].getAttribute('content');
      break;
    }
  }

  // Strategy B: <item properties="cover-image" />
  let coverHref = null;
  if (manifest) {
    const items = manifest.querySelectorAll('item');
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (coverItemId && item.getAttribute('id') === coverItemId) {
        coverHref = item.getAttribute('href');
        coverMimeType = item.getAttribute('media-type');
        break;
      }
      if (!coverItemId && (item.getAttribute('properties') || '').includes('cover-image')) {
        coverHref = item.getAttribute('href');
        coverMimeType = item.getAttribute('media-type');
        break;
      }
    }
  }

  if (coverHref) {
    const coverPath = coverHref.startsWith('/') ? coverHref.substring(1) : opfDir + coverHref;
    const coverBytes = await readZipEntry(zip, coverPath);
    if (coverBytes) {
      coverData = coverBytes.buffer.byteLength === coverBytes.length
        ? coverBytes.buffer
        : coverBytes.buffer.slice(coverBytes.byteOffset, coverBytes.byteOffset + coverBytes.byteLength);
    }
  }

  // 4. Estimate page count from XHTML content sizes
  let totalContentBytes = 0;
  if (manifest) {
    const items = manifest.querySelectorAll('item');
    for (let i = 0; i < items.length; i++) {
      const mediaType = items[i].getAttribute('media-type') || '';
      if (mediaType === 'application/xhtml+xml') {
        const href = items[i].getAttribute('href');
        const entryPath = href.startsWith('/') ? href.substring(1) : opfDir + href;
        const entry = zip.entries[entryPath];
        if (entry) totalContentBytes += entry.uncompressedSize;
      }
    }
  }
  const pageCount = totalContentBytes > 0 ? Math.max(1, Math.round(totalContentBytes / 2000)) : null;

  return {
    metadata: {
      title,
      subtitle: null,
      author,
      coAuthors,
      publisher,
      description,
      language,
      isbn,
      pageCount,
    },
    coverData,
    coverMimeType,
  };
}
```

- [ ] **Step 2: Verify the worker file is syntactically valid**

Run: `node --check app/web/book_worker.js`
Expected: No output (no syntax errors)

- [ ] **Step 3: Commit**

```bash
git add app/web/book_worker.js
git commit -m "feat: add Web Worker for EPUB processing and OPFS storage"
```

---

### Task 2: Dart service — `BookImportService`

**Files:**
- Create: `app/lib/services/book_import_service.dart`

This service wraps the Web Worker communication using `package:web` and `dart:js_interop`. It exposes a clean async API and converts between JS and Dart types.

- [ ] **Step 1: Create `BookImportResult` model and `BookImportService`**

Create `app/lib/services/book_import_service.dart`:

```dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Result of processing a book file in the Web Worker.
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

  const BookImportResult({
    required this.bookId,
    required this.title,
    this.subtitle,
    required this.author,
    this.coAuthors = const [],
    this.publisher,
    this.description,
    this.language,
    this.isbn,
    this.pageCount,
    this.coverImage,
    this.coverMimeType,
    required this.fileSize,
    required this.fileHash,
  });
}

/// Service for importing book files via a Web Worker.
///
/// On web, delegates to `book_worker.js` for off-thread processing.
/// On native platforms, throws [UnsupportedError] (not yet implemented).
class BookImportService {
  web.Worker? _worker;

  web.Worker _getWorker() {
    return _worker ??= web.Worker('book_worker.js');
  }

  /// Import a book file: extract metadata and store in OPFS.
  ///
  /// Format is inferred from [filename] extension.
  /// Currently supports: `.epub`
  Future<BookImportResult> importBook(
    Uint8List bytes,
    String filename,
  ) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only available on web');
    }

    final ext = filename.split('.').last.toLowerCase();
    if (ext != 'epub') {
      throw ArgumentError('Unsupported format: .$ext');
    }

    final bookId = 'book-${DateTime.now().millisecondsSinceEpoch}';
    final worker = _getWorker();
    final completer = Completer<BookImportResult>();

    void onMessage(web.MessageEvent event) {
      final data = event.data as JSObject;
      final type = (data['type'] as JSString).toDart;

      if (type == 'error') {
        final message = (data['message'] as JSString).toDart;
        completer.completeError(Exception(message));
        return;
      }

      if (type == 'success') {
        final action = (data['action'] as JSString).toDart;
        if (action != 'process') return;

        final metadata = data['metadata'] as JSObject;

        // Extract cover bytes if present
        Uint8List? coverImage;
        String? coverMimeType;
        final coverDataJs = data['coverData'];
        if (coverDataJs != null && coverDataJs is JSArrayBuffer) {
          coverImage = coverDataJs.toDart.asUint8List();
          final mimeJs = data['coverMimeType'];
          if (mimeJs != null && mimeJs is JSString) {
            coverMimeType = mimeJs.toDart;
          }
        }

        // Extract coAuthors array
        final coAuthorsJs = metadata['coAuthors'];
        final coAuthors = <String>[];
        if (coAuthorsJs != null && coAuthorsJs is JSArray) {
          for (var i = 0; i < (coAuthorsJs as JSArray).length; i++) {
            coAuthors.add(((coAuthorsJs as JSArray)[i] as JSString).toDart);
          }
        }

        final result = BookImportResult(
          bookId: bookId,
          title: (metadata['title'] as JSString).toDart,
          subtitle: _jsToNullableString(metadata['subtitle']),
          author: (metadata['author'] as JSString).toDart,
          coAuthors: coAuthors,
          publisher: _jsToNullableString(metadata['publisher']),
          description: _jsToNullableString(metadata['description']),
          language: _jsToNullableString(metadata['language']),
          isbn: _jsToNullableString(metadata['isbn']),
          pageCount: _jsToNullableInt(metadata['pageCount']),
          coverImage: coverImage,
          coverMimeType: coverMimeType,
          fileSize: (data['fileSize'] as JSNumber).toDartInt,
          fileHash: (data['fileHash'] as JSString).toDart,
        );

        completer.complete(result);
      }
    }

    worker.onmessage = onMessage.toJS;

    // Send file bytes to worker, transferring the ArrayBuffer
    final jsBuffer = bytes.buffer.toJS;
    final message = {
      'type': 'process'.toJS,
      'format': ext.toJS,
      'bookId': bookId.toJS,
      'fileData': jsBuffer,
    }.jsify();
    worker.postMessage(message, [jsBuffer].toJS);

    return completer.future;
  }

  /// Delete a book's stored file from OPFS.
  Future<void> deleteBookFile(String bookId) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only available on web');
    }

    final worker = _getWorker();
    final completer = Completer<void>();

    void onMessage(web.MessageEvent event) {
      final data = event.data as JSObject;
      final type = (data['type'] as JSString).toDart;

      if (type == 'error') {
        final message = (data['message'] as JSString).toDart;
        completer.completeError(Exception(message));
        return;
      }

      if (type == 'success') {
        final action = (data['action'] as JSString).toDart;
        if (action == 'delete') completer.complete();
      }
    }

    worker.onmessage = onMessage.toJS;
    final message = {
      'type': 'delete'.toJS,
      'bookId': bookId.toJS,
    }.jsify();
    worker.postMessage(message);

    return completer.future;
  }

  /// Retrieve a book's file bytes from OPFS.
  Future<Uint8List?> getBookFile(String bookId) async {
    if (!kIsWeb) {
      throw UnsupportedError('BookImportService is only available on web');
    }

    final worker = _getWorker();
    final completer = Completer<Uint8List?>();

    void onMessage(web.MessageEvent event) {
      final data = event.data as JSObject;
      final type = (data['type'] as JSString).toDart;

      if (type == 'error') {
        final message = (data['message'] as JSString).toDart;
        completer.completeError(Exception(message));
        return;
      }

      if (type == 'success') {
        final action = (data['action'] as JSString).toDart;
        if (action != 'getFile') return;

        final fileDataJs = data['fileData'];
        if (fileDataJs != null && fileDataJs is JSArrayBuffer) {
          completer.complete(fileDataJs.toDart.asUint8List());
        } else {
          completer.complete(null);
        }
      }
    }

    worker.onmessage = onMessage.toJS;
    final message = {
      'type': 'getFile'.toJS,
      'bookId': bookId.toJS,
    }.jsify();
    worker.postMessage(message);

    return completer.future;
  }

  /// Dispose of the worker.
  void dispose() {
    _worker?.terminate();
    _worker = null;
  }

  static String? _jsToNullableString(JSAny? value) {
    if (value == null || value.isNull || value.isUndefined) return null;
    return (value as JSString).toDart;
  }

  static int? _jsToNullableInt(JSAny? value) {
    if (value == null || value.isNull || value.isUndefined) return null;
    return (value as JSNumber).toDartInt;
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd app && dart analyze lib/services/book_import_service.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add app/lib/services/book_import_service.dart
git commit -m "feat: add BookImportService for web worker communication"
```

---

### Task 3: Import UI — `ImportBookSheet`

**Files:**
- Create: `app/lib/widgets/add_book/import_book_sheet.dart`

**Key patterns to follow (from existing codebase):**
- `AddBookChoiceSheet` (`lib/widgets/add_book/add_book_choice_sheet.dart`): bottom sheet on mobile, dialog on desktop
- `BottomSheetHandle` (`lib/widgets/shared/bottom_sheet_handle.dart`): drag handle for mobile bottom sheets
- `BottomSheetHeader` (`lib/widgets/shared/bottom_sheet_header.dart`): Cancel / Title / Action header
- Cover image stored as data URI via `bytesToDataUri()` from `lib/utils/image_utils.dart`
- Book creation: `Book(id: 'book-${now.millisecondsSinceEpoch}', ...)` then `dataStore.addBook(book)`
- Success snackbar: `ScaffoldMessenger.of(context).showSnackBar(...)`
- Design tokens: `Spacing.*`, `AppRadius.*`, `Breakpoints.*` from `lib/themes/design_tokens.dart`

- [ ] **Step 1: Create the import sheet widget**

Create `app/lib/widgets/add_book/import_book_sheet.dart`:

```dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/image_utils.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:provider/provider.dart';

enum _ImportState { idle, processing, success, error }

/// Sheet for importing a digital book file (EPUB).
///
/// Opens a file picker, processes the file in a Web Worker,
/// previews the extracted metadata, and adds the book to the library.
class ImportBookSheet extends StatelessWidget {
  const ImportBookSheet({super.key});

  /// Show the import sheet (bottom sheet on mobile, dialog on desktop).
  static Future<void> show(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: _ImportContent(),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: const Padding(
            padding: EdgeInsets.only(
              left: Spacing.lg,
              right: Spacing.lg,
              top: Spacing.md,
              bottom: Spacing.lg,
            ),
            child: _ImportContent(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ImportContent extends StatefulWidget {
  const _ImportContent();

  @override
  State<_ImportContent> createState() => _ImportContentState();
}

class _ImportContentState extends State<_ImportContent> {
  final _importService = BookImportService();
  _ImportState _state = _ImportState.idle;
  String? _filename;
  String? _errorMessage;
  BookImportResult? _result;

  @override
  void dispose() {
    _importService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess() async {
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: true,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) return;

    final file = pickerResult.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _state = _ImportState.error;
        _errorMessage = 'Could not read the selected file.';
      });
      return;
    }

    setState(() {
      _state = _ImportState.processing;
      _filename = file.name;
      _errorMessage = null;
    });

    try {
      final result = await _importService.importBook(bytes, file.name);
      setState(() {
        _state = _ImportState.success;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _state = _ImportState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _addToLibrary() {
    final result = _result;
    if (result == null) return;

    final dataStore = context.read<DataStore>();
    final now = DateTime.now();

    String? coverUrl;
    if (result.coverImage != null) {
      coverUrl = bytesToDataUri(result.coverImage!);
    }

    final book = Book(
      id: result.bookId,
      title: result.title,
      subtitle: result.subtitle,
      author: result.author,
      coAuthors: result.coAuthors,
      publisher: result.publisher,
      description: result.description,
      language: result.language,
      isbn: result.isbn,
      pageCount: result.pageCount,
      coverUrl: coverUrl,
      filePath: 'opfs://books/${result.bookId}.epub',
      fileFormat: BookFormat.epub,
      fileSize: result.fileSize,
      fileHash: result.fileHash,
      addedAt: now,
    );

    dataStore.addBook(book);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Added "${book.title}" to library')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDesktop =
        MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop) const BottomSheetHandle(),
        if (!isDesktop) const SizedBox(height: Spacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Import book', style: textTheme.headlineSmall),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        switch (_state) {
          _ImportState.idle => _buildIdleState(context),
          _ImportState.processing => _buildProcessingState(context),
          _ImportState.success => _buildSuccessState(context),
          _ImportState.error => _buildErrorState(context),
        },
      ],
    );
  }

  Widget _buildIdleState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file, size: 48, color: colorScheme.primary),
              const SizedBox(height: Spacing.md),
              Text('Select an EPUB file', style: textTheme.titleMedium),
              const SizedBox(height: Spacing.xs),
              Text(
                'The file will be stored offline on this device',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: _pickAndProcess,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse files'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Processing...', style: textTheme.titleMedium),
          if (_filename != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              _filename!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final result = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover preview
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              clipBehavior: Clip.antiAlias,
              child: result.coverImage != null
                  ? Image.memory(result.coverImage!, fit: BoxFit.cover)
                  : Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title, style: textTheme.titleMedium),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    result.author,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (result.pageCount != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '~${result.pageCount} pages',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _state = _ImportState.idle;
                    _result = null;
                    _filename = null;
                  });
                },
                child: const Text('Pick different file'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: _addToLibrary,
                child: const Text('Add to library'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _pickAndProcess,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd app && dart analyze lib/widgets/add_book/import_book_sheet.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add app/lib/widgets/add_book/import_book_sheet.dart
git commit -m "feat: add ImportBookSheet UI for EPUB file import"
```

---

### Task 4: Wire up the "Import digital books" button

**Files:**
- Modify: `app/lib/widgets/add_book/add_book_choice_sheet.dart`

Connect the existing empty `onTap: () {}` handler to open the new `ImportBookSheet`.

- [ ] **Step 1: Add import and wire the button**

In `app/lib/widgets/add_book/add_book_choice_sheet.dart`, add the import at the top (after line 3):

```dart
import 'package:papyrus/widgets/add_book/import_book_sheet.dart';
```

Then change the "Import digital books" `onTap` handler. Replace line 76:

```dart
          onTap: () {},
```

with:

```dart
          onTap: () {
            Navigator.of(context).pop();
            ImportBookSheet.show(callerContext);
          },
```

Also update the subtitle to reflect current support (replace line 75):

```dart
          subtitle: 'EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ',
```

with:

```dart
          subtitle: 'EPUB',
```

- [ ] **Step 2: Verify it compiles**

Run: `cd app && dart analyze lib/widgets/add_book/add_book_choice_sheet.dart`
Expected: No issues found

- [ ] **Step 3: Run all tests to ensure nothing is broken**

Run: `cd app && flutter test`
Expected: All tests pass (470 passing, 8 skipped)

- [ ] **Step 4: Commit**

```bash
git add app/lib/widgets/add_book/add_book_choice_sheet.dart
git commit -m "feat: wire import digital books button to ImportBookSheet"
```

---

### Task 5: Manual end-to-end verification

No files created or modified. This is a manual verification task.

- [ ] **Step 1: Start the web app**

Run: `cd app && flutter run -d chrome --web-port=8080`

- [ ] **Step 2: Navigate to the import flow**

1. Click "Use offline mode" on the welcome page
2. Go to Library
3. Click "+ Add book"
4. Click "Import digital books"
5. Select an EPUB file from disk
6. Verify: processing spinner appears, UI remains responsive (scroll/click around)
7. Verify: metadata preview shows (title, author, cover image)
8. Click "Add to library"
9. Verify: book appears in the library grid with cover, title, and "EPUB" format badge

- [ ] **Step 3: Verify OPFS storage**

Open Chrome DevTools → Application tab → Storage → OPFS
Verify a `books/` directory exists with the EPUB file stored

- [ ] **Step 4: Commit any final adjustments if needed**

```bash
git add -A
git commit -m "fix: adjustments from manual testing"
```
