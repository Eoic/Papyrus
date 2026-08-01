import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/library_filter_options.dart';
import 'package:papyrus/models/library_filters.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/enums/library_sort_option.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/utils/book_language.dart';
import 'package:provider/provider.dart';

class _ChipEntry {
  final String id;
  final bool isActive;
  final int defaultOrder;
  final Widget child;

  const _ChipEntry({required this.id, required this.isActive, required this.defaultOrder, required this.child});
}

class _SelectionOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const _SelectionOption({required this.value, required this.label, this.icon});
}

class _DropdownFilterChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool isSelected;
  final String? tooltip;
  final VoidCallback onPressed;

  const _DropdownFilterChip({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$semanticLabel: $label',
      child: ActionChip(
        tooltip: tooltip,
        avatar: Icon(icon, size: 18, color: foregroundColor),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: foregroundColor),
          ],
        ),
        labelStyle: TextStyle(color: foregroundColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
        backgroundColor: isSelected ? colorScheme.secondaryContainer : colorScheme.surfaceContainerLow,
        side: BorderSide(color: isSelected ? colorScheme.secondaryContainer : colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        onPressed: onPressed,
      ),
    );
  }
}

class _SingleSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<_SelectionOption<T>> options;
  final T selectedValue;

  const _SingleSelectionSheet({required this.title, required this.options, required this.selectedValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetTitle(title: title),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.value == selectedValue;

              return ListTile(
                selected: isSelected,
                leading: option.icon == null ? null : Icon(option.icon),
                title: Text(option.label),
                trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(context).pop(option.value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MultiSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<_SelectionOption<T>> options;
  final Set<T> selectedValues;
  final bool searchable;

  const _MultiSelectionSheet({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.searchable,
  });

  @override
  State<_MultiSelectionSheet<T>> createState() => _MultiSelectionSheetState<T>();
}

class _MultiSelectionSheetState<T> extends State<_MultiSelectionSheet<T>> {
  late final Set<T> _selectedValues = Set.of(widget.selectedValues);
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleOptions = normalizedQuery.isEmpty
        ? widget.options
        : widget.options.where((option) => option.label.toLowerCase().contains(normalizedQuery)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetTitle(title: widget.title),
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (query) => setState(() => _searchQuery = query),
            ),
          ),
        const Divider(height: 1),
        Flexible(
          child: visibleOptions.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40), child: Text('No matches'))
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleOptions.length,
                  itemBuilder: (context, index) {
                    final option = visibleOptions[index];
                    final isSelected = _selectedValues.contains(option.value);

                    return CheckboxListTile(
                      value: isSelected,
                      secondary: option.icon == null ? null : Icon(option.icon),
                      title: Text(option.label),
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedValues.remove(option.value);
                          } else {
                            _selectedValues.add(option.value);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(Set<T>.of(_selectedValues)),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String title;

  const _SheetTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

Future<T?> _showSingleSelectionSheet<T>(
  BuildContext context, {
  required String title,
  required List<_SelectionOption<T>> options,
  required T selectedValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SingleSelectionSheet<T>(title: title, options: options, selectedValue: selectedValue),
  );
}

Future<Set<T>?> _showMultiSelectionSheet<T>(
  BuildContext context, {
  required String title,
  required List<_SelectionOption<T>> options,
  required Set<T> selectedValues,
  bool searchable = false,
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _MultiSelectionSheet<T>(title: title, options: options, selectedValues: selectedValues, searchable: searchable),
  );
}

class LibraryFilterChips extends StatelessWidget {
  final double? horizontalPadding;
  final LibraryFilterOptions? filterOptions;
  final bool showDownloading;
  final bool isDownloadingSelected;
  final VoidCallback? onDownloadingTapped;
  final VoidCallback? onLibraryFilterTapped;

  const LibraryFilterChips({
    super.key,
    this.horizontalPadding,
    this.filterOptions,
    this.showDownloading = false,
    this.isDownloadingSelected = false,
    this.onDownloadingTapped,
    this.onLibraryFilterTapped,
  });

  static final List<_SelectionOption<LibrarySortOption>> _sortOptions = [
    for (final option in LibrarySortOption.values)
      _SelectionOption<LibrarySortOption>(value: option, label: option.label),
  ];

  static final List<_SelectionOption<FavoriteFilter>> _favoriteOptions = [
    const _SelectionOption(value: FavoriteFilter.any, label: 'Any'),
    const _SelectionOption(value: FavoriteFilter.favorites, label: 'Favorites', icon: Icons.favorite_outline),
    const _SelectionOption(
      value: FavoriteFilter.notFavorites,
      label: 'Not favorites',
      icon: Icons.heart_broken_outlined,
    ),
  ];

  static final List<_SelectionOption<LibraryViewMode>> _viewModeOptions = [
    for (final option in LibraryViewMode.values) _SelectionOption<LibraryViewMode>(value: option, label: option.label),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final dataStore = context.watch<DataStore>();
    final filterOptions = this.filterOptions ?? LibraryFilterOptions.fromDataStore(dataStore);
    final statusOptions = [
      for (final option in filterOptions.readingStatuses)
        _SelectionOption<LibraryReadingStatus>(value: option.value, label: option.label, icon: option.value.icon),
    ];
    final effectiveStatusOptions = _withSelectedSelectionOptions(
      statusOptions,
      provider.selectedStatuses,
      (status) => status.label,
    );
    final authorOptions = _withIcon(
      _withSelectedFilterOptions(
        filterOptions.authors,
        provider.selectedAuthors,
        (value) => _authorLabel(dataStore.books, value),
      ),
      Icons.person_outline_rounded,
    );
    final languageOptions = _withIcon(
      _withSelectedFilterOptions(
        filterOptions.languages,
        provider.selectedLanguages,
        (value) => _languageLabel(dataStore.books, value),
      ),
      Icons.language_rounded,
    );
    final formatOptions = _withIcon(
      _withSelectedFilterOptions(
        filterOptions.formats,
        provider.selectedFormats,
        (value) => _formatLabel(dataStore.books, value),
      ),
      Icons.description_outlined,
    );
    final topicOptions = _withIcon(
      _withSelectedFilterOptions(
        filterOptions.topics,
        provider.selectedTopicIds,
        (value) => _topicLabel(dataStore, value),
      ),
      Icons.label_outline_rounded,
    );
    final shelfOptions = _withIcon(
      _withSelectedFilterOptions(
        filterOptions.shelves,
        provider.selectedShelfIds,
        (value) => _shelfLabel(dataStore, value),
      ),
      Icons.folder_outlined,
    );
    final selectedSort = _sortOptions.firstWhere((option) => option.value == provider.sortOption);
    final selectedFavorite = _favoriteOptions.firstWhere((option) => option.value == provider.favoriteFilter);
    final selectedViewMode = _viewModeOptions.firstWhere((option) => option.value == provider.viewMode);

    final chips = <_ChipEntry>[
      _ChipEntry(
        id: 'status',
        defaultOrder: 0,
        isActive: provider.selectedStatuses.isNotEmpty,
        child: _DropdownFilterChip(
          label: _multiSelectionLabel('Status', provider.selectedStatuses, effectiveStatusOptions),
          semanticLabel: 'Reading status',
          icon: Icons.auto_stories_outlined,
          isSelected: provider.selectedStatuses.isNotEmpty,
          tooltip: 'Filter by reading status',
          onPressed: () => _selectMultiple<LibraryReadingStatus>(
            context: context,
            title: 'Reading status',
            options: effectiveStatusOptions,
            selectedValues: provider.selectedStatuses,
            onSelected: provider.setStatusFilters,
          ),
        ),
      ),
      _ChipEntry(
        id: 'sort',
        defaultOrder: 1,
        isActive: provider.sortOption != LibrarySortOption.dateAddedNewest,
        child: _DropdownFilterChip(
          label: selectedSort.label,
          semanticLabel: 'Book sorting',
          icon: Icons.sort_rounded,
          isSelected: provider.sortOption != LibrarySortOption.dateAddedNewest,
          tooltip: 'Sort books',
          onPressed: () => _selectSingle<LibrarySortOption>(
            context: context,
            title: 'Sort books',
            options: _sortOptions,
            selectedValue: provider.sortOption,
            onSelected: provider.setSortOption,
          ),
        ),
      ),
      _ChipEntry(
        id: 'favorites',
        defaultOrder: 2,
        isActive: provider.favoriteFilter != FavoriteFilter.any,
        child: _DropdownFilterChip(
          label: provider.favoriteFilter == FavoriteFilter.any ? 'Favorites' : selectedFavorite.label,
          semanticLabel: 'Favorite state',
          icon: selectedFavorite.icon ?? Icons.favorite_outline,
          isSelected: provider.favoriteFilter != FavoriteFilter.any,
          tooltip: 'Filter by favorite state',
          onPressed: () => _selectSingle<FavoriteFilter>(
            context: context,
            title: 'Favorite state',
            options: _favoriteOptions,
            selectedValue: provider.favoriteFilter,
            onSelected: provider.setFavoriteFilter,
          ),
        ),
      ),
      _ChipEntry(
        id: 'author',
        defaultOrder: 3,
        isActive: provider.selectedAuthors.isNotEmpty,
        child: _DropdownFilterChip(
          label: _multiSelectionLabel('Author', provider.selectedAuthors, authorOptions),
          semanticLabel: 'Author',
          icon: Icons.person_outline_rounded,
          isSelected: provider.selectedAuthors.isNotEmpty,
          tooltip: 'Filter by author',
          onPressed: () => _selectMultiple<String>(
            context: context,
            title: 'Authors',
            options: authorOptions,
            selectedValues: provider.selectedAuthors,
            onSelected: provider.setAuthorFilters,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'language',
        defaultOrder: 4,
        isActive: provider.selectedLanguages.isNotEmpty,
        child: _DropdownFilterChip(
          label: _multiSelectionLabel('Language', provider.selectedLanguages, languageOptions),
          semanticLabel: 'Language',
          icon: Icons.language_rounded,
          isSelected: provider.selectedLanguages.isNotEmpty,
          tooltip: 'Filter by language',
          onPressed: () => _selectMultiple<String>(
            context: context,
            title: 'Languages',
            options: languageOptions,
            selectedValues: provider.selectedLanguages,
            onSelected: provider.setLanguageFilters,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'format',
        defaultOrder: 5,
        isActive: provider.selectedFormats.isNotEmpty,
        child: _DropdownFilterChip(
          label: _multiSelectionLabel('Format', provider.selectedFormats, formatOptions),
          semanticLabel: 'Format',
          icon: Icons.description_outlined,
          isSelected: provider.selectedFormats.isNotEmpty,
          tooltip: 'Filter by format',
          onPressed: () => _selectMultiple<String>(
            context: context,
            title: 'Formats',
            options: formatOptions,
            selectedValues: provider.selectedFormats,
            onSelected: provider.setFormatFilters,
          ),
        ),
      ),
      _ChipEntry(
        id: 'topic',
        defaultOrder: 6,
        isActive: provider.selectedTopicIds.isNotEmpty,
        child: _DropdownFilterChip(
          label: _multiSelectionLabel('Topic', provider.selectedTopicIds, topicOptions),
          semanticLabel: 'Topic',
          icon: Icons.label_outline_rounded,
          isSelected: provider.selectedTopicIds.isNotEmpty,
          tooltip: 'Filter by topic',
          onPressed: () => _selectMultiple<String>(
            context: context,
            title: 'Topics',
            options: topicOptions,
            selectedValues: provider.selectedTopicIds,
            onSelected: provider.setTopicFilters,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'shelf',
        defaultOrder: 7,
        isActive: provider.selectedShelfIds.isNotEmpty,
        child: _DropdownFilterChip(
          label: _multiSelectionLabel('Shelf', provider.selectedShelfIds, shelfOptions),
          semanticLabel: 'Shelf',
          icon: Icons.folder_outlined,
          isSelected: provider.selectedShelfIds.isNotEmpty,
          tooltip: 'Filter by shelf',
          onPressed: () => _selectMultiple<String>(
            context: context,
            title: 'Shelves',
            options: shelfOptions,
            selectedValues: provider.selectedShelfIds,
            onSelected: provider.setShelfFilters,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'view-mode',
        defaultOrder: 8,
        isActive: provider.viewMode != LibraryViewMode.smallGrid,
        child: _DropdownFilterChip(
          label: selectedViewMode.label,
          semanticLabel: 'View mode',
          icon: Icons.grid_on,
          isSelected: provider.viewMode != LibraryViewMode.smallGrid,
          tooltip: 'Change view mode',
          onPressed: () => _selectSingle<LibraryViewMode>(
            context: context,
            title: 'View mode',
            options: _viewModeOptions,
            selectedValue: provider.viewMode,
            onSelected: provider.setViewMode,
          ),
        ),
      ),
    ];

    final hasActiveSelections =
        chips.any((chip) => chip.isActive) || provider.activeFilterCount > 0 || isDownloadingSelected;

    chips.sort((a, b) {
      final activeComparison = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
      return activeComparison != 0 ? activeComparison : a.defaultOrder.compareTo(b.defaultOrder);
    });

    final orderKey = [...chips.map((chip) => chip.id), if (hasActiveSelections) 'clear-all'].join('-');

    return SizedBox(
      height: 48,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(alignment: Alignment.centerLeft, children: [...previousChildren, ?currentChild]);
        },
        child: ListView.separated(
          key: ValueKey(orderKey),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 16),
          itemCount: chips.length + (hasActiveSelections ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index < chips.length) {
              final chip = chips[index];
              return KeyedSubtree(key: ValueKey(chip.id), child: chip.child);
            }

            return Align(
              alignment: Alignment.center,
              child: TextButton(
                key: const ValueKey('clear-all'),
                onPressed: () {
                  provider.resetQuickFilters();
                  if (isDownloadingSelected) {
                    onDownloadingTapped?.call();
                  }
                  onLibraryFilterTapped?.call();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Clear all'),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectSingle<T>({
    required BuildContext context,
    required String title,
    required List<_SelectionOption<T>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) async {
    final result = await _showSingleSelectionSheet<T>(
      context,
      title: title,
      options: options,
      selectedValue: selectedValue,
    );

    if (result == null || result == selectedValue) {
      return;
    }

    onSelected(result);
    onLibraryFilterTapped?.call();
  }

  Future<void> _selectMultiple<T>({
    required BuildContext context,
    required String title,
    required List<_SelectionOption<T>> options,
    required Set<T> selectedValues,
    required ValueChanged<Set<T>> onSelected,
    bool searchable = false,
  }) async {
    final result = await _showMultiSelectionSheet<T>(
      context,
      title: title,
      options: options,
      selectedValues: selectedValues,
      searchable: searchable,
    );

    if (result == null || setEquals(result, selectedValues)) {
      return;
    }

    onSelected(result);
    onLibraryFilterTapped?.call();
  }

  static String _multiSelectionLabel<T>(String category, Set<T> selectedValues, List<_SelectionOption<T>> options) {
    if (selectedValues.isEmpty) {
      return category;
    }
    if (selectedValues.length > 1) {
      return '$category · ${selectedValues.length}';
    }

    final selectedValue = selectedValues.first;
    for (final option in options) {
      if (option.value == selectedValue) {
        return option.label;
      }
    }
    return category;
  }

  static List<_SelectionOption<String>> _withIcon(List<LibraryFilterOption<String>> options, IconData icon) {
    return [for (final option in options) _SelectionOption(value: option.value, label: option.label, icon: icon)];
  }

  static List<_SelectionOption<T>> _withSelectedSelectionOptions<T>(
    List<_SelectionOption<T>> options,
    Set<T> selectedValues,
    String Function(T value) labelForValue,
  ) {
    return [
      ...options,
      for (final value in selectedValues)
        if (!options.any((option) => option.value == value))
          _SelectionOption(value: value, label: labelForValue(value)),
    ];
  }

  static List<LibraryFilterOption<String>> _withSelectedFilterOptions(
    List<LibraryFilterOption<String>> options,
    Set<String> selectedValues,
    String Function(String value) labelForValue,
  ) {
    return [
      ...options,
      for (final value in selectedValues)
        if (!options.any((option) => option.value == value))
          LibraryFilterOption(value: value, label: labelForValue(value)),
    ];
  }

  static String _authorLabel(Iterable<Book> books, String value) {
    for (final book in books) {
      for (final author in [book.author, ...book.coAuthors]) {
        if (author.trim().toLowerCase() == value) {
          return author.trim();
        }
      }
    }
    return 'Unknown author ($value)';
  }

  static String _formatLabel(Iterable<Book> books, String value) {
    for (final book in books) {
      if (book.formatLabel.toLowerCase() == value) {
        return book.formatLabel;
      }
    }
    return 'Unknown format ($value)';
  }

  static String _languageLabel(Iterable<Book> books, String value) {
    for (final book in books) {
      if (normalizeBookLanguage(book.language) == value) {
        return bookLanguageLabel(book.language ?? value);
      }
    }
    final label = bookLanguageLabel(value);
    return label == value ? 'Unknown language ($value)' : label;
  }

  static String _topicLabel(DataStore dataStore, String value) {
    for (final topic in dataStore.tags) {
      if (topic.id == value) {
        return topic.name;
      }
    }
    return 'Unknown topic ($value)';
  }

  static String _shelfLabel(DataStore dataStore, String value) {
    for (final shelf in dataStore.shelves) {
      if (shelf.id == value) {
        return shelf.name;
      }
    }
    return 'Unknown shelf ($value)';
  }
}
