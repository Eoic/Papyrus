import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/statistics_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/statistics/reading_charts.dart';
import 'package:papyrus/widgets/statistics/stat_card.dart';
import 'package:provider/provider.dart';

/// Statistics page displaying reading analytics and charts.
///
/// Provides two responsive layouts:
/// - **Mobile**: Vertical scrolling with stacked charts
/// - **Desktop**: Full-width charts with period segmented control
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late StatisticsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = StatisticsProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Connect to DataStore for persistent storage
    final dataStore = context.read<DataStore>();
    _provider.attach(dataStore);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<StatisticsProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (isDesktop) {
            return _buildDesktopLayout(context, provider);
          }

          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  // ============================================================================
  // LOADING STATE
  // ============================================================================

  Widget _buildLoadingState(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, StatisticsProvider provider) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              // Period filter
              _buildPeriodSegmentedButton(context, provider),
              const SizedBox(height: Spacing.md),
              // Custom range indicator
              if (provider.hasCustomRange) ...[
                _buildCustomRangeChip(context, provider),
                const SizedBox(height: Spacing.md),
              ],
              // Summary cards
              _buildMobileSummaryCards(context, provider),
              const SizedBox(height: Spacing.lg),
              // Reading time chart
              StatSectionCard(
                title: 'Reading time',
                child: ReadingTimeBarChart(
                  activities: provider.readingTimeData,
                  isWeekly: provider.selectedPeriod == StatsPeriod.week,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              // Pages read trend
              StatSectionCard(
                title: 'Pages read',
                child: PagesReadLineChart(
                  activities: provider.pagesReadData,
                  isWeekly: provider.selectedPeriod == StatsPeriod.week,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              // Books per month (for year/all time views)
              if (provider.selectedPeriod == StatsPeriod.year ||
                  provider.selectedPeriod == StatsPeriod.allTime) ...[
                StatSectionCard(
                  title: 'Books per month',
                  child: BooksPerMonthChart(
                    monthlyStats: provider.monthlyStats,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              // Genre distribution
              _buildGenreDistributionCard(context, provider),
              const SizedBox(height: Spacing.lg),
              // Reading insights (session stats + streaks)
              _buildInsightsCard(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSegmentedButton(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final periods = StatsPeriod.values
        .where((p) => p != StatsPeriod.custom)
        .toList();
    final selectedPeriod = provider.selectedPeriod == StatsPeriod.custom
        ? StatsPeriod.week
        : provider.selectedPeriod;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: BorderWidths.thin,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    for (int i = 0; i < periods.length; i++) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => provider.setPeriod(periods[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.sm,
                            ),
                            color: selectedPeriod == periods[i]
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerLow,
                            child: Center(
                              child: Text(
                                _getPeriodLabel(periods[i]),
                                style: textTheme.labelLarge?.copyWith(
                                  color: selectedPeriod == periods[i]
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (i < periods.length - 1)
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        IconButton.outlined(
          onPressed: () => _showDateRangePicker(context, provider),
          icon: const Icon(Icons.date_range_outlined, size: 20),
          tooltip: 'Custom date range',
          style: IconButton.styleFrom(
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomRangeChip(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.date_range,
            size: 16,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            provider.periodLabel,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          GestureDetector(
            onTap: () => provider.setPeriod(StatsPeriod.week),
            child: Icon(
              Icons.close,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryCards(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: CompactStatCard(
            value: provider.totalBooks.toString(),
            label: 'Books',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: CompactStatCard(
            value: provider.pagesRead.toString(),
            label: 'Pages',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: CompactStatCard(
            value: provider.totalReadingLabel,
            label: 'Reading time',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: CompactStatCard(
            value: provider.goalsCompleted.toString(),
            label: 'Goals',
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    StatisticsProvider provider, {
    bool isDesktop = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessionStats = provider.sessionStats;
    final streak = provider.streak;
    final rowGap = SizedBox(height: isDesktop ? Spacing.md : Spacing.sm);

    return StatSectionCard(
      title: 'Reading insights',
      isDesktop: isDesktop,
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: Icons.timer_outlined,
            label: 'Average session',
            value: sessionStats.averageSessionLabel,
          ),
          rowGap,
          _buildStatRow(
            context,
            icon: Icons.speed_outlined,
            label: 'Reading velocity',
            value: sessionStats.velocityLabel,
          ),
          rowGap,
          _buildStatRow(
            context,
            icon: Icons.repeat_outlined,
            label: 'Total sessions',
            value: '${sessionStats.totalSessions}',
          ),
          rowGap,
          _buildStatRow(
            context,
            icon: Icons.show_chart_outlined,
            label: 'Avg. daily reading',
            value: provider.averageReadingLabel,
          ),
          Divider(
            height: isDesktop ? Spacing.xl : Spacing.lg,
            color: colorScheme.outlineVariant,
          ),
          _buildStreakRow(
            context,
            icon: Icons.local_fire_department,
            iconColor: streak.hasActiveStreak
                ? colorScheme.tertiary
                : colorScheme.onSurfaceVariant,
            label: 'Current streak',
            value: '${streak.currentStreak} days',
            isHighlighted: streak.isCurrentBest,
          ),
          rowGap,
          _buildStreakRow(
            context,
            icon: Icons.emoji_events_outlined,
            iconColor: colorScheme.primary,
            label: 'Best streak',
            value: '${streak.bestStreak} days',
          ),
          rowGap,
          _buildStreakRow(
            context,
            icon: Icons.calendar_month_outlined,
            iconColor: colorScheme.onSurfaceVariant,
            label: 'Days this month',
            value: '${streak.daysThisMonth} of ${streak.totalDaysInMonth}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
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
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGenreDistributionCard(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    return _buildGenreBarsCard(context, provider);
  }

  Widget _buildGenreBarsCard(
    BuildContext context,
    StatisticsProvider provider, {
    bool isDesktop = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final genres = provider.genreDistribution;

    if (genres.isEmpty) {
      return StatSectionCard(
        title: 'Books by genre',
        isDesktop: isDesktop,
        child: Center(
          child: Text(
            'No genre data available',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final chartColors = [
      colorScheme.primary,
      colorScheme.primary.withValues(alpha: 0.7),
      colorScheme.tertiary,
      colorScheme.tertiary.withValues(alpha: 0.7),
      colorScheme.secondary,
      colorScheme.secondary.withValues(alpha: 0.7),
    ];

    return StatSectionCard(
      title: 'Books by genre',
      isDesktop: isDesktop,
      child: Column(
        children: genres.asMap().entries.map((entry) {
          final genre = entry.value;
          final color = chartColors[entry.key % chartColors.length];
          final pct = (genre.percentage * 100).round();

          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key < genres.length - 1 ? Spacing.md : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      genre.genre,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: genre.percentage.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreakRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
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
            color: isHighlighted ? colorScheme.tertiary : null,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period toggle
              _buildPeriodSegmentedButton(context, provider),
              // Custom range indicator
              if (provider.hasCustomRange) ...[
                const SizedBox(height: Spacing.md),
                _buildCustomRangeChip(context, provider),
              ],
              const SizedBox(height: Spacing.lg),
              // Summary cards row
              _buildDesktopSummaryRow(context, provider),
              const SizedBox(height: Spacing.lg),
              // Charts row: Reading time + Pages read
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatSectionCard(
                        title: 'Reading time',
                        isDesktop: true,
                        child: ReadingTimeBarChart(
                          activities: provider.readingTimeData,
                          isWeekly: provider.selectedPeriod == StatsPeriod.week,
                          isDesktop: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      child: StatSectionCard(
                        title: 'Pages read',
                        isDesktop: true,
                        child: PagesReadLineChart(
                          activities: provider.pagesReadData,
                          isWeekly: provider.selectedPeriod == StatsPeriod.week,
                          isDesktop: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              // Second row: Genre + Books per month (if applicable)
              if (provider.selectedPeriod == StatsPeriod.year ||
                  provider.selectedPeriod == StatsPeriod.allTime)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildDesktopGenreDistributionCard(
                          context,
                          provider,
                        ),
                      ),
                      const SizedBox(width: Spacing.lg),
                      Expanded(
                        child: StatSectionCard(
                          title: 'Books per month',
                          isDesktop: true,
                          child: BooksPerMonthChart(
                            monthlyStats: provider.monthlyStats,
                            isDesktop: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildDesktopGenreDistributionCard(context, provider),
              const SizedBox(height: Spacing.lg),
              // Reading insights (session stats + streaks)
              _buildInsightsCard(context, provider, isDesktop: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSummaryRow(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: CompactStatCard(
            value: provider.totalBooks.toString(),
            label: 'Books',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: CompactStatCard(
            value: provider.pagesRead.toString(),
            label: 'Pages',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: CompactStatCard(
            value: provider.totalReadingLabel,
            label: 'Reading time',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: CompactStatCard(
            value: provider.goalsCompleted.toString(),
            label: 'Goals',
            isDesktop: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGenreDistributionCard(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    return _buildGenreBarsCard(context, provider, isDesktop: true);
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _getPeriodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'Week';
      case StatsPeriod.month:
        return 'Month';
      case StatsPeriod.year:
        return 'Year';
      case StatsPeriod.allTime:
        return 'All time';
      case StatsPeriod.custom:
        return 'Custom';
    }
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    StatisticsProvider provider,
  ) async {
    final now = DateTime.now();
    final initialRange = provider.hasCustomRange
        ? DateTimeRange(
            start: provider.customStartDate!,
            end: provider.customEndDate!,
          )
        : DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );

    final picked = await showDateRangePicker(
      context: context,
      useRootNavigator: false,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select date range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      saveText: 'Apply',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: child,
          ),
        );
      },
    );

    if (picked != null) {
      provider.setCustomDateRange(picked.start, picked.end);
    }
  }
}
