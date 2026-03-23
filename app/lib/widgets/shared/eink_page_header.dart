import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Standard header widget for E-ink pages.
///
/// Provides a consistent header with a title and optional trailing widget,
/// styled for E-ink displays with high contrast borders.
class EinkPageHeader extends StatelessWidget {
  /// The title text to display.
  final String title;

  /// Optional widget to display on the right side of the header.
  final Widget? trailing;

  const EinkPageHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: ComponentSizes.einkHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline,
            width: BorderWidths.einkDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
