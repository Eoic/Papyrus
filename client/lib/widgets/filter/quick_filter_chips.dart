import 'package:flutter/material.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Horizontal scrolling row of quick filter chips.
/// Provides one-tap access to common filter states.
class QuickFilterChips extends StatelessWidget {
  /// Selected filter types.
  final Set<LibraryFilterType> selectedFilters;

  /// Callback when filter selection changes.
  final ValueChanged<LibraryFilterType>? onFilterToggled;

  /// Callback when "More filters" is tapped.
  final VoidCallback? onMoreFilters;

  /// Whether to show the "More" chip.
  final bool showMoreChip;

  const QuickFilterChips({
    super.key,
    required this.selectedFilters,
    this.onFilterToggled,
    this.onMoreFilters,
    this.showMoreChip = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: Icons.apps,
            isSelected: selectedFilters.contains(LibraryFilterType.all),
            onTap: () => onFilterToggled?.call(LibraryFilterType.all),
          ),
          const SizedBox(width: Spacing.sm),
          _QuickFilterChip(
            label: 'Reading',
            icon: Icons.auto_stories,
            isSelected: selectedFilters.contains(LibraryFilterType.reading),
            onTap: () => onFilterToggled?.call(LibraryFilterType.reading),
          ),
          const SizedBox(width: Spacing.sm),
          _QuickFilterChip(
            label: 'Favorites',
            icon: Icons.favorite,
            isSelected: selectedFilters.contains(LibraryFilterType.favorites),
            onTap: () => onFilterToggled?.call(LibraryFilterType.favorites),
          ),
          const SizedBox(width: Spacing.sm),
          _QuickFilterChip(
            label: 'Finished',
            icon: Icons.check_circle,
            isSelected: selectedFilters.contains(LibraryFilterType.finished),
            onTap: () => onFilterToggled?.call(LibraryFilterType.finished),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isSelected
                ? null
                : Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
