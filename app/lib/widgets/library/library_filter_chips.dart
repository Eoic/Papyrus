import 'package:flutter/material.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/shared/quick_filter_chips.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable filter chips for library filtering.
/// Thin wrapper around [QuickFilterChips] that reads [LibraryProvider].
class LibraryFilterChips extends StatelessWidget {
  final double? horizontalPadding;
  final bool showDownloading;
  final bool isDownloadingSelected;
  final VoidCallback? onDownloadingTapped;
  final VoidCallback? onLibraryFilterTapped;

  const LibraryFilterChips({
    super.key,
    this.horizontalPadding,
    this.showDownloading = false,
    this.isDownloadingSelected = false,
    this.onDownloadingTapped,
    this.onLibraryFilterTapped,
  });

  static const _filters = [
    (type: LibraryFilterType.all, label: 'All', icon: Icons.apps),
    (type: LibraryFilterType.reading, label: 'Reading', icon: Icons.auto_stories),
    (type: LibraryFilterType.favorites, label: 'Favorites', icon: Icons.favorite),
    (type: LibraryFilterType.finished, label: 'Finished', icon: Icons.check_circle),
    (type: LibraryFilterType.unread, label: 'Unread', icon: Icons.book),
  ];

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final filters = _filters
        .map(
          (filter) => QuickFilterChipData(
            label: filter.label,
            icon: filter.icon,
            isSelected: libraryProvider.isFilterActive(filter.type),
          ),
        )
        .toList();

    if (showDownloading) {
      filters.add(
        QuickFilterChipData(label: 'Downloading', icon: Icons.downloading_outlined, isSelected: isDownloadingSelected),
      );
    }

    return QuickFilterChips(
      horizontalPadding: horizontalPadding,
      filters: filters,
      onFilterTapped: (index) {
        if (index == _filters.length) {
          onDownloadingTapped?.call();

          return;
        }

        final filter = _filters[index];

        if (filter.type == LibraryFilterType.all) {
          libraryProvider.resetFilters();
        } else {
          libraryProvider.toggleFilter(filter.type);
        }

        onLibraryFilterTapped?.call();
      },
    );
  }
}
