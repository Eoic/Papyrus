import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A horizontal divider with centered title text.
/// Supports standard and e-ink display modes.
class TitledDivider extends StatelessWidget {
  /// The title text to display in the center
  final String title;

  /// Whether to display in e-ink optimized mode
  final bool isEink;

  /// Vertical padding around the divider
  final double? verticalPadding;

  const TitledDivider({
    super.key,
    required this.title,
    this.isEink = false,
    this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = verticalPadding ?? Spacing.lg;

    if (isEink) {
      return _buildEinkDivider(theme, padding);
    }

    return _buildStandardDivider(theme, padding);
  }

  Widget _buildStandardDivider(ThemeData theme, double padding) {
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

  Widget _buildEinkDivider(ThemeData theme, double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Color(0xFFC0C0C0), // EinkColors.lightGray
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Color(0xFF404040), // EinkColors.darkGray
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Color(0xFFC0C0C0), // EinkColors.lightGray
            ),
          ),
        ],
      ),
    );
  }
}
