import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A reusable password input field with visibility toggle and validation.
/// Supports standard and e-ink display modes.
class PasswordInput extends StatefulWidget {
  /// Label text displayed for the input field
  final String labelText;

  /// Optional text controller for the input
  final TextEditingController? controller;

  /// Optional additional validation function
  final String? Function(String?)? extraValidator;

  /// Whether to display in e-ink optimized mode
  final bool isEink;

  /// Optional focus node for managing focus
  final FocusNode? focusNode;

  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;

  /// Text input action for the keyboard
  final TextInputAction? textInputAction;

  /// Callback when the field is submitted
  final ValueChanged<String>? onFieldSubmitted;

  const PasswordInput({
    super.key,
    this.controller,
    this.extraValidator,
    required this.labelText,
    this.isEink = false,
    this.focusNode,
    this.onEditingComplete,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _isTextHidden = true;

  void _toggleVisibility() {
    setState(() => _isTextHidden = !_isTextHidden);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isEink) {
      return _buildEinkInput(theme);
    }

    return _buildStandardInput(theme);
  }

  Widget _buildStandardInput(ThemeData theme) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.labelText,
        suffixIcon: IconButton(
          onPressed: _toggleVisibility,
          icon: Icon(
            _isTextHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      obscureText: _isTextHidden,
      enableSuggestions: false,
      autocorrect: false,
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: _validate,
    );
  }

  Widget _buildEinkInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label above the input (no floating labels for e-ink)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Text(
            widget.labelText.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Input field with text toggle button
        SizedBox(
          height: ComponentSizes.inputHeightEink,
          child: TextFormField(
            decoration: InputDecoration(
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
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkFocused,
                ),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkError,
                ),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkError,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
              // No floating label for e-ink
              floatingLabelBehavior: FloatingLabelBehavior.never,
              hintText: 'Enter password',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 18),
              // Text button instead of icon for e-ink
              suffixIcon: TextButton(
                onPressed: _toggleVisibility,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                child: Text(_isTextHidden ? 'SHOW' : 'HIDE'),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            obscureText: _isTextHidden,
            enableSuggestions: false,
            autocorrect: false,
            controller: widget.controller,
            focusNode: widget.focusNode,
            textInputAction: widget.textInputAction ?? TextInputAction.done,
            onEditingComplete: widget.onEditingComplete,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: _validate,
          ),
        ),
      ],
    );
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (widget.extraValidator != null) {
      return widget.extraValidator!.call(value);
    }

    return null;
  }
}
