import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/book_actions.dart';

/// Responsive book card for grid display.
/// - Mobile: 171×256 with 8px gap
/// - Desktop: 200×300 with 16px gap
/// Supports context menu via long press (mobile) or right-click (desktop).
class BookCard extends StatefulWidget {
  final BookData book;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool isFavorite;
  final void Function(bool)? onToggleFavorite;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.showProgress = true,
    required this.isFavorite,
    this.onToggleFavorite,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isHovered = false;

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          // Right-click for desktop
          showBookContextMenu(
            context: context,
            book: widget.book,
            position: details.globalPosition,
          );
        },
        onLongPressStart: (details) {
          // Long press for mobile
          showBookContextMenu(
            context: context,
            book: widget.book,
            position: details.globalPosition,
          );
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
                          icon: widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isFavorite
                              ? colorScheme.error
                              : Colors.white,
                          onTap: widget.onToggleFavorite != null
                              ? () =>
                                    widget.onToggleFavorite!(widget.isFavorite)
                              : null,
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
                              onTap: () => showBookContextMenu(
                                context: context,
                                book: widget.book,
                              ),
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
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
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
      return CachedNetworkImage(
        imageUrl: widget.book.coverURL!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildPlaceholder(context),
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
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

  const _CardIconButton({required this.icon, this.color, this.onTap});

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
