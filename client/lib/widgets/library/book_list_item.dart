import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// List row for displaying books, optimized for e-ink.
/// - Standard: 80px height with cover thumbnail
/// - E-ink: 96px height with larger touch target, 64×96 thumbnail
class BookListItem extends StatelessWidget {
  final BookData book;
  final VoidCallback? onTap;
  final bool showProgress;

  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEink = context.watch<DisplayModeProvider>().isEinkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final itemHeight = isEink ? 96.0 : 80.0;
    final thumbnailWidth = isEink ? 64.0 : 54.0;
    final thumbnailHeight = isEink ? 96.0 : 80.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: itemHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isEink ? Spacing.md : Spacing.sm,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: isEink ? BorderWidths.einkDefault : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Cover thumbnail
              SizedBox(
                width: thumbnailWidth,
                height: thumbnailHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    isEink ? AppRadius.einkCard : AppRadius.sm,
                  ),
                  child: _buildCover(context),
                ),
              ),
              SizedBox(width: isEink ? Spacing.md : Spacing.sm),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showProgress && book.progress > 0) ...[
                      const SizedBox(height: Spacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: book.progress,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: book.isFinished
                                  ? colorScheme.tertiary
                                  : colorScheme.primary,
                              minHeight: isEink ? 4 : 3,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            book.progressLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing indicators
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Format badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isEink
                          ? Border.all(color: colorScheme.outline)
                          : null,
                    ),
                    child: Text(
                      book.formatLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (book.isFavorite) ...[
                    const SizedBox(height: Spacing.xs),
                    Icon(
                      Icons.favorite,
                      size: IconSizes.indicator,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    if (book.coverURL != null && book.coverURL!.isNotEmpty) {
      return Image.network(
        book.coverURL!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book,
        size: IconSizes.medium,
        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
