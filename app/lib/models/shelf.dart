import 'package:flutter/material.dart';

/// Backwards compatibility alias.
typedef ShelfData = Shelf;

/// Lightweight cover preview data for shelf mosaic.
class CoverPreview {
  final String bookId;
  final String? url;
  final String? mediaId;
  final String title;

  const CoverPreview({required this.bookId, this.url, this.mediaId, required this.title});
}

/// Stored icon identity, including icons unavailable in this app's font bundle.
class ShelfIconDescriptor {
  final int codePoint;
  final String? fontFamily;
  final String? fontPackage;
  final bool matchTextDirection;

  const ShelfIconDescriptor({
    required this.codePoint,
    this.fontFamily,
    this.fontPackage,
    this.matchTextDirection = false,
  });

  factory ShelfIconDescriptor.fromIcon(IconData icon) => ShelfIconDescriptor(
    codePoint: icon.codePoint,
    fontFamily: icon.fontFamily,
    fontPackage: icon.fontPackage,
    matchTextDirection: icon.matchTextDirection,
  );

  bool matches(IconData icon) =>
      codePoint == icon.codePoint &&
      fontFamily == icon.fontFamily &&
      fontPackage == icon.fontPackage &&
      matchTextDirection == icon.matchTextDirection;
}

/// Data model for a book shelf (collection).
class Shelf {
  final String id;
  final String name;
  final String? description;
  final String? colorHex;
  final IconData? icon;
  final ShelfIconDescriptor? _storedIconDescriptor;
  final String? parentShelfId;
  final bool isSmart;
  final String? smartQuery;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties (populated from DataStore)
  final int bookCount;
  final List<CoverPreview> coverPreviews;

  const Shelf({
    required this.id,
    required this.name,
    this.description,
    this.colorHex,
    this.icon,
    ShelfIconDescriptor? iconDescriptor,
    this.parentShelfId,
    this.isSmart = false,
    this.smartQuery,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.bookCount = 0,
    this.coverPreviews = const [],
  }) : _storedIconDescriptor = iconDescriptor;

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

  /// The original identity is independent of the icon used for rendering.
  ShelfIconDescriptor? get iconDescriptor =>
      _storedIconDescriptor ?? (icon == null ? null : ShelfIconDescriptor.fromIcon(icon!));

  /// Create a copy with updated fields.
  Shelf copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    String? colorHex,
    bool clearColorHex = false,
    IconData? icon,
    bool clearIcon = false,
    String? parentShelfId,
    bool clearParentShelfId = false,
    bool? isSmart,
    String? smartQuery,
    bool clearSmartQuery = false,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookCount,
    List<CoverPreview>? coverPreviews,
  }) {
    return Shelf(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      colorHex: clearColorHex ? null : colorHex ?? this.colorHex,
      icon: clearIcon ? null : icon ?? this.icon,
      // Editors also pass the unchanged display icon when editing other fields.
      iconDescriptor: clearIcon || (icon != null && icon != this.icon) ? null : _storedIconDescriptor,
      parentShelfId: clearParentShelfId ? null : parentShelfId ?? this.parentShelfId,
      isSmart: isSmart ?? this.isSmart,
      smartQuery: clearSmartQuery ? null : smartQuery ?? this.smartQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookCount: bookCount ?? this.bookCount,
      coverPreviews: coverPreviews ?? this.coverPreviews,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    final descriptor = iconDescriptor;
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'icon': descriptor?.codePoint,
      'icon_font_family': descriptor?.fontFamily,
      'icon_font_package': descriptor?.fontPackage,
      'icon_match_text_direction': descriptor?.matchTextDirection ?? false,
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
    final codePoint = json['icon'] as int?;
    final descriptor = codePoint == null
        ? null
        : ShelfIconDescriptor(
            codePoint: codePoint,
            // Legacy shelf JSON stored only the Material icon's code point.
            fontFamily: json.containsKey('icon_font_family')
                ? json['icon_font_family'] as String?
                : Icons.folder_outlined.fontFamily,
            fontPackage: json['icon_font_package'] as String?,
            matchTextDirection: json['icon_match_text_direction'] as bool? ?? false,
          );
    return Shelf(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      colorHex: json['color_hex'] as String?,
      icon: _iconFromDescriptor(descriptor),
      iconDescriptor: descriptor,
      parentShelfId: json['parent_shelf_id'] as String?,
      isSmart: json['is_smart'] as bool? ?? false,
      smartQuery: json['smart_query'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Resolve a stored descriptor to a constant display icon.
  /// Only returns icons from availableIcons to allow tree shaking.
  static IconData? _iconFromDescriptor(ShelfIconDescriptor? descriptor) {
    if (descriptor == null) return null;
    // Look up in available icons only (for tree shaking compatibility)
    for (final icon in availableIcons) {
      if (descriptor.matches(icon)) return icon;
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
