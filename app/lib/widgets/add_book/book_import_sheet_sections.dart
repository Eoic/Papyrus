import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/add_book_sheet_scaffold.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/book_import_controller.dart';
import 'package:papyrus/widgets/add_book/book_import_item_card.dart';

class BookImportSelectingSection extends StatelessWidget {
  const BookImportSelectingSection({
    super.key,
    required this.files,
    required this.readableFiles,
    required this.isPicking,
    required this.onBrowse,
    required this.onRemoveFile,
    required this.onClearSelection,
    required this.onStartImport,
    required this.onClose,
    this.pickerError,
    this.scrollController,
  });

  final List<SelectedBookFile> files;
  final List<SelectedBookFile> readableFiles;
  final bool isPicking;
  final String? pickerError;
  final ScrollController? scrollController;
  final VoidCallback onBrowse;
  final ValueChanged<SelectedBookFile> onRemoveFile;
  final VoidCallback onClearSelection;
  final VoidCallback onStartImport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hasFiles = files.isNotEmpty;
    return AddBookSheetScaffold(
      title: 'Import books',
      canClose: true,
      onClose: onClose,
      body: hasFiles ? _buildFileList(context) : _buildBrowseOnly(context),
      footer: Row(
        children: [
          if (hasFiles) FilledButton(onPressed: isPicking ? null : onClearSelection, child: const Text('Reset')),
          const Spacer(),
          TextButton(onPressed: onClose, child: const Text('Cancel')),
          const SizedBox(width: Spacing.sm),
          FilledButton(
            onPressed: readableFiles.isNotEmpty ? onStartImport : null,
            child: Text('Import ${readableFiles.length} ${readableFiles.length == 1 ? 'book' : 'books'}'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseOnly(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _BrowseArea(isPicking: isPicking, onTap: onBrowse),
          if (pickerError case final message?) ...[
            const SizedBox(height: Spacing.sm),
            Text(message, style: TextStyle(color: colorScheme.error, fontSize: 13)),
          ],
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      children: [
        if (pickerError case final message?) ...[
          Text(message, style: TextStyle(color: colorScheme.error, fontSize: 13)),
          const SizedBox(height: Spacing.sm),
        ],
        Text(
          '${files.length} ${files.length == 1 ? 'file' : 'files'} selected',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Spacing.sm),
        ...files.map((file) => _FileSelectCard(file: file, onRemove: () => onRemoveFile(file))),
      ],
    );
  }
}

class BookImportProcessingSection extends StatelessWidget {
  const BookImportProcessingSection({
    super.key,
    required this.items,
    required this.isClosing,
    required this.anyProcessing,
    required this.onRetry,
    required this.onRemove,
    required this.onClose,
    this.scrollController,
  });

  final List<BookImportBatchItem> items;
  final bool isClosing;
  final bool anyProcessing;
  final ScrollController? scrollController;
  final ValueChanged<String> onRetry;
  final ValueChanged<String> onRemove;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AddBookSheetScaffold(
      title: 'Importing books',
      canClose: !isClosing,
      onClose: onClose,
      body: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          return BookImportItemCard(
            key: ValueKey(item.id),
            item: item,
            presentation: BookImportItemCardPresentation.progress,
            onRetry: isClosing ? null : () => onRetry(item.id),
            onRemove: isClosing ? null : () => onRemove(item.id),
          );
        },
      ),
      footer: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: Spacing.sm,
        overflowSpacing: Spacing.sm,
        children: [TextButton(onPressed: isClosing || anyProcessing ? null : onClose, child: const Text('Close'))],
      ),
    );
  }
}

class BookImportSummarySection extends StatelessWidget {
  const BookImportSummarySection({
    super.key,
    required this.items,
    required this.failureCount,
    required this.isClosing,
    required this.onRetry,
    required this.onRetryFailed,
    required this.onDone,
    this.scrollController,
  });

  final List<BookImportBatchItem> items;
  final int failureCount;
  final bool isClosing;
  final ScrollController? scrollController;
  final ValueChanged<String> onRetry;
  final VoidCallback onRetryFailed;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final hasFailures = failureCount > 0;
    return AddBookSheetScaffold(
      title: 'Import complete',
      canClose: !isClosing,
      onClose: onDone,
      body: ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        children: items
            .map(
              (item) => BookImportItemCard(
                key: ValueKey(item.id),
                item: item,
                presentation: BookImportItemCardPresentation.summary,
                onRetry: hasFailures && !isClosing ? () => onRetry(item.id) : null,
              ),
            )
            .toList(),
      ),
      footer: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: Spacing.sm,
        overflowSpacing: Spacing.sm,
        children: [
          FilledButton(onPressed: isClosing ? null : onDone, child: const Text('Done')),
          if (hasFailures)
            OutlinedButton(onPressed: isClosing ? null : onRetryFailed, child: Text('Retry $failureCount failed')),
        ],
      ),
    );
  }
}

class _BrowseArea extends StatelessWidget {
  const _BrowseArea({required this.isPicking, required this.onTap});

  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formats = bookImportNativeExtensions.map((extension) => extension.toUpperCase()).join(', ');

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.symmetric(vertical: Spacing.xxl, horizontal: Spacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (isPicking)
                const SizedBox.square(dimension: 48, child: CircularProgressIndicator(strokeWidth: 3))
              else
                Icon(Icons.cloud_upload_outlined, size: 48, color: colorScheme.primary),
              const SizedBox(height: Spacing.md),
              Text('Browse files', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: Spacing.sm),
              Text(
                'Tap to select $formats',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileSelectCard extends StatelessWidget {
  const _FileSelectCard({required this.file, required this.onRemove});

  final SelectedBookFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readable = file.bytes != null;
    final sizeText = file.bytes != null ? _formatSize(file.bytes!.length) : 'Unknown size';

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: readable ? colorScheme.primaryContainer : colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              readable ? _iconForExtension(file.name) : Icons.error_outline,
              size: 20,
              color: readable ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(file.name, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  readable ? sizeText : 'Unreadable',
                  style: textTheme.bodySmall?.copyWith(
                    color: readable ? colorScheme.onSurfaceVariant : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${file.name}',
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

IconData _iconForExtension(String name) {
  final extension = name.toLowerCase().split('.').last;
  return switch (extension) {
    'pdf' => Icons.picture_as_pdf,
    'epub' || 'mobi' || 'azw3' => Icons.menu_book,
    'cbz' || 'cbr' => Icons.folder_zip,
    'txt' => Icons.text_snippet,
    _ => Icons.insert_drive_file,
  };
}
