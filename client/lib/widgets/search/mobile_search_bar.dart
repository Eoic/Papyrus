import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';

/// Mobile search bar with query language support and filter button.
/// Features:
/// - Pill-shaped search field
/// - Query syntax suggestions
/// - Filter button with badge
/// - Recent searches
class MobileSearchBar extends StatefulWidget {
  /// Callback when search query changes.
  final ValueChanged<String>? onQueryChanged;

  /// Callback when filter button is tapped.
  final VoidCallback? onFilterTap;

  /// Current active filter count for badge.
  final int activeFilterCount;

  /// Whether to show voice search button.
  final bool showVoiceSearch;

  /// Initial search query.
  final String initialQuery;

  const MobileSearchBar({
    super.key,
    this.onQueryChanged,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.showVoiceSearch = false,
    this.initialQuery = '',
  });

  @override
  State<MobileSearchBar> createState() => _MobileSearchBarState();
}

class _MobileSearchBarState extends State<MobileSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(MobileSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery && !_focusNode.hasFocus) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (!_isFocused) {
        _suggestions = [];
      }
    });
  }

  void _onQueryChanged(String value) {
    _updateSuggestions(value);
    widget.onQueryChanged?.call(value);
  }

  void _updateSuggestions(String text) {
    final lastWord = text.split(' ').last.toLowerCase();

    if (lastWord.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    List<String> newSuggestions = [];

    // Check if typing a field name
    if (!lastWord.contains(':')) {
      newSuggestions = SearchQueryParser.fieldSuggestions
          .where((s) => s.toLowerCase().startsWith(lastWord))
          .toList();
    }
    // Check if typing status value
    else if (lastWord.startsWith('status:')) {
      final value = lastWord.substring(7);
      newSuggestions = SearchQueryParser.statusSuggestions
          .where((s) => s.toLowerCase().contains(value))
          .toList();
    }
    // Check if typing format value
    else if (lastWord.startsWith('format:')) {
      final value = lastWord.substring(7);
      newSuggestions = SearchQueryParser.formatSuggestions
          .where((s) => s.toLowerCase().contains(value))
          .toList();
    }

    setState(() => _suggestions = newSuggestions);
  }

  void _applySuggestion(String suggestion) {
    final text = _controller.text;
    final lastSpace = text.lastIndexOf(' ');
    final prefix = lastSpace >= 0 ? text.substring(0, lastSpace + 1) : '';
    _controller.text = '$prefix$suggestion';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _onQueryChanged(_controller.text);
    setState(() => _suggestions = []);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onQueryChanged?.call('');
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Row(
            children: [
              const SizedBox(width: Spacing.md),
              Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: IconSizes.medium,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search books...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: _onQueryChanged,
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: _clearSearch,
                  tooltip: 'Clear',
                ),
              if (widget.showVoiceSearch)
                IconButton(
                  icon: Icon(Icons.mic, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    // Voice search not implemented
                  },
                  tooltip: 'Voice search',
                ),
              // Filter button with badge
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: widget.activeFilterCount > 0
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: widget.onFilterTap,
                    tooltip: 'Filters',
                  ),
                  if (widget.activeFilterCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${widget.activeFilterCount}',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: Spacing.xs),
            ],
          ),
        ),

        // Suggestions dropdown
        if (_suggestions.isNotEmpty && _isFocused)
          Container(
            margin: const EdgeInsets.only(top: Spacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return _SuggestionTile(
                  suggestion: suggestion,
                  onTap: () => _applySuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.onTap});

  IconData _getIconForSuggestion(String suggestion) {
    if (suggestion.startsWith('author:')) return Icons.person_outline;
    if (suggestion.startsWith('format:')) return Icons.book_outlined;
    if (suggestion.startsWith('shelf:')) return Icons.folder_outlined;
    if (suggestion.startsWith('topic:')) return Icons.label_outline;
    if (suggestion.startsWith('status:')) return Icons.schedule;
    if (suggestion.startsWith('progress:')) return Icons.show_chart;

    // Field name suggestions
    if (suggestion == 'author:') return Icons.person_outline;
    if (suggestion == 'format:') return Icons.book_outlined;
    if (suggestion == 'shelf:') return Icons.folder_outlined;
    if (suggestion == 'topic:') return Icons.label_outline;
    if (suggestion == 'status:') return Icons.schedule;
    if (suggestion == 'progress:') return Icons.show_chart;

    return Icons.search;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        _getIconForSuggestion(suggestion),
        color: colorScheme.onSurfaceVariant,
        size: IconSizes.small,
      ),
      title: Text(suggestion),
      onTap: onTap,
    );
  }
}
