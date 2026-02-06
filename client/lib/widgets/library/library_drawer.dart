import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Navigation drawer for the library section on mobile.
///
/// Provides navigation to the different library sub-sections:
/// Books, Shelves, Topics, Bookmarks, Annotations, and Notes.
class LibraryDrawer extends StatelessWidget {
  /// The current route path, used to determine which item is selected.
  final String currentPath;

  const LibraryDrawer({super.key, this.currentPath = '/library'});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Text(
                'Library',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: Spacing.sm),
            // Navigation items with horizontal padding for rounded corners
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Column(
                children: [
                  _DrawerNavItem(
                    icon: Icons.book,
                    label: 'Books',
                    isSelected:
                        currentPath == '/library' ||
                        currentPath == '/library/books',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/library');
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.shelves,
                    label: 'Shelves',
                    isSelected: currentPath == '/library/shelves',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/library/shelves');
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.bookmark,
                    label: 'Bookmarks',
                    isSelected: currentPath == '/library/bookmarks',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/library/bookmarks');
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.format_quote,
                    label: 'Annotations',
                    isSelected: currentPath == '/library/annotations',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/library/annotations');
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.note,
                    label: 'Notes',
                    isSelected: currentPath == '/library/notes',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/library/notes');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item for the library drawer.
class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
