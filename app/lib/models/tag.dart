import 'package:flutter/material.dart';

/// Tag data model for categorizing books (called "Topics" in UI).
class Tag {
  final String id;
  final String name;
  final String colorHex;
  final String? description;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.colorHex,
    this.description,
    required this.createdAt,
  });

  /// Get the color from hex string.
  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Create a copy with updated fields.
  Tag copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? description,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Predefined tag colors for the color picker.
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
    '#FF9800', // Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];
}
