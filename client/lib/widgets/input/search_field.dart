import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A reusable search field widget.
///
/// Provides a consistent search input with a search icon prefix,
/// optional clear button, and Material Design 3 styling.
///
/// ```dart
/// SearchField(
///   controller: _searchController,
///   hintText: 'Search notes...',
///   onChanged: (value) => setState(() => _query = value),
///   onClear: () => setState(() => _query = ''),
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

  /// Height of the search field. Defaults to 40.
  final double? height;

  /// Creates a search field widget.
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.height,
  });

  /// Whether the search field has text content.
  bool get _hasContent => controller.text.isNotEmpty;

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
      height: height ?? 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
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
        ),
      ),
    );
  }
}
