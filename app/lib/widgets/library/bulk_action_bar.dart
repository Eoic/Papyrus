import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Row of bulk action buttons used in both the contextual header (desktop)
/// and the bottom bar (mobile).
class BulkActionBar extends StatelessWidget {
  final VoidCallback? onAddToShelf;
  final VoidCallback? onManageTopics;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;

  const BulkActionBar({
    super.key,
    this.onAddToShelf,
    this.onManageTopics,
    this.onChangeStatus,
    this.onToggleFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.folder_outlined),
          tooltip: 'Add to shelf',
          onPressed: onAddToShelf,
        ),
        const SizedBox(width: Spacing.xs),
        IconButton(
          icon: const Icon(Icons.label_outline),
          tooltip: 'Manage topics',
          onPressed: onManageTopics,
        ),
        const SizedBox(width: Spacing.xs),
        IconButton(
          icon: const Icon(Icons.auto_stories),
          tooltip: 'Change status',
          onPressed: onChangeStatus,
        ),
        const SizedBox(width: Spacing.xs),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          tooltip: 'Toggle favorite',
          onPressed: onToggleFavorite,
        ),
        const SizedBox(width: Spacing.xs),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
