import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/goals_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/goals/active_goal_details_sheet.dart';
import 'package:papyrus/widgets/goals/add_goal_sheet.dart';
import 'package:papyrus/widgets/goals/completed_goal_chip.dart';
import 'package:papyrus/widgets/goals/goal_card.dart';
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

  Widget _buildMobileLayout(BuildContext context, GoalsProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Completed goals', style: textTheme.titleMedium),
                    TextButton(onPressed: () {}, child: const Text('See all')),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.completedGoals.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(width: Spacing.sm),
                    itemBuilder: (context, index) {
                      final goal = provider.completedGoals[index];
                      return CompletedGoalChip(
                        goal: goal,
                        onDelete: () => _provider.deleteGoal(goal.id),
                      );
                    },
                  ),
                ),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Goals', style: textTheme.displaySmall),
                  FilledButton.icon(
                    onPressed: () => _showAddGoalSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New goal'),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              // Active goals section
              if (provider.hasActiveGoals) ...[
                Text('Active goals', style: textTheme.titleMedium),
                const SizedBox(height: Spacing.md),
                _buildGoalGrid(context, provider),
              ],
              // Empty state
              if (!provider.hasActiveGoals) _buildEmptyState(context),
              // Completed goals section
              if (provider.hasCompletedGoals) ...[
                const SizedBox(height: Spacing.xl),
                Text('Completed goals', style: textTheme.titleMedium),
                const SizedBox(height: Spacing.md),
                Wrap(
                  spacing: Spacing.md,
                  runSpacing: Spacing.md,
                  children: provider.completedGoals
                      .map(
                        (goal) => CompletedGoalChip(
                          goal: goal,
                          isExpanded: true,
                          onDelete: () => _provider.deleteGoal(goal.id),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalGrid(BuildContext context, GoalsProvider provider) {
    final goals = provider.activeGoals;

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
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkLayout(BuildContext context, GoalsProvider provider) {
    return Scaffold(
      body: Column(
        children: [
          _buildEinkHeader(context),
          const Divider(color: Colors.black, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageMarginsEink),
              children: [
                // Active goals
                if (provider.hasActiveGoals) ...[
                  _buildEinkSectionHeader(context, 'ACTIVE GOALS'),
                  const SizedBox(height: Spacing.md),
                  ...provider.activeGoals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: GoalCard(
                        goal: goal,
                        isEinkMode: true,
                        onTap: () => _showGoalDetails(context, goal),
                      ),
                    ),
                  ),
                ],
                // Empty state
                if (!provider.hasActiveGoals) _buildEinkEmptyState(context),
                // Completed goals
                if (provider.hasCompletedGoals) ...[
                  const SizedBox(height: Spacing.lg),
                  _buildEinkSectionHeader(context, 'COMPLETED GOALS'),
                  const SizedBox(height: Spacing.md),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: BorderWidths.einkDefault,
                      ),
                    ),
                    child: Column(
                      children: provider.completedGoals
                          .map(
                            (goal) => CompletedGoalChip(
                              goal: goal,
                              isEinkMode: true,
                              onDelete: () => _provider.deleteGoal(goal.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'GOALS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: () => _showAddGoalSheet(context),
            child: Container(
              width: TouchTargets.einkMin,
              height: TouchTargets.einkMin,
              alignment: Alignment.center,
              child: const Text(
                '+',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  // ============================================================================
  // EMPTY STATES
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

  Widget _buildEinkEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 64),
          const SizedBox(height: Spacing.lg),
          Text(
            'NO GOALS YET',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Tap + to create your first reading goal',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
