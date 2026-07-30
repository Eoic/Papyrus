import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Plain-text book search used by library views.
class LibrarySearchBar extends StatefulWidget {
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
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

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
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
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    widget.onQueryChanged?.call(value);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {});
    widget.onQueryChanged?.call('');
  }

  Widget _buildFilterButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveFilters = widget.activeFilterCount > 0;
    final semanticLabel = hasActiveFilters
        ? 'Advanced filters, ${widget.activeFilterCount} active'
        : 'Advanced filters';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              tooltip: semanticLabel,
              onPressed: widget.onFilterTap,
            ),
            if (hasActiveFilters)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.activeFilterCount}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search books...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty && widget.onFilterTap == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch, tooltip: 'Clear'),
                  if (widget.onFilterTap != null) _buildFilterButton(context),
                ],
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      ),
      onChanged: _onQueryChanged,
    );
  }
}
