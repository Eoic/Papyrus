import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';

/// Keeps transfers visible without pushing catalog content down the page.
class OpdsDownloadPanel extends StatefulWidget {
  const OpdsDownloadPanel({
    super.key,
    required this.downloads,
    required this.onRetry,
    this.allowExpansion = true,
    this.maxExpandedHeight = 240,
  });
  final OpdsDownloads downloads;
  final ValueChanged<OpdsDownloadJob> onRetry;
  final bool allowExpansion;
  final double maxExpandedHeight;

  @override
  State<OpdsDownloadPanel> createState() => _OpdsDownloadPanelState();
}

class _OpdsDownloadPanelState extends State<OpdsDownloadPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final jobs = widget.downloads.jobs;
    if (jobs.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final active = jobs.where((job) => job.isActive).length;
    final failed = jobs.where((job) => job.status == OpdsDownloadStatus.failed).length;
    final summary = [
      if (active > 0) '$active in progress',
      if (failed > 0) '$failed failed',
      if (active == 0 && failed == 0) '${jobs.length} finished',
    ].join(' · ');
    return Material(
      color: colors.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(
              failed > 0 ? Icons.error_outline : Icons.downloading_outlined,
              color: failed > 0 ? colors.error : colors.primary,
            ),
            title: Text('Downloads · $summary'),
            trailing: widget.allowExpansion ? Icon(_expanded ? Icons.expand_more : Icons.expand_less) : null,
            onTap: widget.allowExpansion ? () => setState(() => _expanded = !_expanded) : null,
          ),
          if (_expanded && widget.allowExpansion)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxExpandedHeight),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
                itemCount: jobs.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) => _job(context, jobs[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _job(BuildContext context, OpdsDownloadJob job) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                job.publication.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (job.isCancellable)
              IconButton(
                tooltip: 'Cancel download',
                onPressed: () => widget.downloads.cancel(job.key),
                icon: const Icon(Icons.close),
              ),
            if (!job.isActive) ...[
              if (job.status == OpdsDownloadStatus.complete)
                TextButton(
                  onPressed: () => context.go('/library/details/${job.bookId}'),
                  child: const Text('Open book'),
                )
              else
                TextButton(onPressed: () => widget.onRetry(job), child: const Text('Retry')),
              IconButton(
                tooltip: 'Dismiss download',
                onPressed: () => widget.downloads.dismiss(job.key),
                icon: const Icon(Icons.close, size: IconSizes.small),
              ),
            ],
          ],
        ),
        Text(
          job.error ?? opdsDownloadStatus(job),
          style: theme.textTheme.bodySmall?.copyWith(
            color: job.error == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
          ),
        ),
        if (job.isActive) ...[
          const SizedBox(height: Spacing.sm),
          AppLinearProgressIndicator(value: job.status == OpdsDownloadStatus.downloading ? job.progress : null),
        ],
      ],
    );
  }
}

String opdsDownloadStatus(OpdsDownloadJob job) => switch (job.status) {
  OpdsDownloadStatus.downloading =>
    job.total == null
        ? 'Downloading · ${job.received ~/ 1024} KB'
        : 'Downloading · ${(100 * (job.progress ?? 0)).round()}%',
  OpdsDownloadStatus.importing => 'Importing…',
  OpdsDownloadStatus.committing => 'Adding to library…',
  OpdsDownloadStatus.complete => 'Added to library',
  OpdsDownloadStatus.failed => 'Download failed',
  OpdsDownloadStatus.cancelled => 'Cancelled',
};
