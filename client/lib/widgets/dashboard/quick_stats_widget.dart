import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Quick stats widget showing summary statistics (desktop only in standard mode).
class QuickStatsWidget extends StatelessWidget {
  /// Total number of books in the library.
  final int totalBooks;

  /// Total number of shelves.
  final int totalShelves;

  /// Total number of topics.
  final int totalTopics;

  /// Total reading time label (e.g., "24h").
  final String totalReadingLabel;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const QuickStatsWidget({
    super.key,
    required this.totalBooks,
    required this.totalShelves,
    required this.totalTopics,
    required this.totalReadingLabel,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkStats(context);
    return _buildStandardStats(context);
  }

  // ============================================================================
  // STANDARD LAYOUT (Desktop)
  // ============================================================================

  Widget _buildStandardStats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick stats', style: textTheme.titleMedium),
          const SizedBox(height: Spacing.md),
          _buildStatRow(
            context,
            icon: Icons.menu_book_outlined,
            label: 'Books in library',
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
            label: 'Total reading',
            value: totalReadingLabel,
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/statistics'),
              child: const Text('View stats →'),
            ),
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

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkStats(BuildContext context) {
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
              'QUICK STATS',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildEinkStatRow(
            context,
            label: 'Books in library',
            value: totalBooks.toString(),
          ),
          _buildEinkStatRow(
            context,
            label: 'Shelves',
            value: totalShelves.toString(),
          ),
          _buildEinkStatRow(
            context,
            label: 'Total reading time',
            value: totalReadingLabel,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEinkStatRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Colors.black26)),
      ),
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
}
