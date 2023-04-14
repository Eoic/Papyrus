import 'package:flutter/material.dart';

class TitledDivider extends StatelessWidget {
  final String title;

  const TitledDivider({ super.key, required this.title });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 0.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: 1.5,
              color: Colors.grey[400]
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline
              )
            )
          ),
          Expanded(
            child: Divider(
              thickness: 1.5,
              color: Colors.grey[400]
            )
          )
        ],
      ),
    );
  }
}