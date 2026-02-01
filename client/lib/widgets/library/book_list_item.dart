import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/context_menu/book_context_menu.dart';
import 'package:provider/provider.dart';

/// List row for displaying books, optimized for e-ink.
/// - Standard: 80px height with cover thumbnail
/// - E-ink: 96px height with larger touch target, 64×96 thumbnail
/// Supports context menu via long press (mobile) or right-click (desktop).
class BookListItem extends StatefulWidget {
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
  State<BookListItem> createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  bool _isHovered = false;

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

  void _showContextMenu(Offset? position) {
    final libraryProvider = context.read<LibraryProvider>();
    final isFavorite =
        libraryProvider.isBookFavorite(widget.book.id, widget.book.isFavorite);

    BookContextMenu.show(
      context: context,
      book: widget.book,
      isFavorite: isFavorite,
      tapPosition: position,
      onFavoriteToggle: () {
        libraryProvider.toggleFavorite(widget.book.id, isFavorite);
      },
      onEdit: () {
        // TODO: Implement edit
      },
      onMoveToShelf: () {
        // TODO: Implement move to shelf
      },
      onManageTopics: () {
        // TODO: Implement manage topics
      },
      onStatusChange: (status) {
        // TODO: Implement status change
      },
      onDelete: () {
        // TODO: Implement delete
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEink = context.watch<DisplayModeProvider>().isEinkMode;
    final libraryProvider = context.watch<LibraryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final itemHeight = isEink ? 96.0 : 80.0;
    final thumbnailWidth = isEink ? 64.0 : 54.0;
    final thumbnailHeight = isEink ? 96.0 : 80.0;
    final isFavorite =
        libraryProvider.isBookFavorite(widget.book.id, widget.book.isFavorite);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          // Right-click for desktop
          _showContextMenu(details.globalPosition);
        },
        onLongPressStart: (details) {
          // Long press for mobile
          _showContextMenu(details.globalPosition);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
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
                          widget.book.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.book.author,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.showProgress && widget.book.progress > 0) ...[
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
                                  minHeight: isEink ? 4 : 3,
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                widget.book.progressLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
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
                          border: isEink
                              ? Border.all(color: colorScheme.outline)
                              : null,
                        ),
                        child: Text(
                          widget.book.formatLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      // Favorite indicator
                      Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: IconSizes.indicator,
                        color: isFavorite
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      // Overflow menu - show on hover (desktop only)
                      if (_isDesktop)
                        AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: IconButton(
                            icon: const Icon(Icons.more_vert),
                            iconSize: IconSizes.action,
                            onPressed: () => _showContextMenu(null),
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
      return Image.network(
        widget.book.coverURL!,
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
