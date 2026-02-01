import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Responsive book card for grid display.
/// - Mobile: 171×256 with 8px gap
/// - Desktop: 200×300 with 16px gap
class BookCard extends StatelessWidget {
  final BookData book;
  final VoidCallback? onTap;
  final bool showProgress;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: AppElevation.level1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCover(context),
                  // Favorite badge
                  if (book.isFavorite)
                    Positioned(
                      top: Spacing.xs,
                      right: Spacing.xs,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: IconSizes.small,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  // Format badge
                  Positioned(
                    bottom: Spacing.xs,
                    left: Spacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        book.formatLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            if (showProgress && book.progress > 0)
              LinearProgressIndicator(
                value: book.progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: book.isFinished
                    ? colorScheme.tertiary
                    : colorScheme.primary,
                minHeight: 3,
              ),
            // Title and author
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (book.coverURL != null && book.coverURL!.isNotEmpty) {
      return Image.network(
        book.coverURL!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: IconSizes.display,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text(
              book.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
