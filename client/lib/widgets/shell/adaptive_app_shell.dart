import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
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

  const AppShellNavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.children,
  });
}

/// Main app shell that adapts to platform and display mode.
/// - Desktop: Permanent collapsible sidebar
/// - Mobile: Bottom navigation bar
/// - E-ink: Text-based bottom navigation
class AdaptiveAppShell extends StatelessWidget {
  final Widget child;

  const AdaptiveAppShell({super.key, required this.child});

  static const List<AppShellNavItem> mainNavItems = [
    AppShellNavItem(
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
          label: 'All books',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
        ),
        AppShellNavItem(
          path: '/library/shelves',
          label: 'Shelves',
          icon: Icons.shelves,
          selectedIcon: Icons.shelves,
        ),
        AppShellNavItem(
          path: '/library/topics',
          label: 'Topics',
          icon: Icons.topic_outlined,
          selectedIcon: Icons.topic,
        ),
        AppShellNavItem(
          path: '/library/bookmarks',
          label: 'Bookmarks',
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
        ),
        AppShellNavItem(
          path: '/library/annotations',
          label: 'Annotations',
          icon: Icons.border_color_outlined,
          selectedIcon: Icons.border_color,
        ),
        AppShellNavItem(
          path: '/library/notes',
          label: 'Notes',
          icon: Icons.notes_outlined,
          selectedIcon: Icons.notes,
        ),
      ],
    ),
    AppShellNavItem(
      path: '/goals',
      label: 'Goals',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
    ),
    AppShellNavItem(
      path: '/statistics',
      label: 'Statistics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    AppShellNavItem(
      path: '/profile',
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    // E-ink mode uses special text-based navigation
    if (displayMode.isEinkMode) {
      return _buildEinkShell(context);
    }

    // Desktop uses sidebar, mobile uses bottom nav
    if (isDesktop) {
      return _buildDesktopShell(context);
    } else {
      return _buildMobileShell(context);
    }
  }

  Widget _buildDesktopShell(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(
            items: mainNavItems,
            currentPath: GoRouterState.of(context).uri.toString(),
            onNavigate: (path) => context.go(path),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMobileShell(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isInLibrary = currentPath.startsWith('/library');

    return Scaffold(
      body: child,
      bottomNavigationBar: MobileBottomNav(
        items: mainNavItems,
        currentPath: currentPath,
        onNavigate: (path) => context.go(path),
      ),
      drawer: isInLibrary ? _buildLibraryDrawer(context) : null,
    );
  }

  Widget _buildEinkShell(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: EinkBottomNav(
        items: mainNavItems,
        currentPath: GoRouterState.of(context).uri.toString(),
        onNavigate: (path) => context.go(path),
      ),
    );
  }

  Widget _buildLibraryDrawer(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final libraryItem = mainNavItems.firstWhere(
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
