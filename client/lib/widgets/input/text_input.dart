import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final bool? isDense;
  final bool isRequired;
  final String labelText;
  final TextEditingController? controller;

  const TextInput({
    super.key,
    this.controller,
    this.isRequired = false,
    this.isDense = false,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        isDense: isDense,
    ),
      onSaved: (value) => { },
      controller: controller,
    );
  }
}
