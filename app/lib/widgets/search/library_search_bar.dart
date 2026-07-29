import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Plain-text book search used by library views.
class LibrarySearchBar extends StatefulWidget {
  final ValueChanged<String>? onQueryChanged;
  final String initialQuery;

  const LibrarySearchBar({super.key, this.onQueryChanged, this.initialQuery = ''});

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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search books...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch, tooltip: 'Clear'),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      ),
      onChanged: _onQueryChanged,
    );
  }
}
