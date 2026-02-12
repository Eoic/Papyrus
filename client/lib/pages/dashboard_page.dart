import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/dashboard_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/dashboard/continue_reading_card.dart';
import 'package:papyrus/widgets/dashboard/dashboard_greeting.dart';
import 'package:papyrus/widgets/dashboard/quick_stats_widget.dart';
import 'package:papyrus/widgets/dashboard/reading_goal_card.dart';
import 'package:papyrus/widgets/dashboard/recently_added_section.dart';
import 'package:papyrus/widgets/dashboard/weekly_activity_chart.dart';
import 'package:provider/provider.dart';

/// Dashboard page displaying reading activity, current books, and quick actions.
///
/// Provides two responsive layouts:
/// - **Mobile**: Vertical scrolling with stacked cards
/// - **Desktop**: Widget grid layout with sidebar
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = DashboardProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
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
  // MOBILE LAYOUT
  // ============================================================================

  /// Builds the mobile layout with vertically stacked cards.
  Widget _buildMobileLayout(BuildContext context, DashboardProvider provider) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            children: [
              DashboardGreeting(greeting: provider.greeting),
              const SizedBox(height: Spacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: ContinueReadingCard(book: provider.currentBook),
              ),
              const SizedBox(height: Spacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: ReadingGoalCard(goals: provider.activeGoals),
              ),
              const SizedBox(height: Spacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: WeeklyActivityChart(
                  activities: provider.weeklyActivity,
                  periodLabel: provider.periodLabel,
                  onPreviousPeriod: provider.goToPreviousPeriod,
                  onNextPeriod: provider.goToNextPeriod,
                  canGoToNextPeriod: provider.canGoToNextPeriod,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: _buildMobileRecentlyAddedCard(context, provider),
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  /// Builds the desktop layout with grid arrangement.
  Widget _buildDesktopLayout(BuildContext context, DashboardProvider provider) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardGreeting(greeting: provider.greeting, isDesktop: true),
              const SizedBox(height: Spacing.lg),
              _buildTopCards(context, provider),
              const SizedBox(height: Spacing.lg),
              WeeklyActivityChart(
                activities: provider.weeklyActivity,
                activityPeriod: provider.activityPeriod,
                onPeriodChanged: provider.setActivityPeriod,
                showPeriodToggle: true,
                periodLabel: provider.periodLabel,
                onPreviousPeriod: provider.goToPreviousPeriod,
                onNextPeriod: provider.goToNextPeriod,
                canGoToNextPeriod: provider.canGoToNextPeriod,
              ),
              const SizedBox(height: Spacing.lg),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 65,
                      child: _buildRecentlyAddedCard(context, provider),
                    ),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      flex: 35,
                      child: QuickStatsWidget(
                        totalBooks: provider.totalBooks,
                        totalShelves: provider.totalShelves,
                        totalTopics: provider.totalTopics,
                        totalReadingLabel: provider.totalReadingLabel,
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

  /// Builds the top cards row (side-by-side on wide screens, stacked otherwise).
  Widget _buildTopCards(BuildContext context, DashboardProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1024;

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ContinueReadingCard(
                book: provider.currentBook,
                isDesktop: true,
              ),
            ),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: ReadingGoalCard(
                goals: provider.activeGoals,
                isDesktop: true,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ContinueReadingCard(book: provider.currentBook, isDesktop: true),
        const SizedBox(height: Spacing.lg),
        ReadingGoalCard(goals: provider.activeGoals, isDesktop: true),
      ],
    );
  }

  /// Wraps the recently added section in a bordered card for mobile layout.
  Widget _buildMobileRecentlyAddedCard(
    BuildContext context,
    DashboardProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RecentlyAddedSection(books: provider.recentlyAdded),
    );
  }

  /// Wraps the recently added section in a bordered card for desktop layout.
  Widget _buildRecentlyAddedCard(
    BuildContext context,
    DashboardProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

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
      child: RecentlyAddedSection(
        books: provider.recentlyAdded,
        isDesktop: true,
      ),
    );
  }
}
