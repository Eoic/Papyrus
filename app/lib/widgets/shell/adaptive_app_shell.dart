import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shell/desktop_sidebar.dart';
import 'package:papyrus/widgets/shell/eink_bottom_nav.dart';
import 'package:papyrus/widgets/shell/mobile_bottom_nav.dart';
import 'package:provider/provider.dart';

/// Navigation item for the app shell.
class AppShellNavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final List<AppShellNavItem>? children;
  final int? count;

  const AppShellNavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.children,
    this.count,
  });
}

/// Main app shell that adapts to platform and display mode.
/// - Desktop: Permanent collapsible sidebar
/// - Mobile: Bottom navigation bar
/// - E-ink: Text-based bottom navigation
class AdaptiveAppShell extends StatelessWidget {
  final Widget child;

  const AdaptiveAppShell({super.key, required this.child});

  static List<AppShellNavItem> buildNavItems(DataStore dataStore) {
    return [
      const AppShellNavItem(
        path: '/dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      AppShellNavItem(
        path: '/library',
        label: 'Library',
        icon: Icons.library_books_outlined,
        selectedIcon: Icons.library_books,
        children: [
          AppShellNavItem(
            path: '/library/books',
            label: 'Books',
            icon: Icons.menu_book_outlined,
            count: dataStore.books.length,
            selectedIcon: Icons.menu_book,
          ),
          AppShellNavItem(
            path: '/library/shelves',
            label: 'Shelves',
            icon: Icons.shelves,
            count: dataStore.shelves.length,
            selectedIcon: Icons.shelves,
          ),
          AppShellNavItem(
            path: '/library/bookmarks',
            label: 'Bookmarks',
            icon: Icons.bookmark_outline,
            count: dataStore.bookmarks.length,
            selectedIcon: Icons.bookmark,
          ),
          AppShellNavItem(
            path: '/library/annotations',
            label: 'Annotations',
            icon: Icons.border_color_outlined,
            count: dataStore.annotations.length,
            selectedIcon: Icons.border_color,
          ),
          AppShellNavItem(
            path: '/library/notes',
            label: 'Notes',
            icon: Icons.notes_outlined,
            count: dataStore.notes.length,
            selectedIcon: Icons.notes,
          ),
        ],
      ),
      const AppShellNavItem(
        path: '/goals',
        label: 'Goals',
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
      ),
      const AppShellNavItem(
        path: '/statistics',
        label: 'Statistics',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
      ),
      const AppShellNavItem(
        path: '/profile',
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final dataStore = context.watch<DataStore>();
    final navItems = buildNavItems(dataStore);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    // E-ink mode uses special text-based navigation
    if (prefs.isEinkMode) {
      return _buildEinkShell(context, navItems);
    }

    // Desktop uses sidebar, mobile uses bottom nav
    if (isDesktop) {
      return _buildDesktopShell(context, navItems);
    } else {
      return _buildMobileShell(context, navItems);
    }
  }

  Widget _buildDesktopShell(
    BuildContext context,
    List<AppShellNavItem> navItems,
  ) {
    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(
            items: navItems,
            currentPath: GoRouterState.of(context).uri.toString(),
            onNavigate: (path) => context.go(path),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMobileShell(
    BuildContext context,
    List<AppShellNavItem> navItems,
  ) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isInLibrary = currentPath.startsWith('/library');

    return Scaffold(
      body: child,
      bottomNavigationBar: MobileBottomNav(
        items: navItems,
        currentPath: currentPath,
        onNavigate: (path) => context.go(path),
      ),
      drawer: isInLibrary ? _buildLibraryDrawer(context, navItems) : null,
    );
  }

  Widget _buildEinkShell(
    BuildContext context,
    List<AppShellNavItem> navItems,
  ) {
    return Scaffold(
      body: child,
      bottomNavigationBar: EinkBottomNav(
        items: navItems,
        currentPath: GoRouterState.of(context).uri.toString(),
        onNavigate: (path) => context.go(path),
      ),
    );
  }

  Widget _buildLibraryDrawer(
    BuildContext context,
    List<AppShellNavItem> navItems,
  ) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final libraryItem = navItems.firstWhere(
      (item) => item.path == '/library',
    );
    final children = libraryItem.children ?? [];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                'Library',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final item = children[index];
                  final isSelected = currentPath.startsWith(item.path);

                  return ListTile(
                    leading: Icon(
                      isSelected ? item.selectedIcon ?? item.icon : item.icon,
                    ),
                    title: Text(item.label),
                    selected: isSelected,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(item.path);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
