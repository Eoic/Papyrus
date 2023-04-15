import 'package:flutter/material.dart';

class PasswordInput extends StatefulWidget {
  final String labelText;
  final TextEditingController? controller;
  final Function(String?)? extraValidator;

  const PasswordInput({
    super.key,
    this.controller,
    this.extraValidator,
    required this.labelText,
  });

  @override
  State<PasswordInput> createState() => _PasswordInput();
}

class _PasswordInput extends State<PasswordInput> {
  bool isTextHidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.labelText,
        suffixIcon: IconButton(
          onPressed: () => setState(() => isTextHidden = !isTextHidden),
          icon: Icon(
            isTextHidden ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          )
        )
      ),
      obscureText: isTextHidden,
      enableSuggestions: false,
      autocorrect: false,
      controller: widget.controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }

        if (widget.extraValidator != null) {
          return widget.extraValidator!.call(value);
        }

        return null;
      },
    );
  }
}