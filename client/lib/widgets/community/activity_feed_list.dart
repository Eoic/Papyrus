import 'package:flutter/material.dart';
import 'package:papyrus/providers/community_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/community/activity_card.dart';
import 'package:provider/provider.dart';

/// List of activity feed items.
class ActivityFeedList extends StatelessWidget {
  const ActivityFeedList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isFeedLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.feedError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: IconSizes.large,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: Spacing.sm),
                Text(provider.feedError!, style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        if (!provider.hasFeedItems) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outlined,
                  size: IconSizes.large,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: Spacing.md),
                Text('No activity yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Follow other readers to see their activity here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: provider.feedItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, index) {
            return ActivityCard(activity: provider.feedItems[index]);
          },
        );
      },
    );
  }
}
