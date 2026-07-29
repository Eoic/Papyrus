import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
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

class _SelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<_SelectionOption<T>> options;
  final T selectedValue;
  final bool searchable;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.searchable,
  });

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleOptions = normalizedQuery.isEmpty
        ? widget.options
        : widget.options.where((option) => option.label.toLowerCase().contains(normalizedQuery)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.title, style: theme.textTheme.titleLarge),
          ),
        ),
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
                    final isSelected = option.value == widget.selectedValue;

                    return ListTile(
                      selected: isSelected,
                      leading: option.icon == null ? null : Icon(option.icon),
                      title: Text(option.label),
                      trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                      onTap: () {
                        Navigator.of(context).pop(option);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Future<_SelectionOption<T>?> _showSelectionSheet<T>(
  BuildContext context, {
  required String title,
  required List<_SelectionOption<T>> options,
  required T selectedValue,
  bool searchable = false,
}) {
  return showModalBottomSheet<_SelectionOption<T>>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _SelectionSheet<T>(title: title, options: options, selectedValue: selectedValue, searchable: searchable),
  );
}

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

  static final List<_SelectionOption<LibraryReadingStatus?>> _statusOptions = [
    const _SelectionOption<LibraryReadingStatus?>(value: null, label: 'All', icon: Icons.menu_book_rounded),

    for (final status in LibraryReadingStatus.values)
      _SelectionOption<LibraryReadingStatus?>(value: status, label: status.label, icon: status.icon),
  ];

  static final List<_SelectionOption<LibrarySortOption>> _sortOptions = [
    for (final option in LibrarySortOption.values)
      _SelectionOption<LibrarySortOption>(value: option, label: option.label),
  ];

  static final List<_SelectionOption<LibraryViewMode>> _viewModeOptions = [
    for (final option in LibraryViewMode.values) _SelectionOption<LibraryViewMode>(value: option, label: option.label),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final dataStore = context.watch<DataStore>();
    final colorScheme = Theme.of(context).colorScheme;
    final authorOptions = _buildAuthorOptions(dataStore.books);
    final languageOptions = _buildLanguageOptions(dataStore.books);
    final formatOptions = _buildFormatOptions(dataStore.books);
    final topicOptions = _buildTopicOptions(dataStore);
    final shelfOptions = _buildShelfOptions(dataStore);
    final selectedStatus = _statusOptions.firstWhere((option) => option.value == provider.selectedStatus);
    final selectedSort = _sortOptions.firstWhere((option) => option.value == provider.sortOption);
    final selectedViewMode = _viewModeOptions.firstWhere((option) => option.value == provider.viewMode);
    final selectedAuthor = _selectedOption(authorOptions, provider.selectedAuthor);
    final selectedLanguage = _selectedOption(languageOptions, provider.selectedLanguage);
    final selectedFormat = _selectedOption(formatOptions, provider.selectedFormat);
    final selectedTopic = _selectedOption(topicOptions, provider.selectedTopicId);
    final selectedShelf = _selectedOption(shelfOptions, provider.selectedShelfId);
    final isStatusActive = selectedStatus.value != null;
    final isSortActive = provider.sortOption != LibrarySortOption.dateAddedNewest;
    final isFavoritesActive = provider.isFavoritesSelected;
    final isAuthorActive = provider.selectedAuthor != null;
    final isLanguageActive = provider.selectedLanguage != null;
    final isFormatActive = provider.selectedFormat != null;
    final isTopicActive = provider.selectedTopicId != null;
    final isShelfActive = provider.selectedShelfId != null;
    final isViewModeActive = provider.viewMode != LibraryViewMode.smallGrid;

    final chips = <_ChipEntry>[
      _ChipEntry(
        id: 'status',
        defaultOrder: 0,
        isActive: isStatusActive,
        child: _DropdownFilterChip(
          label: selectedStatus.label,
          semanticLabel: 'Book progress',
          icon: selectedStatus.icon!,
          isSelected: isStatusActive,
          tooltip: 'Filter by book progress',
          onPressed: () => _selectOption<LibraryReadingStatus?>(
            context: context,
            title: 'Book progress',
            options: _statusOptions,
            selectedValue: provider.selectedStatus,
            onSelected: provider.setStatusFilter,
          ),
        ),
      ),
      _ChipEntry(
        id: 'sort',
        defaultOrder: 1,
        isActive: isSortActive,
        child: _DropdownFilterChip(
          label: selectedSort.label,
          semanticLabel: 'Book sorting',
          icon: Icons.sort_rounded,
          isSelected: isSortActive,
          tooltip: 'Sort books',
          onPressed: () => _selectOption<LibrarySortOption>(
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
        isActive: isFavoritesActive,
        child: FilterChip(
          shape: const StadiumBorder(),
          avatar: Icon(
            isFavoritesActive ? Icons.favorite : Icons.favorite_outline,
            size: 18,
            color: isFavoritesActive ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          label: const Text('Favorites'),
          selected: isFavoritesActive,
          onSelected: (_) {
            provider.setIsFavoritesSelected(!isFavoritesActive);
            onLibraryFilterTapped?.call();
          },
        ),
      ),
      _ChipEntry(
        id: 'author',
        defaultOrder: 3,
        isActive: isAuthorActive,
        child: _DropdownFilterChip(
          label: isAuthorActive ? selectedAuthor.label : 'Author',
          semanticLabel: 'Author',
          icon: Icons.person_outline_rounded,
          isSelected: isAuthorActive,
          tooltip: 'Filter by author',
          onPressed: () => _selectOption<String?>(
            context: context,
            title: 'Author',
            options: authorOptions,
            selectedValue: provider.selectedAuthor,
            onSelected: provider.setAuthorFilter,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'language',
        defaultOrder: 4,
        isActive: isLanguageActive,
        child: _DropdownFilterChip(
          label: isLanguageActive ? selectedLanguage.label : 'Language',
          semanticLabel: 'Language',
          icon: Icons.language_rounded,
          isSelected: isLanguageActive,
          tooltip: 'Filter by language',
          onPressed: () => _selectOption<String?>(
            context: context,
            title: 'Language',
            options: languageOptions,
            selectedValue: provider.selectedLanguage,
            onSelected: provider.setLanguageFilter,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'format',
        defaultOrder: 5,
        isActive: isFormatActive,
        child: _DropdownFilterChip(
          label: isFormatActive ? selectedFormat.label : 'Format',
          semanticLabel: 'Format',
          icon: Icons.description_outlined,
          isSelected: isFormatActive,
          tooltip: 'Filter by format',
          onPressed: () => _selectOption<String?>(
            context: context,
            title: 'Format',
            options: formatOptions,
            selectedValue: provider.selectedFormat,
            onSelected: provider.setFormatFilter,
          ),
        ),
      ),
      _ChipEntry(
        id: 'topic',
        defaultOrder: 6,
        isActive: isTopicActive,
        child: _DropdownFilterChip(
          label: isTopicActive ? selectedTopic.label : 'Topic',
          semanticLabel: 'Topic',
          icon: Icons.label_outline_rounded,
          isSelected: isTopicActive,
          tooltip: 'Filter by topic',
          onPressed: () => _selectOption<String?>(
            context: context,
            title: 'Topic',
            options: topicOptions,
            selectedValue: provider.selectedTopicId,
            onSelected: provider.setTopicFilter,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'shelf',
        defaultOrder: 7,
        isActive: isShelfActive,
        child: _DropdownFilterChip(
          label: isShelfActive ? selectedShelf.label : 'Shelf',
          semanticLabel: 'Shelf',
          icon: Icons.folder_outlined,
          isSelected: isShelfActive,
          tooltip: 'Filter by shelf',
          onPressed: () => _selectOption<String?>(
            context: context,
            title: 'Shelf',
            options: shelfOptions,
            selectedValue: provider.selectedShelfId,
            onSelected: provider.setShelfFilter,
            searchable: true,
          ),
        ),
      ),
      _ChipEntry(
        id: 'view-mode',
        defaultOrder: 8,
        isActive: isViewModeActive,
        child: _DropdownFilterChip(
          label: selectedViewMode.label,
          semanticLabel: 'View mode',
          icon: Icons.grid_on,
          isSelected: isViewModeActive,
          tooltip: 'Change view mode',
          onPressed: () => _selectOption<LibraryViewMode>(
            context: context,
            title: 'View mode',
            options: _viewModeOptions,
            selectedValue: provider.viewMode,
            onSelected: provider.setViewMode,
          ),
        ),
      ),
      // if (showDownloading)
      //   _ChipEntry(
      //     id: 'downloading',
      //     defaultOrder: 3,
      //     isActive: isDownloadingSelected,
      //     child: FilterChip(
      //       shape: const StadiumBorder(),
      //       avatar: const Icon(Icons.downloading_outlined, size: 18),
      //       label: const Text('Downloading'),
      //       selected: isDownloadingSelected,
      //       onSelected: (_) {
      //         provider.resetFilters();
      //         onDownloadingTapped?.call();
      //       },
      //     ),
      //   ),
    ];

    final hasActiveSelections =
        isStatusActive ||
        isSortActive ||
        isFavoritesActive ||
        isAuthorActive ||
        isLanguageActive ||
        isFormatActive ||
        isTopicActive ||
        isShelfActive ||
        isDownloadingSelected ||
        isViewModeActive;

    chips.sort((a, b) {
      final activeComparison = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);

      if (activeComparison != 0) {
        return activeComparison;
      }

      return a.defaultOrder.compareTo(b.defaultOrder);
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

  Future<void> _selectOption<T>({
    required BuildContext context,
    required String title,
    required List<_SelectionOption<T>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
    bool searchable = false,
  }) async {
    final result = await _showSelectionSheet<T>(
      context,
      title: title,
      options: options,
      selectedValue: selectedValue,
      searchable: searchable,
    );

    if (result == null || result.value == selectedValue) {
      return;
    }

    onSelected(result.value);
    onLibraryFilterTapped?.call();
  }

  static List<_SelectionOption<String?>> _buildAuthorOptions(List<Book> books) {
    final authorsByKey = <String, String>{};

    for (final book in books) {
      for (final author in [book.author, ...book.coAuthors]) {
        final label = author.trim();
        if (label.isNotEmpty) {
          authorsByKey.putIfAbsent(label.toLowerCase(), () => label);
        }
      }
    }

    return _stringOptions(authorsByKey, icon: Icons.person_outline_rounded);
  }

  static List<_SelectionOption<String?>> _buildLanguageOptions(List<Book> books) {
    final languagesByKey = <String, String>{};

    for (final book in books) {
      final language = book.language;
      final key = normalizeBookLanguage(language);
      if (language != null && key != null) {
        languagesByKey.putIfAbsent(key, () => bookLanguageLabel(language));
      }
    }

    return _stringOptions(languagesByKey, icon: Icons.language_rounded);
  }

  static List<_SelectionOption<String?>> _buildFormatOptions(List<Book> books) {
    final formatsByKey = <String, String>{};

    for (final book in books) {
      final label = book.formatLabel;
      formatsByKey.putIfAbsent(label.toLowerCase(), () => label);
    }

    return _stringOptions(formatsByKey, icon: Icons.description_outlined);
  }

  static List<_SelectionOption<String?>> _buildTopicOptions(DataStore dataStore) {
    final options = [
      for (final topic in dataStore.tags)
        _SelectionOption<String?>(value: topic.id, label: topic.name, icon: Icons.label_outline_rounded),
    ]..sort((a, b) => _compareLabels(a.label, b.label));

    return [const _SelectionOption<String?>(value: null, label: 'All', icon: Icons.label_outline_rounded), ...options];
  }

  static List<_SelectionOption<String?>> _buildShelfOptions(DataStore dataStore) {
    final options = [
      for (final shelf in dataStore.shelves)
        _SelectionOption<String?>(value: shelf.id, label: shelf.name, icon: Icons.folder_outlined),
    ]..sort((a, b) => _compareLabels(a.label, b.label));

    return [const _SelectionOption<String?>(value: null, label: 'All', icon: Icons.folder_outlined), ...options];
  }

  static List<_SelectionOption<String?>> _stringOptions(Map<String, String> labelsByValue, {required IconData icon}) {
    final options =
        labelsByValue.entries
            .map((entry) => _SelectionOption<String?>(value: entry.key, label: entry.value, icon: icon))
            .toList()
          ..sort((a, b) => _compareLabels(a.label, b.label));

    return [_SelectionOption<String?>(value: null, label: 'All', icon: icon), ...options];
  }

  static _SelectionOption<String?> _selectedOption(List<_SelectionOption<String?>> options, String? selectedValue) {
    return options.firstWhere((option) => option.value == selectedValue, orElse: () => options.first);
  }

  static int _compareLabels(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}
