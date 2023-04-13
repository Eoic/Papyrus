import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String labelText;

  const TextInput({
    Key? key,
    required this.labelText
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText
      ),
      onSaved: (value) => { }
    );
  }
}