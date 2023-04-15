import "package:flutter/material.dart";

class EmailInput extends StatelessWidget {
  final String labelText;
  final TextEditingController? controller;

  const EmailInput({
    super.key,
    this.controller,
    required this.labelText
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(
          Icons.email,
          color: Colors.grey.shade600,
        )
      ),
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }

        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
          return "Not a valid email";
        }

        return null;
      },
    );
  }
}
