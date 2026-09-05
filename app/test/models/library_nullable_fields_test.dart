import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';

void main() {
  final now = DateTime.utc(2026);

  test('nullable book metadata can be explicitly cleared', () {
    final original = Book(
      id: 'book',
      title: 'Book',
      author: 'Author',
      addedAt: now,
      fileMediaId: 'file',
      coverMediaId: 'cover',
      fileFormat: BookFormat.epub,
      fileSize: 42,
      fileHash: 'hash',
      currentPage: 3,
      currentCfi: 'cfi',
      customMetadata: const {'key': 'value'},
      seriesId: 'series',
      startedAt: now,
      completedAt: now,
      lastReadAt: now,
    );
    final cleared = original
        .copyWith(
          clearFileMediaId: true,
          clearCoverMediaId: true,
          clearFileFormat: true,
          clearFileSize: true,
          clearFileHash: true,
          clearCurrentPage: true,
          clearCurrentCfi: true,
          clearCustomMetadata: true,
          clearSeriesId: true,
          clearStartedAt: true,
          clearCompletedAt: true,
          clearLastReadAt: true,
        )
        .toJson();
    for (final field in [
      'file_media_id',
      'cover_media_id',
      'file_format',
      'file_size',
      'file_hash',
      'current_page',
      'current_cfi',
      'custom_metadata',
      'series_id',
      'started_at',
      'completed_at',
      'last_read_at',
    ]) {
      expect(cleared[field], isNull, reason: field);
      expect(original.copyWith().toJson()[field], isNotNull, reason: field);
    }
  });

  test('nullable library fields preserve by default and clear explicitly', () {
    final shelf = Shelf(
      id: 'shelf',
      name: 'Shelf',
      description: 'Description',
      colorHex: '#123456',
      icon: Icons.book,
      parentShelfId: 'parent',
      smartQuery: 'query',
      createdAt: now,
      updatedAt: now,
    );
    final cleared = shelf.copyWith(
      clearDescription: true,
      clearColorHex: true,
      clearIcon: true,
      clearParentShelfId: true,
      clearSmartQuery: true,
    );
    expect(cleared.description, isNull);
    expect(cleared.colorHex, isNull);
    expect(cleared.icon, isNull);
    expect(cleared.parentShelfId, isNull);
    expect(cleared.smartQuery, isNull);
    expect(shelf.copyWith().parentShelfId, 'parent');

    final tag = Tag(id: 'tag', name: 'Tag', description: 'Description', colorHex: '#123456', createdAt: now);
    expect(tag.copyWith(clearDescription: true).description, isNull);
    expect(tag.copyWith().description, 'Description');
    final note = Note(
      id: 'note',
      bookId: 'book',
      title: 'Note',
      content: 'Content',
      location: const BookLocation(pageNumber: 3),
      createdAt: now,
    );
    expect(note.copyWith(clearLocation: true).location, isNull);
    expect(note.copyWith().location?.pageNumber, 3);
    final annotation = Annotation(
      id: 'annotation',
      bookId: 'book',
      selectedText: 'Quote',
      note: 'Note',
      location: const BookLocation(pageNumber: 3),
      createdAt: now,
    );
    expect(annotation.copyWith(clearNote: true).note, isNull);
    expect(annotation.copyWith().note, 'Note');
  });
}
