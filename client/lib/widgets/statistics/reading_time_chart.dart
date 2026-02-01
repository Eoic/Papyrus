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

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const ReadingTimeChart({
    super.key,
    required this.activities,
    this.isWeekly = true,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return _buildEmptyState(context);
    if (isEinkMode) return _buildEinkChart(context);
    return _buildStandardChart(context);
  }

  // ============================================================================
  // STANDARD BAR CHART
  // ============================================================================

  Widget _buildStandardChart(BuildContext context) {
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
            'Total: ${activities.totalTimeLabel} • Avg: ${activities.averageTimeLabel}/day',
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

    // Calculate nice Y-axis values
    final maxHours = (maxMinutes / 60).ceil();

    return SizedBox(
      width: 30,
      height: chartHeight - 20, // Leave room for X-axis labels
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
          ? (activity.readingMinutes / maxMinutes * maxHeight).clamp(2.0, maxHeight)
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
                  fontWeight:
                      activity.isToday ? FontWeight.bold : FontWeight.normal,
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
  // E-INK HORIZONTAL BAR CHART
  // ============================================================================

  Widget _buildEinkChart(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxMinutes = activities.maxMinutes;

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
            'READING TIME ${isWeekly ? "THIS WEEK" : ""}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.md),
          const Divider(color: Colors.black, height: 1),
          const SizedBox(height: Spacing.md),
          // Horizontal bars
          ...activities.map((activity) => _buildEinkBarRow(
                context,
                activity,
                maxMinutes,
              )),
          const SizedBox(height: Spacing.md),
          // Summary
          Text(
            'Total: ${activities.totalTimeLabel}   Average: ${activities.averageTimeLabel}/day',
            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkBarRow(
    BuildContext context,
    DailyActivity activity,
    int maxMinutes,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // Calculate bar width as character count (max 30)
    const maxChars = 30;
    final barChars = maxMinutes > 0
        ? (activity.readingMinutes / maxMinutes * maxChars).round().clamp(0, maxChars)
        : 0;

    final filledBar = '█' * barChars;
    final emptyBar = '░' * (maxChars - barChars);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              isWeekly ? activity.dayLabel : _getMonthLabel(activity.date),
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight:
                    activity.isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$filledBar$emptyBar',
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 0,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          SizedBox(
            width: 50,
            child: Text(
              activity.readingTimeLabel,
              style: textTheme.bodyMedium?.copyWith(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isEinkMode) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        padding: const EdgeInsets.all(Spacing.lg),
        child: Center(
          child: Text(
            'NO READING DATA',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

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
