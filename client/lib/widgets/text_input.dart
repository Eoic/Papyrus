import 'package:client/types/input_type.dart';
import 'package:flutter/material.dart';

class TextInput extends StatefulWidget {
  final String labelText;
  final InputType type;
  final TextEditingController? controller;
  bool isTextHidden = true;

  TextInput({
    super.key,
    required this.labelText,
    required this.type,
    this.controller
  });

  @override
  _TextInput createState() => _TextInput();
}

class _TextInput extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case InputType.password:
        return TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.labelText,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  widget.isTextHidden = !widget.isTextHidden;
                });
              },
              icon: Icon(
                widget.isTextHidden ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              )
            )
          ),
          obscureText: widget.isTextHidden,
          enableSuggestions: false,
          autocorrect: false,
          onSaved: (value) => { },
          controller: widget.controller,
        );

      case InputType.email:
        return TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.labelText,
            suffixIcon: Icon(
              Icons.email,
              color: Colors.grey.shade600,
            )
          ),
          onSaved: (value) => { },
          controller: widget.controller,
        );

      default:
        return TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.labelText
          ),
          onSaved: (value) => { },
          controller: widget.controller,
        );
    }
  }
}