import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A reusable email input field with validation.
/// Supports standard and e-ink display modes.
class EmailInput extends StatelessWidget {
  /// Label text displayed for the input field
  final String labelText;

  /// Optional text controller for the input
  final TextEditingController? controller;

  /// Whether to display in e-ink optimized mode
  final bool isEink;

  /// Optional focus node for managing focus
  final FocusNode? focusNode;

  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;

  /// Text input action for the keyboard
  final TextInputAction? textInputAction;

  const EmailInput({
    super.key,
    this.controller,
    required this.labelText,
    this.isEink = false,
    this.focusNode,
    this.onEditingComplete,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEink) {
      return _buildEinkInput(theme);
    }

    return _buildStandardInput(theme);
  }

  Widget _buildStandardInput(ThemeData theme) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(
          Icons.email_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      onEditingComplete: onEditingComplete,
      autocorrect: false,
      enableSuggestions: false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validateEmail,
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
            labelText.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Input field
        TextFormField(
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
            hintText: 'Enter email address',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 18),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: textInputAction ?? TextInputAction.next,
          onEditingComplete: onEditingComplete,
          autocorrect: false,
          enableSuggestions: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: _validateEmail,
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (!RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value)) {
      return 'Not a valid email';
    }

    return null;
  }
}
