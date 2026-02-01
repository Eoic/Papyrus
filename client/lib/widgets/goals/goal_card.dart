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

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkCard(context);
    return _buildStandardCard(context);
  }

  // ============================================================================
  // STANDARD CARD (Mobile & Desktop)
  // ============================================================================

  Widget _buildStandardCard(BuildContext context) {
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
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title + Streak badge
              _buildHeader(context, colorScheme, textTheme),
              const SizedBox(height: Spacing.md),
              // Progress values: "8 of 12 books" and "67%"
              _buildProgressValues(context, colorScheme, textTheme),
              const SizedBox(height: Spacing.sm),
              // Progress bar
              _buildProgressBar(context, colorScheme),
              const SizedBox(height: Spacing.sm),
              // Footer: Status + Time context
              _buildFooter(context, colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // Goal type icon
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
        // Title
        Expanded(
          child: Text(
            goal.description,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Streak badge (recurring daily goals only)
        if (goal.isDaily && goal.isRecurring && goal.streak > 0) ...[
          const SizedBox(width: Spacing.sm),
          _buildStreakBadge(context, colorScheme, textTheme),
        ],
        // Recurrence indicator for non-recurring goals
        if (!goal.isRecurring && !goal.isCustomPeriod) ...[
          const SizedBox(width: Spacing.sm),
          _buildOneOffBadge(context, colorScheme, textTheme),
        ],
        // Completed checkmark
        if (goal.isCompleted) ...[
          const SizedBox(width: Spacing.sm),
          Icon(
            Icons.check_circle,
            size: 24,
            color: colorScheme.tertiary,
          ),
        ],
      ],
    );
  }

  Widget _buildStreakBadge(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
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

  Widget _buildOneOffBadge(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
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

  Widget _buildProgressValues(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Current / Target
        Text(
          '${goal.current} of ${goal.target} ${goal.typeLabel}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        // Percentage
        Text(
          goal.progressLabel,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: goal.isCompleted ? colorScheme.tertiary : colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, ColorScheme colorScheme) {
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

  Widget _buildFooter(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Status text
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
        // Time context
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
  // E-INK CARD
  // ============================================================================

  Widget _buildEinkCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Title with streak
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.description.toUpperCase(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (goal.isDaily && goal.streak > 0)
                  Text(
                    'STREAK: ${goal.streak}',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            // Progress text
            Text(
              '${goal.current} of ${goal.target} ${goal.typeLabel} (${goal.progressLabel})',
              style: textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: Spacing.sm),
            // Segmented progress bar
            _buildEinkProgressBar(context),
            const SizedBox(height: Spacing.sm),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.statusText,
                  style: textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                Text(
                  _getTimeContext(),
                  style: textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEinkProgressBar(BuildContext context) {
    const segmentCount = 20;
    final filledSegments = (goal.progress * segmentCount).round().clamp(0, 20);

    return SizedBox(
      height: 16,
      child: Row(
        children: List.generate(segmentCount, (index) {
          final isFilled = index < filledSegments;
          final isFirst = index == 0;

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isFilled ? Colors.black : Colors.white,
                border: Border(
                  top: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                  bottom: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                  left: isFirst
                      ? const BorderSide(
                          color: Colors.black,
                          width: BorderWidths.einkDefault,
                        )
                      : BorderSide.none,
                  right: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
