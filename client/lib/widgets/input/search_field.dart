import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A reusable search field widget with standard and e-ink mode support.
///
/// This widget provides a consistent search input experience across the app
/// with automatic styling for different display modes. It handles:
/// - Standard mode: Material Design 3 styled input with rounded corners
/// - E-ink mode: High-contrast styling with sharp corners and thicker borders
///
/// ## Usage
///
/// ```dart
/// SearchField(
///   controller: _searchController,
///   hintText: 'Search notes...',
///   onChanged: (value) => setState(() => _query = value),
///   onClear: () => setState(() => _query = ''),
/// )
/// ```
///
/// For e-ink devices, set [isEinkMode] to true:
///
/// ```dart
/// SearchField(
///   controller: _searchController,
///   hintText: 'Search...',
///   isEinkMode: true,
///   onChanged: _handleSearch,
/// )
/// ```
class SearchField extends StatelessWidget {
  /// Controller for the text field.
  final TextEditingController controller;

  /// Placeholder text shown when the field is empty.
  final String hintText;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the clear button is pressed.
  ///
  /// If not provided but [onChanged] is, the clear button will call
  /// [onChanged] with an empty string.
  final VoidCallback? onClear;

  /// Whether to use e-ink optimized styling.
  ///
  /// When true, applies high-contrast borders and removes rounded corners
  /// for better visibility on e-ink displays.
  final bool isEinkMode;

  /// Height of the search field.
  ///
  /// Defaults to 40 for standard mode and [TouchTargets.einkMin] for e-ink.
  final double? height;

  /// Creates a search field widget.
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.isEinkMode = false,
    this.height,
  });

  /// Whether the search field has text content.
  bool get _hasContent => controller.text.isNotEmpty;

  /// Effective height based on mode.
  double get _effectiveHeight =>
      height ?? (isEinkMode ? TouchTargets.einkMin : 40);

  void _handleClear() {
    controller.clear();
    if (onClear != null) {
      onClear!();
    } else {
      onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _effectiveHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: _buildDecoration(context),
      ),
    );
  }

  /// Builds the input decoration based on display mode.
  InputDecoration _buildDecoration(BuildContext context) {
    if (isEinkMode) {
      return _buildEinkDecoration();
    }

    return _buildStandardDecoration();
  }

  /// Standard Material Design 3 decoration.
  InputDecoration _buildStandardDecoration() {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search, size: 20),
      suffixIcon: _hasContent
          ? IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _handleClear,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      isDense: true,
    );
  }

  /// High-contrast decoration optimized for e-ink displays.
  InputDecoration _buildEinkDecoration() {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _hasContent
          ? IconButton(icon: const Icon(Icons.close), onPressed: _handleClear)
          : null,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
    );
  }
}
