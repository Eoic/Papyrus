import 'package:flutter/material.dart';
import 'package:papyrus/models/reading_streak.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Widget displaying reading streak statistics.
class StreakWidget extends StatelessWidget {
  /// Streak data to display.
  final ReadingStreak streak;

  /// Whether to use desktop styling.
  final bool isDesktop;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const StreakWidget({
    super.key,
    required this.streak,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkWidget(context);
    return _buildStandardWidget(context);
  }

  // ============================================================================
  // STANDARD WIDGET
  // ============================================================================

  Widget _buildStandardWidget(BuildContext context) {
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

  // ============================================================================
  // E-INK WIDGET
  // ============================================================================

  Widget _buildEinkWidget(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'READING STREAK',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.md),
          const Divider(color: Colors.black, height: 1),
          const SizedBox(height: Spacing.md),
          // Stats as label-value pairs
          _buildEinkStatRow(
            context,
            label: 'Current streak',
            value: '${streak.currentStreak} days',
          ),
          _buildEinkStatRow(
            context,
            label: 'Best streak',
            value: '${streak.bestStreak} days',
          ),
          _buildEinkStatRow(
            context,
            label: 'Days this month',
            value: '${streak.daysThisMonth} of ${streak.totalDaysInMonth}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEinkStatRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Colors.black26),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
