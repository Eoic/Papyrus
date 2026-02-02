import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';
import 'package:provider/provider.dart';

/// Advanced search bar with query language support and filter dropdown.
class AdvancedSearchBar extends StatefulWidget {
  final double? width;
  final bool showFilterButton;

  /// Callback when focus changes.
  final ValueChanged<bool>? onFocusChanged;

  /// Height of the search bar.
  final double height;

  const AdvancedSearchBar({
    super.key,
    this.width,
    this.showFilterButton = true,
    this.onFocusChanged,
    this.height = 48,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideSuggestions();
    }
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _showSuggestionsOverlay() {
    if (_suggestions.isEmpty) return;

    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion),
                    onTap: () => _applySuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applySuggestion(String suggestion) {
    final text = _controller.text;
    final lastSpace = text.lastIndexOf(' ');
    final prefix = lastSpace >= 0 ? text.substring(0, lastSpace + 1) : '';
    _controller.text = '$prefix$suggestion';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _hideSuggestions();
    _onSearchChanged(_controller.text);
  }

  void _updateSuggestions(String text) {
    final lastWord = text.split(' ').last.toLowerCase();

    if (lastWord.isEmpty) {
      _suggestions = [];
      _hideSuggestions();
      return;
    }

    // Check if typing a field name
    if (!lastWord.contains(':')) {
      _suggestions = SearchQueryParser.fieldSuggestions
          .where((s) => s.toLowerCase().startsWith(lastWord))
          .toList();
    }
    // Check if typing status value
    else if (lastWord.startsWith('status:')) {
      final value = lastWord.substring(7);
      _suggestions = SearchQueryParser.statusSuggestions
          .where((s) => s.toLowerCase().contains(value))
          .toList();
    }
    // Check if typing format value
    else if (lastWord.startsWith('format:')) {
      final value = lastWord.substring(7);
      _suggestions = SearchQueryParser.formatSuggestions
          .where((s) => s.toLowerCase().contains(value))
          .toList();
    } else {
      _suggestions = [];
    }

    if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestions();
    }
  }

  void _onSearchChanged(String value) {
    _updateSuggestions(value);

    final libraryProvider = context.read<LibraryProvider>();
    libraryProvider.setSearchQuery(value);
  }

  void _clearSearch() {
    _controller.clear();
    _hideSuggestions();
    final libraryProvider = context.read<LibraryProvider>();
    libraryProvider.clearSearch();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const _FilterBuilderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final libraryProvider = context.watch<LibraryProvider>();

    // Sync controller with provider if needed
    if (_controller.text != libraryProvider.searchQuery && !_focusNode.hasFocus) {
      _controller.text = libraryProvider.searchQuery;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search books... (e.g., author:tolkien)',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _clearSearch,
                    tooltip: 'Clear search',
                  ),
                if (widget.showFilterButton)
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: libraryProvider.hasActiveAdvancedFilters
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _showFilterDialog,
                    tooltip: 'Advanced filters',
                  ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }
}

/// Dialog for building filters visually.
class _FilterBuilderDialog extends StatefulWidget {
  const _FilterBuilderDialog();

  @override
  State<_FilterBuilderDialog> createState() => _FilterBuilderDialogState();
}

class _FilterBuilderDialogState extends State<_FilterBuilderDialog> {
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

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final libraryProvider = context.read<LibraryProvider>();
    setState(() {
      _filterReading = libraryProvider.isFilterActive(LibraryFilterType.reading);
      _filterFavorites = libraryProvider.isFilterActive(LibraryFilterType.favorites);
      _filterFinished = libraryProvider.isFilterActive(LibraryFilterType.finished);
      _selectedShelf = libraryProvider.selectedShelf;
      _selectedTopic = libraryProvider.selectedTopic;
    });
  }

  void _applyFilters() {
    final libraryProvider = context.read<LibraryProvider>();
    final parts = <String>[];

    // Build query from filters
    if (_selectedAuthor != null && _selectedAuthor!.isNotEmpty) {
      parts.add('author:"$_selectedAuthor"');
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

    // Apply quick filters
    if (_filterReading) {
      libraryProvider.addFilter(LibraryFilterType.reading);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.reading);
    }
    if (_filterFavorites) {
      libraryProvider.addFilter(LibraryFilterType.favorites);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.favorites);
    }
    if (_filterFinished) {
      libraryProvider.addFilter(LibraryFilterType.finished);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.finished);
    }

    // Set search query from advanced filters
    if (parts.isNotEmpty) {
      libraryProvider.setSearchQuery(parts.join(' '));
    }

    Navigator.of(context).pop();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get unique values from sample books for dropdowns
    final books = BookData.sampleBooks;
    final formats = books.map((b) => b.formatLabel).toSet().toList()..sort();
    final shelves = books.expand((b) => b.shelves).toSet().toList()..sort();
    final topics = books.expand((b) => b.topics).toSet().toList()..sort();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          const Text('Advanced filters'),
        ],
      ),
      content: SizedBox(
        width: 400,
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

              const SizedBox(height: Spacing.lg),
              const Divider(),
              const SizedBox(height: Spacing.md),

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
                  const DropdownMenuItem(value: null, child: Text('Any format')),
                  ...formats.map(
                    (f) => DropdownMenuItem(value: f.toLowerCase(), child: Text(f)),
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
                  DropdownMenuItem(value: 'reading', child: Text('Currently reading')),
                  DropdownMenuItem(value: 'finished', child: Text('Finished')),
                  DropdownMenuItem(value: 'unread', child: Text('Unread')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear all'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _applyFilters,
          child: const Text('Apply filters'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.start,
    );
  }
}
