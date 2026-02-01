import 'package:flutter/material.dart';
import 'package:papyrus/utils/navigation_utils.dart';
import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';

/// Mobile bottom navigation bar with Material 3 styling.
class MobileBottomNav extends StatelessWidget {
  final List<AppShellNavItem> items;
  final String currentPath;
  final void Function(String path) onNavigate;

  const MobileBottomNav({
    super.key,
    required this.items,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Only show main nav items (no children in bottom nav)
    final mainItems = items.where((item) => !isChildPath(item.path)).toList();
    final currentIndex = _getCurrentIndex(mainItems);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final item = mainItems[index];
        // For library, navigate to books subpage
        if (item.path == '/library') {
          onNavigate('/library/books');
        } else {
          onNavigate(item.path);
        }
      },
      destinations: mainItems.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon ?? item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }

  int _getCurrentIndex(List<AppShellNavItem> mainItems) {
    for (var i = 0; i < mainItems.length; i++) {
      if (isNavItemSelected(currentPath, mainItems[i])) {
        return i;
      }
    }
    return 0;
  }
}
