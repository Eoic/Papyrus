import 'package:flutter/material.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Bottom sheet for viewing and editing an active goal.
class ActiveGoalDetailsSheet extends StatefulWidget {
  /// The goal to display/edit.
  final ReadingGoal goal;

  /// Called when progress is updated.
  final void Function(int newProgress)? onUpdateProgress;

  /// Called when goal is edited.
  final void Function(int newTarget)? onEdit;

  /// Called when goal is deleted.
  final VoidCallback? onDelete;

  const ActiveGoalDetailsSheet({
    super.key,
    required this.goal,
    this.onUpdateProgress,
    this.onEdit,
    this.onDelete,
  });

  /// Shows the active goal details sheet.
  static Future<void> show(
    BuildContext context, {
    required ReadingGoal goal,
    void Function(int newProgress)? onUpdateProgress,
    void Function(int newTarget)? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => ActiveGoalDetailsSheet(
        goal: goal,
        onUpdateProgress: onUpdateProgress,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ActiveGoalDetailsSheet> createState() => _ActiveGoalDetailsSheetState();
}

class _ActiveGoalDetailsSheetState extends State<ActiveGoalDetailsSheet> {
  late TextEditingController _progressController;
  late TextEditingController _targetController;
  late int _currentProgress;
  late int _currentTarget;
  bool _isEditingProgress = false;
  bool _isEditingTarget = false;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.goal.current;
    _currentTarget = widget.goal.target;
    _progressController = TextEditingController(
      text: _currentProgress.toString(),
    );
    _targetController = TextEditingController(text: _currentTarget.toString());
  }

  @override
  void dispose() {
    _progressController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
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

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _getIconForType(widget.goal.type),
                  size: 24,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.description,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getGoalTypeLabel(),
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

          // Progress section
          _buildProgressSection(context, colorScheme, textTheme),
          const SizedBox(height: Spacing.lg),

          // Target section
          _buildTargetSection(context, colorScheme, textTheme),
          const SizedBox(height: Spacing.lg),

          // Goal info
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: _getRecurrenceIcon(),
                  label: 'Type',
                  value: widget.goal.recurrenceLabel,
                ),
                const Divider(height: Spacing.lg),
                _buildInfoRow(
                  context,
                  icon: Icons.date_range,
                  label: 'Period',
                  value: _getPeriodDescription(),
                ),
                if (widget.goal.isDaily &&
                    widget.goal.isRecurring &&
                    widget.goal.streak > 0) ...[
                  const Divider(height: Spacing.lg),
                  _buildInfoRow(
                    context,
                    icon: Icons.local_fire_department,
                    label: 'Current streak',
                    value: '${widget.goal.streak} days',
                    valueColor: colorScheme.tertiary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!_isEditingProgress)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingProgress = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          if (_isEditingProgress) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _progressController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      suffixText: 'of $_currentTarget',
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                IconButton.filled(
                  onPressed: _saveProgress,
                  icon: const Icon(Icons.check, size: 20),
                ),
                const SizedBox(width: Spacing.xs),
                IconButton.outlined(
                  onPressed: () {
                    setState(() {
                      _isEditingProgress = false;
                      _progressController.text = _currentProgress.toString();
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ] else ...[
            Builder(
              builder: (context) {
                final progress = (_currentProgress / _currentTarget).clamp(
                  0.0,
                  1.0,
                );
                final isCompleted = _currentProgress >= _currentTarget;
                final progressLabel = '${(progress * 100).round()}%';

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_currentProgress of $_currentTarget ${widget.goal.typeLabel}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              color: isCompleted
                                  ? colorScheme.tertiary
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Text(
                      progressLabel,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!_isEditingTarget)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingTarget = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // Fixed height container to prevent layout shifts
          SizedBox(
            height: 36,
            child: _isEditingTarget
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: Spacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            suffixText: widget.goal.typeLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      IconButton.filled(
                        onPressed: _saveTarget,
                        icon: const Icon(Icons.check, size: 20),
                      ),
                      const SizedBox(width: Spacing.xs),
                      IconButton.outlined(
                        onPressed: () {
                          setState(() {
                            _isEditingTarget = false;
                            _targetController.text = _currentTarget.toString();
                          });
                        },
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$_currentTarget ${widget.goal.typeLabel}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
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

  void _saveProgress() {
    final newProgress = int.tryParse(_progressController.text);
    if (newProgress != null && newProgress >= 0) {
      widget.onUpdateProgress?.call(newProgress);
      setState(() {
        _currentProgress = newProgress;
        _isEditingProgress = false;
      });
    }
  }

  void _saveTarget() {
    final newTarget = int.tryParse(_targetController.text);
    if (newTarget != null && newTarget > 0) {
      widget.onEdit?.call(newTarget);
      setState(() {
        _currentTarget = newTarget;
        _isEditingTarget = false;
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
          'This will permanently remove "${widget.goal.description}" from your goals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getGoalTypeLabel() {
    if (widget.goal.isCustomPeriod) {
      return 'Custom date range';
    }
    final period = _getPeriodLabel();
    if (widget.goal.isRecurring) {
      return 'Recurring $period goal';
    }
    return 'One-off $period goal';
  }

  String _getPeriodLabel() {
    switch (widget.goal.period) {
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
    if (widget.goal.isCustomPeriod) {
      return '${_formatDate(widget.goal.startDate)} - ${_formatDate(widget.goal.endDate)}';
    }
    switch (widget.goal.period) {
      case GoalPeriod.daily:
        return 'Today';
      case GoalPeriod.weekly:
        return 'This week';
      case GoalPeriod.monthly:
        return _formatMonthYear(widget.goal.startDate);
      case GoalPeriod.yearly:
        return '${widget.goal.startDate.year}';
      case GoalPeriod.custom:
        return '${_formatDate(widget.goal.startDate)} - ${_formatDate(widget.goal.endDate)}';
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

  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
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

  IconData _getRecurrenceIcon() {
    if (widget.goal.isCustomPeriod) return Icons.date_range;
    if (widget.goal.isRecurring) return Icons.repeat;
    return Icons.looks_one;
  }
}
