import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: "Search...",
            isDense: true,
            // prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () {
                context.pushNamed('SEARCH_OPTIONS');
              },
            ),
          ),
          onSaved: (value) => {},
          // controller: controller,
        ),
      ],
    );
  }
}
