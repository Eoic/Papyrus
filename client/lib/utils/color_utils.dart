import 'package:flutter/material.dart';

/// Parses a hex color string (e.g. '#FF5722' or 'FF5722') into a [Color].
///
/// Returns [Colors.blue] if parsing fails.
Color parseHexColor(String hex) {
  try {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexValue', radix: 16));
  } catch (_) {
    return Colors.blue;
  }
}

/// Returns black or white depending on which has better contrast against
/// [color], based on its luminance.
Color getContrastColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}
