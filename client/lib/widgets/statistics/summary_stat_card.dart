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

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const SummaryStatCard({
    super.key,
    required this.value,
    required this.label,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkCard(context);
    return _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
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
            style: (isDesktop ? textTheme.headlineMedium : textTheme.headlineSmall)
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

  Widget _buildEinkCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // E-ink uses label-value pairs, not cards
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
