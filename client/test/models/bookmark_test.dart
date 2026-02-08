import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/bookmark.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Bookmark', () {
    group('computed properties', () {
      test('color parses valid hex string', () {
        final bookmark = buildTestBookmark(colorHex: '#4CAF50');
        expect(bookmark.color, const Color(0xFF4CAF50));
      });

      test('color returns default on invalid hex', () {
        final bookmark = buildTestBookmark(colorHex: 'not-a-color');
        expect(bookmark.color, const Color(0xFFFF5722));
      });

      test('displayLocation shows chapter and page when both present', () {
        final bookmark = buildTestBookmark(
          chapterTitle: 'Chapter 1',
          pageNumber: 42,
        );
        expect(bookmark.displayLocation, 'Chapter 1, Page 42');
      });

      test('displayLocation shows page only when no chapter', () {
        final bookmark = buildTestBookmark(pageNumber: 42);
        expect(bookmark.displayLocation, 'Page 42');
      });

      test('displayLocation shows percentage when no page number', () {
        final bookmark = buildTestBookmark(position: 0.75);
        expect(bookmark.displayLocation, '75%');
      });

      test('hasNote is true for non-empty note', () {
        expect(buildTestBookmark(note: 'A note').hasNote, true);
      });

      test('hasNote is false for null note', () {
        expect(buildTestBookmark().hasNote, false);
      });

      test('hasNote is false for empty string note', () {
        expect(buildTestBookmark(note: '').hasNote, false);
      });
    });

    group('copyWith sentinel pattern', () {
      test('keeps nullable fields when not passed', () {
        final bookmark = buildTestBookmark(
          pageNumber: 10,
          chapterTitle: 'Ch1',
          note: 'A note',
        );
        final copy = bookmark.copyWith(colorHex: '#FF0000');

        expect(copy.pageNumber, 10);
        expect(copy.chapterTitle, 'Ch1');
        expect(copy.note, 'A note');
        expect(copy.colorHex, '#FF0000');
      });

      test('clears pageNumber when explicitly set to null', () {
        final bookmark = buildTestBookmark(pageNumber: 10);
        final copy = bookmark.copyWith(pageNumber: null);

        expect(copy.pageNumber, isNull);
      });

      test('clears chapterTitle when explicitly set to null', () {
        final bookmark = buildTestBookmark(chapterTitle: 'Ch1');
        final copy = bookmark.copyWith(chapterTitle: null);

        expect(copy.chapterTitle, isNull);
      });

      test('clears note when explicitly set to null', () {
        final bookmark = buildTestBookmark(note: 'A note');
        final copy = bookmark.copyWith(note: null);

        expect(copy.note, isNull);
      });

      test('updates pageNumber to new value', () {
        final bookmark = buildTestBookmark(pageNumber: 10);
        final copy = bookmark.copyWith(pageNumber: 20);

        expect(copy.pageNumber, 20);
      });

      test('updates note to new value', () {
        final bookmark = buildTestBookmark(note: 'Old note');
        final copy = bookmark.copyWith(note: 'New note');

        expect(copy.note, 'New note');
      });
    });

    group('toJson', () {
      test('serializes all fields with snake_case keys', () {
        final now = DateTime(2025, 6, 15);
        final bookmark = Bookmark(
          id: 'bm-1',
          bookId: 'book-1',
          position: 0.5,
          pageNumber: 100,
          chapterTitle: 'Ch 5',
          note: 'Important',
          colorHex: '#FF5722',
          createdAt: now,
        );

        final json = bookmark.toJson();

        expect(json['id'], 'bm-1');
        expect(json['book_id'], 'book-1');
        expect(json['position'], 0.5);
        expect(json['page_number'], 100);
        expect(json['chapter_title'], 'Ch 5');
        expect(json['note'], 'Important');
        expect(json['color_hex'], '#FF5722');
        expect(json['created_at'], now.toIso8601String());
      });

      test('null optional fields serialize as null', () {
        final bookmark = buildTestBookmark();
        final json = bookmark.toJson();

        expect(json['page_number'], isNull);
        expect(json['chapter_title'], isNull);
        expect(json['note'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'bm-1',
          'book_id': 'book-1',
          'position': 0.75,
          'page_number': 150,
          'chapter_title': 'The End',
          'note': 'Great ending',
          'color_hex': '#2196F3',
          'created_at': '2025-06-15T00:00:00.000',
        };

        final bookmark = Bookmark.fromJson(json);

        expect(bookmark.id, 'bm-1');
        expect(bookmark.bookId, 'book-1');
        expect(bookmark.position, 0.75);
        expect(bookmark.pageNumber, 150);
        expect(bookmark.chapterTitle, 'The End');
        expect(bookmark.note, 'Great ending');
        expect(bookmark.colorHex, '#2196F3');
      });

      test('defaults colorHex when missing', () {
        final json = {
          'id': 'bm-1',
          'book_id': 'book-1',
          'position': 0.5,
          'created_at': '2025-01-01T00:00:00.000',
        };

        final bookmark = Bookmark.fromJson(json);
        expect(bookmark.colorHex, '#FF5722');
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves all data', () {
        final original = Bookmark(
          id: 'bm-rt',
          bookId: 'book-rt',
          position: 0.33,
          pageNumber: 99,
          chapterTitle: 'Roundtrip',
          note: 'Test note',
          colorHex: '#E91E63',
          createdAt: DateTime(2025, 3, 15),
        );

        final restored = Bookmark.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.bookId, original.bookId);
        expect(restored.position, original.position);
        expect(restored.pageNumber, original.pageNumber);
        expect(restored.chapterTitle, original.chapterTitle);
        expect(restored.note, original.note);
        expect(restored.colorHex, original.colorHex);
      });
    });

    test('availableColors contains expected number of colors', () {
      expect(Bookmark.availableColors.length, 7);
      expect(Bookmark.availableColors.first, '#FF5722');
    });
  });
}
