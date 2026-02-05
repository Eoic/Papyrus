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
  });

  @override
  Widget build(BuildContext context) {
    return _buildChart(context);
  }

  // ============================================================================
  // CHART LAYOUT
  // ============================================================================

  /// Builds the chart container with header, bar chart, and optional summary.
  Widget _buildChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxMinutes = activities.maxMinutes;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, textTheme, colorScheme),
          const SizedBox(height: Spacing.md),
          _buildBarChart(context, textTheme, colorScheme, maxMinutes),
          const SizedBox(height: Spacing.sm),
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

  /// Builds the header row with period navigation and optional toggle.
  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: onPreviousPeriod,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        if (showPeriodToggle) _buildPeriodToggle(context),
      ],
    );
  }

  /// Builds the bar chart showing activity per day.
  Widget _buildBarChart(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    int maxMinutes,
  ) {
    return SizedBox(
      height: 120,
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
    );
  }

  /// Builds a single bar with time label and day label.
  Widget _buildBar(
    BuildContext context, {
    required DailyActivity activity,
    required int maxMinutes,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final maxHeight = 80.0;
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
          Text(
            activity.dayLabel,
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

  /// Builds the week/month segmented toggle button.
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
}
