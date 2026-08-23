import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';

enum BookImportItemCardPresentation { progress, summary }

/// Displays an import item consistently in the processing and summary phases.
class BookImportItemCard extends StatelessWidget {
  const BookImportItemCard({super.key, required this.item, required this.presentation, this.onRetry, this.onRemove});

  final BookImportBatchItem item;
  final BookImportItemCardPresentation presentation;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  bool get _failed =>
      item.status == BookImportBatchStatus.processingFailed || item.status == BookImportBatchStatus.commitFailed;

  bool get _added => item.status == BookImportBatchStatus.added;

  String get _displayTitle {
    final result = item.result;
    if (result != null && result.title.isNotEmpty) return result.title;
    return item.file.name;
  }

  String get _displaySubtitle => switch (item.status) {
    BookImportBatchStatus.queued => 'Preparing…',
    BookImportBatchStatus.processing => 'Extracting metadata…',
    BookImportBatchStatus.adding => 'Saving to library…',
    BookImportBatchStatus.ready => 'Ready',
    BookImportBatchStatus.added => item.result?.author.isNotEmpty == true ? 'by ${item.result!.author}' : 'Added',
    BookImportBatchStatus.processingFailed => item.errorMessage ?? 'Could not read this file.',
    BookImportBatchStatus.commitFailed => item.errorMessage ?? 'Could not save to library.',
  };

  @override
  Widget build(BuildContext context) => switch (presentation) {
    BookImportItemCardPresentation.progress => _buildProgress(context),
    BookImportItemCardPresentation.summary => _buildSummary(context),
  };

  Widget _buildProgress(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      key: ValueKey('${item.id}-${item.status}'),
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      decoration: BoxDecoration(
        color: _added
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : _failed
            ? colorScheme.errorContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _added
              ? colorScheme.primary.withValues(alpha: 0.3)
              : _failed
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _statusWidget(colorScheme)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_displayTitle, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  _displaySubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: _failed ? colorScheme.error : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_failed && onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            )
          else if (onRemove != null && (_failed || item.status == BookImportBatchStatus.ready))
            IconButton(
              tooltip: 'Remove ${item.file.name}',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final result = item.result;
    final hasCover = result?.coverImage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _added
              ? colorScheme.primary.withValues(alpha: 0.2)
              : _failed
              ? colorScheme.error.withValues(alpha: 0.2)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: hasCover
                ? Image.memory(
                    result!.coverImage!,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackIcon(colorScheme),
                  )
                : _fallbackIcon(colorScheme),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayTitle,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result?.author.isNotEmpty == true)
                  Text(
                    result!.author,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _added ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: _added ? colorScheme.primary : colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _added ? 'Imported' : (item.errorMessage ?? 'Failed'),
                        style: textTheme.labelSmall?.copyWith(color: _added ? colorScheme.primary : colorScheme.error),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_failed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _statusWidget(ColorScheme colorScheme) => switch (item.status) {
    BookImportBatchStatus.queued => SizedBox(
      key: const ValueKey('queued-icon'),
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSurfaceVariant),
    ),
    BookImportBatchStatus.processing => const SizedBox(
      key: ValueKey('processing-icon'),
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    BookImportBatchStatus.adding => const SizedBox(
      key: ValueKey('adding-icon'),
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    BookImportBatchStatus.ready => Icon(
      Icons.check_circle_outline,
      key: const ValueKey('ready-icon'),
      color: colorScheme.primary,
      size: 24,
    ),
    BookImportBatchStatus.added => Icon(
      Icons.check_circle,
      key: const ValueKey('added-icon'),
      color: colorScheme.primary,
      size: 24,
    ),
    BookImportBatchStatus.processingFailed => Icon(
      Icons.error_outline,
      key: const ValueKey('parse-failed-icon'),
      color: colorScheme.error,
      size: 24,
    ),
    BookImportBatchStatus.commitFailed => Icon(
      Icons.error_outline,
      key: const ValueKey('commit-failed-icon'),
      color: colorScheme.error,
      size: 24,
    ),
  };

  Widget _fallbackIcon(ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: _added
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : _failed
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        _added ? Icons.menu_book : Icons.insert_drive_file,
        size: 20,
        color: _added ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
