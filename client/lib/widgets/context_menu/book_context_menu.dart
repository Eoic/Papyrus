import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Context menu for book actions.
/// Shows a bottom sheet on mobile and a popup menu on desktop.
class BookContextMenu {
  /// Show the context menu for a book.
  static void show({
    required BuildContext context,
    required BookData book,
    required bool isFavorite,
    Offset? tapPosition,
    VoidCallback? onFavoriteToggle,
    VoidCallback? onEdit,
    VoidCallback? onMoveToShelf,
    VoidCallback? onManageTopics,
    Function(ReadingStatus)? onStatusChange,
    VoidCallback? onDelete,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop && tapPosition != null) {
      _showDesktopMenu(
        context: context,
        position: tapPosition,
        book: book,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        onEdit: onEdit,
        onMoveToShelf: onMoveToShelf,
        onManageTopics: onManageTopics,
        onStatusChange: onStatusChange,
        onDelete: onDelete,
      );
    } else {
      _showMobileSheet(
        context: context,
        book: book,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        onEdit: onEdit,
        onMoveToShelf: onMoveToShelf,
        onManageTopics: onManageTopics,
        onStatusChange: onStatusChange,
        onDelete: onDelete,
      );
    }
  }

  static void _showDesktopMenu({
    required BuildContext context,
    required Offset position,
    required BookData book,
    required bool isFavorite,
    VoidCallback? onFavoriteToggle,
    VoidCallback? onEdit,
    VoidCallback? onMoveToShelf,
    VoidCallback? onManageTopics,
    Function(ReadingStatus)? onStatusChange,
    VoidCallback? onDelete,
  }) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final colorScheme = Theme.of(context).colorScheme;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      elevation: AppElevation.level2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      items: [
        PopupMenuItem(
          value: 'favorite',
          height: 40,
          child: _MenuItemRow(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            iconColor: isFavorite ? colorScheme.error : null,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          height: 40,
          child: _MenuItemRow(icon: Icons.edit_outlined, label: 'Edit details'),
        ),
        const PopupMenuItem(
          value: 'shelf',
          height: 40,
          child: _MenuItemRow(
            icon: Icons.folder_outlined,
            label: 'Move to shelf',
          ),
        ),
        const PopupMenuItem(
          value: 'topics',
          height: 40,
          child: _MenuItemRow(
            icon: Icons.label_outline,
            label: 'Manage topics',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'reading',
          height: 40,
          child: _MenuItemRow(
            icon: Icons.auto_stories,
            label: 'Mark as reading',
            isSelected: book.isReading,
          ),
        ),
        PopupMenuItem(
          value: 'finished',
          height: 40,
          child: _MenuItemRow(
            icon: Icons.check_circle_outline,
            label: 'Mark as finished',
            isSelected: book.isFinished,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          height: 40,
          child: _MenuItemRow(
            icon: Icons.delete_outline,
            label: 'Delete book',
            isDestructive: true,
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (!context.mounted) return;

      switch (value) {
        case 'favorite':
          onFavoriteToggle?.call();
        case 'edit':
          onEdit?.call();
        case 'shelf':
          onMoveToShelf?.call();
        case 'topics':
          onManageTopics?.call();
        case 'reading':
          onStatusChange?.call(ReadingStatus.inProgress);
        case 'finished':
          onStatusChange?.call(ReadingStatus.completed);
        case 'delete':
          _confirmDelete(context, book, onDelete);
      }
    });
  }

  static void _showMobileSheet({
    required BuildContext context,
    required BookData book,
    required bool isFavorite,
    VoidCallback? onFavoriteToggle,
    VoidCallback? onEdit,
    VoidCallback? onMoveToShelf,
    VoidCallback? onManageTopics,
    Function(ReadingStatus)? onStatusChange,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => _BookContextBottomSheet(
        book: book,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        onEdit: onEdit,
        onMoveToShelf: onMoveToShelf,
        onManageTopics: onManageTopics,
        onStatusChange: onStatusChange,
        onDelete: onDelete,
      ),
    );
  }

  static void _confirmDelete(
    BuildContext context,
    BookData book,
    VoidCallback? onDelete,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Menu item row for desktop popup menu.
class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool isSelected;
  final Color? iconColor;

  const _MenuItemRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.isSelected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : null;
    final effectiveIconColor = iconColor ?? color;

    return Row(
      children: [
        Icon(icon, size: IconSizes.action, color: effectiveIconColor),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(label, style: TextStyle(color: color)),
        ),
        if (isSelected)
          Icon(Icons.check, size: IconSizes.small, color: colorScheme.primary),
      ],
    );
  }
}

/// Bottom sheet for mobile context menu.
class _BookContextBottomSheet extends StatelessWidget {
  final BookData book;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onMoveToShelf;
  final VoidCallback? onManageTopics;
  final Function(ReadingStatus)? onStatusChange;
  final VoidCallback? onDelete;

  const _BookContextBottomSheet({
    required this.book,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onEdit,
    this.onMoveToShelf,
    this.onManageTopics,
    this.onStatusChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Book info header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 48,
                    height: 72,
                    child: _buildCover(context),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.author,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: Spacing.md),
            const Divider(),

            // Action items
            _BottomSheetItem(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              iconColor: isFavorite ? colorScheme.error : null,
              onTap: () {
                Navigator.pop(context);
                onFavoriteToggle?.call();
              },
            ),
            _BottomSheetItem(
              icon: Icons.edit_outlined,
              label: 'Edit details',
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            _BottomSheetItem(
              icon: Icons.folder_outlined,
              label: 'Move to shelf',
              onTap: () {
                Navigator.pop(context);
                onMoveToShelf?.call();
              },
            ),
            _BottomSheetItem(
              icon: Icons.label_outline,
              label: 'Manage topics',
              onTap: () {
                Navigator.pop(context);
                onManageTopics?.call();
              },
            ),

            const Divider(),

            // Reading status section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Text(
                'Reading status',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _BottomSheetItem(
              icon: Icons.auto_stories,
              label: 'Currently reading',
              isSelected: book.isReading,
              onTap: () {
                Navigator.pop(context);
                onStatusChange?.call(ReadingStatus.inProgress);
              },
            ),
            _BottomSheetItem(
              icon: Icons.check_circle_outline,
              label: 'Finished',
              isSelected: book.isFinished,
              onTap: () {
                Navigator.pop(context);
                onStatusChange?.call(ReadingStatus.completed);
              },
            ),
            _BottomSheetItem(
              icon: Icons.bookmark_outline,
              label: 'Unread',
              isSelected: book.progress == 0 && !book.isFinished,
              onTap: () {
                Navigator.pop(context);
                onStatusChange?.call(ReadingStatus.notStarted);
              },
            ),

            const Divider(),

            _BottomSheetItem(
              icon: Icons.delete_outline,
              label: 'Delete book',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                // Use a post-frame callback to ensure context is valid
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  BookContextMenu._confirmDelete(context, book, onDelete);
                });
              },
            ),

            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (book.coverURL != null && book.coverURL!.isNotEmpty) {
      return Image.network(
        book.coverURL!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.menu_book, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.menu_book, color: colorScheme.onSurfaceVariant),
    );
  }
}

/// Bottom sheet action item.
class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isSelected;
  final Color? iconColor;

  const _BottomSheetItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
    this.isSelected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : null;
    final effectiveIconColor = iconColor ?? color;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(label, style: TextStyle(color: color)),
      trailing: isSelected
          ? Icon(Icons.check, color: colorScheme.primary, size: IconSizes.small)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      visualDensity: VisualDensity.compact,
    );
  }
}
