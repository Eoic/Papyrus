import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/dashboard_provider.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
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
/// Provides three responsive layouts:
/// - **Mobile**: Vertical scrolling with stacked cards
/// - **Desktop**: Widget grid layout with sidebar
/// - **E-ink**: High-contrast vertical layout
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
      child: Consumer<DashboardProvider>(
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

  Widget _buildMobileLayout(BuildContext context, DashboardProvider provider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            children: [
              // Greeting
              DashboardGreeting(
                greeting: provider.greeting,
                todayReadingLabel: provider.todayReadingLabel,
              ),
              const SizedBox(height: Spacing.lg),
              // Continue Reading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: ContinueReadingCard(book: provider.currentBook),
              ),
              const SizedBox(height: Spacing.md),
              // Reading Goals
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: ReadingGoalCard(goals: provider.activeGoals),
              ),
              const SizedBox(height: Spacing.md),
              // Weekly Activity
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
              const SizedBox(height: Spacing.lg),
              // Recently Added
              RecentlyAddedSection(books: provider.recentlyAdded),
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

  Widget _buildDesktopLayout(BuildContext context, DashboardProvider provider) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              DashboardGreeting(
                greeting: provider.greeting,
                todayReadingLabel: provider.todayReadingLabel,
                isDesktop: true,
              ),
              const SizedBox(height: Spacing.lg),
              // Row 1: Continue Reading + Reading Goal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: Spacing.lg),
              // Row 2: Activity Chart (full width)
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
              // Row 3: Recently Added + Quick Stats
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
      ),
      child: RecentlyAddedSection(
        books: provider.recentlyAdded,
        isDesktop: true,
      ),
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkLayout(BuildContext context, DashboardProvider provider) {
    return Scaffold(
      body: Column(
        children: [
          _buildEinkHeader(context),
          const Divider(color: Colors.black, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageMarginsEink),
              children: [
                // Greeting
                DashboardGreeting(
                  greeting: provider.greeting,
                  todayReadingLabel: provider.todayReadingLabel,
                  isEinkMode: true,
                ),
                const SizedBox(height: Spacing.lg),
                // Continue Reading
                ContinueReadingCard(
                  book: provider.currentBook,
                  isEinkMode: true,
                ),
                const SizedBox(height: Spacing.lg),
                // Reading Goals
                ReadingGoalCard(goals: provider.activeGoals, isEinkMode: true),
                const SizedBox(height: Spacing.lg),
                // Weekly Activity
                WeeklyActivityChart(
                  activities: provider.weeklyActivity,
                  isEinkMode: true,
                  periodLabel: provider.periodLabel,
                  onPreviousPeriod: provider.goToPreviousPeriod,
                  onNextPeriod: provider.goToNextPeriod,
                  canGoToNextPeriod: provider.canGoToNextPeriod,
                ),
                const SizedBox(height: Spacing.lg),
                // Quick Stats
                QuickStatsWidget(
                  totalBooks: provider.totalBooks,
                  totalShelves: provider.totalShelves,
                  totalTopics: provider.totalTopics,
                  totalReadingLabel: provider.totalReadingLabel,
                  isEinkMode: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkHeader(BuildContext context) {
    return Container(
      height: ComponentSizes.einkHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageMarginsEink),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'DASHBOARD',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
