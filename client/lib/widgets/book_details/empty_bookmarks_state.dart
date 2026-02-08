import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Empty state widget for when a book has no bookmarks.
class EmptyBookmarksState extends StatelessWidget {
  final bool isPhysical;
  final VoidCallback? onAddBookmark;

  const EmptyBookmarksState({
    super.key,
    this.isPhysical = false,
    this.onAddBookmark,
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
              Icons.bookmark_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No bookmarks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              isPhysical
                  ? 'Save pages you want to return to later.'
                  : 'Bookmarks you create while reading will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isPhysical) ...[
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: onAddBookmark,
                icon: const Icon(Icons.add),
                label: const Text('Add bookmark'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
