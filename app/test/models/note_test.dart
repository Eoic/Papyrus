import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/note.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Note', () {
    group('computed properties', () {
      test('preview returns full content when <= 100 characters', () {
        final note = buildTestNote(content: 'Short content');
        expect(note.preview, 'Short content');
      });

      test('preview truncates content longer than 100 characters', () {
        final longContent = 'A' * 150;
        final note = buildTestNote(content: longContent);

        expect(note.preview.length, 103); // 100 chars + "..."
        expect(note.preview.endsWith('...'), true);
      });

      test('hasLocation is true when location is set', () {
        final note = buildTestNote(
          location: const BookLocation(pageNumber: 10),
        );
        expect(note.hasLocation, true);
      });

      test('hasLocation is false when location is null', () {
        final note = buildTestNote();
        expect(note.hasLocation, false);
      });

      test('hasTags is true when tags are present', () {
        final note = buildTestNote(tags: ['tag1', 'tag2']);
        expect(note.hasTags, true);
      });

      test('hasTags is false when tags are empty', () {
        final note = buildTestNote();
        expect(note.hasTags, false);
      });

      test('formattedDate uses updatedAt when present', () {
        final note = buildTestNote(
          createdAt: DateTime(2025, 1, 15),
          updatedAt: DateTime(2025, 6, 20),
        );
        expect(note.formattedDate, 'Jun 20, 2025');
      });

      test('formattedDate uses createdAt when no updatedAt', () {
        final note = buildTestNote(createdAt: DateTime(2025, 3, 5));
        expect(note.formattedDate, 'Mar 5, 2025');
      });

      test('dateLabel says Edited when updatedAt present', () {
        final note = buildTestNote(
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 6, 20),
        );
        expect(note.dateLabel, 'Edited Jun 20, 2025');
      });

      test('dateLabel says Created when no updatedAt', () {
        final note = buildTestNote(createdAt: DateTime(2025, 3, 5));
        expect(note.dateLabel, 'Created Mar 5, 2025');
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = buildTestNote(
          title: 'Original',
          content: 'Original content',
          tags: ['tag1'],
          isPinned: false,
        );
        final copy = original.copyWith(
          title: 'Updated',
          isPinned: true,
          tags: ['tag1', 'tag2'],
        );

        expect(copy.title, 'Updated');
        expect(copy.content, 'Original content');
        expect(copy.isPinned, true);
        expect(copy.tags, ['tag1', 'tag2']);
        expect(copy.id, original.id);
      });
    });

    group('toJson', () {
      test('serializes all fields including flattened location', () {
        final now = DateTime(2025, 6, 15);
        final note = Note(
          id: 'note-1',
          bookId: 'book-1',
          title: 'Test',
          content: 'Content',
          location: const BookLocation(
            chapter: 2,
            chapterTitle: 'Ch 2',
            pageNumber: 30,
            percentage: 0.1,
          ),
          tags: ['review', 'important'],
          isPinned: true,
          createdAt: now,
          updatedAt: now,
        );

        final json = note.toJson();

        expect(json['id'], 'note-1');
        expect(json['book_id'], 'book-1');
        expect(json['title'], 'Test');
        expect(json['content'], 'Content');
        expect(json['chapter'], 2);
        expect(json['chapter_title'], 'Ch 2');
        expect(json['page_number'], 30);
        expect(json['percentage'], 0.1);
        expect(json['tags'], ['review', 'important']);
        expect(json['is_pinned'], true);
        expect(json['created_at'], now.toIso8601String());
        expect(json['updated_at'], now.toIso8601String());
      });

      test('null location fields serialize as null', () {
        final note = buildTestNote();
        final json = note.toJson();

        expect(json['chapter'], isNull);
        expect(json['chapter_title'], isNull);
        expect(json['page_number'], isNull);
        expect(json['percentage'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields with location', () {
        final json = {
          'id': 'note-1',
          'book_id': 'book-1',
          'title': 'Test',
          'content': 'Content',
          'chapter': 2,
          'chapter_title': 'Ch 2',
          'page_number': 30,
          'percentage': 0.1,
          'tags': ['review'],
          'is_pinned': true,
          'created_at': '2025-06-15T00:00:00.000',
          'updated_at': '2025-06-16T00:00:00.000',
        };

        final note = Note.fromJson(json);

        expect(note.id, 'note-1');
        expect(note.bookId, 'book-1');
        expect(note.title, 'Test');
        expect(note.content, 'Content');
        expect(note.location, isNotNull);
        expect(note.location!.chapter, 2);
        expect(note.location!.chapterTitle, 'Ch 2');
        expect(note.location!.pageNumber, 30);
        expect(note.location!.percentage, 0.1);
        expect(note.tags, ['review']);
        expect(note.isPinned, true);
        expect(note.updatedAt, isNotNull);
      });

      test('deserializes without location when page_number is null', () {
        final json = {
          'id': 'note-1',
          'book_id': 'book-1',
          'title': 'Test',
          'content': 'Content',
          'created_at': '2025-01-01T00:00:00.000',
        };

        final note = Note.fromJson(json);
        expect(note.location, isNull);
      });

      test('defaults for missing optional fields', () {
        final json = {
          'id': 'note-1',
          'book_id': 'book-1',
          'title': 'Test',
          'content': 'Content',
          'created_at': '2025-01-01T00:00:00.000',
        };

        final note = Note.fromJson(json);
        expect(note.tags, isEmpty);
        expect(note.isPinned, false);
        expect(note.updatedAt, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves all data', () {
        final original = Note(
          id: 'note-rt',
          bookId: 'book-rt',
          title: 'Roundtrip',
          content: 'Roundtrip content',
          location: const BookLocation(
            chapter: 3,
            chapterTitle: 'Middle',
            pageNumber: 100,
            percentage: 0.5,
          ),
          tags: ['test', 'roundtrip'],
          isPinned: true,
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 4, 1),
        );

        final restored = Note.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.content, original.content);
        expect(restored.location!.chapter, original.location!.chapter);
        expect(restored.location!.pageNumber, original.location!.pageNumber);
        expect(restored.tags, original.tags);
        expect(restored.isPinned, original.isPinned);
      });
    });
  });
}
