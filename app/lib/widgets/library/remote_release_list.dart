import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/app_motion_control.dart';

class RemoteReleaseList extends StatelessWidget {
  final List<TorrentRelease> releases;
  final Set<String> selectedReleaseTokens;
  final Map<String, String> errorsByReleaseToken;
  final ValueChanged<String> onToggleSelection;

  const RemoteReleaseList({
    super.key,
    required this.releases,
    required this.selectedReleaseTokens,
    this.errorsByReleaseToken = const {},
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      itemCount: releases.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: colorScheme.outlineVariant),
      itemBuilder: (context, index) {
        final release = releases[index];
        final selected = selectedReleaseTokens.contains(release.releaseToken);
        final trimmedError = errorsByReleaseToken[release.releaseToken]?.trim();
        final error = trimmedError == null || trimmedError.isEmpty ? null : trimmedError;
        final formatHints = release.formatHints
            .map((format) => format.trim().toUpperCase())
            .where((format) => format.isNotEmpty)
            .join(', ');
        final details = <String>[
          release.indexer.trim(),
          if (formatHints.isNotEmpty) formatHints,
          if (release.sizeBytes != null) _formatBytes(release.sizeBytes!),
          if (release.seeders != null) '${release.seeders} seeders',
        ].where((detail) => detail.isNotEmpty).toList();
        final semanticLabel = _semanticLabel(release.title, details, error);

        return Semantics(
          key: ValueKey('remote-release-${release.releaseToken}'),
          container: true,
          label: semanticLabel,
          button: true,
          selected: selected,
          onTap: () => onToggleSelection(release.releaseToken),
          child: ExcludeSemantics(
            child: Material(
              color: selected ? colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
              child: InkWell(
                onTap: () => onToggleSelection(release.releaseToken),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Row(
                    children: [
                      AppMotionControl(
                        value: selected,
                        builder: (focusNode) => Checkbox(
                          focusNode: focusNode,
                          value: selected,
                          onChanged: (_) => onToggleSelection(release.releaseToken),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              release.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              details.join(' · '),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (error != null) ...[
                              const SizedBox(height: Spacing.xs),
                              Text(
                                error,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                                maxLines: 2,
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
        );
      },
    );
  }
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;

  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }

  final precision = value >= 10 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unit]}';
}

String _semanticLabel(String title, List<String> details, String? error) {
  return <String>[title, ...details, ?error].where((part) => part.isNotEmpty).join('. ');
}
