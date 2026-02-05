import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A bordered card displaying a single statistic with value, label, and optional icon.
///
/// Matches the goals page styling with consistent borders and design tokens.
class StatCard extends StatelessWidget {
  /// The main value to display (e.g., "45", "3.5h").
  final String value;

  /// The label below the value (e.g., "books read").
  final String label;

  /// Optional icon to display.
  final IconData? icon;

  /// Optional secondary value (e.g., "+12%").
  final String? trend;

  /// Whether the trend is positive.
  final bool? isTrendPositive;

  /// Whether to use desktop styling (larger).
  final bool isDesktop;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.trend,
    this.isTrendPositive,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? Spacing.lg : Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null || trend != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (icon != null)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (trend != null) _buildTrendBadge(context),
              ],
            ),
          if (icon != null || trend != null) const SizedBox(height: Spacing.sm),
          Text(
            value,
            style:
                (isDesktop ? textTheme.headlineMedium : textTheme.headlineSmall)
                    ?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isPositive = isTrendPositive ?? true;
    final trendColor = isPositive ? colorScheme.tertiary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: trendColor,
          ),
          const SizedBox(width: 4),
          Text(
            trend!,
            style: textTheme.labelSmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact stat card for use in horizontal rows.
class CompactStatCard extends StatelessWidget {
  /// The main value to display.
  final String value;

  /// The label below the value.
  final String label;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const CompactStatCard({
    super.key,
    required this.value,
    required this.label,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? Spacing.md : Spacing.sm,
        vertical: isDesktop ? Spacing.md : Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: (isDesktop ? textTheme.titleLarge : textTheme.titleMedium)
                ?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A section card with a title and content area.
class StatSectionCard extends StatelessWidget {
  /// The section title.
  final String title;

  /// Optional action widget (e.g., button).
  final Widget? action;

  /// The content of the section.
  final Widget child;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const StatSectionCard({
    super.key,
    required this.title,
    this.action,
    required this.child,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? Spacing.lg : Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
              Text(title, style: textTheme.titleMedium),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}
