import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/providers/goals_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/goals/active_goal_details_sheet.dart';
import 'package:papyrus/widgets/goals/add_goal_sheet.dart';
import 'package:papyrus/widgets/goals/completed_goal_chip.dart';
import 'package:papyrus/widgets/goals/goal_card.dart';
import 'package:papyrus/widgets/statistics/stat_card.dart';
import 'package:provider/provider.dart';

/// Goals page displaying reading goals with progress tracking.
///
/// Features a clean, unified design where all goals use consistent
/// linear progress bars regardless of their time period.
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late GoalsProvider _provider;
  bool _completedCollapsed = true;

  @override
  void initState() {
    super.initState();
    _provider = GoalsProvider();
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
      child: Consumer<GoalsProvider>(
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

  Widget _buildMobileLayout(BuildContext context, GoalsProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              // Stats summary row
              if (provider.hasActiveGoals || provider.hasCompletedGoals) ...[
                _buildStatsRow(provider, isDesktop: false),
                const SizedBox(height: Spacing.lg),
              ],
              // Active goals section
              if (provider.hasActiveGoals) ...[
                Text('Active goals', style: textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                ...provider.activeGoals.map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: GoalCard(
                      goal: goal,
                      onTap: () => _showGoalDetails(context, goal),
                    ),
                  ),
                ),
              ],
              // Empty state
              if (!provider.hasActiveGoals) _buildEmptyState(context),
              // Completed goals section
              if (provider.hasCompletedGoals) ...[
                const SizedBox(height: Spacing.lg),
                _buildCompletedHeader(context, provider.completedGoals.length),
                const SizedBox(height: Spacing.sm),
                if (!_completedCollapsed) ...[
                  Opacity(
                    opacity: 0.6,
                    child: Column(
                      children: provider.completedGoals
                          .map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: Spacing.md,
                              ),
                              child: GoalCard(
                                goal: goal,
                                onTap: () => _showGoalDetails(context, goal),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
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

  Widget _buildDesktopLayout(BuildContext context, GoalsProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats summary row
              if (provider.hasActiveGoals || provider.hasCompletedGoals) ...[
                _buildStatsRow(provider, isDesktop: true),
                const SizedBox(height: Spacing.lg),
              ],
              // Active goals section
              if (provider.hasActiveGoals) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active goals', style: textTheme.titleMedium),
                    FilledButton.icon(
                      onPressed: () => _showAddGoalSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New goal'),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                _buildGoalGrid(context, provider.activeGoals),
              ],
              // Empty state
              if (!provider.hasActiveGoals) _buildEmptyState(context),
              // Completed goals section
              if (provider.hasCompletedGoals) ...[
                const SizedBox(height: Spacing.xl),
                _buildCompletedHeader(context, provider.completedGoals.length),
                const SizedBox(height: Spacing.md),
                if (!_completedCollapsed)
                  Opacity(
                    opacity: 0.6,
                    child: _buildGoalGrid(context, provider.completedGoals),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalGrid(BuildContext context, List<ReadingGoal> goals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns: 1 for narrow, 2 for medium, 3 for wide
        final crossAxisCount = _getColumnCount(constraints.maxWidth);

        // Card height: header(36) + gaps(32) + progress row(20) + bar(8) + footer(16) + padding(48) = 160
        // Adding extra padding for comfortable spacing
        const cardHeight = 176.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            mainAxisExtent: cardHeight,
          ),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            return GoalCard(
              goal: goals[index],
              isDesktop: true,
              onTap: () => _showGoalDetails(context, goals[index]),
            );
          },
        );
      },
    );
  }

  int _getColumnCount(double width) {
    if (width >= 1200) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  // ============================================================================
  // STATS & HEADERS
  // ============================================================================

  Widget _buildStatsRow(GoalsProvider provider, {required bool isDesktop}) {
    return Row(
      children: [
        Expanded(
          child: CompactStatCard(
            value: '${provider.activeGoals.length}',
            label: 'Active',
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: CompactStatCard(
            value: '${provider.completedGoals.length}',
            label: 'Completed',
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: CompactStatCard(
            value: '${_getBestStreak(provider)}',
            label: 'Best streak',
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  int _getBestStreak(GoalsProvider provider) {
    return provider.activeGoals
        .where((g) => g.isDaily && g.isRecurring && g.streak > 0)
        .fold(0, (max, g) => g.streak > max ? g.streak : max);
  }

  Widget _buildCompletedHeader(BuildContext context, int count) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => setState(() => _completedCollapsed = !_completedCollapsed),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Row(
          children: [
            Text('Completed goals', style: textTheme.titleMedium),
            const SizedBox(width: Spacing.sm),
            Text(
              '($count)',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              _completedCollapsed ? Icons.expand_more : Icons.expand_less,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'No goals yet',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Create your first reading goal to track your progress',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => _showAddGoalSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Create goal'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _showAddGoalSheet(BuildContext context) {
    AddGoalSheet.show(
      context,
      onCreate: (type, target, period, isRecurring, startDate, endDate) {
        _provider.createGoal(
          type: type,
          target: target,
          period: period,
          isRecurring: isRecurring,
          startDate: startDate,
          endDate: endDate,
        );
      },
    );
  }

  void _showGoalDetails(BuildContext context, ReadingGoal goal) {
    if (goal.isCompleted) {
      CompletedGoalChip.showDetailsSheet(
        context,
        goal: goal,
        onDelete: () => _provider.deleteGoal(goal.id),
      );
      return;
    }

    ActiveGoalDetailsSheet.show(
      context,
      goal: goal,
      onUpdateProgress: (newProgress) {
        _provider.updateGoalProgress(goal.id, newProgress);
      },
      onEdit: (newTarget) {
        _provider.updateGoal(goalId: goal.id, target: newTarget);
      },
      onDelete: () {
        _provider.deleteGoal(goal.id);
      },
    );
  }
}
