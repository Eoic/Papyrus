import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  final String subtitle;

  const Heading({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage("assets/images/logo.png"),
                height: 64.0,
              ),
              const SizedBox(width: 12.0),
              Text("Papyrus", style: Theme.of(context).textTheme.displayMedium),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text(subtitle, style: const TextStyle(fontSize: 16))],
          ),
        ],
      ),
    );
  }
}
