import 'package:flutter/material.dart';
import 'package:papyrus/models/reading_streak.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Widget displaying reading streak statistics.
class StreakWidget extends StatelessWidget {
  /// Streak data to display.
  final ReadingStreak streak;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const StreakWidget({super.key, required this.streak, this.isDesktop = false});

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
          Text('Reading streak', style: textTheme.titleMedium),
          const SizedBox(height: Spacing.md),
          // Current streak
          _buildStreakRow(
            context,
            icon: Icons.local_fire_department,
            iconColor: streak.hasActiveStreak
                ? colorScheme.tertiary
                : colorScheme.onSurfaceVariant,
            label: 'Current',
            value: '${streak.currentStreak} days',
            isHighlighted: streak.isCurrentBest,
          ),
          const SizedBox(height: Spacing.sm),
          // Best streak
          _buildStreakRow(
            context,
            icon: Icons.emoji_events_outlined,
            iconColor: colorScheme.primary,
            label: 'Best',
            value: '${streak.bestStreak} days',
          ),
          const SizedBox(height: Spacing.sm),
          // Days this month
          _buildStreakRow(
            context,
            icon: Icons.calendar_month_outlined,
            iconColor: colorScheme.onSurfaceVariant,
            label: 'This month',
            value: '${streak.daysThisMonth} days',
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlighted ? colorScheme.tertiary : null,
          ),
        ),
      ],
    );
  }
}
