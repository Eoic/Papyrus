import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/remote_release_list.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';

class OnlineResultsView extends StatelessWidget {
  final bool hasSearched;
  final bool isSearching;
  final String query;
  final String? error;
  final List<TorrentRelease> releases;
  final Set<String> selectedReleaseTokens;
  final Map<String, String> errorsByReleaseToken;
  final VoidCallback onRetry;
  final ValueChanged<String> onToggleSelection;

  const OnlineResultsView({
    super.key,
    required this.hasSearched,
    required this.isSearching,
    required this.query,
    required this.error,
    required this.releases,
    required this.selectedReleaseTokens,
    required this.errorsByReleaseToken,
    required this.onRetry,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppCircularProgressIndicator(),
            const SizedBox(height: Spacing.md),
            Text(
              query.trim().isEmpty
                  ? 'Searching connected sources…'
                  : 'Searching connected sources for “${query.trim()}”…',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to search connected sources',
        subtitle: error,
        action: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
      );
    }

    if (!hasSearched) {
      return const EmptyState(
        icon: Icons.travel_explore_outlined,
        title: 'Search connected sources',
        subtitle: 'Search by title or author to find available releases.',
      );
    }

    if (releases.isEmpty) {
      final trimmedQuery = query.trim();
      final subtitle = trimmedQuery.isEmpty
          ? 'Try another title or author.'
          : 'No releases found for “$trimmedQuery”. Try another title or author.';

      return EmptyState(icon: Icons.search_off_outlined, title: 'No releases found', subtitle: subtitle);
    }

    return RemoteReleaseList(
      releases: releases,
      selectedReleaseTokens: selectedReleaseTokens,
      errorsByReleaseToken: errorsByReleaseToken,
      onToggleSelection: onToggleSelection,
    );
  }
}
