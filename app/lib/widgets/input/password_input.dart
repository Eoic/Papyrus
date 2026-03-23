import 'package:flutter/material.dart';

/// A reusable password input field with visibility toggle and validation.
class PasswordInput extends StatefulWidget {
  /// Label text displayed for the input field
  final String labelText;

  /// Optional text controller for the input
  final TextEditingController? controller;

  /// Optional additional validation function
  final String? Function(String?)? extraValidator;

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
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
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
