import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book/private_book_cover.dart';
import 'package:papyrus/themes/app_motion.dart';

/// Context menu for book actions.
class BookContextMenu {
  static void show({
    required BuildContext context,
    required Book book,
    required bool isFavorite,
    Offset? tapPosition,
    VoidCallback? onSelect,
    VoidCallback? onFavoriteToggle,
    VoidCallback? onEdit,
    VoidCallback? onMoveToShelf,
    VoidCallback? onManageTopics,
    Function(LibraryReadingStatus)? onStatusChange,
    VoidCallback? onDownload,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.animationStyle(context),
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (context) => _BookContextBottomSheet(
        book: book,
        isFavorite: isFavorite,
        onSelect: onSelect,
        onFavoriteToggle: onFavoriteToggle,
        onEdit: onEdit,
        onMoveToShelf: onMoveToShelf,
        onManageTopics: onManageTopics,
        onStatusChange: onStatusChange,
        onDownload: onDownload,
        onDelete: onDelete,
      ),
    );
  }

  static void _confirmDelete(BuildContext context, Book book, VoidCallback? onDelete) {
    showDialog(
      animationStyle: AppMotion.animationStyle(context),
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for mobile context menu.
class _BookContextBottomSheet extends StatelessWidget {
  final Book book;
  final bool isFavorite;
  final VoidCallback? onSelect;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onMoveToShelf;
  final VoidCallback? onManageTopics;
  final Function(LibraryReadingStatus)? onStatusChange;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const _BookContextBottomSheet({
    required this.book,
    required this.isFavorite,
    this.onSelect,
    this.onFavoriteToggle,
    this.onEdit,
    this.onMoveToShelf,
    this.onManageTopics,
    this.onStatusChange,
    this.onDownload,
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
                decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Book info header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(width: 48, height: 72, child: _buildCover(context)),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: Spacing.md),
            const Divider(),

            // Select action
            _BottomSheetItem(
              icon: Icons.checklist,
              label: 'Select',
              onTap: () {
                Navigator.pop(context);
                onSelect?.call();
              },
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              child: Text(
                'Reading status',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            _BottomSheetItem(
              icon: Icons.auto_stories,
              label: 'Reading',
              isSelected: book.readingStatus == LibraryReadingStatus.inProgress,
              onTap: () {
                Navigator.pop(context);
                onStatusChange?.call(LibraryReadingStatus.inProgress);
              },
            ),
            _BottomSheetItem(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              isSelected: book.readingStatus == LibraryReadingStatus.completed,
              onTap: () {
                Navigator.pop(context);
                onStatusChange?.call(LibraryReadingStatus.completed);
              },
            ),
            _BottomSheetItem(
              icon: Icons.bookmark_outline,
              label: 'Unread',
              isSelected: book.readingStatus == LibraryReadingStatus.unread,
              onTap: () {
                Navigator.pop(context);
                onStatusChange?.call(LibraryReadingStatus.unread);
              },
            ),

            const Divider(),

            if (!book.isPhysical)
              _BottomSheetItem(
                icon: Icons.file_download_outlined,
                label: 'Download',
                onTap: () {
                  Navigator.pop(context);
                  onDownload?.call();
                },
              ),
            _BottomSheetItem(
              icon: Icons.delete_outline,
              label: 'Delete',
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
    final placeholder = Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.menu_book, color: colorScheme.onSurfaceVariant),
    );
    return CoverImage(bookId: book.id, imageUrl: book.coverURL, mediaId: book.coverMediaId, placeholder: placeholder);
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
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary, size: IconSizes.small) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      visualDensity: VisualDensity.compact,
    );
  }
}
