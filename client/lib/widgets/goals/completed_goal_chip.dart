import 'package:flutter/material.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Card displaying a completed goal with details.
class CompletedGoalChip extends StatelessWidget {
  /// The completed goal to display.
  final ReadingGoal goal;

  /// Called when the chip is tapped.
  final VoidCallback? onTap;

  /// Called when the delete button is pressed.
  final VoidCallback? onDelete;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  /// Whether to use expanded card layout (for desktop).
  final bool isExpanded;

  const CompletedGoalChip({
    super.key,
    required this.goal,
    this.onTap,
    this.onDelete,
    this.isEinkMode = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkChip(context);
    if (isExpanded) return _buildExpandedCard(context);
    return _buildCompactCard(context);
  }

  // ============================================================================
  // COMPACT CARD (for horizontal scroll)
  // ============================================================================

  Widget _buildCompactCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _showDetailsSheet(context),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with checkmark and type badge
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: colorScheme.onTertiary,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    _getGoalTypeLabel(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            // Target achieved
            Text(
              '${goal.target} ${goal.typeLabel}',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.xs),
            // Completion info
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _getCompletionDateLabel(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // EXPANDED CARD (for desktop wrap layout)
  // ============================================================================

  Widget _buildExpandedCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => _showDetailsSheet(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onTertiary,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${goal.target} ${goal.typeLabel}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getGoalTypeLabel(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              // Details row
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.calendar_today,
                    label: _getCompletionDateLabel(),
                  ),
                  const SizedBox(width: Spacing.sm),
                  _buildInfoChip(
                    context,
                    icon: _getRecurrenceIcon(),
                    label: goal.recurrenceLabel,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              // View details hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap for details',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // E-INK CHIP
  // ============================================================================

  Widget _buildEinkChip(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _showDetailsSheet(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black26),
          ),
        ),
        child: Row(
          children: [
            const Text(
              '[X]',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${goal.target} ${goal.typeLabel}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_getGoalTypeLabel()} • ${_getCompletionDateLabel()}',
                    style: textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DETAILS BOTTOM SHEET
  // ============================================================================

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _CompletedGoalDetailsSheet(
        goal: goal,
        onDelete: onDelete,
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _getGoalTypeLabel() {
    if (goal.isCustomPeriod) {
      return 'Custom goal';
    }
    if (goal.isRecurring) {
      return 'Recurring ${_getPeriodLabel()}';
    }
    return 'One-off ${_getPeriodLabel()}';
  }

  String _getPeriodLabel() {
    switch (goal.period) {
      case GoalPeriod.daily:
        return 'daily';
      case GoalPeriod.weekly:
        return 'weekly';
      case GoalPeriod.monthly:
        return 'monthly';
      case GoalPeriod.yearly:
        return 'yearly';
      case GoalPeriod.custom:
        return '';
    }
  }

  String _getCompletionDateLabel() {
    if (goal.completedAt == null) {
      return _formatShortDate(goal.endDate);
    }
    return _formatShortDate(goal.completedAt!);
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  IconData _getRecurrenceIcon() {
    if (goal.isCustomPeriod) return Icons.date_range;
    if (goal.isRecurring) return Icons.repeat;
    return Icons.looks_one;
  }
}

// ============================================================================
// DETAILS SHEET WIDGET
// ============================================================================

class _CompletedGoalDetailsSheet extends StatelessWidget {
  final ReadingGoal goal;
  final VoidCallback? onDelete;

  const _CompletedGoalDetailsSheet({
    required this.goal,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Header with success indicator
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 24,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal completed!',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      goal.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),

          // Stats grid
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  icon: Icons.track_changes,
                  label: 'Target achieved',
                  value: '${goal.current} of ${goal.target} ${goal.typeLabel}',
                ),
                const Divider(height: Spacing.lg),
                _buildDetailRow(
                  context,
                  icon: Icons.percent,
                  label: 'Progress',
                  value: '${(goal.progress * 100).round()}%',
                  valueColor: colorScheme.tertiary,
                ),
                const Divider(height: Spacing.lg),
                _buildDetailRow(
                  context,
                  icon: _getRecurrenceIcon(),
                  label: 'Goal type',
                  value: _getFullGoalTypeLabel(),
                ),
                const Divider(height: Spacing.lg),
                _buildDetailRow(
                  context,
                  icon: Icons.date_range,
                  label: 'Period',
                  value: _getPeriodDescription(),
                ),
                const Divider(height: Spacing.lg),
                _buildDetailRow(
                  context,
                  icon: Icons.check_circle,
                  label: 'Completed on',
                  value: _getCompletionDate(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(context);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete goal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
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
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
          'This will permanently remove "${goal.description}" from your completed goals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getFullGoalTypeLabel() {
    if (goal.isCustomPeriod) {
      return 'Custom date range';
    }
    final period = _getPeriodLabel();
    if (goal.isRecurring) {
      return 'Recurring $period goal';
    }
    return 'One-off $period goal';
  }

  String _getPeriodLabel() {
    switch (goal.period) {
      case GoalPeriod.daily:
        return 'daily';
      case GoalPeriod.weekly:
        return 'weekly';
      case GoalPeriod.monthly:
        return 'monthly';
      case GoalPeriod.yearly:
        return 'yearly';
      case GoalPeriod.custom:
        return 'custom';
    }
  }

  String _getPeriodDescription() {
    if (goal.isCustomPeriod) {
      return '${_formatDate(goal.startDate)} - ${_formatDate(goal.endDate)}';
    }
    switch (goal.period) {
      case GoalPeriod.daily:
        return _formatDate(goal.startDate);
      case GoalPeriod.weekly:
        return 'Week of ${_formatDate(goal.startDate)}';
      case GoalPeriod.monthly:
        return _formatMonthYear(goal.startDate);
      case GoalPeriod.yearly:
        return '${goal.startDate.year}';
      case GoalPeriod.custom:
        return '${_formatDate(goal.startDate)} - ${_formatDate(goal.endDate)}';
    }
  }

  String _getCompletionDate() {
    if (goal.completedAt == null) return 'Unknown';
    return _formatDate(goal.completedAt!);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  IconData _getRecurrenceIcon() {
    if (goal.isCustomPeriod) return Icons.date_range;
    if (goal.isRecurring) return Icons.repeat;
    return Icons.looks_one;
  }
}
