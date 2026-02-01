import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/providers/statistics_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A bar chart displaying reading time data using fl_chart.
class ReadingTimeBarChart extends StatelessWidget {
  /// Activity data to display.
  final List<DailyActivity> activities;

  /// Whether this is showing weekly data (affects labels).
  final bool isWeekly;

  /// Whether to use desktop styling.
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
    final maxMinutes = activities.maxMinutes.toDouble();
    final chartHeight = isDesktop ? 200.0 : 160.0;

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxMinutes > 0 ? maxMinutes * 1.1 : 60,
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
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= activities.length) {
                    return const SizedBox.shrink();
                  }
                  // Show every nth label to avoid crowding
                  final interval = activities.length > 14 ? 7 : 1;
                  final idx = value.toInt();
                  if (idx % interval != 0 && idx != activities.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final activity = activities[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      activity.dayInitial,
                      style: textTheme.labelSmall?.copyWith(
                        color: activity.isToday
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: activity.isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text(
                      '0',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  final hours = value / 60;
                  if (hours >= 1 && value == meta.max) {
                    return Text(
                      '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)}h',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
            horizontalInterval: maxMinutes > 0 ? maxMinutes / 4 : 15,
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
                  width: isDesktop ? 16 : 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
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

/// A line chart displaying pages read trends using fl_chart.
class PagesReadLineChart extends StatelessWidget {
  /// Activity data to display.
  final List<DailyActivity> activities;

  /// Whether this is showing weekly data (affects labels).
  final bool isWeekly;

  /// Whether to use desktop styling.
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
    final maxPages = activities
        .map((a) => a.pagesRead)
        .reduce((a, b) => math.max(a, b))
        .toDouble();
    final chartHeight = isDesktop ? 200.0 : 160.0;

    final spots = activities.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.pagesRead.toDouble());
    }).toList();

    return SizedBox(
      height: chartHeight,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxPages > 0 ? maxPages * 1.1 : 50,
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
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= activities.length) {
                    return const SizedBox.shrink();
                  }
                  // Show every nth label to avoid crowding
                  final interval = activities.length > 14 ? 7 : 1;
                  final idx = value.toInt();
                  if (idx % interval != 0 && idx != activities.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final activity = activities[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      activity.dayInitial,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text(
                      '0',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  if (value == meta.max) {
                    return Text(
                      '${value.toInt()}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
            horizontalInterval: maxPages > 0 ? maxPages / 4 : 12.5,
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
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
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

/// A bar chart displaying books read per month using fl_chart.
class BooksPerMonthChart extends StatelessWidget {
  /// Monthly statistics data.
  final List<MonthlyStats> monthlyStats;

  /// Whether to use desktop styling.
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
      child: BarChart(
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
                  if (value == value.truncateToDouble() && value >= 0) {
                    return Text(
                      '${value.toInt()}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                  width: isDesktop ? 24 : 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
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
        'No books read data available',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A pie chart displaying genre distribution using fl_chart.
class GenrePieChart extends StatefulWidget {
  /// Genre statistics to display.
  final List<({String genre, double percentage, Color color})> genres;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const GenrePieChart({
    super.key,
    required this.genres,
    this.isDesktop = false,
  });

  @override
  State<GenrePieChart> createState() => _GenrePieChartState();
}

class _GenrePieChartState extends State<GenrePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.genres.isEmpty) return _buildEmptyState(context);

    final chartSize = widget.isDesktop ? 160.0 : 120.0;
    final centerRadius = chartSize * 0.28;
    final sectionRadius = chartSize * 0.18;
    final touchedRadius = chartSize * 0.22;

    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = response.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: centerRadius,
          sections: widget.genres.asMap().entries.map((entry) {
            final index = entry.key;
            final genre = entry.value;
            final isTouched = index == _touchedIndex;

            return PieChartSectionData(
              color: genre.color,
              value: genre.percentage * 100,
              title: isTouched ? '${(genre.percentage * 100).round()}%' : '',
              radius: isTouched ? touchedRadius : sectionRadius,
              titleStyle: TextStyle(
                fontSize: widget.isDesktop ? 12 : 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
        duration: AnimationDurations.standard,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final size = widget.isDesktop ? 160.0 : 120.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Text(
        'No genre data',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
