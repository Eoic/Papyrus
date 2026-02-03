import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/statistics_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/statistics/reading_charts.dart';
import 'package:papyrus/widgets/statistics/stat_card.dart';
import 'package:provider/provider.dart';

/// Statistics page displaying reading analytics and charts.
///
/// Provides three responsive layouts:
/// - **Mobile**: Vertical scrolling with stacked charts
/// - **Desktop**: Full-width charts with period segmented control
/// - **E-ink**: Text-based horizontal bar charts
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
          final displayMode = context.watch<DisplayModeProvider>();
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (displayMode.isEinkMode) {
            return _buildEinkLayout(context, provider);
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
      appBar: AppBar(title: const Text('Statistics')),
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
              // Session stats
              _buildSessionStatsCard(context, provider),
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
              // Streak section
              _buildStreakCard(context, provider),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: provider.totalBooks.toString(),
                label: 'Books read',
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: StatCard(
                value: provider.pagesRead.toString(),
                label: 'Pages read',
                icon: Icons.article_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: provider.totalReadingLabel,
                label: 'Total reading time',
                icon: Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: StatCard(
                value: provider.goalsCompleted.toString(),
                label: 'Goals completed',
                icon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionStatsCard(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final sessionStats = provider.sessionStats;

    return StatSectionCard(
      title: 'Session statistics',
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: Icons.timer_outlined,
            label: 'Average session',
            value: sessionStats.averageSessionLabel,
          ),
          const SizedBox(height: Spacing.sm),
          _buildStatRow(
            context,
            icon: Icons.speed_outlined,
            label: 'Reading velocity',
            value: sessionStats.velocityLabel,
          ),
          const SizedBox(height: Spacing.sm),
          _buildStatRow(
            context,
            icon: Icons.repeat_outlined,
            label: 'Total sessions',
            value: '${sessionStats.totalSessions}',
          ),
          const SizedBox(height: Spacing.sm),
          _buildStatRow(
            context,
            icon: Icons.show_chart_outlined,
            label: 'Avg. daily reading',
            value: provider.averageReadingLabel,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final genres = provider.genreDistribution;

    if (genres.isEmpty) {
      return StatSectionCard(
        title: 'Books by genre',
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

    // Harmonious color palette based on primary
    final chartColors = [
      colorScheme.primary,
      colorScheme.primary.withValues(alpha: 0.7),
      colorScheme.tertiary,
      colorScheme.tertiary.withValues(alpha: 0.7),
      colorScheme.secondary,
      colorScheme.secondary.withValues(alpha: 0.7),
    ];

    final genreData = genres.asMap().entries.map((entry) {
      return (
        genre: entry.value.genre,
        percentage: entry.value.percentage,
        color: chartColors[entry.key % chartColors.length],
      );
    }).toList();

    return StatSectionCard(
      title: 'Books by genre',
      child: SizedBox(
        height: 140,
        child: Row(
          children: [
            GenrePieChart(genres: genreData),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: genreData.map((genre) {
                  return _buildLegendItem(
                    context,
                    color: genre.color,
                    label: genre.genre,
                    percentage: (genre.percentage * 100).round(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int percentage,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$percentage%',
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, StatisticsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final streak = provider.streak;

    return StatSectionCard(
      title: 'Reading streaks',
      child: Column(
        children: [
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
          const SizedBox(height: Spacing.sm),
          _buildStreakRow(
            context,
            icon: Icons.emoji_events_outlined,
            iconColor: colorScheme.primary,
            label: 'Best streak',
            value: '${streak.bestStreak} days',
          ),
          const SizedBox(height: Spacing.sm),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with period toggle
              // TODO: Fix unconstrained width issue with Row in SingleChildScrollView
              // The OutlinedButton gets infinite width constraints from the scroll view
              Text('Statistics', style: textTheme.displaySmall),
              const SizedBox(height: Spacing.md),
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
              // Second row: Session stats + Books per month (if applicable)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildDesktopSessionStatsCard(context, provider),
                    ),
                    const SizedBox(width: Spacing.lg),
                    if (provider.selectedPeriod == StatsPeriod.year ||
                        provider.selectedPeriod == StatsPeriod.allTime)
                      Expanded(
                        child: StatSectionCard(
                          title: 'Books per month',
                          isDesktop: true,
                          child: BooksPerMonthChart(
                            monthlyStats: provider.monthlyStats,
                            isDesktop: true,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: _buildDesktopGenreDistributionCard(
                          context,
                          provider,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              // Third row: Genre distribution (if year view) + Streaks
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
                        child: _buildDesktopStreakCard(context, provider),
                      ),
                    ],
                  ),
                )
              else
                _buildDesktopStreakCard(context, provider),
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
          child: StatCard(
            value: provider.totalBooks.toString(),
            label: 'Books read',
            icon: Icons.menu_book_outlined,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: StatCard(
            value: provider.pagesRead.toString(),
            label: 'Pages read',
            icon: Icons.article_outlined,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: StatCard(
            value: provider.totalReadingLabel,
            label: 'Total reading time',
            icon: Icons.schedule_outlined,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: StatCard(
            value: provider.goalsCompleted.toString(),
            label: 'Goals completed',
            icon: Icons.flag_outlined,
            isDesktop: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSessionStatsCard(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final sessionStats = provider.sessionStats;

    return StatSectionCard(
      title: 'Session statistics',
      isDesktop: true,
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: Icons.timer_outlined,
            label: 'Average session',
            value: sessionStats.averageSessionLabel,
          ),
          const SizedBox(height: Spacing.md),
          _buildStatRow(
            context,
            icon: Icons.speed_outlined,
            label: 'Reading velocity',
            value: sessionStats.velocityLabel,
          ),
          const SizedBox(height: Spacing.md),
          _buildStatRow(
            context,
            icon: Icons.repeat_outlined,
            label: 'Total sessions',
            value: '${sessionStats.totalSessions}',
          ),
          const SizedBox(height: Spacing.md),
          _buildStatRow(
            context,
            icon: Icons.show_chart_outlined,
            label: 'Avg. daily reading',
            value: provider.averageReadingLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGenreDistributionCard(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final genres = provider.genreDistribution;

    if (genres.isEmpty) {
      return StatSectionCard(
        title: 'Books by genre',
        isDesktop: true,
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

    // Harmonious color palette based on primary
    final chartColors = [
      colorScheme.primary,
      colorScheme.primary.withValues(alpha: 0.7),
      colorScheme.tertiary,
      colorScheme.tertiary.withValues(alpha: 0.7),
      colorScheme.secondary,
      colorScheme.secondary.withValues(alpha: 0.7),
    ];

    final genreData = genres.asMap().entries.map((entry) {
      return (
        genre: entry.value.genre,
        percentage: entry.value.percentage,
        color: chartColors[entry.key % chartColors.length],
      );
    }).toList();

    return StatSectionCard(
      title: 'Books by genre',
      isDesktop: true,
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            GenrePieChart(genres: genreData, isDesktop: true),
            const SizedBox(width: Spacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: genreData.map((genre) {
                  return _buildLegendItem(
                    context,
                    color: genre.color,
                    label: genre.genre,
                    percentage: (genre.percentage * 100).round(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStreakCard(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final streak = provider.streak;

    return StatSectionCard(
      title: 'Reading streaks',
      isDesktop: true,
      child: Column(
        children: [
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
          const SizedBox(height: Spacing.md),
          _buildStreakRow(
            context,
            icon: Icons.emoji_events_outlined,
            iconColor: colorScheme.primary,
            label: 'Best streak',
            value: '${streak.bestStreak} days',
          ),
          const SizedBox(height: Spacing.md),
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

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkLayout(BuildContext context, StatisticsProvider provider) {
    return Scaffold(
      body: Column(
        children: [
          _buildEinkHeader(context, provider),
          const Divider(color: Colors.black, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageMarginsEink),
              children: [
                // Summary section
                _buildEinkSummary(context, provider),
                const SizedBox(height: Spacing.lg),
                // Reading time chart (text-based)
                _buildEinkReadingTime(context, provider),
                const SizedBox(height: Spacing.lg),
                // Session stats
                _buildEinkSessionStats(context, provider),
                const SizedBox(height: Spacing.lg),
                // Genre distribution
                _buildEinkGenreDistribution(context, provider),
                const SizedBox(height: Spacing.lg),
                // Streak widget
                _buildEinkStreak(context, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkHeader(BuildContext context, StatisticsProvider provider) {
    // Filter out custom from e-ink periods
    final periods = StatsPeriod.values
        .where((p) => p != StatsPeriod.custom)
        .toList();

    return Container(
      height: ComponentSizes.einkHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageMarginsEink),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'STATISTICS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Row(
            children: periods.map((period) {
              final isSelected = provider.selectedPeriod == period;
              return GestureDetector(
                onTap: () => provider.setPeriod(period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  margin: const EdgeInsets.only(left: Spacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
                  child: Text(
                    _getPeriodShortLabel(period),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkSummary(BuildContext context, StatisticsProvider provider) {
    return StatSectionCard(
      title: 'Summary',
      isEinkMode: true,
      child: Column(
        children: [
          _buildEinkStatRow(
            context,
            'Books read',
            provider.totalBooks.toString(),
          ),
          _buildEinkStatRow(
            context,
            'Pages read',
            provider.pagesRead.toString(),
          ),
          _buildEinkStatRow(
            context,
            'Total reading time',
            provider.totalReadingLabel,
          ),
          _buildEinkStatRow(
            context,
            'Goals completed',
            provider.goalsCompleted.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkReadingTime(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final activities = provider.readingTimeData;
    final maxMinutes = activities.maxMinutes;
    final isWeekly = provider.selectedPeriod == StatsPeriod.week;

    return StatSectionCard(
      title: 'Reading time ${isWeekly ? "this week" : ""}',
      isEinkMode: true,
      child: Column(
        children: [
          ...activities.map((activity) {
            const maxChars = 30;
            final barChars = maxMinutes > 0
                ? (activity.readingMinutes / maxMinutes * maxChars)
                      .round()
                      .clamp(0, maxChars)
                : 0;
            final filledBar = String.fromCharCodes(
              List.filled(barChars, 0x2588),
            );
            final emptyBar = String.fromCharCodes(
              List.filled(maxChars - barChars, 0x2591),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      isWeekly
                          ? activity.dayLabel
                          : _getMonthLabel(activity.date),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: activity.isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
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
          }),
          const Divider(color: Colors.black26),
          _buildEinkStatRow(context, 'Total', activities.totalTimeLabel),
          _buildEinkStatRow(
            context,
            'Average',
            '${activities.averageTimeLabel}/day',
          ),
        ],
      ),
    );
  }

  Widget _buildEinkSessionStats(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final sessionStats = provider.sessionStats;

    return StatSectionCard(
      title: 'Session statistics',
      isEinkMode: true,
      child: Column(
        children: [
          _buildEinkStatRow(
            context,
            'Average session',
            sessionStats.averageSessionLabel,
          ),
          _buildEinkStatRow(
            context,
            'Reading velocity',
            sessionStats.velocityLabel,
          ),
          _buildEinkStatRow(
            context,
            'Total sessions',
            '${sessionStats.totalSessions}',
          ),
          _buildEinkStatRow(
            context,
            'Avg. daily reading',
            provider.averageReadingLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildEinkGenreDistribution(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final genres = provider.genreDistribution;

    return StatSectionCard(
      title: 'Books by genre',
      isEinkMode: true,
      child: Column(
        children: genres.map((genre) {
          const maxChars = 30;
          final barChars = (genre.percentage * maxChars).round().clamp(
            0,
            maxChars,
          );
          final filledBar = String.fromCharCodes(List.filled(barChars, 0x2588));
          final emptyBar = String.fromCharCodes(
            List.filled(maxChars - barChars, 0x2591),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    genre.genre,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 14),
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
                  width: 40,
                  child: Text(
                    '${genre.percentageInt}%',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEinkStreak(BuildContext context, StatisticsProvider provider) {
    final streak = provider.streak;

    return StatSectionCard(
      title: 'Reading streaks',
      isEinkMode: true,
      child: Column(
        children: [
          _buildEinkStatRow(
            context,
            'Current streak',
            '${streak.currentStreak} days',
          ),
          _buildEinkStatRow(
            context,
            'Best streak',
            '${streak.bestStreak} days',
          ),
          _buildEinkStatRow(
            context,
            'Days this month',
            '${streak.daysThisMonth} of ${streak.totalDaysInMonth}',
          ),
        ],
      ),
    );
  }

  Widget _buildEinkStatRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 16)),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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

  String _getPeriodShortLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'W';
      case StatsPeriod.month:
        return 'M';
      case StatsPeriod.year:
        return 'Y';
      case StatsPeriod.allTime:
        return 'All';
      case StatsPeriod.custom:
        return 'C';
    }
  }

  String _getMonthLabel(DateTime date) {
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
    return months[date.month - 1];
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
