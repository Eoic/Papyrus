import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Empty state widget for when a book has no annotations.
class EmptyAnnotationsState extends StatelessWidget {
  final bool isEinkMode;

  const EmptyAnnotationsState({super.key, this.isEinkMode = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isEinkMode) {
      return _buildEinkState(context);
    }

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
              'Highlight text while reading to create annotations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEinkState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.pageMarginsEink),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO ANNOTATIONS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Highlight text while reading to create annotations.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
