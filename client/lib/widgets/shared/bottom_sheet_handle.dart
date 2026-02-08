import 'package:flutter/material.dart';

/// A drag handle displayed at the top of bottom sheets.
///
/// A centered 40x4 rounded pill that signals to users they can drag
/// the bottom sheet.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
