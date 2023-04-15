import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final bool isRequired;
  final String labelText;
  final TextEditingController? controller;

  const TextInput({
    super.key,
    this.controller,
    this.isRequired = false,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText
      ),
      onSaved: (value) => { },
      controller: controller,
    );
  }
}
