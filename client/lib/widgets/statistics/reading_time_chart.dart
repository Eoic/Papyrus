import 'package:flutter/material.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Chart displaying reading time over a period.
class ReadingTimeChart extends StatelessWidget {
  /// Activity data to display.
  final List<DailyActivity> activities;

  /// Whether this is showing weekly data (affects labels).
  final bool isWeekly;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const ReadingTimeChart({
    super.key,
    required this.activities,
    this.isWeekly = true,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return _buildEmptyState(context);
    return _buildChart(context);
  }

  // ============================================================================
  // BAR CHART
  // ============================================================================

  Widget _buildChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxMinutes = activities.maxMinutes;
    final chartHeight = isDesktop ? 200.0 : 150.0;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading time', style: textTheme.titleMedium),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                _buildYAxisLabels(context, maxMinutes, chartHeight),
                const SizedBox(width: Spacing.sm),
                // Bars
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _buildBars(context, maxMinutes, chartHeight - 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Summary
          Text(
            'Total: ${activities.totalTimeLabel} \u2022 Avg: ${activities.averageTimeLabel}/day',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabels(
    BuildContext context,
    int maxMinutes,
    double chartHeight,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final maxHours = (maxMinutes / 60).ceil();

    return SizedBox(
      width: 30,
      height: chartHeight - 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${maxHours}h',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          Text(
            '${maxHours ~/ 2}h',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          Text(
            '0h',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBars(
    BuildContext context,
    int maxMinutes,
    double maxHeight,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return activities.map((activity) {
      final barHeight = maxMinutes > 0
          ? (activity.readingMinutes / maxMinutes * maxHeight).clamp(
              2.0,
              maxHeight,
            )
          : 2.0;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Bar
              Container(
                height: activity.hasActivity ? barHeight : 2,
                decoration: BoxDecoration(
                  color: activity.isToday
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // X-axis label
              Text(
                isWeekly ? activity.dayInitial : _getMonthLabel(activity.date),
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
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
        ),
      );
    }).toList();
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Text(
          'No reading data for this period',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _getMonthLabel(DateTime date) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return months[date.month - 1];
  }
}
