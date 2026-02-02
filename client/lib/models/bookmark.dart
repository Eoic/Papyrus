import 'package:flutter/material.dart';

/// Bookmark data model for saved positions within books.
class Bookmark {
  final String id;
  final String bookId;
  final double position; // 0.0 to 1.0
  final int? pageNumber;
  final String? chapterTitle;
  final String? note;
  final String colorHex;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.position,
    this.pageNumber,
    this.chapterTitle,
    this.note,
    this.colorHex = '#FF5722', // Deep Orange default
    required this.createdAt,
  });

  /// Get the color from hex string.
  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFFF5722);
    }
  }

  /// Get a display-friendly location string.
  String get displayLocation {
    if (chapterTitle != null && pageNumber != null) {
      return '$chapterTitle, Page $pageNumber';
    }
    if (pageNumber != null) {
      return 'Page $pageNumber';
    }
    return '${(position * 100).round()}%';
  }

  /// Whether this bookmark has a note.
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Create a copy with updated fields.
  Bookmark copyWith({
    String? id,
    String? bookId,
    double? position,
    int? pageNumber,
    String? chapterTitle,
    String? note,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      position: position ?? this.position,
      pageNumber: pageNumber ?? this.pageNumber,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'position': position,
      'page_number': pageNumber,
      'chapter_title': chapterTitle,
      'note': note,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      position: (json['position'] as num).toDouble(),
      pageNumber: json['page_number'] as int?,
      chapterTitle: json['chapter_title'] as String?,
      note: json['note'] as String?,
      colorHex: json['color_hex'] as String? ?? '#FF5722',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Predefined bookmark colors.
  static const List<String> availableColors = [
    '#FF5722', // Deep Orange (default)
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FFC107', // Amber
  ];
}
