import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/design_tokens.dart';

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
        final error = errorsByReleaseToken[release.releaseToken];
        final details = [
          release.indexer,
          if (release.formatHints.isNotEmpty) release.formatHints.map((format) => format.toUpperCase()).join(', '),
          if (release.sizeBytes != null) _formatBytes(release.sizeBytes!),
          if (release.seeders != null) '${release.seeders} seeders',
        ];

        return Semantics(
          container: true,
          label: release.title,
          selected: selected,
          child: Material(
            color: selected ? colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
            child: InkWell(
              onTap: () => onToggleSelection(release.releaseToken),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Row(
                  children: [
                    Checkbox(value: selected, onChanged: (_) => onToggleSelection(release.releaseToken)),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
