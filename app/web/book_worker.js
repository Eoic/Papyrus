/**
 * book_worker.js — Web Worker for EPUB processing and OPFS file storage.
 *
 * Runs off the main thread so the Flutter UI stays responsive.
 *
 * Message protocol:
 *   Incoming:
 *     { type: 'process', format: 'epub', bookId, fileData: ArrayBuffer }
 *     { type: 'delete',  bookId }
 *     { type: 'getFile', bookId }
 *
 *   Outgoing:
 *     { type: 'success', action: 'process', bookId, metadata, coverData, coverMimeType, fileSize, fileHash }
 *     { type: 'success', action: 'delete',  bookId }
 *     { type: 'success', action: 'getFile', bookId, fileData }
 *     { type: 'error',   message }
 */

'use strict';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

self.onmessage = async (event) => {
  const msg = event.data;
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
        postMessage({ type: 'error', message: `Unknown message type: ${msg.type}` });
    }
  } catch (err) {
    postMessage({
      type: 'error',
      action: msg.type,
      bookId: msg.bookId,
      message: err.message || String(err),
    });
  }
};

// ---------------------------------------------------------------------------
// Process dispatcher — switch on format for future extensibility
// ---------------------------------------------------------------------------

async function handleProcess(msg) {
  const { format, bookId, fileData } = msg;
  switch (format) {
    case 'epub':
      await processEpub(bookId, fileData);
      break;
    default:
      postMessage({
        type: 'error',
        action: 'process',
        bookId,
        message: `Unsupported format: ${format}`,
      });
  }
}

// ---------------------------------------------------------------------------
// Delete handler
// ---------------------------------------------------------------------------

async function handleDelete(msg) {
  const { bookId } = msg;
  await opfsDelete(bookId);
  postMessage({ type: 'success', action: 'delete', bookId });
}

// ---------------------------------------------------------------------------
// GetFile handler
// ---------------------------------------------------------------------------

async function handleGetFile(msg) {
  const { bookId } = msg;
  const bytes = await opfsRead(bookId);
  const fileData = bytes ? bytes.buffer : null;
  postMessage(
    { type: 'success', action: 'getFile', bookId, fileData },
    fileData ? [fileData] : [],
  );
}

// ---------------------------------------------------------------------------
// EPUB processing
// ---------------------------------------------------------------------------

async function processEpub(bookId, fileData) {
  const bytes = new Uint8Array(fileData);

  // 1. Parse ZIP central directory
  const zip = parseZip(bytes);

  // 2. Read META-INF/container.xml → OPF path
  const containerEntry = zip.get('META-INF/container.xml');
  if (!containerEntry) {
    throw new Error('Could not read EPUB metadata');
  }
  const containerXml = decodeUtf8(await inflateEntry(bytes, containerEntry));
  const opfPath = parseContainerXml(containerXml);
  if (!opfPath) {
    throw new Error('Could not read EPUB metadata');
  }

  // 3. Parse OPF
  const opfEntry = zip.get(opfPath);
  if (!opfEntry) {
    throw new Error('Could not read EPUB metadata');
  }
  const opfXml = decodeUtf8(await inflateEntry(bytes, opfEntry));

  // 4. Extract Dublin Core metadata
  const metadata = extractMetadata(opfXml, bookId);

  // 5. Find cover image
  const opfDir = opfPath.includes('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
  const { coverPath, coverMimeType } = findCoverPath(opfXml);
  let coverData = null;
  let resolvedCoverMimeType = coverMimeType;
  if (coverPath) {
    const fullCoverPath = resolvePath(opfDir, coverPath);
    const coverEntry = zip.get(fullCoverPath);
    if (coverEntry) {
      const coverBytes = await inflateEntry(bytes, coverEntry);
      coverData = coverBytes.slice().buffer;
    }
  }

  // 6. Compute SHA-256 hash of the full file
  const hashBuffer = await crypto.subtle.digest('SHA-256', fileData);
  const fileHash = bufferToHex(hashBuffer);

  // 7. Estimate page count
  const pageCount = estimatePageCount(opfXml, opfDir, zip);

  // 8. Store original EPUB blob in OPFS
  await opfsWrite(bookId, 'epub', new Uint8Array(fileData));

  // 9. Return result
  const transferables = [];
  if (coverData) transferables.push(coverData);

  postMessage(
    {
      type: 'success',
      action: 'process',
      bookId,
      metadata: { ...metadata, pageCount },
      coverData,
      coverMimeType: resolvedCoverMimeType,
      fileSize: bytes.byteLength,
      fileHash,
    },
    transferables,
  );
}

// ---------------------------------------------------------------------------
// ZIP parsing — central directory only (no seeking from end of local headers)
// ---------------------------------------------------------------------------

/**
 * Parses the ZIP central directory and returns a Map<string, ZipEntry>.
 *
 * ZipEntry: { compressionMethod, compressedSize, uncompressedSize, localHeaderOffset, fileName }
 *
 * Throws if the end-of-central-directory signature cannot be found.
 */
function parseZip(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

  // Locate End of Central Directory record (signature 0x06054b50).
  // It may be followed by a comment of up to 65535 bytes.
  let eocdOffset = -1;
  const minEocdOffset = Math.max(0, bytes.length - 65535 - 22);
  for (let i = bytes.length - 22; i >= minEocdOffset; i--) {
    if (
      view.getUint8(i) === 0x50 &&
      view.getUint8(i + 1) === 0x4b &&
      view.getUint8(i + 2) === 0x05 &&
      view.getUint8(i + 3) === 0x06
    ) {
      const commentLength = view.getUint16(i + 20, true);
      if (i + 22 + commentLength === bytes.length) {
        eocdOffset = i;
        break;
      }
    }
  }
  if (eocdOffset === -1) {
    throw new Error("This file doesn't appear to be a valid EPUB");
  }

  const cdCount = view.getUint16(eocdOffset + 10, true);
  const cdSize = view.getUint32(eocdOffset + 12, true);
  let cdOffset = view.getUint32(eocdOffset + 16, true);

  // Handle ZIP64 (cdOffset === 0xffffffff)
  if (cdOffset === 0xffffffff) {
    throw new Error("This file doesn't appear to be a valid EPUB");
  }

  const entries = new Map();
  const decoder = new TextDecoder('utf-8');
  let pos = cdOffset;
  const cdEnd = cdOffset + cdSize;

  for (let i = 0; i < cdCount; i++) {
    if (pos + 46 > cdEnd) {
      throw new Error("This file doesn't appear to be a valid EPUB");
    }
    // Central directory file header signature: 0x02014b50
    if (
      view.getUint8(pos) !== 0x50 ||
      view.getUint8(pos + 1) !== 0x4b ||
      view.getUint8(pos + 2) !== 0x01 ||
      view.getUint8(pos + 3) !== 0x02
    ) {
      throw new Error("This file doesn't appear to be a valid EPUB");
    }

    const compressionMethod = view.getUint16(pos + 10, true);
    const compressedSize = view.getUint32(pos + 20, true);
    const uncompressedSize = view.getUint32(pos + 24, true);
    const fileNameLength = view.getUint16(pos + 28, true);
    const extraFieldLength = view.getUint16(pos + 30, true);
    const fileCommentLength = view.getUint16(pos + 32, true);
    const localHeaderOffset = view.getUint32(pos + 42, true);

    const fileNameBytes = bytes.subarray(pos + 46, pos + 46 + fileNameLength);
    const fileName = decoder.decode(fileNameBytes);

    entries.set(fileName, {
      compressionMethod,
      compressedSize,
      uncompressedSize,
      localHeaderOffset,
      fileName,
    });

    pos += 46 + fileNameLength + extraFieldLength + fileCommentLength;
  }

  return entries;
}

/**
 * Returns the raw (possibly compressed) data for a ZIP entry by reading its
 * local file header at localHeaderOffset.
 */
function getEntryData(bytes, entry) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const off = entry.localHeaderOffset;

  // Local file header signature: 0x04034b50
  if (
    view.getUint8(off) !== 0x50 ||
    view.getUint8(off + 1) !== 0x4b ||
    view.getUint8(off + 2) !== 0x03 ||
    view.getUint8(off + 3) !== 0x04
  ) {
    throw new Error("This file doesn't appear to be a valid EPUB");
  }

  const fileNameLength = view.getUint16(off + 26, true);
  const extraFieldLength = view.getUint16(off + 28, true);
  const dataStart = off + 30 + fileNameLength + extraFieldLength;
  return bytes.subarray(dataStart, dataStart + entry.compressedSize);
}

/**
 * Inflates (decompresses) a ZIP entry and returns a Uint8Array of the raw bytes.
 * Supports compression methods 0 (stored) and 8 (deflate).
 */
async function inflateEntry(bytes, entry) {
  const raw = getEntryData(bytes, entry);
  if (entry.compressionMethod === 0) {
    // Stored — no compression
    return raw;
  }
  if (entry.compressionMethod === 8) {
    // Raw deflate
    const ds = new DecompressionStream('deflate-raw');
    const writer = ds.writable.getWriter();
    const reader = ds.readable.getReader();

    writer.write(raw);
    writer.close();

    const chunks = [];
    let totalLength = 0;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(value);
      totalLength += value.length;
    }

    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const chunk of chunks) {
      result.set(chunk, offset);
      offset += chunk.length;
    }
    return result;
  }
  throw new Error(`Unsupported ZIP compression method: ${entry.compressionMethod}`);
}

function decodeUtf8(bytes) {
  return new TextDecoder('utf-8').decode(bytes);
}

// ---------------------------------------------------------------------------
// EPUB / OPF helpers
// ---------------------------------------------------------------------------

/**
 * Parses META-INF/container.xml and returns the rootfile full-path attribute.
 * Uses regex since DOMParser is not available in Web Workers.
 */
function parseContainerXml(xml) {
  const match = xml.match(/<rootfile[^>]+full-path\s*=\s*"([^"]*)"/);
  return match ? match[1] : null;
}

/**
 * Returns the text content of the first XML element matching the given tag name.
 * Handles namespace prefixes (e.g. "dc:title" matches both <dc:title> and <title>).
 */
function xmlGetText(xml, tagName) {
  // Match with or without namespace prefix
  const pattern = new RegExp(`<(?:[a-zA-Z0-9_-]+:)?${tagName}[^>]*>([\\s\\S]*?)</(?:[a-zA-Z0-9_-]+:)?${tagName}>`, 'i');
  const match = xml.match(pattern);
  return match ? match[1].replace(/<[^>]*>/g, '').trim() : null;
}

/**
 * Returns the text content of all XML elements matching the given tag name.
 */
function xmlGetAllText(xml, tagName) {
  const pattern = new RegExp(`<(?:[a-zA-Z0-9_-]+:)?${tagName}[^>]*>([\\s\\S]*?)</(?:[a-zA-Z0-9_-]+:)?${tagName}>`, 'gi');
  const results = [];
  let match;
  while ((match = pattern.exec(xml)) !== null) {
    const text = match[1].replace(/<[^>]*>/g, '').trim();
    if (text) results.push(text);
  }
  return results;
}

/**
 * Returns the value of a named attribute from an XML tag string.
 */
function xmlGetAttr(tag, attrName) {
  const match = tag.match(new RegExp(`${attrName}\\s*=\\s*"([^"]*)"`));
  return match ? match[1] : null;
}

/**
 * Returns all <item ...> tags from the XML string.
 */
function xmlGetAllItems(xml) {
  const results = [];
  const pattern = /<item\s[^>]*>/gi;
  let match;
  while ((match = pattern.exec(xml)) !== null) {
    results.push(match[0]);
  }
  return results;
}

/**
 * Extracts Dublin Core metadata from OPF XML string.
 */
function extractMetadata(opfXml, bookId) {
  const title = xmlGetText(opfXml, 'title') || bookId;
  const subtitle = null;

  const creators = xmlGetAllText(opfXml, 'creator');
  const author = creators.length > 0 ? creators[0] : null;
  const coAuthors = creators.length > 1 ? creators.slice(1) : [];

  const publisher = xmlGetText(opfXml, 'publisher') || null;
  const description = xmlGetText(opfXml, 'description') || null;
  const language = xmlGetText(opfXml, 'language') || null;

  const identifiers = xmlGetAllText(opfXml, 'identifier');
  let isbn = null;
  for (const id of identifiers) {
    const digits = id.replace(/[-\s]/g, '');
    if (/^\d{10}$/.test(digits) || /^\d{13}$/.test(digits)) {
      isbn = digits;
      break;
    }
  }

  return { title, subtitle, author, coAuthors, publisher, description, language, isbn };
}

/**
 * Finds the cover image path from OPF XML string.
 * Returns { coverPath: string|null, coverMimeType: string|null }.
 *
 * Strategy A: <meta name="cover" content="item-id"> → resolve from manifest
 * Strategy B: <item properties="cover-image"> in manifest
 */
function findCoverPath(opfXml) {
  const items = xmlGetAllItems(opfXml);

  // Strategy A: <meta name="cover" content="item-id">
  const metaMatch = opfXml.match(/<meta[^>]+name\s*=\s*"cover"[^>]*>/i);
  if (metaMatch) {
    const coverId = xmlGetAttr(metaMatch[0], 'content');
    if (coverId) {
      for (const tag of items) {
        if (xmlGetAttr(tag, 'id') === coverId) {
          return {
            coverPath: xmlGetAttr(tag, 'href'),
            coverMimeType: xmlGetAttr(tag, 'media-type'),
          };
        }
      }
    }
  }

  // Strategy B: <item properties="cover-image">
  for (const tag of items) {
    const props = xmlGetAttr(tag, 'properties') || '';
    if (props.split(/\s+/).includes('cover-image')) {
      return {
        coverPath: xmlGetAttr(tag, 'href'),
        coverMimeType: xmlGetAttr(tag, 'media-type'),
      };
    }
  }

  return { coverPath: null, coverMimeType: null };
}

/**
 * Estimates page count by summing uncompressed sizes of all application/xhtml+xml
 * items in the manifest and dividing by 2000.
 */
function estimatePageCount(opfXml, opfDir, zip) {
  const items = xmlGetAllItems(opfXml);
  let totalBytes = 0;

  for (const tag of items) {
    const mediaType = xmlGetAttr(tag, 'media-type');
    if (mediaType !== 'application/xhtml+xml') continue;
    const href = xmlGetAttr(tag, 'href');
    if (!href) continue;
    const fullPath = resolvePath(opfDir, href);
    const entry = zip.get(fullPath);
    if (entry) {
      totalBytes += entry.uncompressedSize;
    }
  }

  return Math.max(1, Math.round(totalBytes / 2000));
}

/**
 * Resolves a relative path against a base directory.
 * e.g. resolvePath('OEBPS/', 'images/cover.jpg') → 'OEBPS/images/cover.jpg'
 * e.g. resolvePath('OEBPS/', '../cover.jpg') → 'cover.jpg'
 */
function resolvePath(base, relative) {
  if (!base) return relative;
  const parts = (base + relative).split('/');
  const resolved = [];
  for (const part of parts) {
    if (part === '..') {
      resolved.pop();
    } else if (part !== '.') {
      resolved.push(part);
    }
  }
  return resolved.join('/');
}

// ---------------------------------------------------------------------------
// OPFS helpers
// ---------------------------------------------------------------------------

const KNOWN_EXTENSIONS = ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];

/**
 * Writes bytes to OPFS at books/<bookId>.<format>.
 */
async function opfsWrite(bookId, format, uint8Array) {
  const root = await navigator.storage.getDirectory();
  const booksDir = await root.getDirectoryHandle('books', { create: true });
  const fileName = `${bookId}.${format}`;
  const fileHandle = await booksDir.getFileHandle(fileName, { create: true });
  const writable = await fileHandle.createWritable();
  await writable.write(uint8Array);
  await writable.close();
}

/**
 * Reads a file from OPFS for the given bookId.
 * Tries all known extensions and returns the first match, or null if not found.
 */
async function opfsRead(bookId) {
  const root = await navigator.storage.getDirectory();
  let booksDir;
  try {
    booksDir = await root.getDirectoryHandle('books', { create: false });
  } catch (_) {
    return null;
  }

  for (const ext of KNOWN_EXTENSIONS) {
    try {
      const fileHandle = await booksDir.getFileHandle(`${bookId}.${ext}`, { create: false });
      const file = await fileHandle.getFile();
      const buffer = await file.arrayBuffer();
      return new Uint8Array(buffer);
    } catch (_) {
      // Not found with this extension — try next
    }
  }

  return null;
}

/**
 * Deletes a file from OPFS for the given bookId.
 * Tries all known extensions silently.
 */
async function opfsDelete(bookId) {
  const root = await navigator.storage.getDirectory();
  let booksDir;
  try {
    booksDir = await root.getDirectoryHandle('books', { create: false });
  } catch (_) {
    return;
  }

  for (const ext of KNOWN_EXTENSIONS) {
    try {
      await booksDir.removeEntry(`${bookId}.${ext}`);
    } catch (_) {
      // File not found with this extension — continue
    }
  }
}

// ---------------------------------------------------------------------------
// Utility helpers
// ---------------------------------------------------------------------------

function bufferToHex(buffer) {
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
