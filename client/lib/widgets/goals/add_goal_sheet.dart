import 'package:flutter/material.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// The type of goal scheduling.
enum GoalScheduleType {
  recurring, // Repeats periodically (daily, weekly, monthly, yearly)
  oneOff, // Single occurrence with a preset period
  custom, // Custom date range
}

/// Bottom sheet for creating a new goal.
class AddGoalSheet extends StatefulWidget {
  /// Called when a goal is created.
  final void Function(
    GoalType type,
    int target,
    GoalPeriod period,
    bool isRecurring,
    DateTime? startDate,
    DateTime? endDate,
  )?
  onCreate;

  const AddGoalSheet({super.key, this.onCreate});

  /// Shows the add goal sheet.
  static Future<void> show(
    BuildContext context, {
    void Function(
      GoalType type,
      int target,
      GoalPeriod period,
      bool isRecurring,
      DateTime? startDate,
      DateTime? endDate,
    )?
    onCreate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => AddGoalSheet(onCreate: onCreate),
    );
  }

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  GoalScheduleType _scheduleType = GoalScheduleType.recurring;
  GoalType _selectedType = GoalType.books;
  GoalPeriod _selectedPeriod = GoalPeriod.yearly;
  final _targetController = TextEditingController(text: '12');
  int _durationMinutes = 30;

  // Custom date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.lg),
            // Title
            Text('Create new goal', style: textTheme.headlineSmall),
            const SizedBox(height: Spacing.lg),

            // Schedule type selection
            Text(
              'Goal type',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            SegmentedButton<GoalScheduleType>(
              segments: const [
                ButtonSegment(
                  value: GoalScheduleType.recurring,
                  label: Text('Recurring'),
                  icon: Icon(Icons.repeat, size: 18),
                ),
                ButtonSegment(
                  value: GoalScheduleType.oneOff,
                  label: Text('One-off'),
                  icon: Icon(Icons.looks_one, size: 18),
                ),
                ButtonSegment(
                  value: GoalScheduleType.custom,
                  label: Text('Custom'),
                  icon: Icon(Icons.date_range, size: 18),
                ),
              ],
              selected: {_scheduleType},
              onSelectionChanged: (selected) {
                setState(() => _scheduleType = selected.first);
              },
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: Spacing.md),

            // Description of selected type
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      _getScheduleDescription(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // What to track
            Text(
              'What to track',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            DropdownButtonFormField<GoalType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
              items: GoalType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _targetController.text = _getDefaultTarget(value);
                    if (value == GoalType.minutes) _durationMinutes = 30;
                  });
                }
              },
            ),
            const SizedBox(height: Spacing.lg),

            // Target
            Text(
              'Target',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            if (_selectedType == GoalType.minutes)
              _buildDurationPicker(colorScheme, textTheme)
            else
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  suffixText: _getTypeSuffix(_selectedType),
                ),
              ),
            const SizedBox(height: Spacing.lg),

            // Period selection (for recurring and one-off)
            if (_scheduleType != GoalScheduleType.custom) ...[
              Text(
                'Time period',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SegmentedButton<GoalPeriod>(
                segments:
                    [
                      GoalPeriod.daily,
                      GoalPeriod.weekly,
                      GoalPeriod.monthly,
                      GoalPeriod.yearly,
                    ].map((period) {
                      return ButtonSegment(
                        value: period,
                        label: Text(_getPeriodLabel(period)),
                      );
                    }).toList(),
                selected: {_selectedPeriod},
                onSelectionChanged: (selected) {
                  setState(() => _selectedPeriod = selected.first);
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(height: Spacing.lg),
            ],

            // Custom date range picker
            if (_scheduleType == GoalScheduleType.custom) ...[
              Text(
                'Date range',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      context,
                      label: 'Start',
                      date: _startDate,
                      onTap: () => _pickStartDate(context),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _buildDateButton(
                      context,
                      label: 'End',
                      date: _endDate,
                      onTap: () => _pickEndDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                '${_daysBetween()} days total',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],

            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onCreate,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Text('Create goal'),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPicker(ColorScheme colorScheme, TextTheme textTheme) {
    const presets = [15, 30, 60, 120];
    const presetLabels = ['15m', '30m', '1h', '2h'];

    return Column(
      children: [
        // Preset chips
        Wrap(
          spacing: Spacing.sm,
          children: List.generate(presets.length, (i) {
            return ChoiceChip(
              label: Text(presetLabels[i]),
              selected: _durationMinutes == presets[i],
              onSelected: (_) {
                setState(() => _durationMinutes = presets[i]);
              },
            );
          }),
        ),
        const SizedBox(height: Spacing.md),
        // Stepper row
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _durationMinutes > 5
                    ? () {
                        setState(() {
                          final step = _durationMinutes > 60 ? 15 : 5;
                          _durationMinutes = (_durationMinutes - step).clamp(
                            5,
                            _durationMinutes,
                          );
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                formatDuration(_durationMinutes),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: Spacing.md),
              IconButton(
                onPressed: () {
                  setState(() {
                    final step = _durationMinutes >= 60 ? 15 : 5;
                    _durationMinutes += step;
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: Spacing.sm),
                Text(_formatDate(date), style: textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _onCreate() {
    final target = _selectedType == GoalType.minutes
        ? _durationMinutes
        : (int.tryParse(_targetController.text) ?? 0);
    if (target <= 0) return;

    final GoalPeriod period;
    final bool isRecurring;
    DateTime? startDate;
    DateTime? endDate;

    switch (_scheduleType) {
      case GoalScheduleType.recurring:
        period = _selectedPeriod;
        isRecurring = true;
        break;
      case GoalScheduleType.oneOff:
        period = _selectedPeriod;
        isRecurring = false;
        break;
      case GoalScheduleType.custom:
        period = GoalPeriod.custom;
        isRecurring = false;
        startDate = _startDate;
        endDate = _endDate;
        break;
    }

    widget.onCreate?.call(
      _selectedType,
      target,
      period,
      isRecurring,
      startDate,
      endDate,
    );
    Navigator.of(context).pop();
  }

  String _getScheduleDescription() {
    switch (_scheduleType) {
      case GoalScheduleType.recurring:
        return 'Goal resets and repeats each period (e.g., 30 min daily, every day)';
      case GoalScheduleType.oneOff:
        return 'Single goal that ends when completed or period expires';
      case GoalScheduleType.custom:
        return 'Set your own start and end dates for this goal';
    }
  }

  String _getTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.books:
        return 'Books to read';
      case GoalType.pages:
        return 'Pages to read';
      case GoalType.minutes:
        return 'Reading time (minutes)';
    }
  }

  String _getTypeSuffix(GoalType type) {
    switch (type) {
      case GoalType.books:
        return 'books';
      case GoalType.pages:
        return 'pages';
      case GoalType.minutes:
        return 'minutes';
    }
  }

  String _getDefaultTarget(GoalType type) {
    switch (type) {
      case GoalType.books:
        return '12';
      case GoalType.pages:
        return '50';
      case GoalType.minutes:
        return '30';
    }
  }

  String _getPeriodLabel(GoalPeriod period) {
    switch (period) {
      case GoalPeriod.daily:
        return 'Daily';
      case GoalPeriod.weekly:
        return 'Weekly';
      case GoalPeriod.monthly:
        return 'Monthly';
      case GoalPeriod.yearly:
        return 'Yearly';
      case GoalPeriod.custom:
        return 'Custom';
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

  int _daysBetween() {
    return _endDate.difference(_startDate).inDays + 1;
  }
}
