import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  const Search({ super.key });

  @override
  Widget build(BuildContext context) {
    return
      TextFormField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Search...",
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(icon: const Icon(Icons.filter_alt), onPressed: () {  },)
        ),
        onSaved: (value) => { },
        // controller: controller,
      );
  }
}
