import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Card displaying a single summary statistic.
class SummaryStatCard extends StatelessWidget {
  /// The value to display (e.g., "45", "3.5h").
  final String value;

  /// The label below the value (e.g., "books").
  final String label;

  /// Whether to use desktop styling (larger).
  final bool isDesktop;

  const SummaryStatCard({
    super.key,
    required this.value,
    required this.label,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? Spacing.md : Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style:
                (isDesktop ? textTheme.headlineMedium : textTheme.headlineSmall)
                    ?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
