import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/filter/filter_bottom_sheet.dart';

/// Dialog for building filters visually (used on desktop).
/// Returns the same [AppliedFilters] as [FilterBottomSheet].
class FilterDialog extends StatefulWidget {
  /// Available filter options for dropdowns.
  final FilterOptions filterOptions;

  /// Initial filter values to populate the dialog.
  final AppliedFilters? initialFilters;

  const FilterDialog({
    super.key,
    required this.filterOptions,
    this.initialFilters,
  });

  /// Show the filter dialog and return the applied filters.
  static Future<AppliedFilters?> show(
    BuildContext context, {
    required FilterOptions filterOptions,
    AppliedFilters? initialFilters,
  }) {
    return showDialog<AppliedFilters>(
      context: context,
      builder: (context) => FilterDialog(
        filterOptions: filterOptions,
        initialFilters: initialFilters,
      ),
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
    _loadInitialFilters();
  }

  void _loadInitialFilters() {
    final initial = widget.initialFilters;
    if (initial == null) return;

    setState(() {
      _selectedAuthor = initial.author;
      _selectedFormat = initial.format;
      _selectedShelf = initial.shelf;
      _selectedTopic = initial.topic;
      _selectedStatus = initial.status;
      _filterReading = initial.filterReading;
      _filterFavorites = initial.filterFavorites;
      _filterFinished = initial.filterFinished;
      _filterUnread = initial.filterUnread;
      if (initial.progressRange != null) {
        _progressRange = initial.progressRange!;
        _useProgressFilter = true;
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

    final formats = widget.filterOptions.formats;
    final shelves = widget.filterOptions.shelves;
    final topics = widget.filterOptions.topics;

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
                controller: TextEditingController(text: _selectedAuthor),
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
                      child: Text(f.toUpperCase()),
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
