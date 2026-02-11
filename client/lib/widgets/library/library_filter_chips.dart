import 'package:flutter/material.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/shared/quick_filter_chips.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable filter chips for library filtering.
/// Thin wrapper around [QuickFilterChips] that reads [LibraryProvider].
class LibraryFilterChips extends StatelessWidget {
  final double? horizontalPadding;

  const LibraryFilterChips({super.key, this.horizontalPadding});

  static const _filters = [
    (type: LibraryFilterType.all, label: 'All', icon: Icons.apps),
    (
      type: LibraryFilterType.reading,
      label: 'Reading',
      icon: Icons.auto_stories,
    ),
    (
      type: LibraryFilterType.favorites,
      label: 'Favorites',
      icon: Icons.favorite,
    ),
    (
      type: LibraryFilterType.finished,
      label: 'Finished',
      icon: Icons.check_circle,
    ),
    (type: LibraryFilterType.unread, label: 'Unread', icon: Icons.book),
  ];

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();

    return QuickFilterChips(
      horizontalPadding: horizontalPadding,
      filters: _filters
          .map(
            (f) => QuickFilterChipData(
              label: f.label,
              icon: f.icon,
              isSelected: libraryProvider.isFilterActive(f.type),
            ),
          )
          .toList(),
      onFilterTapped: (index) {
        final filter = _filters[index];
        if (filter.type == LibraryFilterType.all) {
          libraryProvider.resetFilters();
        } else {
          libraryProvider.toggleFilter(filter.type);
        }
      },
    );
  }
}
