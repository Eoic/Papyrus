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

  /// Whether to show as list item (vs grid card).
  final bool isListItem;

  const ShelfCard({
    super.key,
    required this.shelf,
    this.onTap,
    this.onMoreTap,
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
    if (widget.isListItem) return _buildListItem(context);
    return _buildGridCard(context);
  }

  // ============================================================================
  // GRID CARD
  // ============================================================================

  Widget _buildGridCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shelfColor = widget.shelf.color ?? colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: AppElevation.level1,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover preview area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverPreview(context, shelfColor),
                    // Color indicator bar
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(color: shelfColor),
                    ),
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
      ),
    );
  }

  Widget _buildCoverPreview(BuildContext context, Color shelfColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final covers = widget.shelf.coverPreviewUrls;

    if (covers.isEmpty) {
      // Empty shelf placeholder
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.shelf.displayIcon,
                size: 48,
                color: shelfColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'No books',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Stack up to 3 covers offset diagonally
    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(Spacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coverWidth = (constraints.maxWidth - Spacing.lg) * 0.55;
          final coverHeight = coverWidth * 1.5;

          return Stack(
            children: [
              for (int i = 0; i < covers.length.clamp(0, 3); i++)
                Positioned(
                  left: Spacing.xs + (i * 12),
                  top: Spacing.xs + (i * 8),
                  child: Container(
                    width: coverWidth,
                    height: coverHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: CachedNetworkImage(
                        imageUrl: covers[covers.length - 1 - i],
                        fit: BoxFit.cover,
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
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
            color: colorScheme.onInverseSurface,
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
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
              // More button
              if (widget.onMoreTap != null) ...[
                const SizedBox(width: Spacing.sm),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: widget.onMoreTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
