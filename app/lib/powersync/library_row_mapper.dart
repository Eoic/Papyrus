import 'dart:convert';

import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book_shelf_relation.dart';
import 'package:papyrus/models/book_tag_relation.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';

class LibraryRowMapper<T> {
  final String table;
  final Map<String, Object?> Function(T) toRow;
  final T Function(Map<String, dynamic>) fromRow;

  const LibraryRowMapper(this.table, this.toRow, this.fromRow);
}

const libraryTableNames = ['books', 'shelves', 'tags', 'notes', 'annotations', 'book_shelves', 'book_tags'];

final shelfRowMapper = LibraryRowMapper<Shelf>('shelves', (shelf) {
  final row = Map<String, Object?>.from(shelf.toJson());
  row['icon_code_point'] = row.remove('icon');
  return encodeLibraryRow(row);
}, (row) => Shelf.fromJson({...decodeLibraryRow(row), 'icon': row['icon_code_point']}));

final tagRowMapper = LibraryRowMapper<Tag>(
  'tags',
  (value) => encodeLibraryRow(value.toJson()),
  (row) => Tag.fromJson(decodeLibraryRow(row)),
);

Map<String, Object?> _locatedRow(Map<String, dynamic> json, BookLocation? location) {
  final row = Map<String, Object?>.from(json);
  for (final key in ['chapter', 'chapter_title', 'page_number', 'percentage']) {
    row.remove(key);
  }
  row['location'] = location == null
      ? null
      : {
          'chapter': location.chapter,
          'chapter_title': location.chapterTitle,
          'page_number': location.pageNumber,
          'percentage': location.percentage,
        };
  return encodeLibraryRow(row);
}

Map<String, dynamic> _locatedJson(Map<String, dynamic> row) {
  final json = decodeLibraryRow(row);
  final location = json.remove('location');
  if (location is Map) json.addAll(Map<String, dynamic>.from(location));
  return json;
}

final noteRowMapper = LibraryRowMapper<Note>(
  'notes',
  (value) => _locatedRow(value.toJson(), value.location),
  (row) => Note.fromJson(_locatedJson(row)),
);
final annotationRowMapper = LibraryRowMapper<Annotation>(
  'annotations',
  (value) => _locatedRow(value.toJson(), value.location),
  (row) => Annotation.fromJson(_locatedJson(row)),
);
final bookShelfRowMapper = LibraryRowMapper<BookShelfRelation>(
  'book_shelves',
  (value) => encodeLibraryRow({'id': '${value.bookId}:${value.shelfId}', ...value.toJson()}),
  BookShelfRelation.fromJson,
);
final bookTagRowMapper = LibraryRowMapper<BookTagRelation>(
  'book_tags',
  (value) => encodeLibraryRow({'id': '${value.bookId}:${value.tagId}', ...value.toJson()}),
  BookTagRelation.fromJson,
);

Map<String, Object?> encodeLibraryRow(Map<String, Object?> row) => row.map((key, value) {
  if (value is bool) return MapEntry(key, value ? 1 : 0);
  if (value is List || value is Map) return MapEntry(key, jsonEncode(value));
  return MapEntry(key, value);
});

Map<String, dynamic> decodeLibraryRow(Map<String, dynamic> row) => row.map((key, value) {
  if (['is_smart', 'is_pinned', 'icon_match_text_direction'].contains(key)) {
    return MapEntry(key, value == true || value == 1);
  }
  if (['tags', 'location'].contains(key) && value is String) {
    return MapEntry(key, jsonDecode(value));
  }
  return MapEntry(key, value);
});
