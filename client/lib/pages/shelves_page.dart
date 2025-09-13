import 'package:flutter/material.dart';

class ShelvesPage extends StatelessWidget {
  const ShelvesPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shelves")),
      body: const SafeArea(child: Placeholder()), // body: ,
    );
  }
}
