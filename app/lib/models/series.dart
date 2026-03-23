/// Series data model for grouping related books.
class Series {
  final String id;
  final String name;
  final String? description;
  final String? author;
  final int? totalBooks;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Series({
    required this.id,
    required this.name,
    this.description,
    this.author,
    this.totalBooks,
    this.isComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields.
  Series copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    int? totalBooks,
    bool? isComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Series(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      totalBooks: totalBooks ?? this.totalBooks,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'total_books': totalBooks,
      'is_complete': isComplete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      author: json['author'] as String?,
      totalBooks: json['total_books'] as int?,
      isComplete: json['is_complete'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
