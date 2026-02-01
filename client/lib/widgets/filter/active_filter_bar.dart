import 'package:flutter/material.dart';
import 'package:papyrus/models/active_filter.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Horizontal scrolling bar showing active filters with remove buttons.
/// Only visible when filters are active.
class ActiveFilterBar extends StatelessWidget {
  /// List of currently active filters.
  final List<ActiveFilter> filters;

  /// Callback when a filter is removed.
  final ValueChanged<ActiveFilter>? onFilterRemoved;

  /// Callback when "Clear All" is tapped.
  final VoidCallback? onClearAll;

  const ActiveFilterBar({
    super.key,
    required this.filters,
    this.onFilterRemoved,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: filters.length + 1, // +1 for Clear All button
        separatorBuilder: (context, index) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          if (index == filters.length) {
            // Clear All button
            return TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final filter = filters[index];
          return _ActiveFilterChip(
            filter: filter,
            onRemoved: () => onFilterRemoved?.call(filter),
          );
        },
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final ActiveFilter filter;
  final VoidCallback? onRemoved;

  const _ActiveFilterChip({
    required this.filter,
    this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      label: _buildLabel(context),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: colorScheme.onSecondaryContainer,
      ),
      onDeleted: onRemoved,
    );
  }

  Widget _buildLabel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondaryContainer,
        );

    if (filter.type == ActiveFilterType.quick) {
      return Text(filter.label, style: textStyle);
    }

    // Query filter with syntax highlighting
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${filter.label}: ',
            style: textStyle?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: filter.value,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
