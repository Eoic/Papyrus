import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/search_filter.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';
import 'package:papyrus/widgets/filter/filter_bottom_sheet.dart';
import 'package:provider/provider.dart';

/// Dialog for building filters visually (used on desktop).
/// Returns the same [AppliedFilters] as [FilterBottomSheet].
class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  /// Show the filter dialog and return the applied filters.
  static Future<AppliedFilters?> show(BuildContext context) {
    return showDialog<AppliedFilters>(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _selectedAuthor;
  String? _selectedFormat;
  String? _selectedShelf;
  String? _selectedTopic;
  String? _selectedStatus;

  // Quick filters
  bool _filterReading = false;
  bool _filterFavorites = false;
  bool _filterFinished = false;
  bool _filterUnread = false;

  // Progress filter
  RangeValues _progressRange = const RangeValues(0, 100);
  bool _useProgressFilter = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final libraryProvider = context.read<LibraryProvider>();
    final query = libraryProvider.searchQuery;

    setState(() {
      _filterReading = libraryProvider.isFilterActive(
        LibraryFilterType.reading,
      );
      _filterFavorites = libraryProvider.isFilterActive(
        LibraryFilterType.favorites,
      );
      _filterFinished = libraryProvider.isFilterActive(
        LibraryFilterType.finished,
      );
      _filterUnread = libraryProvider.isFilterActive(LibraryFilterType.unread);
      _selectedShelf = libraryProvider.selectedShelf;
      _selectedTopic = libraryProvider.selectedTopic;

      // Parse existing search query to restore advanced filter values
      if (query.isNotEmpty) {
        double progressMin = 0;
        double progressMax = 100;
        bool hasProgress = false;

        final parsed = SearchQueryParser.parse(query);
        for (final filter in parsed.filters) {
          switch (filter.field) {
            case SearchField.author:
              _selectedAuthor = filter.value;
            case SearchField.format:
              _selectedFormat = filter.value;
            case SearchField.status:
              _selectedStatus = filter.value;
            case SearchField.shelf:
              _selectedShelf ??= filter.value;
            case SearchField.topic:
              _selectedTopic ??= filter.value;
            case SearchField.progress:
              hasProgress = true;
              if (filter.operator == SearchOperator.greaterThan) {
                progressMin = double.tryParse(filter.value) ?? 0;
              } else if (filter.operator == SearchOperator.lessThan) {
                progressMax = double.tryParse(filter.value) ?? 100;
              }
            default:
              break;
          }
        }

        if (hasProgress) {
          _useProgressFilter = true;
          _progressRange = RangeValues(progressMin, progressMax);
        }
      }
    });
  }

  void _applyFilters() {
    final result = AppliedFilters(
      author: _selectedAuthor?.isNotEmpty == true ? _selectedAuthor : null,
      format: _selectedFormat,
      shelf: _selectedShelf,
      topic: _selectedTopic,
      status: _selectedStatus,
      filterReading: _filterReading,
      filterFavorites: _filterFavorites,
      filterFinished: _filterFinished,
      filterUnread: _filterUnread,
      progressRange: _useProgressFilter ? _progressRange : null,
    );
    Navigator.of(context).pop(result);
  }

  void _clearFilters() {
    setState(() {
      _selectedAuthor = null;
      _selectedFormat = null;
      _selectedShelf = null;
      _selectedTopic = null;
      _selectedStatus = null;
      _filterReading = false;
      _filterFavorites = false;
      _filterFinished = false;
      _filterUnread = false;
      _progressRange = const RangeValues(0, 100);
      _useProgressFilter = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get unique values from DataStore for dropdowns
    final dataStore = context.read<DataStore>();
    final formats = dataStore.books.map((b) => b.formatLabel).toSet().toList()
      ..sort();
    final shelves = dataStore.shelves.map((s) => s.name).toList()..sort();
    final topics = dataStore.tags.map((t) => t.name).toList()..sort();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          const Text('Advanced filters'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick filters section
              Text(
                'Quick filters',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  FilterChip(
                    label: const Text('Reading'),
                    selected: _filterReading,
                    onSelected: (v) => setState(() => _filterReading = v),
                  ),
                  FilterChip(
                    label: const Text('Favorites'),
                    selected: _filterFavorites,
                    onSelected: (v) => setState(() => _filterFavorites = v),
                  ),
                  FilterChip(
                    label: const Text('Finished'),
                    selected: _filterFinished,
                    onSelected: (v) => setState(() => _filterFinished = v),
                  ),
                  FilterChip(
                    label: const Text('Unread'),
                    selected: _filterUnread,
                    onSelected: (v) => setState(() => _filterUnread = v),
                  ),
                ],
              ),

              const SizedBox(height: Spacing.sm),
              const Divider(),
              const SizedBox(height: Spacing.sm),

              // Advanced filters section
              Text(
                'Advanced filters',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Author filter
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Enter author name...',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: (v) => _selectedAuthor = v,
              ),
              const SizedBox(height: Spacing.md),

              // Format dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedFormat,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Any format'),
                  ),
                  ...formats.map(
                    (f) => DropdownMenuItem(
                      value: f.toLowerCase(),
                      child: Text(f),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedFormat = v),
              ),
              const SizedBox(height: Spacing.md),

              // Shelf dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedShelf,
                decoration: const InputDecoration(
                  labelText: 'Shelf',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any shelf')),
                  ...shelves.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedShelf = v),
              ),
              const SizedBox(height: Spacing.md),

              // Topic dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedTopic,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any topic')),
                  ...topics.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedTopic = v),
              ),
              const SizedBox(height: Spacing.md),

              // Status dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Any status')),
                  DropdownMenuItem(
                    value: 'reading',
                    child: Text('Currently reading'),
                  ),
                  DropdownMenuItem(value: 'finished', child: Text('Finished')),
                  DropdownMenuItem(value: 'unread', child: Text('Unread')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
              const SizedBox(height: Spacing.md),

              // Progress range slider
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: IconSizes.small,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${_progressRange.start.toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(
                        context,
                      ).copyWith(overlayShape: SliderComponentShape.noOverlay),
                      child: RangeSlider(
                        values: _progressRange,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        onChanged: (v) => setState(() {
                          _progressRange = v;
                          _useProgressFilter = true;
                        }),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${_progressRange.end.toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear all'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: Spacing.sm),
            FilledButton(
              onPressed: _applyFilters,
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ],
    );
  }
}
