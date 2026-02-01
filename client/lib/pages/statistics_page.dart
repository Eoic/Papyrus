import 'package:flutter/material.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/statistics_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/statistics/genre_distribution.dart';
import 'package:papyrus/widgets/statistics/reading_time_chart.dart';
import 'package:papyrus/widgets/statistics/streak_widget.dart';
import 'package:papyrus/widgets/statistics/summary_stat_card.dart';
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
    _provider.loadStatistics();
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

          if (displayMode.isEinkMode) return _buildEinkLayout(context, provider);
          if (isDesktop) return _buildDesktopLayout(context, provider);
          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  // ============================================================================
  // LOADING STATE
  // ============================================================================

  Widget _buildLoadingState(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, StatisticsProvider provider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          _buildPeriodDropdown(context, provider),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              // Summary cards
              _buildSummaryRow(context, provider),
              const SizedBox(height: Spacing.lg),
              // Reading time chart
              ReadingTimeChart(
                activities: provider.readingTimeData,
                isWeekly: provider.selectedPeriod == StatsPeriod.week,
              ),
              const SizedBox(height: Spacing.lg),
              // Genre distribution
              GenreDistribution(
                genres: provider.genreDistribution,
              ),
              const SizedBox(height: Spacing.lg),
              // Streak widget
              StreakWidget(
                streak: provider.streak,
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown(BuildContext context, StatisticsProvider provider) {
    return PopupMenuButton<StatsPeriod>(
      initialValue: provider.selectedPeriod,
      onSelected: provider.setPeriod,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.periodShortLabel),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => StatsPeriod.values.map((period) {
        return PopupMenuItem(
          value: period,
          child: Text(_getPeriodLabel(period)),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(BuildContext context, StatisticsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: SummaryStatCard(
            value: provider.totalBooks.toString(),
            label: 'books',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: SummaryStatCard(
            value: provider.goalsCompleted.toString(),
            label: 'goals',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: SummaryStatCard(
            value: provider.totalReadingLabel,
            label: '/week',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: SummaryStatCard(
            value: provider.pagesRead.toString(),
            label: 'pages',
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context, StatisticsProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with period toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Statistics', style: textTheme.displaySmall),
                  _buildPeriodSegmentedButton(context, provider),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              // Summary cards
              _buildDesktopSummaryRow(context, provider),
              const SizedBox(height: Spacing.lg),
              // Reading time chart (full width)
              ReadingTimeChart(
                activities: provider.readingTimeData,
                isWeekly: provider.selectedPeriod == StatsPeriod.week,
                isDesktop: true,
              ),
              const SizedBox(height: Spacing.lg),
              // Bottom row: Genre + Streak
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GenreDistribution(
                        genres: provider.genreDistribution,
                        isDesktop: true,
                      ),
                    ),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      child: StreakWidget(
                        streak: provider.streak,
                        isDesktop: true,
                      ),
                    ),
                  ],
                ),
              ),
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
    return SegmentedButton<StatsPeriod>(
      segments: StatsPeriod.values.map((period) {
        return ButtonSegment(
          value: period,
          label: Text(_getPeriodLabel(period)),
        );
      }).toList(),
      selected: {provider.selectedPeriod},
      onSelectionChanged: (selected) {
        provider.setPeriod(selected.first);
      },
    );
  }

  Widget _buildDesktopSummaryRow(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: SummaryStatCard(
            value: provider.totalBooks.toString(),
            label: 'Total books',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: SummaryStatCard(
            value: provider.goalsCompleted.toString(),
            label: 'Goals completed',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: SummaryStatCard(
            value: provider.totalReadingLabel,
            label: 'Total reading',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: SummaryStatCard(
            value: provider.pagesRead.toString(),
            label: 'Pages read',
            isDesktop: true,
          ),
        ),
      ],
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
                // Reading time chart
                ReadingTimeChart(
                  activities: provider.readingTimeData,
                  isWeekly: provider.selectedPeriod == StatsPeriod.week,
                  isEinkMode: true,
                ),
                const SizedBox(height: Spacing.lg),
                // Genre distribution
                GenreDistribution(
                  genres: provider.genreDistribution,
                  isEinkMode: true,
                ),
                const SizedBox(height: Spacing.lg),
                // Streak widget
                StreakWidget(
                  streak: provider.streak,
                  isEinkMode: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkHeader(BuildContext context, StatisticsProvider provider) {
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
            children: StatsPeriod.values.map((period) {
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkDefault,
                ),
              ),
            ),
            child: Text(
              'SUMMARY',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              children: [
                SummaryStatCard(
                  value: provider.totalBooks.toString(),
                  label: 'Total books',
                  isEinkMode: true,
                ),
                SummaryStatCard(
                  value: provider.goalsCompleted.toString(),
                  label: 'Goals completed',
                  isEinkMode: true,
                ),
                SummaryStatCard(
                  value: provider.totalReadingLabel,
                  label: 'Total reading time',
                  isEinkMode: true,
                ),
                SummaryStatCard(
                  value: provider.pagesRead.toString(),
                  label: 'Pages read',
                  isEinkMode: true,
                ),
              ],
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
    }
  }
}
