import 'package:flutter/material.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Goals")),
      body: const SafeArea(child: Placeholder()), // body: ,
    );
  }
}
