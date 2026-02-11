import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/book_actions.dart';

/// List row for displaying a book with cover thumbnail, title, author,
/// progress, format badge, and favorite indicator.
/// Supports context menu via long press (mobile) or right-click (desktop).
class BookListItem extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool isFavorite;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;

  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
    this.showProgress = true,
    required this.isFavorite,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  @override
  State<BookListItem> createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  bool _isHovered = false;

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inSelection = widget.isSelectionMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onLongPressStart: _isDesktop
            ? null
            : (details) {
                showBookContextMenu(
                  context: context,
                  book: widget.book,
                  position: details.globalPosition,
                );
              },
        child: Material(
          color: inSelection && widget.isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: inSelection ? widget.onSelectToggle : widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  // Selection checkbox (leading)
                  if (inSelection) ...[
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onSelectToggle?.call(),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  // Cover thumbnail
                  SizedBox(
                    width: ComponentSizes.bookCoverWidthList,
                    height: ComponentSizes.bookCoverHeightList,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: _buildCover(context),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),

                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          widget.book.author,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.showProgress &&
                            widget.book.progress > 0) ...[
                          const SizedBox(height: Spacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: widget.book.progress,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  color: widget.book.isFinished
                                      ? colorScheme.tertiary
                                      : colorScheme.primary,
                                  minHeight: 3,
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                widget.book.progressLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing indicators and actions
                  if (!inSelection)
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                          ),
                          child: Text(
                            widget.book.formatLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        // Favorite indicator
                        Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: IconSizes.indicator,
                          color: widget.isFavorite
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                        // Overflow menu - show on hover (desktop only)
                        if (_isDesktop)
                          AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: IconButton(
                              icon: const Icon(Icons.more_vert),
                              iconSize: IconSizes.action,
                              onPressed: () => showBookContextMenu(
                                context: context,
                                book: widget.book,
                              ),
                              tooltip: 'More options',
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    if (widget.book.coverURL != null && widget.book.coverURL!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.book.coverURL!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildPlaceholder(context),
        placeholder: (context, url) => _buildPlaceholder(context),
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
