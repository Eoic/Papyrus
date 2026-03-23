import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A stat item data class for ProfileStatsCard.
class ProfileStat {
  /// Display label for the stat.
  final String label;

  /// Value to display.
  final String value;

  /// Optional icon for the stat.
  final IconData? icon;

  /// Creates a profile stat item.
  const ProfileStat({required this.label, required this.value, this.icon});
}

/// A card displaying reading statistics on the profile page.
///
/// Shows a grid of stats like books read, reading time, current streak, etc.
/// Only displayed on desktop layouts where there's sufficient space.
///
/// ## Features
///
/// - Configurable list of stats
/// - Optional "View All Stats" link
/// - Responsive grid layout
///
/// ## Example
///
/// ```dart
/// ProfileStatsCard(
///   stats: [
///     ProfileStat(label: 'Books read', value: '135'),
///     ProfileStat(label: 'Reading time', value: '45h'),
///     ProfileStat(label: 'Current streak', value: '5 days'),
///     ProfileStat(label: 'Goals completed', value: '12'),
///   ],
///   onViewAllStats: () => context.go('/statistics'),
/// )
/// ```
class ProfileStatsCard extends StatelessWidget {
  /// List of stats to display.
  final List<ProfileStat> stats;

  /// Called when "View All Stats" is tapped.
  final VoidCallback? onViewAllStats;

  /// Title for the card.
  final String title;

  /// Creates a profile stats card widget.
  const ProfileStatsCard({
    super.key,
    required this.stats,
    this.onViewAllStats,
    this.title = 'Reading statistics',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          ...stats.map((stat) => _buildStatRow(context, stat)),
          if (onViewAllStats != null) ...[
            const SizedBox(height: Spacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewAllStats,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View all stats'),
                    SizedBox(width: Spacing.xs),
                    Icon(Icons.arrow_forward, size: IconSizes.small),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, ProfileStat stat) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (stat.icon != null) ...[
                Icon(
                  stat.icon,
                  size: IconSizes.small,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Text(
                stat.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            stat.value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
