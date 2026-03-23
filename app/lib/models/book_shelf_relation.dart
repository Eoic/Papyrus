/// Junction table model for book-shelf relationships.
class BookShelfRelation {
  final String bookId;
  final String shelfId;
  final DateTime addedAt;
  final int sortOrder;

  const BookShelfRelation({
    required this.bookId,
    required this.shelfId,
    required this.addedAt,
    this.sortOrder = 0,
  });

  /// Create a copy with updated fields.
  BookShelfRelation copyWith({
    String? bookId,
    String? shelfId,
    DateTime? addedAt,
    int? sortOrder,
  }) {
    return BookShelfRelation(
      bookId: bookId ?? this.bookId,
      shelfId: shelfId ?? this.shelfId,
      addedAt: addedAt ?? this.addedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'shelf_id': shelfId,
      'added_at': addedAt.toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  /// Create from JSON.
  factory BookShelfRelation.fromJson(Map<String, dynamic> json) {
    return BookShelfRelation(
      bookId: json['book_id'] as String,
      shelfId: json['shelf_id'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookShelfRelation &&
        other.bookId == bookId &&
        other.shelfId == shelfId;
  }

  @override
  int get hashCode => Object.hash(bookId, shelfId);
}
