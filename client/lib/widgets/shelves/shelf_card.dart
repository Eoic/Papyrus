import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Card widget for displaying a shelf in grid or list view.
///
/// Shows shelf name, book count, color indicator, and cover previews.
class ShelfCard extends StatefulWidget {
  /// The shelf data to display.
  final ShelfData shelf;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the more menu is tapped.
  final VoidCallback? onMoreTap;

  /// Called when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether to show as list item (vs grid card).
  final bool isListItem;

  const ShelfCard({
    super.key,
    required this.shelf,
    this.onTap,
    this.onMoreTap,
    this.onLongPress,
    this.isListItem = false,
  });

  @override
  State<ShelfCard> createState() => _ShelfCardState();
}

class _ShelfCardState extends State<ShelfCard> {
  bool _isHovered = false;

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.isListItem
          ? _buildListItem(context)
          : _buildGridCard(context),
    );
  }

  // ============================================================================
  // GRID CARD
  // ============================================================================

  Widget _buildGridCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shelfColor = widget.shelf.color ?? colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: AppElevation.level1,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover preview area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverMosaic(context, shelfColor),
                  // More button (desktop hover)
                  if (_isDesktop && widget.onMoreTap != null)
                    Positioned(
                      top: Spacing.xs,
                      right: Spacing.xs,
                      child: AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: _buildMoreButton(context),
                      ),
                    ),
                ],
              ),
            ),
            // Shelf info
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and title row
                  Row(
                    children: [
                      Icon(
                        widget.shelf.displayIcon,
                        size: IconSizes.small,
                        color: shelfColor,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          widget.shelf.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.shelf.bookCountLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a 2x2 mosaic.
  ///
  /// Adapts layout based on available covers:
  /// - 4+: 2x2 grid
  /// - 3: top row = 2, bottom = 1 spanning full width
  /// - 2: side by side, full height
  /// - 1: single cover fills the area
  /// - 0: shelf color gradient with centered icon
  Widget _buildCoverMosaic(BuildContext context, Color shelfColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final covers = widget.shelf.coverPreviewUrls;
    const double gap = 2.0;

    if (covers.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              shelfColor.withValues(alpha: 0.3),
              shelfColor.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            widget.shelf.displayIcon,
            size: 48,
            color: shelfColor.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    if (covers.length == 1) {
      return _buildCoverImage(covers[0], colorScheme);
    }

    if (covers.length == 2) {
      return Container(
        color: shelfColor,
        child: Row(
          children: [
            Expanded(child: _buildCoverImage(covers[0], colorScheme)),
            const SizedBox(width: gap),
            Expanded(child: _buildCoverImage(covers[1], colorScheme)),
          ],
        ),
      );
    }

    if (covers.length == 3) {
      return Container(
        color: shelfColor,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCoverImage(covers[0], colorScheme)),
                  const SizedBox(width: gap),
                  Expanded(child: _buildCoverImage(covers[1], colorScheme)),
                ],
              ),
            ),
            const SizedBox(height: gap),
            Expanded(child: _buildCoverImage(covers[2], colorScheme)),
          ],
        ),
      );
    }

    // 4+ covers: 2x2 grid
    return Container(
      color: shelfColor,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildCoverImage(covers[0], colorScheme)),
                const SizedBox(width: gap),
                Expanded(child: _buildCoverImage(covers[1], colorScheme)),
              ],
            ),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildCoverImage(covers[2], colorScheme)),
                const SizedBox(width: gap),
                Expanded(child: _buildCoverImage(covers[3], colorScheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String url, ColorScheme colorScheme) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: colorScheme.surfaceContainerHigh,
        child: Icon(
          Icons.menu_book,
          size: 24,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      placeholder: (context, url) =>
          Container(color: colorScheme.surfaceContainerHigh),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.scrim.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: widget.onMoreTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.more_vert,
            size: IconSizes.small,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // LIST ITEM
  // ============================================================================

  Widget _buildListItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shelfColor = widget.shelf.color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
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
              // Color indicator and icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: shelfColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: shelfColor.withValues(alpha: 0.3)),
                ),
                child: Icon(widget.shelf.displayIcon, color: shelfColor),
              ),
              const SizedBox(width: Spacing.md),
              // Shelf info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shelf.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.shelf.description ?? widget.shelf.bookCountLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Book count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${widget.shelf.bookCount}',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // More button (desktop hover only)
              if (_isDesktop && widget.onMoreTap != null)
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    iconSize: IconSizes.action,
                    onPressed: widget.onMoreTap,
                    tooltip: 'More options',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
