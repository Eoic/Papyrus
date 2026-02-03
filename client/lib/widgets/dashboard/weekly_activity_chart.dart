import 'package:flutter/material.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/providers/dashboard_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Weekly activity chart showing reading time per day.
class WeeklyActivityChart extends StatelessWidget {
  /// List of daily activity data for the week.
  final List<DailyActivity> activities;

  /// Current activity period (week/month).
  final ActivityPeriod activityPeriod;

  /// Called when the period toggle is changed.
  final ValueChanged<ActivityPeriod>? onPeriodChanged;

  /// Whether to show the period toggle (desktop only).
  final bool showPeriodToggle;

  /// Label for the current period (e.g., "This week", "Jan 15-21").
  final String periodLabel;

  /// Called when navigating to previous period.
  final VoidCallback? onPreviousPeriod;

  /// Called when navigating to next period.
  final VoidCallback? onNextPeriod;

  /// Whether next period navigation is enabled.
  final bool canGoToNextPeriod;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const WeeklyActivityChart({
    super.key,
    required this.activities,
    this.activityPeriod = ActivityPeriod.week,
    this.onPeriodChanged,
    this.showPeriodToggle = false,
    this.periodLabel = 'This week',
    this.onPreviousPeriod,
    this.onNextPeriod,
    this.canGoToNextPeriod = true,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkChart(context);
    return _buildStandardChart(context);
  }

  // ============================================================================
  // STANDARD LAYOUT
  // ============================================================================

  Widget _buildStandardChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxMinutes = activities.maxMinutes;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Period label with navigation arrows
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: onPreviousPeriod,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Text(periodLabel, style: textTheme.titleMedium),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: canGoToNextPeriod
                          ? null
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    onPressed: canGoToNextPeriod ? onNextPeriod : null,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              if (showPeriodToggle) _buildPeriodToggle(context),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Chart
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: activities.map((activity) {
                return Expanded(
                  child: _buildBar(
                    context,
                    activity: activity,
                    maxMinutes: maxMinutes,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Summary
          if (showPeriodToggle)
            Text(
              'Total: ${activities.totalTimeLabel} • Avg: ${activities.averageTimeLabel}/day',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBar(
    BuildContext context, {
    required DailyActivity activity,
    required int maxMinutes,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Calculate bar height (max 40px)
    final maxHeight = 40.0;
    final barHeight = maxMinutes > 0
        ? (activity.readingMinutes / maxMinutes * maxHeight).clamp(
            2.0,
            maxHeight,
          )
        : 2.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Time label (only if has activity)
          if (activity.hasActivity)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                activity.readingTimeLabel,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          // Bar
          Container(
            height: activity.hasActivity ? barHeight : 2,
            decoration: BoxDecoration(
              color: activity.isToday
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          // Day label
          Text(
            activity.dayInitial,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: activity.isToday
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: activity.isToday
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(BuildContext context) {
    return SegmentedButton<ActivityPeriod>(
      segments: const [
        ButtonSegment(value: ActivityPeriod.week, label: Text('Week')),
        ButtonSegment(value: ActivityPeriod.month, label: Text('Month')),
      ],
      selected: {activityPeriod},
      onSelectionChanged: (selected) {
        onPeriodChanged?.call(selected.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkChart(BuildContext context) {
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
          // Header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onPreviousPeriod,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Text(
                        '<',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    periodLabel.toUpperCase(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: canGoToNextPeriod ? onNextPeriod : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '>',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: canGoToNextPeriod
                              ? Colors.black
                              : Colors.black26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Total: ${activities.totalTimeLabel}',
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Divider(color: Colors.black, height: 1),
          const SizedBox(height: Spacing.md),
          // Chart rows
          _buildEinkChartRows(context),
        ],
      ),
    );
  }

  Widget _buildEinkChartRows(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxMinutes = activities.maxMinutes;

    return Column(
      children: [
        // Day labels
        Row(
          children: activities.map((activity) {
            return Expanded(
              child: Center(
                child: Text(
                  activity.dayLabel.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: activity.isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: Spacing.sm),
        // ASCII bars
        Row(
          children: activities.map((activity) {
            return Expanded(
              child: Center(
                child: _buildEinkBar(
                  context,
                  activity: activity,
                  maxMinutes: maxMinutes,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: Spacing.sm),
        // Time labels
        Row(
          children: activities.map((activity) {
            return Expanded(
              child: Center(
                child: Text(
                  activity.readingTimeLabel,
                  style: textTheme.labelMedium?.copyWith(fontSize: 14),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEinkBar(
    BuildContext context, {
    required DailyActivity activity,
    required int maxMinutes,
  }) {
    // Calculate fill level (0-3 blocks)
    final fillLevel = maxMinutes > 0
        ? ((activity.readingMinutes / maxMinutes) * 3).round().clamp(0, 3)
        : 0;

    // Use Unicode block characters for ASCII-style bars
    String barText;
    switch (fillLevel) {
      case 0:
        barText = '░░░';
        break;
      case 1:
        barText = '█░░';
        break;
      case 2:
        barText = '██░';
        break;
      case 3:
        barText = '███';
        break;
      default:
        barText = '░░░';
    }

    return Text(
      barText,
      style: TextStyle(
        fontSize: 16,
        fontWeight: activity.isToday ? FontWeight.bold : FontWeight.normal,
        letterSpacing: 1,
      ),
    );
  }
}
