import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Empty state widget for when a book has no annotations.
class EmptyAnnotationsState extends StatelessWidget {
  final bool isPhysical;
  final VoidCallback? onAddAnnotation;

  const EmptyAnnotationsState({
    super.key,
    this.isPhysical = false,
    this.onAddAnnotation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.highlight_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No annotations yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              isPhysical
                  ? 'Add passages you\'ve highlighted or underlined in your book.'
                  : 'Highlight text while reading to create annotations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isPhysical) ...[
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: onAddAnnotation,
                icon: const Icon(Icons.add),
                label: const Text('Add annotation'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
