import 'package:flutter/material.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable filter chips for library filtering.
class LibraryFilterChips extends StatelessWidget {
  const LibraryFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final filters = [
      _FilterChipData(
        type: LibraryFilterType.all,
        label: 'All',
        icon: Icons.apps,
      ),
      _FilterChipData(
        type: LibraryFilterType.reading,
        label: 'Reading',
        icon: Icons.auto_stories,
      ),
      _FilterChipData(
        type: LibraryFilterType.favorites,
        label: 'Favorites',
        icon: Icons.favorite,
      ),
      _FilterChipData(
        type: LibraryFilterType.finished,
        label: 'Finished',
        icon: Icons.check_circle,
      ),
      _FilterChipData(
        type: LibraryFilterType.shelves,
        label: 'Shelves',
        icon: Icons.shelves,
      ),
      _FilterChipData(
        type: LibraryFilterType.topics,
        label: 'Topics',
        icon: Icons.topic,
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = libraryProvider.isFilterActive(filter.type);

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter.icon,
                  size: IconSizes.small,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.xs),
                Text(filter.label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) {
              libraryProvider.setFilter(filter.type);
            },
          );
        },
      ),
    );
  }
}

class _FilterChipData {
  final LibraryFilterType type;
  final String label;
  final IconData icon;

  const _FilterChipData({
    required this.type,
    required this.label,
    required this.icon,
  });
}
