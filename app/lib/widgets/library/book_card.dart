import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/book_actions.dart';
import 'package:papyrus/widgets/book/private_book_cover.dart';
import 'package:papyrus/widgets/library/acquisition_status_text.dart';

/// Responsive book card for grid display.
/// - Mobile: 171×256 with 8px gap
/// - Desktop: 200×300 with 16px gap
/// Supports context menu via long press (mobile) or right-click (desktop).
class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool isFavorite;
  final void Function(bool)? onToggleFavorite;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onEnterSelectionMode;
  final AcquisitionJob? acquisitionJob;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.showProgress = true,
    required this.isFavorite,
    this.onToggleFavorite,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.onEnterSelectionMode,
    this.acquisitionJob,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isHovered = false;

  bool get _isDesktop => MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inSelection = widget.isSelectionMode;
    final effectiveTap = inSelection ? widget.onSelectToggle : widget.onTap;
    final effectiveLongPress = inSelection ? null : widget.onEnterSelectionMode;

    final card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onLongPressStart: _isDesktop
            ? null
            : (details) {
                if (widget.acquisitionJob != null) {
                  effectiveLongPress?.call();
                  return;
                }

                showBookContextMenu(context: context, book: widget.book, position: details.globalPosition);
              },
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: effectiveTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCover(context),
                      // Selection tint overlay
                      if (inSelection && widget.isSelected)
                        Container(color: colorScheme.primary.withValues(alpha: 0.15)),
                      if (!inSelection && widget.acquisitionJob == null)
                        Positioned(
                          top: Spacing.xs,
                          left: Spacing.xs,
                          child: _CardIconButton(
                            icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: widget.isFavorite ? colorScheme.error : Colors.white,
                            onTap: widget.onToggleFavorite != null
                                ? () => widget.onToggleFavorite!(widget.isFavorite)
                                : null,
                          ),
                        ),
                      // Selection mode: checkbox overlay (top-right)
                      if (inSelection)
                        Positioned(
                          top: Spacing.xs,
                          right: Spacing.xs,
                          child: _CardIconButton(
                            icon: widget.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: widget.isSelected ? colorScheme.primary : Colors.white,
                            onTap: widget.onSelectToggle,
                          ),
                        ),
                      // Desktop hover: checkbox to enter selection mode
                      if (!inSelection && _isDesktop)
                        Positioned(
                          top: Spacing.xs,
                          right: Spacing.xs,
                          child: AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CardIconButton(icon: Icons.radio_button_unchecked, onTap: widget.onEnterSelectionMode),
                                if (widget.acquisitionJob == null) ...[
                                  const SizedBox(width: Spacing.xs),
                                  _CardIconButton(
                                    icon: Icons.more_vert,
                                    onTap: () => showBookContextMenu(context: context, book: widget.book),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      // Format badge
                      if (widget.acquisitionJob == null)
                        Positioned(
                          bottom: Spacing.xs,
                          left: Spacing.xs,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              widget.book.formatLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (widget.acquisitionJob case final job?)
                        Positioned(
                          bottom: Spacing.xs,
                          left: Spacing.xs,
                          right: Spacing.xs,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                acquisitionStatusLabel(job),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: job.requiresAttention ? colorScheme.error : colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Progress bar
                if (widget.acquisitionJob case final job?) ...[
                  if (job.progress case final progress?)
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: job.requiresAttention ? colorScheme.error : colorScheme.primary,
                      minHeight: 3,
                    ),
                ] else if (widget.showProgress && widget.book.progress > 0)
                  LinearProgressIndicator(
                    value: widget.book.progress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: widget.book.isFinished ? colorScheme.tertiary : colorScheme.primary,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.acquisitionJob case final job?)
                        if (acquisitionTransferDetails(job) case final details?) ...[
                          const SizedBox(height: 2),
                          Text(
                            details,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final job = widget.acquisitionJob;

    if (job == null) {
      return card;
    }

    final details = acquisitionTransferDetails(job);
    final semanticLabel = <String>[widget.book.title, acquisitionStatusLabel(job), ?details].join('. ');
    final hasInteraction = effectiveTap != null || effectiveLongPress != null;

    return Semantics(
      key: ValueKey('linked-acquisition-book-card-${job.id}'),
      container: true,
      label: semanticLabel,
      button: hasInteraction,
      selected: widget.isSelected,
      onTap: effectiveTap,
      onLongPress: effectiveLongPress,
      child: Stack(
        children: [
          ExcludeSemantics(child: card),
          if (!inSelection && _isDesktop && widget.onEnterSelectionMode != null)
            Positioned(
              top: Spacing.xs,
              right: Spacing.xs,
              child: Semantics(
                key: ValueKey('acquisition-selector-${job.id}'),
                container: true,
                label: 'Select ${widget.book.title}',
                button: true,
                onTap: widget.onEnterSelectionMode,
                child: const ExcludeSemantics(child: SizedBox(width: 32, height: 32)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return CoverImage(
      bookId: widget.book.id,
      imageUrl: widget.book.coverURL,
      mediaId: widget.book.coverMediaId,
      placeholder: _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: IconSizes.display, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: Spacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text(
              widget.book.title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
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
          child: Icon(icon, size: IconSizes.small, color: color ?? Colors.white),
        ),
      ),
    );
  }
}
