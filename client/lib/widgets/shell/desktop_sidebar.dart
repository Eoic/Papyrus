import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:papyrus/providers/sidebar_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';
import 'package:provider/provider.dart';

/// Desktop sidebar with collapsible navigation.
/// Expanded: 280px with labels
/// Collapsed: 72px with icons only
class DesktopSidebar extends StatelessWidget {
  final List<AppShellNavItem> items;
  final String currentPath;
  final void Function(String path) onNavigate;

  const DesktopSidebar({
    super.key,
    required this.items,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = context.watch<SidebarProvider>();
    final isCollapsed = sidebarProvider.isCollapsed;
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarWidth = sidebarProvider.sidebarWidth;

    return ClipRect(
      child: SizedBox(
        width: sidebarWidth,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: sidebarWidth,
          child: SizedBox(
            width: sidebarWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Logo area
                  _buildLogoArea(context, isCollapsed),
                  const Divider(height: 1),

                  // Navigation items
                  Expanded(
                    child: ListView(
                      clipBehavior: Clip.hardEdge,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      children: items.map((item) {
                        return _buildNavItem(context, item, isCollapsed);
                      }).toList(),
                    ),
                  ),

                  // Collapse toggle
                  const Divider(height: 1),
                  _buildCollapseToggle(context, isCollapsed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoArea(BuildContext context, bool isCollapsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: ComponentSizes.appBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            // Logo icon from SVG
            SvgPicture.asset(
              isDark
                  ? 'assets/images/logo-icon-dark.svg'
                  : 'assets/images/logo-icon-light.svg',
              width: 40,
              height: 40,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: Spacing.sm),
              // Papyrus text in Madimi One font
              Flexible(
                child: Text(
                  'Papyrus',
                  style: TextStyle(
                    fontFamily: 'MadimiOne',
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AppShellNavItem item,
    bool isCollapsed,
  ) {
    final isSelected = _isItemSelected(item);
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final sidebarProvider = context.read<SidebarProvider>();

    if (hasChildren && !isCollapsed) {
      return _buildExpandableNavItem(context, item, isCollapsed);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            if (hasChildren && isCollapsed) {
              // When collapsed with children, expand sidebar and navigate
              sidebarProvider.setCollapsed(false);
              sidebarProvider.setLibraryExpanded(true);
            }
            onNavigate(item.path);
          },
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? Spacing.md : Spacing.md,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  isSelected ? item.selectedIcon ?? item.icon : item.icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: IconSizes.navigation,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableNavItem(
    BuildContext context,
    AppShellNavItem item,
    bool isCollapsed,
  ) {
    final sidebarProvider = context.watch<SidebarProvider>();
    final isExpanded =
        item.path == '/library' && sidebarProvider.isLibraryExpanded;
    final isSelected = _isItemSelected(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent item
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 2,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () {
                if (item.path == '/library') {
                  sidebarProvider.toggleLibraryExpanded();
                }
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                decoration: BoxDecoration(
                  color: isSelected && !isExpanded
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon ?? item.icon : item.icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: IconSizes.navigation,
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: isExpanded ? pi : 0,
                      child: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: IconSizes.indicator,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Children (instant visibility, no animation)
        if (isExpanded)
          Column(
            children: item.children!.map((child) {
              return _buildChildNavItem(context, child);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildChildNavItem(BuildContext context, AppShellNavItem item) {
    final isSelected = currentPath.startsWith(item.path);

    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.xl + Spacing.sm,
        right: Spacing.sm,
        top: 2,
        bottom: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => onNavigate(item.path),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon ?? item.icon : item.icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: IconSizes.small,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseToggle(BuildContext context, bool isCollapsed) {
    final sidebarProvider = context.read<SidebarProvider>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => sidebarProvider.toggleCollapsed(),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: Spacing.md),
                Text(
                  '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isItemSelected(AppShellNavItem item) {
    if (currentPath == item.path) return true;
    if (currentPath.startsWith(item.path) && item.path != '/') return true;
    if (item.children != null) {
      return item.children!.any((child) => currentPath.startsWith(child.path));
    }
    return false;
  }
}
