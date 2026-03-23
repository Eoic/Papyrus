import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/providers/statistics_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';

// =============================================================================
// DATA AGGREGATION
// =============================================================================

/// A bucket of aggregated daily activities (e.g., a week).
class _AggregatedBucket {
  final DateTime startDate;
  final DateTime endDate;
  final int totalMinutes;
  final int totalPages;
  final int dayCount;

  const _AggregatedBucket({
    required this.startDate,
    required this.endDate,
    required this.totalMinutes,
    required this.totalPages,
    required this.dayCount,
  });

  bool get containsToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(startDate) && !today.isAfter(endDate);
  }

  String get label {
    if (startDate.month == endDate.month) {
      return '${_months[startDate.month - 1]} ${startDate.day}-${endDate.day}';
    }
    return '${_months[startDate.month - 1]} ${startDate.day} - ${_months[endDate.month - 1]} ${endDate.day}';
  }
}

/// Aggregates daily activities into weekly buckets.
List<_AggregatedBucket> _aggregateWeekly(List<DailyActivity> activities) {
  if (activities.isEmpty) return [];

  final buckets = <_AggregatedBucket>[];
  var bucketStart = 0;

  while (bucketStart < activities.length) {
    var bucketEnd = bucketStart;
    while (bucketEnd + 1 < activities.length) {
      final nextDate = activities[bucketEnd + 1].date;
      if (nextDate.weekday == DateTime.monday && bucketEnd > bucketStart) break;
      if (bucketEnd - bucketStart >= 6) break;
      bucketEnd++;
    }

    final slice = activities.sublist(bucketStart, bucketEnd + 1);
    buckets.add(
      _AggregatedBucket(
        startDate: slice.first.date,
        endDate: slice.last.date,
        totalMinutes: slice.fold(0, (s, a) => s + a.readingMinutes),
        totalPages: slice.fold(0, (s, a) => s + a.pagesRead),
        dayCount: slice.length,
      ),
    );

    bucketStart = bucketEnd + 1;
  }

  return buckets;
}

// =============================================================================
// AXIS HELPERS
// =============================================================================

const _months = [
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

/// Formats a minutes value for the Y-axis (e.g., "0", "30m", "1h", "1.5h").
String _formatMinutesLabel(double value) {
  if (value <= 0) return '0';
  if (value < 60) return '${value.round()}m';
  final hours = value / 60;
  if (hours == hours.truncateToDouble()) return '${hours.toInt()}h';
  return '${hours.toStringAsFixed(1)}h';
}

/// Formats a pages value for the Y-axis.
String _formatPagesLabel(double value) {
  if (value <= 0) return '0';
  return '${value.round()}';
}

/// Computes a nice Y-axis interval and maxY that align cleanly.
({double interval, double maxY}) _niceYAxis(double maxValue) {
  if (maxValue <= 0) return (interval: 15.0, maxY: 60.0);
  final rawInterval = maxValue / 3;
  const niceSteps = [
    5,
    10,
    15,
    20,
    25,
    30,
    50,
    60,
    100,
    120,
    150,
    200,
    250,
    300,
    500,
    1000,
  ];
  var interval = (rawInterval / 100).ceil() * 100.0;
  for (final step in niceSteps) {
    if (step >= rawInterval) {
      interval = step.toDouble();
      break;
    }
  }
  final maxY = (maxValue / interval).ceil() * interval;
  return (interval: interval, maxY: maxY);
}

/// Builds a Y-axis title widget.
Widget _buildYAxisLabel(
  double value,
  TextTheme textTheme,
  ColorScheme colorScheme,
  String Function(double) formatter,
) {
  return Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Text(
      formatter(value),
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 10,
      ),
    ),
  );
}

/// Builds a bottom axis label for chart data points.
Widget _buildBottomLabel(
  double value,
  List<DailyActivity> activities,
  TextTheme textTheme,
  ColorScheme colorScheme,
) {
  final idx = value.toInt();
  if (idx < 0 || idx >= activities.length) return const SizedBox.shrink();

  final activity = activities[idx];
  final count = activities.length;

  String? label;

  if (count <= 7) {
    label = activity.dayInitial;
  } else if (count <= 31) {
    final day = activity.date.day;
    final interval = count > 14 ? 5 : 3;
    if (day == 1 || day % interval == 0 || idx == count - 1) {
      label = '${activity.date.day}';
    }
  } else {
    if (idx == 0 ||
        activities[idx].date.month != activities[idx - 1].date.month) {
      label = _months[activity.date.month - 1];
    }
  }

  if (label == null) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      label,
      style: textTheme.labelSmall?.copyWith(
        color: activity.isToday
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        fontWeight: activity.isToday ? FontWeight.bold : FontWeight.normal,
        fontSize: 10,
      ),
    ),
  );
}

/// Builds a bottom axis label for aggregated weekly buckets.
Widget _buildBucketBottomLabel(
  double value,
  List<_AggregatedBucket> buckets,
  TextTheme textTheme,
  ColorScheme colorScheme,
) {
  final idx = value.toInt();
  if (idx < 0 || idx >= buckets.length) return const SizedBox.shrink();

  final bucket = buckets[idx];
  if (idx > 0 &&
      buckets[idx].startDate.month == buckets[idx - 1].startDate.month) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      _months[bucket.startDate.month - 1],
      style: textTheme.labelSmall?.copyWith(
        color: bucket.containsToday
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        fontWeight: bucket.containsToday ? FontWeight.bold : FontWeight.normal,
        fontSize: 10,
      ),
    ),
  );
}

// =============================================================================
// READING TIME BAR CHART
// =============================================================================

/// A bar chart displaying reading time data using fl_chart.
class ReadingTimeBarChart extends StatelessWidget {
  final List<DailyActivity> activities;
  final bool isWeekly;
  final bool isDesktop;

  const ReadingTimeBarChart({
    super.key,
    required this.activities,
    this.isWeekly = true,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return _buildEmptyState(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartHeight = isDesktop ? 200.0 : 160.0;

    if (activities.length > 21) {
      return _buildAggregatedChart(
        context,
        colorScheme,
        textTheme,
        chartHeight,
      );
    }
    return _buildDailyChart(context, colorScheme, textTheme, chartHeight);
  }

  Widget _buildDailyChart(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double chartHeight,
  ) {
    final maxMinutes = activities.maxMinutes.toDouble();
    final yAxis = _niceYAxis(maxMinutes);

    return SizedBox(
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 60;
          final barWidth = (availableWidth / activities.length * 0.6).clamp(
            4.0,
            isDesktop ? 20.0 : 16.0,
          );

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: yAxis.maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => colorScheme.inverseSurface,
                  tooltipRoundedRadius: AppRadius.md,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final activity = activities[groupIndex];
                    return BarTooltipItem(
                      '${activity.dayName}\n${activity.readingTimeLabel}',
                      textTheme.bodySmall!.copyWith(
                        color: colorScheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => _buildBottomLabel(
                      value,
                      activities,
                      textTheme,
                      colorScheme,
                    ),
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: yAxis.interval,
                    getTitlesWidget: (value, meta) => _buildYAxisLabel(
                      value,
                      textTheme,
                      colorScheme,
                      _formatMinutesLabel,
                    ),
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yAxis.interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: activity.readingMinutes.toDouble(),
                      color: activity.isToday
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.6),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: AnimationDurations.standard,
          );
        },
      ),
    );
  }

  Widget _buildAggregatedChart(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double chartHeight,
  ) {
    final buckets = _aggregateWeekly(activities);
    if (buckets.isEmpty) return _buildEmptyState(context);

    final maxMinutes = buckets
        .map((b) => b.totalMinutes)
        .reduce((a, b) => math.max(a, b))
        .toDouble();
    final yAxis = _niceYAxis(maxMinutes);

    return SizedBox(
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 60;
          final barWidth = (availableWidth / buckets.length * 0.6).clamp(
            6.0,
            isDesktop ? 24.0 : 18.0,
          );

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: yAxis.maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => colorScheme.inverseSurface,
                  tooltipRoundedRadius: AppRadius.md,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final bucket = buckets[groupIndex];
                    final hours = bucket.totalMinutes / 60;
                    final timeLabel = hours >= 1
                        ? '${hours.toStringAsFixed(1)}h'
                        : '${bucket.totalMinutes}m';
                    return BarTooltipItem(
                      '${bucket.label}\n$timeLabel total',
                      textTheme.bodySmall!.copyWith(
                        color: colorScheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => _buildBucketBottomLabel(
                      value,
                      buckets,
                      textTheme,
                      colorScheme,
                    ),
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: yAxis.interval,
                    getTitlesWidget: (value, meta) => _buildYAxisLabel(
                      value,
                      textTheme,
                      colorScheme,
                      _formatMinutesLabel,
                    ),
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yAxis.interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: buckets.asMap().entries.map((entry) {
                final index = entry.key;
                final bucket = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: bucket.totalMinutes.toDouble(),
                      color: bucket.containsToday
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.6),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: AnimationDurations.standard,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: isDesktop ? 200 : 160,
      alignment: Alignment.center,
      child: Text(
        'No reading data for this period',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// =============================================================================
// PAGES READ LINE CHART
// =============================================================================

/// A line chart displaying pages read trends using fl_chart.
class PagesReadLineChart extends StatelessWidget {
  final List<DailyActivity> activities;
  final bool isWeekly;
  final bool isDesktop;

  const PagesReadLineChart({
    super.key,
    required this.activities,
    this.isWeekly = true,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return _buildEmptyState(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartHeight = isDesktop ? 200.0 : 160.0;

    if (activities.length > 21) {
      return _buildAggregatedChart(
        context,
        colorScheme,
        textTheme,
        chartHeight,
      );
    }
    return _buildDailyChart(context, colorScheme, textTheme, chartHeight);
  }

  Widget _buildDailyChart(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double chartHeight,
  ) {
    final maxPages = activities
        .map((a) => a.pagesRead)
        .reduce((a, b) => math.max(a, b))
        .toDouble();
    final yAxis = _niceYAxis(maxPages);

    final spots = activities.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.pagesRead.toDouble());
    }).toList();

    final showDots = activities.length <= 14;

    return SizedBox(
      height: chartHeight,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: yAxis.maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colorScheme.inverseSurface,
              tooltipRoundedRadius: AppRadius.md,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final activity = activities[spot.x.toInt()];
                  return LineTooltipItem(
                    '${activity.dayName}\n${activity.pagesRead} pages',
                    textTheme.bodySmall!.copyWith(
                      color: colorScheme.onInverseSurface,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) => _buildBottomLabel(
                  value,
                  activities,
                  textTheme,
                  colorScheme,
                ),
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yAxis.interval,
                getTitlesWidget: (value, meta) => _buildYAxisLabel(
                  value,
                  textTheme,
                  colorScheme,
                  _formatPagesLabel,
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yAxis.interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: colorScheme.tertiary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: colorScheme.tertiary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.tertiary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        duration: AnimationDurations.standard,
      ),
    );
  }

  Widget _buildAggregatedChart(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double chartHeight,
  ) {
    final buckets = _aggregateWeekly(activities);
    if (buckets.isEmpty) return _buildEmptyState(context);

    final maxPages = buckets
        .map((b) => b.totalPages)
        .reduce((a, b) => math.max(a, b))
        .toDouble();
    final yAxis = _niceYAxis(maxPages);

    final spots = buckets.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalPages.toDouble());
    }).toList();

    final showDots = buckets.length <= 14;

    return SizedBox(
      height: chartHeight,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: yAxis.maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colorScheme.inverseSurface,
              tooltipRoundedRadius: AppRadius.md,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final bucket = buckets[spot.x.toInt()];
                  return LineTooltipItem(
                    '${bucket.label}\n${bucket.totalPages} pages',
                    textTheme.bodySmall!.copyWith(
                      color: colorScheme.onInverseSurface,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) => _buildBucketBottomLabel(
                  value,
                  buckets,
                  textTheme,
                  colorScheme,
                ),
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yAxis.interval,
                getTitlesWidget: (value, meta) => _buildYAxisLabel(
                  value,
                  textTheme,
                  colorScheme,
                  _formatPagesLabel,
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yAxis.interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: colorScheme.tertiary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: colorScheme.tertiary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.tertiary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        duration: AnimationDurations.standard,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: isDesktop ? 200 : 160,
      alignment: Alignment.center,
      child: Text(
        'No reading data for this period',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// =============================================================================
// BOOKS PER MONTH CHART
// =============================================================================

/// A bar chart displaying books read per month using fl_chart.
class BooksPerMonthChart extends StatelessWidget {
  final List<MonthlyStats> monthlyStats;
  final bool isDesktop;

  const BooksPerMonthChart({
    super.key,
    required this.monthlyStats,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) return _buildEmptyState(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxBooks = monthlyStats
        .map((m) => m.booksRead)
        .reduce((a, b) => math.max(a, b))
        .toDouble();
    final chartHeight = isDesktop ? 200.0 : 160.0;

    // Take last 6 months for display
    final displayStats = monthlyStats.length > 6
        ? monthlyStats.sublist(monthlyStats.length - 6)
        : monthlyStats;

    return SizedBox(
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 50;
          final barWidth = (availableWidth / displayStats.length * 0.5).clamp(
            8.0,
            isDesktop ? 28.0 : 22.0,
          );

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxBooks > 0 ? maxBooks * 1.2 : 5,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => colorScheme.inverseSurface,
                  tooltipRoundedRadius: AppRadius.md,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stats = displayStats[groupIndex];
                    return BarTooltipItem(
                      '${stats.fullMonthLabel}\n${stats.booksRead} books',
                      textTheme.bodySmall!.copyWith(
                        color: colorScheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= displayStats.length) {
                        return const SizedBox.shrink();
                      }
                      final stats = displayStats[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          stats.monthLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value == value.truncateToDouble() &&
                          value >= 0 &&
                          value <= meta.max * 0.95) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.toInt()}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: displayStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stats = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: stats.booksRead.toDouble(),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colorScheme.secondary,
                          colorScheme.secondary.withValues(alpha: 0.7),
                        ],
                      ),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: AnimationDurations.standard,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: isDesktop ? 200 : 160,
      alignment: Alignment.center,
      child: Text(
        'No books read data available',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
