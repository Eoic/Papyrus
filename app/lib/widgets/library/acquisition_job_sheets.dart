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
        child: _LiveAcquisitionJobDetailsContent(
          provider: provider,
          fallbackJob: job,
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
      var currentJob = provider.jobById(job.id);

      if (currentJob?.canCancel != true) {
        return;
      }

      final confirmed = await showAcquisitionConfirmationDialog(
        context: context,
        title: 'Cancel download',
        message: 'Cancel "${currentJob!.title}"?',
        actionLabel: 'Cancel download',
      );

      currentJob = provider.jobById(job.id);

      if (confirmed && currentJob?.canCancel == true) {
        final outcome = await provider.cancelJob(job.id);

        if (!context.mounted) {
          return;
        }

        await _handleActionOutcome(context: context, provider: provider, job: job, outcome: outcome);
      }
    case _RetryImport():
      final currentJob = provider.jobById(job.id);

      if (currentJob?.canRetryImport == true) {
        final outcome = await provider.retryJobImport(job.id);

        if (!context.mounted) {
          return;
        }

        await _handleActionOutcome(context: context, provider: provider, job: job, outcome: outcome);
      }
    case _SelectFile(:final index):
      final currentJob = provider.jobById(job.id);

      if (currentJob?.status == AcquisitionJobStatus.needsFileSelection) {
        final outcome = await provider.selectJobFile(job.id, index);

        if (!context.mounted) {
          return;
        }

        await _handleActionOutcome(context: context, provider: provider, job: job, outcome: outcome);
      }
  }
}

Future<void> _handleActionOutcome({
  required BuildContext context,
  required AcquisitionDownloadsProvider provider,
  required AcquisitionJob job,
  required AcquisitionJobActionOutcome outcome,
}) async {
  final message = outcome.error;

  if (!context.mounted || message == null) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  final currentJob = provider.jobById(job.id);

  if (currentJob != null && context.mounted) {
    await showAcquisitionJobDetailsSheet(context: context, provider: provider, job: currentJob);
  }
}

Future<void> showAcquisitionJobAttentionSheet({
  required BuildContext context,
  required AcquisitionDownloadsProvider provider,
  required AcquisitionJob job,
}) {
  return showAcquisitionJobDetailsSheet(context: context, provider: provider, job: job);
}

class _LiveAcquisitionJobDetailsContent extends StatelessWidget {
  const _LiveAcquisitionJobDetailsContent({required this.provider, required this.fallbackJob, required this.onAction});

  final AcquisitionDownloadsProvider provider;
  final AcquisitionJob fallbackJob;
  final ValueChanged<_AcquisitionJobAction> onAction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, child) {
        final currentJob = provider.jobById(fallbackJob.id);
        final displayJob = currentJob ?? fallbackJob;

        return _AcquisitionJobDetailsContent(
          job: displayJob,
          actionsEnabled: currentJob != null,
          fileChoices: currentJob?.status == AcquisitionJobStatus.needsFileSelection
              ? _AcquisitionFileChoices(
                  key: ValueKey('acquisition-file-choices-${currentJob!.id}'),
                  provider: provider,
                  jobId: currentJob.id,
                  onSelected: (index) => onAction(_SelectFile(index)),
                )
              : null,
          onAction: onAction,
        );
      },
    );
  }
}

class _AcquisitionJobDetailsContent extends StatelessWidget {
  const _AcquisitionJobDetailsContent({
    required this.job,
    required this.actionsEnabled,
    required this.fileChoices,
    required this.onAction,
  });

  final AcquisitionJob job;
  final bool actionsEnabled;
  final Widget? fileChoices;
  final ValueChanged<_AcquisitionJobAction> onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: Spacing.md),
        Semantics(
          key: const Key('acquisition-job-details-title'),
          header: true,
          child: Text(job.title, style: textTheme.headlineSmall),
        ),
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
        if (fileChoices case final choices?) ...[
          const SizedBox(height: Spacing.lg),
          Semantics(header: true, child: Text('Select file', style: textTheme.titleMedium)),
          const SizedBox(height: Spacing.sm),
          choices,
        ],
        if (actionsEnabled && job.canCancel) ...[
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => onAction(const _CancelJob()),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Cancel'),
          ),
        ],
        if (actionsEnabled && job.canRetryImport) ...[
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

class _AcquisitionFileChoices extends StatefulWidget {
  const _AcquisitionFileChoices({required this.provider, required this.jobId, required this.onSelected, super.key});

  final AcquisitionDownloadsProvider provider;
  final String jobId;
  final ValueChanged<int> onSelected;

  @override
  State<_AcquisitionFileChoices> createState() => _AcquisitionFileChoicesState();
}

class _AcquisitionFileChoicesState extends State<_AcquisitionFileChoices> {
  late Future<AcquisitionJobFilesResult> _files;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    _files = widget.provider.listJobFiles(widget.jobId);
  }

  void _retry() {
    setState(_loadFiles);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<AcquisitionJobFilesResult>(
      future: _files,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Row(
            children: [
              const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: Spacing.sm),
              Text('Loading files…', style: textTheme.bodyMedium),
            ],
          );
        }

        final result = snapshot.data;

        if (result == null || !result.isSuccess) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(result?.error ?? 'Could not load download files. Try again.', style: textTheme.bodyMedium),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          );
        }

        final supportedFiles = result.files.where((candidate) => candidate.supported).toList();

        if (supportedFiles.isEmpty) {
          return Text('No supported book files found.', style: textTheme.bodyMedium);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final candidate in supportedFiles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(candidate.name),
                subtitle: Text(formatBytes(candidate.sizeBytes)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onSelected(candidate.index),
              ),
          ],
        );
      },
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
