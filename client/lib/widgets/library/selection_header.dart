import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Contextual header shown when selection mode is active.
/// Replaces the normal library header with close, count, select all, and actions.
class SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final Widget? actions;

  const SelectionHeader({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onClose,
    required this.onSelectAll,
    required this.onDeselectAll,
    this.actions,
  });

  bool get _allSelected => selectedCount >= totalCount && totalCount > 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Exit selection',
          onPressed: onClose,
        ),
        const SizedBox(width: Spacing.sm),
        Text(
          '$selectedCount selected',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: Spacing.md),
        TextButton(
          onPressed: _allSelected ? onDeselectAll : onSelectAll,
          child: Text(_allSelected ? 'Deselect all' : 'Select all'),
        ),
        const Spacer(),
        if (actions != null) actions!,
      ],
    );
  }
}
