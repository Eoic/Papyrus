/// Junction table model for book-tag relationships.
class BookTagRelation {
  final String bookId;
  final String tagId;
  final DateTime createdAt;

  const BookTagRelation({
    required this.bookId,
    required this.tagId,
    required this.createdAt,
  });

  /// Create a copy with updated fields.
  BookTagRelation copyWith({
    String? bookId,
    String? tagId,
    DateTime? createdAt,
  }) {
    return BookTagRelation(
      bookId: bookId ?? this.bookId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'tag_id': tagId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory BookTagRelation.fromJson(Map<String, dynamic> json) {
    return BookTagRelation(
      bookId: json['book_id'] as String,
      tagId: json['tag_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookTagRelation &&
        other.bookId == bookId &&
        other.tagId == tagId;
  }

  @override
  int get hashCode => Object.hash(bookId, tagId);
}
