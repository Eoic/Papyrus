import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Card displaying the user's reading goals progress.
/// Supports multiple goals displayed in a compact list.
class ReadingGoalCard extends StatelessWidget {
  /// The active reading goals.
  final List<ReadingGoal> goals;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to use desktop styling.
  final bool isDesktop;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const ReadingGoalCard({
    super.key,
    required this.goals,
    this.onTap,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return isEinkMode
          ? _buildEinkEmptyState(context)
          : _buildEmptyState(context);
    }

    if (isEinkMode) return _buildEinkCard(context);
    return _buildStandardCard(context);
  }

  // ============================================================================
  // STANDARD LAYOUT (Mobile + Desktop)
  // ============================================================================

  Widget _buildStandardCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reading goals', style: textTheme.titleMedium),
              TextButton.icon(
                onPressed: onTap ?? () => context.go('/goals'),
                icon: const Text('View all'),
                label: const Icon(Icons.arrow_forward, size: 16),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // Goals list
          ...goals.take(3).map((goal) => _buildGoalRow(context, goal)),
        ],
      ),
    );
  }

  Widget _buildGoalRow(BuildContext context, ReadingGoal goal) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.description,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${goal.current}/${goal.target}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: goal.isCompleted
                  ? colorScheme.tertiary
                  : colorScheme.primary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkCard(BuildContext context) {
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
          // Header
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'READING GOALS',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${goals.length} ${goals.length == 1 ? 'GOAL' : 'GOALS'}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Goals list
          ...goals.take(3).map((goal) => _buildEinkGoalRow(context, goal)),
        ],
      ),
    );
  }

  Widget _buildEinkGoalRow(BuildContext context, ReadingGoal goal) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.description.toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${goal.current}/${goal.target}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          _buildEinkProgressBar(context, goal),
        ],
      ),
    );
  }

  Widget _buildEinkProgressBar(BuildContext context, ReadingGoal goal) {
    // Use goal target as segment count (max 20)
    final segmentCount = goal.target.clamp(1, 20);
    final filledSegments = (goal.progress * segmentCount).round();

    return SizedBox(
      height: 12,
      child: Row(
        children: List.generate(segmentCount, (index) {
          final isFilled = index < filledSegments;
          final isFirst = index == 0;

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isFilled ? Colors.black : Colors.white,
                border: Border(
                  top: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                  bottom: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                  left: isFirst
                      ? const BorderSide(
                          color: Colors.black,
                          width: BorderWidths.einkDefault,
                        )
                      : BorderSide.none,
                  right: const BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                ),
              ),
            ),
          );
        }),
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
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No reading goals set',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Set a goal to track your progress',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.md),
          TextButton(
            onPressed: () => context.go('/goals'),
            child: const Text('Set a goal'),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                const Icon(Icons.flag_outlined, size: 40),
                const SizedBox(height: Spacing.md),
                Text(
                  'NO READING GOALS SET',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: TouchTargets.einkMin,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'SET A GOAL',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
