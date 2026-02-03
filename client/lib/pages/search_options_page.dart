import 'package:flutter/material.dart';

class SearchOptionsPage extends StatelessWidget {
  const SearchOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search options")),
      body: const SafeArea(child: Placeholder()), // body: ,
    );
  }
}
