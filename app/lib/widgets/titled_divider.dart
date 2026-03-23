import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A horizontal divider with centered title text.
class TitledDivider extends StatelessWidget {
  /// The title text to display in the center
  final String title;

  /// Vertical padding around the divider
  final double? verticalPadding;

  const TitledDivider({super.key, required this.title, this.verticalPadding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = verticalPadding ?? Spacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: 1.5,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: 1.5,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
