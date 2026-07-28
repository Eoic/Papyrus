import 'dart:convert';

import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';

const syncedBookColumns = [
  'title',
  'subtitle',
  'author',
  'co_authors',
  'isbn',
  'isbn13',
  'publisher',
  'language',
  'page_count',
  'description',
  'cover_image_url',
  'file_media_id',
  'cover_media_id',
  'reading_status',
  'current_page',
  'current_position',
  'current_cfi',
  'is_favorite',
  'rating',
  'custom_metadata',
  'added_at',
  'updated_at',
];

class PowerSyncBookMapper {
  static Book fromRow(Map<String, Object?> row) {
    final metadata = _decodeObject(row['custom_metadata']);

    return Book(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled Book',
      subtitle: row['subtitle'] as String?,
      author: row['author'] as String? ?? 'Unknown Author',
      coAuthors: _decodeStringList(row['co_authors']),
      isbn: row['isbn'] as String?,
      isbn13: row['isbn13'] as String?,
      publicationDate: _parseDate(metadata['publication_date']),
      publisher: row['publisher'] as String?,
      language: row['language'] as String?,
      pageCount: _toInt(row['page_count']),
      description: row['description'] as String?,
      coverUrl: row['cover_image_url'] as String?,
      fileMediaId: row['file_media_id'] as String?,
      coverMediaId: row['cover_media_id'] as String?,
      fileFormat: _bookFormat(metadata['file_format']),
      fileSize: _toInt(metadata['file_size']),
      fileHash: metadata['file_hash'] as String?,
      isPhysical: _toBool(metadata['is_physical']),
      physicalLocation: metadata['physical_location'] as String?,
      lentTo: metadata['lent_to'] as String?,
      lentAt: _parseDate(metadata['lent_at']),
      readingStatus: _readingStatus(row['reading_status']),
      currentPage: _toInt(row['current_page']),
      currentPosition: _toDouble(row['current_position']) ?? 0.0,
      currentCfi: row['current_cfi'] as String?,
      isFavorite: _toBool(row['is_favorite']),
      rating: _toInt(row['rating']),
      customMetadata: _decodeNestedMetadata(metadata['custom_metadata']),
      seriesId: metadata['series_id'] as String?,
      seriesName: metadata['series_name'] as String?,
      seriesNumber: _toDouble(metadata['series_number']),
      addedAt: _parseDate(row['added_at']) ?? DateTime.now(),
      startedAt: _parseDate(metadata['started_at']),
      completedAt: _parseDate(metadata['completed_at']),
      lastReadAt: _parseDate(metadata['last_read_at']),
    );
  }

  static Map<String, Object?> toRow(Book book) {
    final metadata = <String, Object?>{
      if (book.publicationDate != null) 'publication_date': book.publicationDate!.toIso8601String(),
      if (book.fileFormat != null) 'file_format': book.fileFormat!.name,
      if (book.fileSize != null) 'file_size': book.fileSize,
      if (book.fileHash != null) 'file_hash': book.fileHash,
      'is_physical': book.isPhysical,
      if (book.physicalLocation != null) 'physical_location': book.physicalLocation,
      if (book.lentTo != null) 'lent_to': book.lentTo,
      if (book.lentAt != null) 'lent_at': book.lentAt!.toIso8601String(),
      if (book.customMetadata != null) 'custom_metadata': book.customMetadata,
      if (book.seriesId != null) 'series_id': book.seriesId,
      if (book.seriesName != null) 'series_name': book.seriesName,
      if (book.seriesNumber != null) 'series_number': book.seriesNumber,
      if (book.startedAt != null) 'started_at': book.startedAt!.toIso8601String(),
      if (book.completedAt != null) 'completed_at': book.completedAt!.toIso8601String(),
      if (book.lastReadAt != null) 'last_read_at': book.lastReadAt!.toIso8601String(),
    };
    final now = DateTime.now().toIso8601String();

    return {
      'id': book.id,
      'title': book.title,
      'subtitle': book.subtitle,
      'author': book.author,
      'co_authors': jsonEncode(book.coAuthors),
      'isbn': book.isbn,
      'isbn13': book.isbn13,
      'publisher': book.publisher,
      'language': book.language,
      'page_count': book.pageCount,
      'description': book.description,
      'cover_image_url': _remoteCoverUrl(book.coverUrl),
      'file_media_id': book.fileMediaId,
      'cover_media_id': book.coverMediaId,
      'reading_status': book.readingStatus.name,
      'current_page': book.currentPage,
      'current_position': book.currentPosition,
      'current_cfi': book.currentCfi,
      'is_favorite': book.isFavorite ? 1 : 0,
      'rating': book.rating,
      'custom_metadata': jsonEncode(metadata),
      'added_at': book.addedAt.toIso8601String(),
      'updated_at': now,
    };
  }

  static Map<String, dynamic>? decodeUploadData(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    final decoded = Map<String, dynamic>.from(data);
    decoded['co_authors'] = _decodeStringList(decoded['co_authors']);
    decoded['custom_metadata'] = _decodeObject(decoded['custom_metadata']);
    return decoded;
  }

  static List<Object?> rowParameters(Map<String, Object?> row) {
    return [row['id'], ...syncedBookColumns.map((column) => row[column])];
  }

  static String insertSql() {
    return '''
INSERT INTO books (id, ${syncedBookColumns.join(', ')})
VALUES (${List.filled(syncedBookColumns.length + 1, '?').join(', ')})
''';
  }

  static String updateSql() {
    return '''
UPDATE books
SET ${syncedBookColumns.map((column) => '$column = ?').join(', ')}
WHERE id = ?
''';
  }

  static List<Object?> updateParameters(Map<String, Object?> row) {
    return [...syncedBookColumns.map((column) => row[column]), row['id']];
  }

  static String? _remoteCoverUrl(String? coverUrl) {
    if (coverUrl == null || coverUrl.startsWith('data:')) {
      return null;
    }

    return coverUrl;
  }

  static Map<String, Object?> _decodeObject(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }

    return {};
  }

  static Map<String, dynamic>? _decodeNestedMetadata(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map<String, Object?>) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static List<String> _decodeStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);

      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    }

    return [];
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static bool _toBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      return {'1', 'true', 'yes', 'on'}.contains(value.toLowerCase());
    }

    return false;
  }

  static LibraryReadingStatus _readingStatus(Object? value) {
    return switch (value) {
      'inProgress' || 'in_progress' || 'reading' => LibraryReadingStatus.inProgress,
      'completed' || 'finished' => LibraryReadingStatus.completed,
      'paused' => LibraryReadingStatus.paused,
      'abandoned' => LibraryReadingStatus.abandoned,
      _ => LibraryReadingStatus.unread,
    };
  }

  static BookFormat? _bookFormat(Object? value) {
    if (value is! String) {
      return null;
    }

    for (final format in BookFormat.values) {
      if (format.name == value) {
        return format;
      }
    }

    return null;
  }
}
