import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BookLocation', () {
    group('displayLocation', () {
      test('shows chapter title, number, and page when all present', () {
        const loc = BookLocation(
          chapter: 3,
          chapterTitle: 'The Quest',
          pageNumber: 42,
        );
        expect(loc.displayLocation, 'Chapter 3: The Quest, Page 42');
      });

      test('shows chapter number and page when no title', () {
        const loc = BookLocation(chapter: 3, pageNumber: 42);
        expect(loc.displayLocation, 'Chapter 3, Page 42');
      });

      test('shows page only when no chapter', () {
        const loc = BookLocation(pageNumber: 42);
        expect(loc.displayLocation, 'Page 42');
      });
    });

    group('shortLocation', () {
      test('shows abbreviated chapter and page', () {
        const loc = BookLocation(chapter: 3, pageNumber: 42);
        expect(loc.shortLocation, 'Ch. 3, p. 42');
      });

      test('shows page only when no chapter', () {
        const loc = BookLocation(pageNumber: 42);
        expect(loc.shortLocation, 'Page 42');
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = BookLocation(
          chapter: 1,
          chapterTitle: 'Intro',
          pageNumber: 5,
          percentage: 0.01,
        );
        final copy = original.copyWith(pageNumber: 10, percentage: 0.05);

        expect(copy.chapter, 1);
        expect(copy.chapterTitle, 'Intro');
        expect(copy.pageNumber, 10);
        expect(copy.percentage, 0.05);
      });
    });
  });

  group('Annotation', () {
    group('computed properties', () {
      test('highlightText is alias for selectedText', () {
        final annotation = buildTestAnnotation(selectedText: 'Test highlight');
        expect(annotation.highlightText, 'Test highlight');
      });

      test('hasNote is true for non-empty note', () {
        expect(buildTestAnnotation(note: 'A note').hasNote, true);
      });

      test('hasNote is false for null note', () {
        expect(buildTestAnnotation().hasNote, false);
      });

      test('hasNote is false for empty string note', () {
        expect(buildTestAnnotation(note: '').hasNote, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = buildTestAnnotation(
          selectedText: 'Original',
          color: HighlightColor.yellow,
          note: 'Note',
        );
        final copy = original.copyWith(
          color: HighlightColor.blue,
          note: 'Updated note',
        );

        expect(copy.selectedText, 'Original');
        expect(copy.color, HighlightColor.blue);
        expect(copy.note, 'Updated note');
        expect(copy.id, original.id);
      });
    });

    group('toJson', () {
      test('serializes all fields including flattened location', () {
        final now = DateTime(2025, 6, 15);
        final annotation = Annotation(
          id: 'ann-1',
          bookId: 'book-1',
          selectedText: 'Some text',
          color: HighlightColor.green,
          location: const BookLocation(
            chapter: 2,
            chapterTitle: 'Methods',
            pageNumber: 45,
            percentage: 0.15,
          ),
          note: 'Great point',
          createdAt: now,
          updatedAt: now,
        );

        final json = annotation.toJson();

        expect(json['id'], 'ann-1');
        expect(json['book_id'], 'book-1');
        expect(json['selected_text'], 'Some text');
        expect(json['color'], 'green');
        expect(json['chapter'], 2);
        expect(json['chapter_title'], 'Methods');
        expect(json['page_number'], 45);
        expect(json['percentage'], 0.15);
        expect(json['note'], 'Great point');
        expect(json['created_at'], now.toIso8601String());
        expect(json['updated_at'], now.toIso8601String());
      });
    });

    group('fromJson', () {
      test('deserializes all fields and reconstructs BookLocation', () {
        final json = {
          'id': 'ann-1',
          'book_id': 'book-1',
          'selected_text': 'Important passage',
          'color': 'blue',
          'chapter': 5,
          'chapter_title': 'Conclusion',
          'page_number': 200,
          'percentage': 0.8,
          'note': 'Key insight',
          'created_at': '2025-06-15T00:00:00.000',
          'updated_at': '2025-06-16T00:00:00.000',
        };

        final annotation = Annotation.fromJson(json);

        expect(annotation.id, 'ann-1');
        expect(annotation.bookId, 'book-1');
        expect(annotation.selectedText, 'Important passage');
        expect(annotation.color, HighlightColor.blue);
        expect(annotation.location.chapter, 5);
        expect(annotation.location.chapterTitle, 'Conclusion');
        expect(annotation.location.pageNumber, 200);
        expect(annotation.location.percentage, 0.8);
        expect(annotation.note, 'Key insight');
        expect(annotation.updatedAt, isNotNull);
      });

      test('defaults color to yellow when missing', () {
        final json = {
          'id': 'ann-1',
          'book_id': 'book-1',
          'selected_text': 'Text',
          'page_number': 1,
          'created_at': '2025-01-01T00:00:00.000',
        };

        final annotation = Annotation.fromJson(json);
        expect(annotation.color, HighlightColor.yellow);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves all data', () {
        final original = Annotation(
          id: 'ann-rt',
          bookId: 'book-rt',
          selectedText: 'Roundtrip highlight',
          color: HighlightColor.purple,
          location: const BookLocation(
            chapter: 3,
            chapterTitle: 'Middle',
            pageNumber: 100,
            percentage: 0.5,
          ),
          note: 'Roundtrip note',
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 4, 1),
        );

        final restored = Annotation.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.selectedText, original.selectedText);
        expect(restored.color, original.color);
        expect(restored.location.chapter, original.location.chapter);
        expect(restored.location.chapterTitle, original.location.chapterTitle);
        expect(restored.location.pageNumber, original.location.pageNumber);
        expect(restored.location.percentage, original.location.percentage);
        expect(restored.note, original.note);
      });
    });
  });

  group('HighlightColor', () {
    test('displayName returns expected values', () {
      expect(HighlightColor.yellow.displayName, 'Yellow');
      expect(HighlightColor.green.displayName, 'Green');
      expect(HighlightColor.blue.displayName, 'Blue');
      expect(HighlightColor.pink.displayName, 'Pink');
      expect(HighlightColor.purple.displayName, 'Purple');
      expect(HighlightColor.orange.displayName, 'Orange');
    });

    test('all values have non-transparent color and accentColor', () {
      for (final hc in HighlightColor.values) {
        expect(hc.color.a, greaterThan(0));
        expect(hc.accentColor.a, greaterThan(0));
      }
    });
  });
}
