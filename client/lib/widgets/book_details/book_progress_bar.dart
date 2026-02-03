import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Progress bar widget for book reading progress.
/// Shows a standard linear progress bar or a segmented bar for e-ink.
class BookProgressBar extends StatelessWidget {
  final double progress;
  final int? currentPage;
  final int? totalPages;
  final bool isEinkMode;
  final bool showLabel;
  final double? height;

  const BookProgressBar({
    super.key,
    required this.progress,
    this.currentPage,
    this.totalPages,
    this.isEinkMode = false,
    this.showLabel = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) {
      return _buildEinkProgressBar(context);
    }
    return _buildStandardProgressBar(context);
  }

  Widget _buildStandardProgressBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barHeight = height ?? 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(barHeight / 2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: progress >= 1.0
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                  minHeight: barHeight,
                ),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: Spacing.sm),
              Text(
                _getProgressLabel(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEinkProgressBar(BuildContext context) {
    const segments = 20;
    final filledSegments = (progress * segments).round().clamp(0, segments);
    final barHeight = height ?? 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xs),
            child: Text(
              'Progress: ${_getProgressLabel()}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: barHeight,
          child: Row(
            children: List.generate(segments, (index) {
              final isFilled = index < filledSegments;
              final isFirst = index == 0;

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isFilled ? Colors.black : Colors.white,
                    border: Border(
                      top: const BorderSide(
                        color: Colors.black,
                        width: BorderWidths.einkDefault,
                      ),
                      bottom: const BorderSide(
                        color: Colors.black,
                        width: BorderWidths.einkDefault,
                      ),
                      left: isFirst
                          ? const BorderSide(
                              color: Colors.black,
                              width: BorderWidths.einkDefault,
                            )
                          : BorderSide.none,
                      right: const BorderSide(
                        color: Colors.black,
                        width: BorderWidths.einkDefault,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _getProgressLabel() {
    final percentage = (progress * 100).round();

    if (currentPage != null && totalPages != null) {
      return '$currentPage / $totalPages ($percentage%)';
    }

    return '$percentage%';
  }
}
