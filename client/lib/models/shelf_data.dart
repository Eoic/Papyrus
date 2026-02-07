import 'package:flutter/material.dart';

/// Data model for a book shelf (collection).
class ShelfData {
  final String id;
  final String name;
  final String? description;
  final String? colorHex;
  final IconData? icon;
  final int bookCount;
  final List<String> coverPreviewUrls;
  final bool isSmart;
  final String? smartQuery;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShelfData({
    required this.id,
    required this.name,
    this.description,
    this.colorHex,
    this.icon,
    this.bookCount = 0,
    this.coverPreviewUrls = const [],
    this.isSmart = false,
    this.smartQuery,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

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

  /// Get display text for book count.
  String get bookCountLabel {
    if (bookCount == 1) return '1 book';
    return '$bookCount books';
  }

  /// Create a copy with updated fields.
  ShelfData copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    IconData? icon,
    int? bookCount,
    List<String>? coverPreviewUrls,
    bool? isSmart,
    String? smartQuery,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShelfData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      bookCount: bookCount ?? this.bookCount,
      coverPreviewUrls: coverPreviewUrls ?? this.coverPreviewUrls,
      isSmart: isSmart ?? this.isSmart,
      smartQuery: smartQuery ?? this.smartQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Sample shelves for development and testing.
  static List<ShelfData> get sampleShelves {
    final now = DateTime.now();
    return [
      ShelfData(
        id: 'shelf-1',
        name: 'Currently reading',
        description: 'Books I am reading right now',
        colorHex: '#4CAF50',
        icon: Icons.menu_book,
        bookCount: 3,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1401432508i/4099.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg',
        ],
        sortOrder: 0,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      ShelfData(
        id: 'shelf-2',
        name: 'Want to read',
        description: 'My reading backlog',
        colorHex: '#2196F3',
        icon: Icons.bookmark_outline,
        bookCount: 5,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554437249i/6088007.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417900846i/29579.jpg',
        ],
        sortOrder: 1,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ShelfData(
        id: 'shelf-3',
        name: 'Finished',
        description: 'Books I have completed',
        colorHex: '#9C27B0',
        icon: Icons.check_circle_outline,
        bookCount: 4,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436202607i/3735293.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg',
        ],
        sortOrder: 2,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      ShelfData(
        id: 'shelf-4',
        name: 'Technical',
        description: 'Programming and software development books',
        colorHex: '#FF9800',
        icon: Icons.code,
        bookCount: 6,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1401432508i/4099.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436202607i/3735293.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348027904i/85009.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386925632i/44936.jpg',
        ],
        sortOrder: 3,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      ShelfData(
        id: 'shelf-5',
        name: 'Fiction',
        description: 'Novels and fiction books',
        colorHex: '#E91E63',
        icon: Icons.auto_stories,
        bookCount: 4,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg',
        ],
        sortOrder: 4,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      ShelfData(
        id: 'shelf-6',
        name: 'Sci-Fi',
        description: 'Science fiction and space opera',
        colorHex: '#00BCD4',
        icon: Icons.rocket_launch,
        bookCount: 3,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554437249i/6088007.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417900846i/29579.jpg',
        ],
        sortOrder: 5,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      ShelfData(
        id: 'shelf-7',
        name: 'Non-Fiction',
        description: 'History, science, and self-help',
        colorHex: '#795548',
        icon: Icons.school,
        bookCount: 2,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg',
        ],
        sortOrder: 6,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      ShelfData(
        id: 'shelf-8',
        name: 'Reference',
        description: 'Books for quick reference and lookup',
        colorHex: '#607D8B',
        icon: Icons.library_books,
        bookCount: 2,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348027904i/85009.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1344692678i/11724436.jpg',
        ],
        sortOrder: 7,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
    ];
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
}
