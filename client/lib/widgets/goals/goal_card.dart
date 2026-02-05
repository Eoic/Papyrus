import 'package:flutter/material.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Unified goal card widget displaying consistent linear progress.
///
/// All goals (daily, weekly, monthly, yearly) use the same layout
/// with linear progress bars for visual consistency and scanability.
class GoalCard extends StatelessWidget {
  /// The reading goal to display.
  final ReadingGoal goal;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? Spacing.lg : Spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme, textTheme),
              const SizedBox(height: Spacing.md),
              _buildProgressValues(context, colorScheme, textTheme),
              const SizedBox(height: Spacing.sm),
              _buildProgressBar(colorScheme),
              const SizedBox(height: Spacing.sm),
              _buildFooter(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // CARD SECTIONS
  // ============================================================================

  /// Builds the header with icon, title, and optional badges.
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _getIconForType(goal.type),
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            goal.description,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (goal.isDaily && goal.isRecurring && goal.streak > 0) ...[
          const SizedBox(width: Spacing.sm),
          _buildStreakBadge(colorScheme, textTheme),
        ],
        if (!goal.isRecurring && !goal.isCustomPeriod) ...[
          const SizedBox(width: Spacing.sm),
          _buildOneOffBadge(colorScheme, textTheme),
        ],
        if (goal.isCompleted) ...[
          const SizedBox(width: Spacing.sm),
          Icon(Icons.check_circle, size: 24, color: colorScheme.tertiary),
        ],
      ],
    );
  }

  /// Builds the streak badge for recurring daily goals.
  Widget _buildStreakBadge(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            '${goal.streak}',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "One-off" badge for non-recurring goals.
  Widget _buildOneOffBadge(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'One-off',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Builds the progress values row showing current/target and percentage.
  Widget _buildProgressValues(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${goal.current} of ${goal.target} ${goal.typeLabel}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          goal.progressLabel,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: goal.isCompleted
                ? colorScheme.tertiary
                : colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Builds the linear progress bar.
  Widget _buildProgressBar(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: LinearProgressIndicator(
        value: goal.progress.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: goal.isCompleted ? colorScheme.tertiary : colorScheme.primary,
      ),
    );
  }

  /// Builds the footer with status text and time context.
  Widget _buildFooter(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          goal.isCompleted
              ? 'Completed!'
              : '${goal.remaining} ${goal.typeLabel} to go',
          style: textTheme.bodySmall?.copyWith(
            color: goal.isCompleted
                ? colorScheme.tertiary
                : colorScheme.onSurfaceVariant,
            fontWeight: goal.isCompleted ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        Text(
          _getTimeContext(),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _getTimeContext() {
    final daysLeft = goal.endDate.difference(DateTime.now()).inDays;

    switch (goal.period) {
      case GoalPeriod.daily:
        return 'Today';
      case GoalPeriod.weekly:
        return daysLeft <= 0 ? 'This week' : '$daysLeft days left';
      case GoalPeriod.monthly:
        return daysLeft <= 7 ? '$daysLeft days left' : 'This month';
      case GoalPeriod.yearly:
        return 'Ends ${_formatDate(goal.endDate)}';
      case GoalPeriod.custom:
        if (daysLeft <= 0) return 'Ends today';
        if (daysLeft <= 7) return '$daysLeft days left';
        return '${_formatShortDate(goal.startDate)} - ${_formatShortDate(goal.endDate)}';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  IconData _getIconForType(GoalType type) {
    switch (type) {
      case GoalType.books:
        return Icons.menu_book_outlined;
      case GoalType.pages:
        return Icons.article_outlined;
      case GoalType.minutes:
        return Icons.schedule_outlined;
    }
  }
}
