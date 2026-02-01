import 'package:flutter/material.dart';

/// Highlight color options for annotations.
enum HighlightColor {
  yellow,
  green,
  blue,
  pink,
  purple,
  orange,
}

/// Extension to get color values for highlight colors.
extension HighlightColorExtension on HighlightColor {
  /// Get the background color for standard mode.
  Color get color {
    switch (this) {
      case HighlightColor.yellow:
        return const Color(0xFFFFF9C4);
      case HighlightColor.green:
        return const Color(0xFFC8E6C9);
      case HighlightColor.blue:
        return const Color(0xFFBBDEFB);
      case HighlightColor.pink:
        return const Color(0xFFF8BBD0);
      case HighlightColor.purple:
        return const Color(0xFFE1BEE7);
      case HighlightColor.orange:
        return const Color(0xFFFFE0B2);
    }
  }

  /// Get the border/accent color for standard mode.
  Color get accentColor {
    switch (this) {
      case HighlightColor.yellow:
        return const Color(0xFFFBC02D);
      case HighlightColor.green:
        return const Color(0xFF66BB6A);
      case HighlightColor.blue:
        return const Color(0xFF42A5F5);
      case HighlightColor.pink:
        return const Color(0xFFEC407A);
      case HighlightColor.purple:
        return const Color(0xFFAB47BC);
      case HighlightColor.orange:
        return const Color(0xFFFFA726);
    }
  }

  /// Get the display name.
  String get displayName {
    switch (this) {
      case HighlightColor.yellow:
        return 'Yellow';
      case HighlightColor.green:
        return 'Green';
      case HighlightColor.blue:
        return 'Blue';
      case HighlightColor.pink:
        return 'Pink';
      case HighlightColor.purple:
        return 'Purple';
      case HighlightColor.orange:
        return 'Orange';
    }
  }
}

/// Location within a book (for annotations and notes).
class BookLocation {
  final int? chapter;
  final String? chapterTitle;
  final int pageNumber;
  final double? percentage;

  const BookLocation({
    this.chapter,
    this.chapterTitle,
    required this.pageNumber,
    this.percentage,
  });

  /// Get a display-friendly location string.
  String get displayLocation {
    if (chapterTitle != null && chapter != null) {
      return 'Chapter $chapter: $chapterTitle, Page $pageNumber';
    }
    if (chapter != null) {
      return 'Chapter $chapter, Page $pageNumber';
    }
    return 'Page $pageNumber';
  }

  /// Get a short location string.
  String get shortLocation {
    if (chapter != null) {
      return 'Ch. $chapter, p. $pageNumber';
    }
    return 'Page $pageNumber';
  }

  BookLocation copyWith({
    int? chapter,
    String? chapterTitle,
    int? pageNumber,
    double? percentage,
  }) {
    return BookLocation(
      chapter: chapter ?? this.chapter,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      pageNumber: pageNumber ?? this.pageNumber,
      percentage: percentage ?? this.percentage,
    );
  }
}

/// Annotation data model for highlighted text in books.
class Annotation {
  final String id;
  final String bookId;
  final String highlightText;
  final HighlightColor color;
  final BookLocation location;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Annotation({
    required this.id,
    required this.bookId,
    required this.highlightText,
    this.color = HighlightColor.yellow,
    required this.location,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  /// Whether this annotation has an attached note.
  bool get hasNote => note != null && note!.isNotEmpty;

  Annotation copyWith({
    String? id,
    String? bookId,
    String? highlightText,
    HighlightColor? color,
    BookLocation? location,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      highlightText: highlightText ?? this.highlightText,
      color: color ?? this.color,
      location: location ?? this.location,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Sample annotations for development and testing.
  static List<Annotation> getSampleAnnotations(String bookId) {
    final now = DateTime.now();

    // Return different sample data based on bookId
    switch (bookId) {
      case '1': // The Pragmatic Programmer
        return [
          Annotation(
            id: 'ann-1-1',
            bookId: bookId,
            highlightText:
                'There are two ways of constructing a software design: One way is to make it so simple that there are obviously no deficiencies, and the other way is to make it so complicated that there are no obvious deficiencies.',
            color: HighlightColor.yellow,
            location: const BookLocation(
              chapter: 1,
              chapterTitle: 'A Pragmatic Philosophy',
              pageNumber: 15,
              percentage: 0.05,
            ),
            note: 'Great insight about software design approaches',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          Annotation(
            id: 'ann-1-2',
            bookId: bookId,
            highlightText:
                'Don\'t live with broken windows. Fix bad designs, wrong decisions, and poor code when you see them.',
            color: HighlightColor.green,
            location: const BookLocation(
              chapter: 1,
              chapterTitle: 'A Pragmatic Philosophy',
              pageNumber: 23,
              percentage: 0.08,
            ),
            createdAt: now.subtract(const Duration(days: 4)),
          ),
          Annotation(
            id: 'ann-1-3',
            bookId: bookId,
            highlightText:
                'Remember the big picture. Don\'t get so engrossed in the details that you forget to check what\'s happening around you.',
            color: HighlightColor.blue,
            location: const BookLocation(
              chapter: 2,
              chapterTitle: 'A Pragmatic Approach',
              pageNumber: 45,
              percentage: 0.15,
            ),
            note: 'Important reminder for daily work',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          Annotation(
            id: 'ann-1-4',
            bookId: bookId,
            highlightText:
                'DRY—Don\'t Repeat Yourself. Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.',
            color: HighlightColor.pink,
            location: const BookLocation(
              chapter: 2,
              pageNumber: 58,
              percentage: 0.19,
            ),
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ];

      case '2': // Clean Code
        return [
          Annotation(
            id: 'ann-2-1',
            bookId: bookId,
            highlightText:
                'Clean code is simple and direct. Clean code reads like well-written prose.',
            color: HighlightColor.yellow,
            location: const BookLocation(
              chapter: 1,
              chapterTitle: 'Clean Code',
              pageNumber: 12,
              percentage: 0.03,
            ),
            createdAt: now.subtract(const Duration(days: 10)),
          ),
          Annotation(
            id: 'ann-2-2',
            bookId: bookId,
            highlightText:
                'The ratio of time spent reading versus writing is well over 10 to 1.',
            color: HighlightColor.orange,
            location: const BookLocation(
              chapter: 1,
              pageNumber: 18,
              percentage: 0.05,
            ),
            note: 'This is why readability matters so much',
            createdAt: now.subtract(const Duration(days: 9)),
          ),
        ];

      case '3': // Design Patterns
        return [
          Annotation(
            id: 'ann-3-1',
            bookId: bookId,
            highlightText:
                'Program to an interface, not an implementation.',
            color: HighlightColor.purple,
            location: const BookLocation(
              chapter: 1,
              chapterTitle: 'Introduction',
              pageNumber: 32,
              percentage: 0.08,
            ),
            note: 'Fundamental principle of OOP',
            createdAt: now.subtract(const Duration(days: 20)),
          ),
        ];

      default:
        // Return empty list for books without sample annotations
        return [];
    }
  }
}
