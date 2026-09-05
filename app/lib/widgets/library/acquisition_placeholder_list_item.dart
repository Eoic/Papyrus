import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/acquisition_status_text.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';
import 'package:papyrus/widgets/shared/app_motion_control.dart';

class AcquisitionPlaceholderListItem extends StatelessWidget {
  final AcquisitionJob job;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onEnterSelectionMode;

  const AcquisitionPlaceholderListItem({
    super.key,
    required this.job,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.onEnterSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = acquisitionStatusLabel(job);
    final details = acquisitionTransferDetails(job);
    final effectiveTap = isSelectionMode ? onSelectToggle : onTap;
    final effectiveLongPress = isSelectionMode ? null : onEnterSelectionMode;
    final semanticLabel = <String>[job.title, status, ?details].join('. ');
    final hasInteraction = effectiveTap != null || effectiveLongPress != null;

    return Semantics(
      key: ValueKey('acquisition-placeholder-list-item-${job.id}'),
      container: true,
      label: semanticLabel,
      button: hasInteraction,
      selected: isSelected,
      onTap: effectiveTap,
      onLongPress: effectiveLongPress,
      child: ExcludeSemantics(
        child: GestureDetector(
          onLongPress: effectiveLongPress,
          child: Material(
            color: isSelectionMode && isSelected ? colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
            child: InkWell(
              onTap: effectiveTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    if (isSelectionMode) ...[
                      AppMotionControl(
                        value: isSelected,
                        builder: (focusNode) =>
                            Checkbox(focusNode: focusNode, value: isSelected, onChanged: (_) => onSelectToggle?.call()),
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    SizedBox(
                      width: ComponentSizes.bookCoverWidthList,
                      height: ComponentSizes.bookCoverHeightList,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: IconSizes.display,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            job.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            status,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: job.requiresAttention ? colorScheme.error : colorScheme.onSurfaceVariant,
                              fontWeight: job.requiresAttention ? FontWeight.w600 : null,
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
                          if (job.progress case final progress?) ...[
                            const SizedBox(height: Spacing.xs),
                            AppLinearProgressIndicator(
                              value: progress,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: job.requiresAttention ? colorScheme.error : colorScheme.primary,
                              minHeight: 3,
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
