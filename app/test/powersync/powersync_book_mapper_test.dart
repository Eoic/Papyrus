import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/powersync/powersync_book_mapper.dart';

void main() {
  test('device-specific cover paths never enter synchronized fields', () {
    for (final url in [
      'file:///home/user/cover.jpg',
      '/home/user/cover.jpg',
      'blob:http://localhost/id',
      'data:image/png;base64,abc',
    ]) {
      final book = Book(id: 'book', title: 'Title', author: 'Author', addedAt: DateTime.utc(2026), coverUrl: url);
      expect(PowerSyncBookMapper.toRow(book)['cover_image_url'], isNull);
    }
  });
  test('partial uploads preserve absent JSON fields and explicit nulls', () {
    expect(PowerSyncBookMapper.decodeUploadData({'title': 'Only title'}), {'title': 'Only title'});
    expect(PowerSyncBookMapper.decodeUploadData({'custom_metadata': null}), {'custom_metadata': null});
  });

  test('every portable book field survives a complete row round trip', () {
    final date = DateTime.utc(2026, 9, 5);
    final original = Book(
      id: 'book',
      title: 'Title',
      subtitle: 'Subtitle',
      author: 'Author',
      coAuthors: const ['Other'],
      isbn: '123',
      isbn13: '456',
      publicationDate: date,
      publisher: 'Publisher',
      language: 'en',
      pageCount: 300,
      description: 'Description',
      coverUrl: 'https://example.com/cover.png',
      fileMediaId: 'file',
      coverMediaId: 'cover',
      fileFormat: BookFormat.epub,
      fileSize: 1024,
      fileHash: 'hash',
      isPhysical: true,
      physicalLocation: 'Room',
      lentTo: 'Reader',
      lentAt: date,
      readingStatus: LibraryReadingStatus.inProgress,
      currentPage: 50,
      currentPosition: 0.3,
      currentCfi: 'epubcfi(/6/2)',
      isFavorite: true,
      rating: 4,
      customMetadata: const {
        'nested': {'value': 1},
        'list': ['a', 'b'],
      },
      seriesId: 'series',
      seriesName: 'Series',
      seriesNumber: 2.5,
      addedAt: date,
      startedAt: date,
      completedAt: date,
      lastReadAt: date,
    );
    final restored = PowerSyncBookMapper.fromRow(PowerSyncBookMapper.toRow(original));
    expect(restored.toJson(), original.toJson());
  });

  test('explicit null promoted fields override legacy metadata', () {
    final book = PowerSyncBookMapper.fromRow({
      'id': 'book',
      'physical_location': null,
      'is_physical': 0,
      'custom_metadata': jsonEncode({'physical_location': 'Old', 'is_physical': true}),
    });
    expect(book.physicalLocation, isNull);
    expect(book.isPhysical, isFalse);
  });

  test('maps Book to synced row without file path or embedded cover bytes', () {
    final book = Book(
      id: '11111111-1111-1111-1111-111111111111',
      title: 'Synced Book',
      author: 'Author',
      coAuthors: const ['Co Author'],
      coverUrl: 'data:image/png;base64,abc',
      filePath: '/local/book.epub',
      fileMediaId: '22222222-2222-2222-2222-222222222222',
      coverMediaId: '33333333-3333-3333-3333-333333333333',
      fileFormat: BookFormat.epub,
      fileSize: 1024,
      fileHash: 'hash',
      isPhysical: true,
      physicalLocation: 'Shelf',
      readingStatus: LibraryReadingStatus.inProgress,
      currentPosition: 0.4,
      isFavorite: true,
      addedAt: DateTime.parse('2026-05-09T12:00:00Z'),
    );

    final row = PowerSyncBookMapper.toRow(book);

    expect(row['cover_image_url'], isNull);
    expect(row['file_media_id'], '22222222-2222-2222-2222-222222222222');
    expect(row['cover_media_id'], '33333333-3333-3333-3333-333333333333');
    expect(row.containsKey('file_path'), isFalse);
    expect(row['co_authors'], jsonEncode(['Co Author']));
    expect(row['reading_status'], 'inProgress');
    expect(row['is_favorite'], 1);
    expect(row['file_format'], 'epub');
    expect(row['file_size'], 1024);
    expect(row['file_hash'], 'hash');
    expect(row['is_physical'], 1);
    expect(row['physical_location'], 'Shelf');
  });

  test('maps synced row to Book', () {
    final book = PowerSyncBookMapper.fromRow({
      'id': '11111111-1111-1111-1111-111111111111',
      'title': 'Synced Book',
      'author': 'Author',
      'co_authors': jsonEncode(['Co Author']),
      'reading_status': 'in_progress',
      'current_position': 0.5,
      'is_favorite': 1,
      'file_media_id': '22222222-2222-2222-2222-222222222222',
      'cover_media_id': '33333333-3333-3333-3333-333333333333',
      'custom_metadata': jsonEncode({'file_format': 'epub', 'is_physical': false}),
      'added_at': '2026-05-09T12:00:00Z',
    });

    expect(book.title, 'Synced Book');
    expect(book.coAuthors, ['Co Author']);
    expect(book.readingStatus, LibraryReadingStatus.inProgress);
    expect(book.currentPosition, 0.5);
    expect(book.isFavorite, isTrue);
    expect(book.fileFormat, BookFormat.epub);
    expect(book.fileMediaId, '22222222-2222-2222-2222-222222222222');
    expect(book.coverMediaId, '33333333-3333-3333-3333-333333333333');
  });
}
