import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/acquisition_confirmation_dialog.dart';
import 'package:papyrus/widgets/library/acquisition_status_text.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

Future<void> showAcquisitionJobDetailsSheet({
  required BuildContext context,
  required AcquisitionDownloadsProvider provider,
  required AcquisitionJob job,
}) async {
  final candidates = job.status == AcquisitionJobStatus.needsFileSelection
      ? await provider.listJobFiles(job.id)
      : const <AcquisitionFileCandidate>[];

  if (!context.mounted) {
    return;
  }

  final action = await showModalBottomSheet<_AcquisitionJobAction>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => SingleChildScrollView(
      child: Padding(
        key: const Key('acquisition-job-details-content'),
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
        child: _AcquisitionJobDetailsContent(
          job: job,
          candidates: candidates,
          onAction: (action) => Navigator.of(sheetContext).pop(action),
        ),
      ),
    ),
  );

  if (!context.mounted || action == null) {
    return;
  }

  switch (action) {
    case _CancelJob():
      final confirmed = await showAcquisitionConfirmationDialog(
        context: context,
        title: 'Cancel download',
        message: 'Cancel "${job.title}"?',
        actionLabel: 'Cancel download',
      );

      if (confirmed) {
        await provider.cancelJob(job.id);
      }
    case _RetryImport():
      await provider.retryJobImport(job.id);
    case _SelectFile(:final index):
      await provider.selectJobFile(job.id, index);
  }
}

Future<void> showAcquisitionJobAttentionSheet({
  required BuildContext context,
  required AcquisitionDownloadsProvider provider,
  required AcquisitionJob job,
}) {
  return showAcquisitionJobDetailsSheet(context: context, provider: provider, job: job);
}

class _AcquisitionJobDetailsContent extends StatelessWidget {
  const _AcquisitionJobDetailsContent({required this.job, required this.candidates, required this.onAction});

  final AcquisitionJob job;
  final List<AcquisitionFileCandidate> candidates;
  final ValueChanged<_AcquisitionJobAction> onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final supportedCandidates = candidates.where((candidate) => candidate.supported).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: Spacing.md),
        Text(job.title, style: textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(acquisitionStatusLabel(job), style: textTheme.bodyMedium),
        if (job.progress case final progress?) ...[
          const SizedBox(height: Spacing.md),
          LinearProgressIndicator(value: progress),
        ],
        if (job.downloadedBytes != null || job.totalBytes != null) ...[
          const SizedBox(height: Spacing.sm),
          Text('${formatBytes(job.downloadedBytes)} of ${formatBytes(job.totalBytes)}', style: textTheme.bodyMedium),
        ],
        if (job.downloadSpeedBytesPerSecond case final speed?) ...[
          const SizedBox(height: Spacing.xs),
          Text(formatSpeed(speed), style: textTheme.bodyMedium),
        ],
        if (job.etaSeconds case final eta?) ...[
          const SizedBox(height: Spacing.xs),
          Text(formatEta(eta), style: textTheme.bodyMedium),
        ],
        if (job.selectedFilePath case final path?) ...[
          const SizedBox(height: Spacing.xs),
          Text(_fileName(path), style: textTheme.bodyMedium),
        ],
        if (job.status == AcquisitionJobStatus.needsFileSelection) ...[
          const SizedBox(height: Spacing.lg),
          Text('Select file', style: textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          if (supportedCandidates.isEmpty)
            Text('No supported book files found.', style: textTheme.bodyMedium)
          else
            for (final candidate in supportedCandidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(candidate.name),
                subtitle: Text(formatBytes(candidate.sizeBytes)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onAction(_SelectFile(candidate.index)),
              ),
        ],
        if (job.canCancel) ...[
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => onAction(const _CancelJob()),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Cancel'),
          ),
        ],
        if (job.canRetryImport) ...[
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => onAction(const _RetryImport()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry import'),
          ),
        ],
      ],
    );
  }
}

sealed class _AcquisitionJobAction {
  const _AcquisitionJobAction();
}

class _CancelJob extends _AcquisitionJobAction {
  const _CancelJob();
}

class _RetryImport extends _AcquisitionJobAction {
  const _RetryImport();
}

class _SelectFile extends _AcquisitionJobAction {
  const _SelectFile(this.index);

  final int index;
}

String _fileName(String path) {
  final segments = path.split(RegExp(r'[/\\]'));

  return segments.lastWhere((segment) => segment.isNotEmpty, orElse: () => path);
}
