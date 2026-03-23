import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A collapsible header showing a book's cover thumbnail, title, item count,
/// and expand/collapse chevron.
///
/// Used in notes, annotations, and bookmarks pages to group items by book.
class BookGroupHeader extends StatelessWidget {
  /// The book title to display.
  final String bookTitle;

  /// Optional cover image URL for the thumbnail.
  final String? coverUrl;

  /// Number of items in this group (e.g. 3 notes).
  final int count;

  /// Singular item label (e.g. "note", "annotation", "bookmark").
  final String itemLabel;

  /// Whether this group is currently collapsed.
  final bool isCollapsed;

  /// Called when the header is tapped to toggle collapse state.
  final VoidCallback onToggle;

  const BookGroupHeader({
    super.key,
    required this.bookTitle,
    this.coverUrl,
    required this.count,
    required this.itemLabel,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Row(
            children: [
              // Small book cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 32,
                  height: 48,
                  child: coverUrl != null && coverUrl!.isNotEmpty
                      ? Image.network(
                          coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.menu_book,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.menu_book,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count ${count == 1 ? itemLabel : '${itemLabel}s'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                color: colorScheme.onSurfaceVariant,
                size: IconSizes.action,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
