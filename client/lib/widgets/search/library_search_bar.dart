import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/search_query_parser.dart';

/// Search bar with query language support and filter button.
/// Used for both mobile and desktop library views.
/// Suggestions appear as an overlay (like IDE autocomplete) and support
/// keyboard navigation (arrow keys, Tab/Enter to select, Escape to dismiss).
class LibrarySearchBar extends StatefulWidget {
  /// Callback when search query changes.
  final ValueChanged<String>? onQueryChanged;

  /// Callback when filter button is tapped.
  final VoidCallback? onFilterTap;

  /// Current active filter count for badge.
  final int activeFilterCount;

  /// Initial search query.
  final String initialQuery;

  const LibrarySearchBar({
    super.key,
    this.onQueryChanged,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.initialQuery = '',
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(LibrarySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery && !_focusNode.hasFocus) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
      setState(() {
        _suggestions = [];
        _selectedIndex = -1;
      });
    }
  }

  void _onQueryChanged(String value) {
    _updateSuggestions(value);
    widget.onQueryChanged?.call(value);
  }

  void _updateSuggestions(String text) {
    final lastWord = text.split(' ').last.toLowerCase();

    if (lastWord.isEmpty) {
      _suggestions = [];
      _selectedIndex = -1;
      _removeOverlay();
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

    _suggestions = newSuggestions;
    _selectedIndex = newSuggestions.isEmpty ? -1 : 0;
    _showOrUpdateOverlay();
  }

  void _applySuggestion(String suggestion) {
    final text = _controller.text;
    final lastSpace = text.lastIndexOf(' ');
    final prefix = lastSpace >= 0 ? text.substring(0, lastSpace + 1) : '';
    _controller.text = '$prefix$suggestion';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _suggestions = [];
    _selectedIndex = -1;
    _removeOverlay();
    _onQueryChanged(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onQueryChanged?.call('');
    _suggestions = [];
    _selectedIndex = -1;
    _removeOverlay();
  }

  // ---------------------------------------------------------------------------
  // Overlay management
  // ---------------------------------------------------------------------------

  void _showOrUpdateOverlay() {
    if (_suggestions.isEmpty || !_focusNode.hasFocus) {
      _removeOverlay();
      return;
    }
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: AppElevation.level3,
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: colorScheme.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              child: TextFieldTapRegion(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        final isHighlighted = index == _selectedIndex;
                        return _SuggestionTile(
                          suggestion: suggestion,
                          isHighlighted: isHighlighted,
                          onTap: () => _applySuggestion(suggestion),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Keyboard navigation
  // ---------------------------------------------------------------------------

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_suggestions.isEmpty) return KeyEventResult.ignored;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
      _showOrUpdateOverlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _selectedIndex =
          (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
      _showOrUpdateOverlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _suggestions.length) {
        _applySuggestion(_suggestions[_selectedIndex]);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.escape) {
      _suggestions = [];
      _selectedIndex = -1;
      _removeOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  Widget _buildFilterButton(ColorScheme colorScheme) {
    return Stack(
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
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search books...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                    tooltip: 'Clear',
                  ),
                _buildFilterButton(colorScheme),
              ],
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          onChanged: _onQueryChanged,
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String suggestion;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.isHighlighted,
    required this.onTap,
  });

  IconData _getIconForSuggestion(String suggestion) {
    final lower = suggestion.toLowerCase();
    if (lower.startsWith('author')) return Icons.person_outline;
    if (lower.startsWith('format')) return Icons.book_outlined;
    if (lower.startsWith('shelf')) return Icons.folder_outlined;
    if (lower.startsWith('topic')) return Icons.label_outline;
    if (lower.startsWith('status')) return Icons.schedule;
    if (lower.startsWith('progress')) return Icons.show_chart;
    return Icons.search;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final platform = Theme.of(context).platform;
    final isDesktopPlatform =
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isHighlighted
            ? colorScheme.primary.withValues(alpha: 0.12)
            : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              _getIconForSuggestion(suggestion),
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: IconSizes.small,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  color: isHighlighted
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (isHighlighted && isDesktopPlatform)
              Text(
                'Tab',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
