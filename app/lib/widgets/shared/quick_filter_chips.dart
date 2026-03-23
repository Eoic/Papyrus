import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Data for a single quick filter chip.
class QuickFilterChipData {
  final String label;
  final IconData icon;
  final bool isSelected;

  const QuickFilterChipData({
    required this.label,
    required this.icon,
    required this.isSelected,
  });
}

/// Horizontal scrollable filter chips, provider-agnostic.
class QuickFilterChips extends StatelessWidget {
  final List<QuickFilterChipData> filters;
  final ValueChanged<int> onFilterTapped;
  final double? horizontalPadding;

  const QuickFilterChips({
    super.key,
    required this.filters,
    required this.onFilterTapped,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding ?? Spacing.md,
          ),
          itemCount: filters.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: Spacing.sm),
          itemBuilder: (context, index) {
            final filter = filters[index];

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: IconSizes.small,
                    color: filter.isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: filter.isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              selected: filter.isSelected,
              showCheckmark: false,
              side: BorderSide(color: colorScheme.outline),
              onSelected: (_) => onFilterTapped(index),
            );
          },
        ),
      ),
    );
  }
}
