import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Developer options use the current theme and the same layout on every display.
class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Developer options')),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.all(Spacing.md), children: const []),
    ),
  );
}
