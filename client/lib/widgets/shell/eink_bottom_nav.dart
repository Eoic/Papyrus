import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/navigation_utils.dart';
import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';

/// E-ink optimized bottom navigation with text labels and high contrast.
/// Uses larger touch targets and no animations.
class EinkBottomNav extends StatelessWidget {
  final List<AppShellNavItem> items;
  final String currentPath;
  final void Function(String path) onNavigate;

  const EinkBottomNav({
    super.key,
    required this.items,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Only show main nav items
    final mainItems = items.where((item) => !isChildPath(item.path)).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: TouchTargets.einkRecommended,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline,
            width: BorderWidths.einkDefault,
          ),
        ),
      ),
      child: Row(
        children: mainItems.map((item) {
          final isSelected = isNavItemSelected(currentPath, item);
          return Expanded(child: _buildNavItem(context, item, isSelected));
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AppShellNavItem item,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // For library, navigate to books subpage
          if (item.path == '/library') {
            onNavigate('/library/books');
          } else {
            onNavigate(item.path);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            border: Border(
              left: BorderSide(color: colorScheme.outline, width: 1),
            ),
          ),
          child: Center(
            child: Text(
              item.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
