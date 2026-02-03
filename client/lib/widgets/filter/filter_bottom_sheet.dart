import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Filter options available for dropdowns.
class FilterOptions {
  final List<String> formats;
  final List<String> shelves;
  final List<String> topics;
  final List<String> statuses;

  const FilterOptions({
    this.formats = const [],
    this.shelves = const [],
    this.topics = const [],
    this.statuses = const ['reading', 'finished', 'unread'],
  });

  factory FilterOptions.fromBooks(List<BookData> books) {
    return FilterOptions(
      formats: books.map((b) => b.formatLabel.toLowerCase()).toSet().toList()
        ..sort(),
      shelves: books.expand((b) => b.shelves).toSet().toList()..sort(),
      topics: books.expand((b) => b.topics).toSet().toList()..sort(),
    );
  }
}

/// Callback data when filters are applied.
class AppliedFilters {
  final String? author;
  final String? format;
  final String? shelf;
  final String? topic;
  final String? status;
  final bool filterReading;
  final bool filterFavorites;
  final bool filterFinished;
  final bool filterUnread;
  final RangeValues? progressRange;

  const AppliedFilters({
    this.author,
    this.format,
    this.shelf,
    this.topic,
    this.status,
    this.filterReading = false,
    this.filterFavorites = false,
    this.filterFinished = false,
    this.filterUnread = false,
    this.progressRange,
  });

  /// Convert to query string.
  String toQueryString() {
    final parts = <String>[];

    if (author != null && author!.isNotEmpty) {
      parts.add('author:"$author"');
    }
    if (format != null) {
      parts.add('format:$format');
    }
    if (shelf != null) {
      parts.add('shelf:"$shelf"');
    }
    if (topic != null) {
      parts.add('topic:"$topic"');
    }
    if (status != null) {
      parts.add('status:$status');
    }
    if (progressRange != null) {
      if (progressRange!.start > 0) {
        parts.add('progress:>${progressRange!.start.toInt()}');
      }
      if (progressRange!.end < 100) {
        parts.add('progress:<${progressRange!.end.toInt()}');
      }
    }

    return parts.join(' ');
  }

  bool get hasFilters {
    return author != null ||
        format != null ||
        shelf != null ||
        topic != null ||
        status != null ||
        filterReading ||
        filterFavorites ||
        filterFinished ||
        filterUnread ||
        progressRange != null;
  }
}

/// Bottom sheet for building advanced filters visually.
class FilterBottomSheet extends StatefulWidget {
  /// Available filter options.
  final FilterOptions filterOptions;

  /// Callback when filters are applied.
  final ValueChanged<AppliedFilters>? onApply;

  /// Callback when reset is requested.
  final VoidCallback? onReset;

  /// Initial filter values.
  final AppliedFilters? initialFilters;

  const FilterBottomSheet({
    super.key,
    required this.filterOptions,
    this.onApply,
    this.onReset,
    this.initialFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();

  /// Show the filter bottom sheet.
  static Future<AppliedFilters?> show(
    BuildContext context, {
    required FilterOptions filterOptions,
    AppliedFilters? initialFilters,
  }) {
    return showModalBottomSheet<AppliedFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: FilterBottomSheet(
            filterOptions: filterOptions,
            initialFilters: initialFilters,
            onApply: (filters) => Navigator.of(context).pop(filters),
            onReset: () => Navigator.of(context).pop(null),
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final TextEditingController _authorController = TextEditingController();

  String? _selectedFormat;
  String? _selectedShelf;
  String? _selectedTopic;
  String? _selectedStatus;

  bool _filterReading = false;
  bool _filterFavorites = false;
  bool _filterFinished = false;
  bool _filterUnread = false;

  RangeValues _progressRange = const RangeValues(0, 100);
  bool _useProgressFilter = false;

  @override
  void initState() {
    super.initState();
    _loadInitialFilters();
  }

  void _loadInitialFilters() {
    final initial = widget.initialFilters;
    if (initial != null) {
      _authorController.text = initial.author ?? '';
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
    }
  }

  @override
  void dispose() {
    _authorController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = AppliedFilters(
      author: _authorController.text.isNotEmpty ? _authorController.text : null,
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
    widget.onApply?.call(filters);
  }

  void _resetFilters() {
    setState(() {
      _authorController.clear();
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
    // Apply empty filters to actually clear them
    widget.onApply?.call(const AppliedFilters());
  }

  String _buildQueryPreview() {
    final parts = <String>[];

    if (_authorController.text.isNotEmpty) {
      parts.add('author:"${_authorController.text}"');
    }
    if (_selectedFormat != null) {
      parts.add('format:$_selectedFormat');
    }
    if (_selectedShelf != null) {
      parts.add('shelf:"$_selectedShelf"');
    }
    if (_selectedTopic != null) {
      parts.add('topic:"$_selectedTopic"');
    }
    if (_selectedStatus != null) {
      parts.add('status:$_selectedStatus');
    }
    if (_filterReading) parts.add('status:reading');
    if (_filterFinished) parts.add('status:finished');

    return parts.isEmpty ? 'No filters applied' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: Spacing.sm),
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          child: Row(
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick filters section
                _buildSectionHeader('Quick filters'),
                const SizedBox(height: Spacing.sm),
                _buildQuickFilters(),

                const SizedBox(height: Spacing.md),
                const Divider(),
                const SizedBox(height: Spacing.md),

                // Advanced filters section
                _buildSectionHeader('Filter by'),
                const SizedBox(height: Spacing.md),

                // Author field
                _buildFilterField(
                  label: 'Author',
                  icon: Icons.person_outline,
                  child: TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      hintText: 'Enter author name...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // Format dropdown
                _buildFilterField(
                  label: 'Format',
                  icon: Icons.book_outlined,
                  child: DropdownMenu<String>(
                    initialSelection: _selectedFormat,
                    expandedInsets: EdgeInsets.zero,
                    hintText: 'Any format',
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: '', label: 'Any format'),
                      ...widget.filterOptions.formats.map(
                        (f) =>
                            DropdownMenuEntry(value: f, label: f.toUpperCase()),
                      ),
                    ],
                    onSelected: (v) => setState(
                      () => _selectedFormat = v?.isEmpty == true ? null : v,
                    ),
                  ),
                ),

                // Shelf dropdown
                _buildFilterField(
                  label: 'Shelf',
                  icon: Icons.folder_outlined,
                  child: DropdownMenu<String>(
                    initialSelection: _selectedShelf,
                    expandedInsets: EdgeInsets.zero,
                    hintText: 'Any shelf',
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: '', label: 'Any shelf'),
                      ...widget.filterOptions.shelves.map(
                        (s) => DropdownMenuEntry(value: s, label: s),
                      ),
                    ],
                    onSelected: (v) => setState(
                      () => _selectedShelf = v?.isEmpty == true ? null : v,
                    ),
                  ),
                ),

                // Topic dropdown
                _buildFilterField(
                  label: 'Topic',
                  icon: Icons.label_outline,
                  child: DropdownMenu<String>(
                    initialSelection: _selectedTopic,
                    expandedInsets: EdgeInsets.zero,
                    hintText: 'Any topic',
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: '', label: 'Any topic'),
                      ...widget.filterOptions.topics.map(
                        (t) => DropdownMenuEntry(value: t, label: t),
                      ),
                    ],
                    onSelected: (v) => setState(
                      () => _selectedTopic = v?.isEmpty == true ? null : v,
                    ),
                  ),
                ),

                // Status dropdown
                _buildFilterField(
                  label: 'Status',
                  icon: Icons.schedule,
                  child: DropdownMenu<String>(
                    initialSelection: _selectedStatus,
                    expandedInsets: EdgeInsets.zero,
                    hintText: 'Any status',
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: '', label: 'Any status'),
                      DropdownMenuEntry(
                        value: 'reading',
                        label: 'Currently reading',
                      ),
                      DropdownMenuEntry(value: 'finished', label: 'Finished'),
                      DropdownMenuEntry(value: 'unread', label: 'Unread'),
                    ],
                    onSelected: (v) => setState(
                      () => _selectedStatus = v?.isEmpty == true ? null : v,
                    ),
                  ),
                ),

                // Progress range slider
                _buildFilterField(
                  label: 'Progress',
                  icon: Icons.show_chart,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Filter by progress'),
                        value: _useProgressFilter,
                        onChanged: (v) =>
                            setState(() => _useProgressFilter = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_useProgressFilter)
                        RangeSlider(
                          values: _progressRange,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          labels: RangeLabels(
                            '${_progressRange.start.toInt()}%',
                            '${_progressRange.end.toInt()}%',
                          ),
                          onChanged: (v) => setState(() => _progressRange = v),
                        ),
                    ],
                  ),
                ),

                // Query preview
                _buildQueryPreviewSection(),
              ],
            ),
          ),
        ),

        // Action bar
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _applyFilters,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _QuickFilterCheckbox(
          label: 'Reading',
          icon: Icons.auto_stories,
          value: _filterReading,
          onChanged: (v) => setState(() => _filterReading = v ?? false),
        ),
        _QuickFilterCheckbox(
          label: 'Favorites',
          icon: Icons.favorite,
          value: _filterFavorites,
          onChanged: (v) => setState(() => _filterFavorites = v ?? false),
        ),
        _QuickFilterCheckbox(
          label: 'Finished',
          icon: Icons.check_circle,
          value: _filterFinished,
          onChanged: (v) => setState(() => _filterFinished = v ?? false),
        ),
        _QuickFilterCheckbox(
          label: 'Unread',
          icon: Icons.book,
          value: _filterUnread,
          onChanged: (v) => setState(() => _filterUnread = v ?? false),
        ),
      ],
    );
  }

  Widget _buildFilterField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: IconSizes.small,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildQueryPreviewSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _buildQueryPreview();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Query: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            preview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickFilterCheckbox extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _QuickFilterCheckbox({
    required this.label,
    required this.icon,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged?.call(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: (MediaQuery.of(context).size.width - Spacing.md * 3) / 2,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        decoration: BoxDecoration(
          color: value
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: value ? null : Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Icon(
              icon,
              size: IconSizes.small,
              color: value
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: TextStyle(
                color: value
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
