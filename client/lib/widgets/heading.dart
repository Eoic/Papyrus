import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  final String subtitle;

  const Heading({
    Key? key,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.book_outlined,
              size: 64.0,
            ),
            Text(
              "Papyrus",
              style: TextStyle(
                fontSize: 36,
                color: Colors.black87
              ),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16
              ),
            ),
          ],
        )
      ],
    );
  }
}