import 'package:client/types/input_type.dart';
import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String labelText;
  final InputType type;

  const TextInput({
    Key? key,
    required this.labelText,
    required this.type
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case InputType.password:
        return TextFormField(
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: labelText
          ),
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          onSaved: (value) => { }
        );
      default:
        return TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: labelText
          ),
          onSaved: (value) => { }
        );
    }
  }
}