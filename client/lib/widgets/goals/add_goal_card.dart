import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Placeholder card for adding a new goal.
class AddGoalCard extends StatelessWidget {
  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to use desktop styling (larger).
  final bool isDesktop;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const AddGoalCard({
    super.key,
    this.onTap,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? Spacing.lg : Spacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 28,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Add new goal',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Create custom goals\nto track progress',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEinkCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: TouchTargets.einkMin),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'ADD NEW GOAL',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
