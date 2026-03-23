import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Progress bar widget for book reading progress.
/// Shows a linear progress bar with an optional label.
class BookProgressBar extends StatelessWidget {
  final double progress;
  final int? currentPage;
  final int? totalPages;
  final bool showLabel;
  final double? height;
  final VoidCallback? onTap;

  const BookProgressBar({
    super.key,
    required this.progress,
    this.currentPage,
    this.totalPages,
    this.showLabel = true,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barHeight = height ?? 4.0;

    Widget content = Column(
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

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }

  String _getProgressLabel() {
    final percentage = (progress * 100).round();

    if (currentPage != null && totalPages != null) {
      return '$currentPage / $totalPages ($percentage%)';
    }

    return '$percentage%';
  }
}
