import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/acquisition_status_text.dart';

class AcquisitionPlaceholderCard extends StatefulWidget {
  final AcquisitionJob job;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onEnterSelectionMode;

  const AcquisitionPlaceholderCard({
    super.key,
    required this.job,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.onEnterSelectionMode,
  });

  @override
  State<AcquisitionPlaceholderCard> createState() => _AcquisitionPlaceholderCardState();
}

class _AcquisitionPlaceholderCardState extends State<AcquisitionPlaceholderCard> {
  bool _isHovered = false;

  bool get _isDesktop => MediaQuery.sizeOf(context).width >= Breakpoints.desktopSmall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = acquisitionStatusLabel(widget.job);
    final details = acquisitionTransferDetails(widget.job);
    final effectiveTap = widget.isSelectionMode ? widget.onSelectToggle : widget.onTap;
    final effectiveLongPress = widget.isSelectionMode ? null : widget.onEnterSelectionMode;
    final semanticLabel = <String>[widget.job.title, status, ?details].join('. ');
    final hasInteraction = effectiveTap != null || effectiveLongPress != null;

    return Semantics(
      key: ValueKey('acquisition-placeholder-card-${widget.job.id}'),
      container: true,
      label: semanticLabel,
      button: hasInteraction,
      selected: widget.isSelected,
      onTap: effectiveTap,
      onLongPress: effectiveLongPress,
      child: ExcludeSemantics(
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onLongPress: effectiveLongPress,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: effectiveTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.menu_book_outlined,
                              size: IconSizes.display,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                            ),
                          ),
                          if (widget.isSelectionMode && widget.isSelected)
                            Container(color: colorScheme.primary.withValues(alpha: 0.15)),
                          if (widget.isSelectionMode)
                            Positioned(
                              top: Spacing.xs,
                              right: Spacing.xs,
                              child: _SelectionIconButton(selected: widget.isSelected, onTap: widget.onSelectToggle),
                            )
                          else if (_isDesktop)
                            Positioned(
                              top: Spacing.xs,
                              right: Spacing.xs,
                              child: AnimatedOpacity(
                                opacity: _isHovered ? 1 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: _SelectionIconButton(selected: false, onTap: widget.onEnterSelectionMode),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.job.progress case final progress?)
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: widget.job.requiresAttention ? colorScheme.error : colorScheme.primary,
                        minHeight: 3,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.job.requiresAttention ? colorScheme.error : colorScheme.onSurfaceVariant,
                              fontWeight: widget.job.requiresAttention ? FontWeight.w600 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (details != null) ...[
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
        ),
      ),
    );
  }
}

class _SelectionIconButton extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const _SelectionIconButton({required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: IconSizes.small,
            color: selected ? colorScheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}
