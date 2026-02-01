import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/context_menu/book_context_menu.dart';
import 'package:provider/provider.dart';

/// Responsive book card for grid display.
/// - Mobile: 171×256 with 8px gap
/// - Desktop: 200×300 with 16px gap
/// Supports context menu via long press (mobile) or right-click (desktop).
class BookCard extends StatefulWidget {
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
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
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
    final colorScheme = Theme.of(context).colorScheme;
    final libraryProvider = context.watch<LibraryProvider>();
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
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: AppElevation.level1,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCover(context),
                      // Favorite button - always visible
                      Positioned(
                        top: Spacing.xs,
                        left: Spacing.xs,
                        child: _CardIconButton(
                          icon:
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? colorScheme.error : Colors.white,
                          onTap: () {
                            libraryProvider.toggleFavorite(
                                widget.book.id, isFavorite);
                          },
                        ),
                      ),
                      // Overflow menu button - show on hover (desktop only)
                      if (_isDesktop)
                        Positioned(
                          top: Spacing.xs,
                          right: Spacing.xs,
                          child: AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: _CardIconButton(
                              icon: Icons.more_vert,
                              onTap: () => _showContextMenu(null),
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
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
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
                      ),
                    ],
                  ),
                ),
                // Progress bar
                if (widget.showProgress && widget.book.progress > 0)
                  LinearProgressIndicator(
                    value: widget.book.progress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: widget.book.isFinished
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
                        widget.book.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.book.author,
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
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.book.coverURL != null && widget.book.coverURL!.isNotEmpty) {
      return Image.network(
        widget.book.coverURL!,
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
              widget.book.title,
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

/// Icon button overlay for book card.
class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _CardIconButton({
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: IconSizes.small,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
