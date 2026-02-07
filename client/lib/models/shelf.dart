import 'package:flutter/material.dart';

/// Backwards compatibility alias.
typedef ShelfData = Shelf;

/// Data model for a book shelf (collection).
class Shelf {
  final String id;
  final String name;
  final String? description;
  final String? colorHex;
  final IconData? icon;
  final String? parentShelfId;
  final bool isSmart;
  final String? smartQuery;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties (populated from DataStore)
  final int bookCount;
  final List<String> coverPreviewUrls;

  const Shelf({
    required this.id,
    required this.name,
    this.description,
    this.colorHex,
    this.icon,
    this.parentShelfId,
    this.isSmart = false,
    this.smartQuery,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.bookCount = 0,
    this.coverPreviewUrls = const [],
  });

  /// Get display text for book count.
  String get bookCountLabel {
    if (bookCount == 1) return '1 book';
    return '$bookCount books';
  }

  /// Get the color from hex string.
  Color? get color {
    if (colorHex == null) return null;
    try {
      final hex = colorHex!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }

  /// Get default icon if none specified.
  IconData get displayIcon => icon ?? Icons.folder_outlined;

  /// Create a copy with updated fields.
  Shelf copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    IconData? icon,
    String? parentShelfId,
    bool? isSmart,
    String? smartQuery,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookCount,
    List<String>? coverPreviewUrls,
  }) {
    return Shelf(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      parentShelfId: parentShelfId ?? this.parentShelfId,
      isSmart: isSmart ?? this.isSmart,
      smartQuery: smartQuery ?? this.smartQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookCount: bookCount ?? this.bookCount,
      coverPreviewUrls: coverPreviewUrls ?? this.coverPreviewUrls,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'icon': icon?.codePoint,
      'parent_shelf_id': parentShelfId,
      'is_smart': isSmart,
      'smart_query': smartQuery,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      colorHex: json['color_hex'] as String?,
      icon: _iconFromCodePoint(json['icon'] as int?),
      parentShelfId: json['parent_shelf_id'] as String?,
      isSmart: json['is_smart'] as bool? ?? false,
      smartQuery: json['smart_query'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert icon code point to IconData.
  /// Returns null if codePoint is null.
  /// Only returns icons from availableIcons to allow tree shaking.
  static IconData? _iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    // Look up in available icons only (for tree shaking compatibility)
    for (final icon in availableIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    // Return default icon if not found (instead of creating non-const IconData)
    return Icons.folder_outlined;
  }

  /// Predefined shelf colors for the color picker.
  static const List<String> availableColors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  /// Predefined shelf icons for the icon picker.
  static const List<IconData> availableIcons = [
    Icons.folder_outlined,
    Icons.menu_book,
    Icons.auto_stories,
    Icons.bookmark_outline,
    Icons.check_circle_outline,
    Icons.star_outline,
    Icons.favorite_outline,
    Icons.library_books,
    Icons.school,
    Icons.code,
    Icons.science,
    Icons.rocket_launch,
    Icons.psychology,
    Icons.history_edu,
    Icons.brush,
    Icons.music_note,
    Icons.sports_esports,
    Icons.travel_explore,
  ];

  /// Sample shelves for backwards compatibility.
  static List<Shelf> get sampleShelves {
    final now = DateTime.now();
    return [
      Shelf(
        id: 'shelf-1',
        name: 'Currently reading',
        description: 'Books I am reading right now',
        colorHex: '#4CAF50',
        icon: Icons.menu_book,
        sortOrder: 0,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Shelf(
        id: 'shelf-2',
        name: 'Want to read',
        description: 'My reading backlog',
        colorHex: '#2196F3',
        icon: Icons.bookmark_outline,
        sortOrder: 1,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Shelf(
        id: 'shelf-3',
        name: 'Finished',
        description: 'Books I have completed',
        colorHex: '#9C27B0',
        icon: Icons.check_circle_outline,
        sortOrder: 2,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      Shelf(
        id: 'shelf-4',
        name: 'Technical',
        description: 'Programming and software development books',
        colorHex: '#FF9800',
        icon: Icons.code,
        sortOrder: 3,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Shelf(
        id: 'shelf-5',
        name: 'Fiction',
        description: 'Novels and fiction books',
        colorHex: '#E91E63',
        icon: Icons.auto_stories,
        sortOrder: 4,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Shelf(
        id: 'shelf-6',
        name: 'Sci-Fi',
        description: 'Science fiction and space opera',
        colorHex: '#00BCD4',
        icon: Icons.rocket_launch,
        sortOrder: 5,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Shelf(
        id: 'shelf-7',
        name: 'Non-Fiction',
        description: 'History, science, and self-help',
        colorHex: '#795548',
        icon: Icons.school,
        sortOrder: 6,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Shelf(
        id: 'shelf-8',
        name: 'Reference',
        description: 'Books for quick reference and lookup',
        colorHex: '#607D8B',
        icon: Icons.library_books,
        sortOrder: 7,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
    ];
  }
}
