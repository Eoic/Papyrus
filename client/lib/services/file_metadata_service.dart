import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_mobi/dart_mobi.dart';
import 'package:epub_pro/epub_pro.dart';
// ignore: implementation_imports
import 'package:epub_pro/src/schema/opf/epub_metadata_date.dart';
// ignore: implementation_imports
import 'package:epub_pro/src/schema/opf/epub_metadata_identifier.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
// ignore: implementation_imports
import 'package:unrar_file/src/rarFile.dart';
// ignore: implementation_imports
import 'package:unrar_file/src/rar_decoder.dart';
import 'package:xml/xml.dart';

/// Result of extracting metadata from a book file.
class FileMetadataResult {
  final String? title;
  final String? subtitle;
  final List<String>? authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final String? language;
  final String? isbn;
  final String? isbn13;
  final int? pageCount;
  final Uint8List? coverImageBytes;
  final String? coverImageMimeType;
  final List<String> warnings;

  const FileMetadataResult({
    this.title,
    this.subtitle,
    this.authors,
    this.publisher,
    this.publishedDate,
    this.description,
    this.language,
    this.isbn,
    this.isbn13,
    this.pageCount,
    this.coverImageBytes,
    this.coverImageMimeType,
    this.warnings = const [],
  });

  /// Get the primary author or empty string.
  String get primaryAuthor => authors?.isNotEmpty == true ? authors!.first : '';

  /// Get co-authors (all authors except the first).
  List<String> get coAuthors =>
      authors != null && authors!.length > 1 ? authors!.sublist(1) : [];
}

/// Parsed ComicInfo.xml fields shared between CBZ and CBR extractors.
class _ComicInfoData {
  final String? title;
  final List<String>? authors;
  final String? publisher;
  final String? description;
  final String? language;
  final int? pageCount;

  const _ComicInfoData({
    this.title,
    this.authors,
    this.publisher,
    this.description,
    this.language,
    this.pageCount,
  });
}

/// Service for extracting metadata from book files.
///
/// Supports EPUB, PDF, MOBI/AZW3, CBZ, CBR, and TXT formats.
/// Never throws — returns partial results with warnings on failure.
class FileMetadataService {
  static const _charsPerPage = 1500;

  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
  };

  /// Extract metadata from file bytes.
  ///
  /// Format is detected from the [filename] extension. Returns partial results
  /// with warnings if extraction encounters issues.
  Future<FileMetadataResult> extractMetadata(
    Uint8List bytes,
    String filename,
  ) async {
    final ext = p.extension(filename).toLowerCase();

    try {
      switch (ext) {
        case '.epub':
          return await _extractEpub(bytes);
        case '.pdf':
          return _extractPdf(bytes);
        case '.mobi' || '.azw3' || '.azw':
          return await _extractMobi(bytes);
        case '.cbz':
          return _extractCbz(bytes);
        case '.cbr':
          return await _extractCbr(bytes, filename);
        case '.txt':
          return _extractTxt(bytes, filename);
        default:
          return FileMetadataResult(
            warnings: ['Unsupported file format: $ext'],
          );
      }
    } catch (e) {
      return FileMetadataResult(warnings: ['Failed to extract metadata: $e']);
    }
  }

  // ============================================================================
  // EPUB
  // ============================================================================

  Future<FileMetadataResult> _extractEpub(Uint8List bytes) async {
    final warnings = <String>[];

    final book = await EpubReader.readBook(bytes);
    final metadata = book.schema?.package?.metadata;

    final title = _tryRead('EPUB title', warnings, () => book.title);

    final authors = _tryRead('EPUB authors', warnings, () {
      final raw = book.authors
          .whereType<String>()
          .where((a) => a.isNotEmpty)
          .toList();
      return raw.isNotEmpty ? raw : null;
    });

    final publisher = _tryRead(
      'EPUB publisher',
      warnings,
      () => metadata?.publishers.firstOrNull,
    );
    final description = _tryRead(
      'EPUB description',
      warnings,
      () => metadata?.description,
    );
    final language = _tryRead(
      'EPUB language',
      warnings,
      () => metadata?.languages.firstOrNull,
    );
    final publishedDate = _tryRead(
      'EPUB date',
      warnings,
      () => _findEpubDate(metadata?.dates),
    );

    final isbns = _tryRead(
      'EPUB identifiers',
      warnings,
      () => _findEpubIsbns(metadata?.identifiers),
    );

    Uint8List? coverImageBytes;
    String? coverImageMimeType;
    final coverImage = _tryRead(
      'EPUB cover image',
      warnings,
      () => book.coverImage,
    );
    if (coverImage != null) {
      coverImageBytes = img.encodePng(coverImage);
      coverImageMimeType = 'image/png';
    }

    return FileMetadataResult(
      title: title,
      authors: authors,
      publisher: publisher,
      publishedDate: publishedDate,
      description: description,
      language: language,
      isbn: isbns?.$1,
      isbn13: isbns?.$2,
      coverImageBytes: coverImageBytes,
      coverImageMimeType: coverImageMimeType,
      warnings: warnings,
    );
  }

  String? _findEpubDate(List<EpubMetadataDate>? dates) {
    if (dates == null || dates.isEmpty) return null;

    // Prefer publication date, fall back to first date.
    final pubDate = dates
        .where((d) => d.event?.toLowerCase() == 'publication')
        .firstOrNull;
    return (pubDate ?? dates.first).date;
  }

  (String?, String?) _findEpubIsbns(List<EpubMetadataIdentifier>? ids) {
    if (ids == null || ids.isEmpty) return (null, null);

    String? isbn;
    String? isbn13;

    for (final id in ids) {
      final value = id.identifier;
      if (value == null) continue;

      final clean = value.replaceAll(RegExp(r'[-\s]'), '');
      final isIsbnScheme = id.scheme?.toLowerCase() == 'isbn';

      if (clean.length == 10 && isbn == null && isIsbnScheme) {
        isbn = clean;
      } else if (clean.length == 13 && isbn13 == null) {
        // ISBN-13 can appear without scheme in some EPUBs.
        if (isIsbnScheme ||
            clean.startsWith('978') ||
            clean.startsWith('979')) {
          isbn13 = clean;
        }
      }
    }

    return (isbn, isbn13);
  }

  // ============================================================================
  // PDF
  // ============================================================================

  FileMetadataResult _extractPdf(Uint8List bytes) {
    final warnings = <String>[];
    final document = PdfDocument(inputBytes: bytes);

    try {
      final info = document.documentInformation;

      // Title
      String? title;
      try {
        final t = info.title;
        if (t.isNotEmpty) title = t;
      } catch (e) {
        warnings.add('Could not read PDF title: $e');
      }

      // Author
      List<String>? authors;
      try {
        final a = info.author;
        if (a.isNotEmpty) authors = [a];
      } catch (e) {
        warnings.add('Could not read PDF author: $e');
      }

      // Subject → description
      String? description;
      try {
        final s = info.subject;
        if (s.isNotEmpty) description = s;
      } catch (e) {
        warnings.add('Could not read PDF subject: $e');
      }

      // Page count
      int? pageCount;
      try {
        pageCount = document.pages.count;
      } catch (e) {
        warnings.add('Could not read PDF page count: $e');
      }

      // Published date from creation date
      String? publishedDate;
      try {
        final date = info.creationDate;
        publishedDate = date.toIso8601String().split('T').first;
      } catch (_) {
        // creationDate may not be set
      }

      return FileMetadataResult(
        title: title,
        authors: authors,
        description: description,
        pageCount: pageCount,
        publishedDate: publishedDate,
        warnings: warnings,
      );
    } finally {
      document.dispose();
    }
  }

  // ============================================================================
  // MOBI / AZW3
  // ============================================================================

  Future<FileMetadataResult> _extractMobi(Uint8List bytes) async {
    final warnings = <String>[];
    final mobiData = await DartMobiReader.read(bytes);

    String? getExthString(MobiExthTag tag) {
      try {
        final record = DartMobiReader.getExthRecordByTag(mobiData, tag);
        if (record?.data != null) {
          return utf8.decode(record!.data!, allowMalformed: true).trim();
        }
      } catch (e) {
        warnings.add('Could not read MOBI ${tag.name}: $e');
      }
      return null;
    }

    // Title — prefer EXTH title, fall back to MOBI header fullname.
    String? title = getExthString(MobiExthTag.title);
    if (title == null || title.isEmpty) {
      try {
        title = mobiData.mobiHeader?.fullname;
      } catch (_) {}
    }

    // Author
    final authorStr = getExthString(MobiExthTag.author);
    List<String>? authors;
    if (authorStr != null && authorStr.isNotEmpty) {
      // Authors can be separated by '&', ';', or ','
      authors = authorStr
          .split(RegExp(r'[;&,]'))
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();
    }

    final publisher = getExthString(MobiExthTag.publisher);
    final description = getExthString(MobiExthTag.description);
    final isbn = getExthString(MobiExthTag.isbm);
    final language = getExthString(MobiExthTag.language);
    final publishedDate = getExthString(MobiExthTag.publishingDate);

    // Cover extraction
    Uint8List? coverImageBytes;
    String? coverImageMimeType;
    try {
      final coverRecord = DartMobiReader.getExthRecordByTag(
        mobiData,
        MobiExthTag.coverOffset,
      );
      if (coverRecord?.data != null) {
        final offset = DartMobiReader.decodeExthValue(
          coverRecord!.data!,
          coverRecord.size!,
        );
        final imageIndex = mobiData.mobiHeader?.imageIndex ?? 0;
        final coverRecordIndex = imageIndex + offset;

        var record = mobiData.mobiPdbRecord;
        var currentIndex = 0;
        while (record != null) {
          if (currentIndex == coverRecordIndex) {
            coverImageBytes = record.data;
            coverImageMimeType = _guessImageMimeType(record.data);
            break;
          }
          currentIndex++;
          record = record.next;
        }
      }
    } catch (e) {
      warnings.add('Could not extract MOBI cover image: $e');
    }

    if (coverImageBytes == null) {
      warnings.add('MOBI cover image extraction is experimental');
    }

    // Classify ISBNs
    String? isbn10;
    String? isbn13;
    if (isbn != null) {
      final clean = isbn.replaceAll(RegExp(r'[-\s]'), '');
      if (clean.length == 13) {
        isbn13 = clean;
      } else if (clean.length == 10) {
        isbn10 = clean;
      }
    }

    return FileMetadataResult(
      title: title,
      authors: authors,
      publisher: publisher,
      publishedDate: publishedDate,
      description: description,
      language: language,
      isbn: isbn10,
      isbn13: isbn13,
      coverImageBytes: coverImageBytes,
      coverImageMimeType: coverImageMimeType,
      warnings: warnings,
    );
  }

  // ============================================================================
  // CBZ (ZIP-based comic archive)
  // ============================================================================

  FileMetadataResult _extractCbz(Uint8List bytes) {
    final warnings = <String>[];
    final archive = ZipDecoder().decodeBytes(bytes);

    final comicInfoBytes = archive.files
        .where((f) => f.name.toLowerCase() == 'comicinfo.xml')
        .firstOrNull
        ?.content;

    final comicInfo = _parseComicInfo(comicInfoBytes, 'CBZ', warnings);

    // Cover: first image file (sorted alphabetically)
    Uint8List? coverImageBytes;
    String? coverImageMimeType;
    try {
      final imageFiles =
          archive.files.where((f) => f.isFile && _isImageFile(f.name)).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      if (imageFiles.isNotEmpty) {
        coverImageBytes = imageFiles.first.content;
        coverImageMimeType = _guessImageMimeType(coverImageBytes);
      }
    } catch (e) {
      warnings.add('Could not extract CBZ cover image: $e');
    }

    return FileMetadataResult(
      title: comicInfo.title,
      authors: comicInfo.authors,
      publisher: comicInfo.publisher,
      description: comicInfo.description,
      language: comicInfo.language,
      pageCount: comicInfo.pageCount,
      coverImageBytes: coverImageBytes,
      coverImageMimeType: coverImageMimeType,
      warnings: warnings,
    );
  }

  // ============================================================================
  // CBR (RAR-based comic archive)
  // ============================================================================

  Future<FileMetadataResult> _extractCbr(
    Uint8List bytes,
    String filename,
  ) async {
    final warnings = <String>[];

    // unrar_file requires file paths. Write bytes to a temp file, extract,
    // then parse. This does not work on Web.
    final tempDir = await Directory.systemTemp.createTemp('papyrus_cbr_');
    final tempFile = File(p.join(tempDir.path, filename));
    await tempFile.writeAsBytes(bytes);

    try {
      final rar = RAR5(tempFile.path);
      final List<RarFile> files = rar.files;

      final comicInfoBytes = files
          .where(
            (f) =>
                f.name?.toLowerCase() == 'comicinfo.xml' && f.content != null,
          )
          .firstOrNull
          ?.content;

      final comicInfo = _parseComicInfo(comicInfoBytes, 'CBR', warnings);

      // Cover: first image file (sorted alphabetically)
      Uint8List? coverImageBytes;
      String? coverImageMimeType;
      try {
        final imageFiles =
            files
                .where(
                  (f) =>
                      f.content != null &&
                      f.name != null &&
                      _isImageFile(f.name!),
                )
                .toList()
              ..sort((a, b) => a.name!.compareTo(b.name!));

        if (imageFiles.isNotEmpty) {
          coverImageBytes = imageFiles.first.content;
          coverImageMimeType = _guessImageMimeType(coverImageBytes);
        }
      } catch (e) {
        warnings.add('Could not extract CBR cover image: $e');
      }

      return FileMetadataResult(
        title: comicInfo.title,
        authors: comicInfo.authors,
        publisher: comicInfo.publisher,
        description: comicInfo.description,
        language: comicInfo.language,
        pageCount: comicInfo.pageCount,
        coverImageBytes: coverImageBytes,
        coverImageMimeType: coverImageMimeType,
        warnings: warnings,
      );
    } catch (e) {
      warnings.add('Could not read CBR archive: $e');
      return FileMetadataResult(warnings: warnings);
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  // ============================================================================
  // TXT
  // ============================================================================

  FileMetadataResult _extractTxt(Uint8List bytes, String filename) {
    final warnings = <String>[];
    final basename = p.basenameWithoutExtension(filename);

    String? title;
    List<String>? authors;

    // Try "Author - Title" pattern
    final parts = basename.split(' - ');
    if (parts.length >= 2) {
      authors = [parts.first.trim()];
      title = parts.sublist(1).join(' - ').trim();
    } else {
      title = basename;
      warnings.add('Could not detect author from filename');
    }

    // Estimate page count from byte length
    int? pageCount;
    try {
      pageCount = (bytes.length / _charsPerPage).ceil();
      if (pageCount == 0) pageCount = 1;
    } catch (e) {
      warnings.add('Could not estimate page count: $e');
    }

    return FileMetadataResult(
      title: title,
      authors: authors,
      pageCount: pageCount,
      warnings: warnings,
    );
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  /// Try reading a metadata field; on failure, add a warning and return null.
  T? _tryRead<T>(String field, List<String> warnings, T? Function() read) {
    try {
      return read();
    } catch (e) {
      warnings.add('Could not read $field: $e');
      return null;
    }
  }

  /// Parse ComicInfo.xml bytes into metadata fields.
  ///
  /// If [xmlBytes] is null, adds a "not found" warning for [archiveType].
  _ComicInfoData _parseComicInfo(
    Uint8List? xmlBytes,
    String archiveType,
    List<String> warnings,
  ) {
    if (xmlBytes == null) {
      warnings.add('No ComicInfo.xml found in $archiveType archive');
      return const _ComicInfoData();
    }

    try {
      final doc = XmlDocument.parse(utf8.decode(xmlBytes));
      final info = doc.rootElement;

      var title = _xmlText(info, 'Title');
      final series = _xmlText(info, 'Series');
      final number = _xmlText(info, 'Number');
      if (title == null && series != null) {
        title = number != null ? '$series #$number' : series;
      }

      // Authors: Writer, Penciller, etc.
      final authorSet = <String>{};
      for (final role in ['Writer', 'Penciller']) {
        final value = _xmlText(info, role);
        if (value != null) {
          authorSet.addAll(value.split(',').map((a) => a.trim()));
        }
      }

      final pageCountStr = _xmlText(info, 'PageCount');

      return _ComicInfoData(
        title: title,
        authors: authorSet.isNotEmpty ? authorSet.toList() : null,
        publisher: _xmlText(info, 'Publisher'),
        description: _xmlText(info, 'Summary'),
        language: _xmlText(info, 'LanguageISO'),
        pageCount: pageCountStr != null ? int.tryParse(pageCountStr) : null,
      );
    } catch (e) {
      warnings.add('Could not parse ComicInfo.xml: $e');
      return const _ComicInfoData();
    }
  }

  /// Get text content of a direct child XML element by tag name.
  String? _xmlText(XmlElement parent, String tagName) {
    final el = parent.findElements(tagName).firstOrNull;
    if (el == null) return null;
    final text = el.innerText.trim();
    return text.isEmpty ? null : text;
  }

  /// Check if a filename looks like an image file.
  bool _isImageFile(String filename) {
    return _imageExtensions.contains(p.extension(filename).toLowerCase());
  }

  /// Guess MIME type from image bytes by checking magic bytes.
  String? _guessImageMimeType(Uint8List? bytes) {
    if (bytes == null || bytes.length < 4) return null;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return null;
  }
}
