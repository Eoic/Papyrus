import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Quick stats widget showing summary statistics on the dashboard.
class QuickStatsWidget extends StatelessWidget {
  /// Total number of books in the library.
  final int totalBooks;

  /// Total number of shelves.
  final int totalShelves;

  /// Total number of topics.
  final int totalTopics;

  /// Total reading time label (e.g., "24h").
  final String totalReadingLabel;

  const QuickStatsWidget({
    super.key,
    required this.totalBooks,
    required this.totalShelves,
    required this.totalTopics,
    required this.totalReadingLabel,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick stats', style: textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => context.go('/statistics'),
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
          const SizedBox(height: Spacing.md),
          _buildStatRow(
            context,
            icon: Icons.menu_book_outlined,
            label: 'Books',
            value: totalBooks.toString(),
          ),
          const SizedBox(height: Spacing.sm),
          _buildStatRow(
            context,
            icon: Icons.collections_bookmark_outlined,
            label: 'Shelves',
            value: totalShelves.toString(),
          ),
          const SizedBox(height: Spacing.sm),
          _buildStatRow(
            context,
            icon: Icons.label_outline,
            label: 'Topics',
            value: totalTopics.toString(),
          ),
          const SizedBox(height: Spacing.sm),
          _buildStatRow(
            context,
            icon: Icons.schedule_outlined,
            label: 'Reading time',
            value: totalReadingLabel,
          ),
        ],
      ),
    );
  }

  /// Builds a single stat row with icon, label, and value.
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
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
