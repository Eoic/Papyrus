import 'package:papyrus/models/annotation.dart';

/// Note data model for user notes about books.
class Note {
  final String id;
  final String bookId;
  final String title;
  final String content;
  final BookLocation? location;
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Note({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    this.location,
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get a preview of the content (first 100 characters).
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  /// Whether this note has a specific location in the book.
  bool get hasLocation => location != null;

  /// Whether this note has any tags.
  bool get hasTags => tags.isNotEmpty;

  /// Get formatted date string for display.
  String get formattedDate {
    final date = updatedAt ?? createdAt;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Get date label (Created or Edited).
  String get dateLabel {
    if (updatedAt != null) {
      return 'Edited $formattedDate';
    }
    return 'Created $formattedDate';
  }

  Note copyWith({
    String? id,
    String? bookId,
    String? title,
    String? content,
    BookLocation? location,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      content: content ?? this.content,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'title': title,
      'content': content,
      'chapter': location?.chapter,
      'chapter_title': location?.chapterTitle,
      'page_number': location?.pageNumber,
      'percentage': location?.percentage,
      'tags': tags,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory Note.fromJson(Map<String, dynamic> json) {
    final hasLocation = json['page_number'] != null;
    return Note(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      location: hasLocation
          ? BookLocation(
              chapter: json['chapter'] as int?,
              chapterTitle: json['chapter_title'] as String?,
              pageNumber: json['page_number'] as int,
              percentage: (json['percentage'] as num?)?.toDouble(),
            )
          : null,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Sample notes for development and testing.
  static List<Note> getSampleNotes(String bookId) {
    final now = DateTime.now();

    switch (bookId) {
      case '1': // The Pragmatic Programmer
        return [
          Note(
            id: 'note-1-1',
            bookId: bookId,
            title: 'Key Takeaways from Chapter 1',
            content:
                'The pragmatic philosophy emphasizes taking responsibility for your work and career. Key points:\n\n'
                '• Own your mistakes and learn from them\n'
                '• Don\'t make excuses, provide solutions\n'
                '• Be a catalyst for change\n'
                '• Remember the big picture while working on details',
            tags: ['summary', 'important'],
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(days: 1)),
          ),
          Note(
            id: 'note-1-2',
            bookId: bookId,
            title: 'DRY Principle Applications',
            content:
                'Ways to apply the DRY principle in daily coding:\n\n'
                '1. Extract common logic into functions\n'
                '2. Use configuration files instead of hardcoded values\n'
                '3. Create reusable components\n'
                '4. Avoid copy-paste coding\n'
                '5. Document decisions in one place',
            location: const BookLocation(chapter: 2, pageNumber: 58),
            tags: ['principle', 'practice'],
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          Note(
            id: 'note-1-3',
            bookId: bookId,
            title: 'Questions to Research',
            content:
                '- How does the "tracer bullet" approach differ from prototyping?\n'
                '- What are good examples of "orthogonality" in modern frameworks?\n'
                '- How to implement "design by contract" in dynamic languages?',
            tags: ['questions'],
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ];

      case '2': // Clean Code
        return [
          Note(
            id: 'note-2-1',
            bookId: bookId,
            title: 'Naming Conventions Checklist',
            content:
                'When naming variables, functions, and classes:\n\n'
                '□ Use intention-revealing names\n'
                '□ Avoid disinformation\n'
                '□ Make meaningful distinctions\n'
                '□ Use pronounceable names\n'
                '□ Use searchable names\n'
                '□ Avoid encodings',
            tags: ['checklist', 'naming'],
            createdAt: now.subtract(const Duration(days: 8)),
          ),
        ];

      case '4': // Refactoring
        return [
          Note(
            id: 'note-4-1',
            bookId: bookId,
            title: 'Code Smells Reference',
            content:
                'Common code smells to watch for:\n\n'
                '• Duplicated Code\n'
                '• Long Method\n'
                '• Large Class\n'
                '• Long Parameter List\n'
                '• Divergent Change\n'
                '• Feature Envy\n'
                '• Data Clumps',
            tags: ['reference', 'code-smells'],
            createdAt: now.subtract(const Duration(days: 15)),
          ),
        ];

      default:
        return [];
    }
  }
}
